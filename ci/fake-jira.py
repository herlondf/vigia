"""Jira Server falso para o teste de tela (ci/ui-smoke.ps1). Dados inventados.
Uso: python ci/fake-jira.py <porta>"""
import json, re
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

NOW = datetime.now(timezone(timedelta(hours=-3)))
def iso(d): return d.strftime('%Y-%m-%dT%H:%M:%S.000-0300')
def day(n): return (NOW + timedelta(days=n)).strftime('%Y-%m-%d')

ME = {'name': 'ana', 'displayName': 'Ana Lima', 'emailAddress': 'ana@acme.example'}
PEOPLE = {'bruno': 'Bruno Costa', 'carla': 'Carla Souza', 'diego': 'Diego Alves', 'ana': 'Ana Lima'}
CAT = {'A fazer': 'new', 'Em andamento': 'indeterminate', 'Em revisão': 'indeterminate',
       'Em teste': 'indeterminate', 'Bloqueado': 'indeterminate'}

# chave, título, status, responsável, prazo (dias), impedida, comentários [(autor, texto, horas atrás)]
ISSUES = [
    ('APP-142', 'Checkout recusa cartão com vencimento no mês atual', 'Em andamento', 'ana', 1, False,
     [('bruno', 'Reproduzi com o cartão de teste 4111. Acontece só no último dia do mês.', 30),
      ('ana', 'Achei: a validação compara com o primeiro dia do mês. Corrijo hoje.', 20),
      ('carla', 'Consegue liberar até amanhã? O time de pagamentos precisa para o teste de regressão.', 2)]),
    ('APP-139', 'Pagamento via PIX não atualiza o pedido após confirmação', 'Em revisão', 'ana', 3, False,
     [('diego', 'O webhook chega, mas o pedido fica "aguardando". Log em anexo.', 50),
      ('ana', 'PR aberto com o retry do webhook. [~bruno] pode revisar?', 6)]),
    ('APP-151', 'Relatório de vendas exporta CSV com acentos quebrados', 'A fazer', 'ana', 6, False,
     [('carla', 'Cliente abriu no Excel e "Média" virou "MÃ©dia". Precisa de BOM.', 26)]),
    ('APP-133', 'Tela de login trava ao trocar de idioma', 'Bloqueado', 'ana', -2, True,
     [('ana', 'Aguardando a lib de i18n publicar a correção.', 72)]),
    ('APP-155', 'Novo filtro por status na lista de pedidos', 'A fazer', 'ana', 12, False, []),
    ('APP-148', 'Cupom de desconto aplicado duas vezes no carrinho', 'Em teste', 'bruno', 2, False,
     [('bruno', 'Corrigido na build 2.8.1. [~ana] consegue validar no ambiente de QA?', 4)]),
    ('APP-120', 'Timeout ao gerar boleto em horário de pico', 'Em andamento', 'diego', 0, True,
     [('diego', 'Impedimento: o banco não liberou o novo endpoint ainda.', 9)]),
    ('MOB-77', 'App Android fecha ao abrir notificação de pedido', 'Em andamento', 'ana', 4, False,
     [('carla', 'Crash só no Android 14. Stack trace no Crashlytics.', 40)]),
    ('MOB-81', 'Biometria não aparece no iOS 18', 'A fazer', 'carla', 9, False, []),
    ('MOB-69', 'Ícone do app cortado em telas pequenas', 'Em revisão', 'diego', None, False, []),
    ('APP-160', 'Documentar a API de pedidos para parceiros', 'A fazer', 'ana', None, False, []),
    ('APP-158', 'Melhorar mensagens de erro do checkout', 'Em teste', 'bruno', 5, False, []),
]
SPRINT = {'APP-142', 'APP-139', 'APP-148', 'MOB-77'}

def comment(author, text, hours):
    return {'author': {'name': author, 'displayName': PEOPLE[author]}, 'body': text,
            'created': iso(NOW - timedelta(hours=hours))}

def issue(t, i):
    key, title, status, who, due, flag, comments = t
    f = {'summary': title,
         'status': {'name': status, 'statusCategory': {'key': CAT[status]}},
         'assignee': {'name': who, 'displayName': PEOPLE[who]},
         'duedate': day(due) if due is not None else None,
         'updated': iso(NOW - timedelta(hours=1 + i * 3)),
         'comment': {'total': len(comments), 'comments': [comment(*c) for c in comments]},
         'customfield_10021': [{'value': 'Impediment'}] if flag else None,
         'description': 'Passos para reproduzir:\n# Abrir o app\n# Ir até o checkout\n# Ver o erro\n\n*Esperado:* concluir sem erro.',
         'attachment': [{'filename': 'log-checkout.txt', 'content': 'http://x', 'size': 18432}],
         'issuelinks': []}
    if who == 'ana':
        f['worklog'] = {'worklogs': [{'author': ME, 'started': iso(NOW - timedelta(days=d % 4, hours=2)),
                                      'timeSpentSeconds': 3600 * (1 + d % 3)} for d in range(i % 3 + 1)]}
    return {'key': key, 'fields': f}

ALL = [issue(t, i) for i, t in enumerate(ISSUES)]

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass

    def send(self, obj, code=200):
        b = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        u = urlparse(self.path); q = parse_qs(u.query); p = u.path
        if p == '/__bump':
            # Teste: comentário novo de outra pessoa na APP-142.
            it = next(x for x in ALL if x['key'] == 'APP-142')
            it['fields']['comment']['comments'].append(comment('bruno', 'Subiu no QA, pode validar?', 0))
            it['fields']['comment']['total'] += 1
            it['fields']['updated'] = iso(datetime.now(timezone(timedelta(hours=-3))))
            return self.send({'ok': True})
        if p.endswith('/myself'):
            return self.send(ME)
        if p.endswith('/field'):
            return self.send([{'id': 'customfield_10021', 'name': 'Flagged'}])
        if p.endswith('/search'):
            jql = q.get('jql', [''])[0]
            items = [x for x in ALL if x['key'] in SPRINT] if 'openSprints' in jql else ALL
            return self.send({'startAt': 0, 'maxResults': 100, 'total': len(items), 'issues': items})
        m = re.match(r'.*/issue/([A-Z]+-\d+)(/\w+)?$', p)
        if m:
            it = next((x for x in ALL if x['key'] == m.group(1)), None)
            if not it:
                return self.send({'errorMessages': ['not found']}, 404)
            if m.group(2) == '/comment':
                return self.send({'comments': list(reversed(it['fields']['comment']['comments']))})
            if m.group(2) == '/transitions':
                return self.send({'transitions': [
                    {'id': '11', 'name': 'Enviar para revisão', 'to': {'name': 'Em revisão'}},
                    {'id': '21', 'name': 'Concluir', 'to': {'name': 'Concluído'}}]})
            return self.send(it)
        if p.endswith('/priority'):
            return self.send([{'name': n} for n in ('Alta', 'Média', 'Baixa')])
        self.send({})

H.POSTS = []
def do_POST(self):
    n = int(self.headers.get('Content-Length', 0))
    H.POSTS.append((self.path, self.rfile.read(n).decode('utf-8', 'replace')))
    print('POST', self.path, H.POSTS[-1][1][:120], flush=True)
    self.send({'id': '999'}, 201)
H.do_POST = do_POST

import sys
ThreadingHTTPServer(('127.0.0.1', int(sys.argv[1]) if len(sys.argv) > 1 else 18080), H).serve_forever()
