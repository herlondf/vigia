"""Tradução da interface do Vigia.

  python tools/i18n.py scan   lista os textos que seriam envolvidos em Tr()
  python tools/i18n.py wrap   envolve os textos de tela das units de UI em Tr()
  python tools/i18n.py keys   grava tools/i18n_keys.txt (todas as chaves em Tr e nas tabelas)
  python tools/i18n.py gen    gera src/Vigia.I18n.En.pas a partir de tools/i18n_en.tsv

O texto em português é a chave. tools/i18n_en.tsv: uma linha por frase,
"português<TAB>inglês", com \\n e \\t escapados.
"""
import re, sys, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'src')
UI_UNITS = ['Vigia.UI.Main.pas', 'Vigia.UI.Views.pas', 'Vigia.UI.Account.pas', 'Vigia.UI.Detail.pas',
            'Vigia.UI.Tags.pas', 'Vigia.UI.Status.pas', 'Vigia.UI.Notify.pas', 'Vigia.UI.Mini.pas',
            'Vigia.UI.Common.pas', 'Vigia.Diff.pas', 'Vigia.Backup.pas', 'Vigia.Update.pas']
# Tabelas constantes com texto de tela: traduzidas onde são usadas (Tr(Nome[...])).
TABLES = ['EventNames', 'FilterNames', 'PageTitles', 'UrlHints', 'TokenHints', 'FamilyNames',
          'ProviderNames', 'ShortProviderNames']
# Palavras soltas em minúscula que aparecem na tela (o resto em minúscula é chave/identificador).
LOWER_UI = {'comigo', 'atrasada', 'review', 'observando', 'manual', 'busca', 'mencionado', 'silenciada',
            'ligada', 'desligada', 'rascunho', 'agora', 'dias', 'min', 'sem'}
# Comparados com dado externo (resposta da IA): nunca traduzir.
SKIP_TEXT = {'Alta', 'Baixa', 'Média', 'NADA'}
SKIP = re.compile(r'https?:|<svg|<path|\{"|currentUser|statusCategory|ORDER BY|\[System\.|SELECT |'
                  r'yyyy|hh:nn|dd/mm|\\d|\^|application/|Mozilla|text/|api-version|wiql|'
                  r'^\s*$|^[%\d\s.,:;/()+\-*#!|]*$|^/|Vigia/|^Vigia:')
CONST_END = re.compile(r'^\s*(var|begin|type|function|procedure|constructor|destructor|implementation|'
                       r'initialization|finalization|class |end\.|resourcestring|\{\s*──)', re.I)


def tokens(s):
    """(tipo, início, fim): 'str' literal, 'cmt' comentário, 'code' resto."""
    i, n = 0, len(s)
    out = []
    start = 0
    while i < n:
        c = s[i]
        if c == "'":
            if start < i: out.append(('code', start, i))
            j = i + 1
            while j < n:
                if s[j] == "'":
                    if j + 1 < n and s[j + 1] == "'":
                        j += 2; continue
                    break
                j += 1
            out.append(('str', i, j + 1)); i = j + 1; start = i; continue
        if c == '{' or s.startswith('(*', i) or s.startswith('//', i):
            if start < i: out.append(('code', start, i))
            if c == '{': j = s.find('}', i) + 1
            elif s.startswith('(*', i): j = s.find('*)', i) + 2
            else:
                j = s.find('\n', i)
                j = n if j < 0 else j
            out.append(('cmt', i, j)); i = j; start = i; continue
        i += 1
    if start < n: out.append(('code', start, n))
    return out


def unq(lit):
    return lit[1:-1].replace("''", "'")


def groups(s):
    """Sequências literal ( + literal )* : (início, fim, texto, linha)."""
    toks = tokens(s)
    res = []
    k = 0
    while k < len(toks):
        t, a, b = toks[k]
        if t != 'str':
            k += 1; continue
        text = unq(s[a:b]); end = b; m = k + 1
        while m + 1 < len(toks) and toks[m][0] == 'code' and s[toks[m][1]:toks[m][2]].strip() == '+' \
                and toks[m + 1][0] == 'str':
            text += unq(s[toks[m + 1][1]:toks[m + 1][2]]); end = toks[m + 1][2]; m += 2
        res.append((a, end, text, s.count('\n', 0, a) + 1))
        k = m
    return res


def const_lines(s):
    """Linhas dentro de seções const (não aceitam chamada de função)."""
    inside = set(); on = False
    for no, line in enumerate(s.split('\n'), 1):
        st = line.strip().lower()
        if re.match(r'^const\b', st) or re.match(r'^(class )?const\b', st):
            on = True; inside.add(no); continue
        if on and CONST_END.match(line):
            on = False
        if on: inside.add(no)
    return inside


def qualifies(text):
    if SKIP.search(text) or text in SKIP_TEXT:
        return False
    if not re.search(r'[A-Za-zÀ-ú]{2,}', text):
        return False
    if re.fullmatch(r'[A-Z0-9_]+', text):
        return False
    if re.fullmatch(r'[a-z0-9_\-.*:#/]+', text):
        return text in LOWER_UI
    return True


def candidates(path):
    s = open(path, encoding='utf-8').read()
    consts = const_lines(s)
    lines = s.split('\n')
    out = []
    for a, b, text, line in groups(s):
        if line in consts:
            continue
        before = s[max(0, a - 40):a]
        ltxt = lines[line - 1]
        if re.search(r'\bTr\(\s*$', before):
            continue
        # cabeçalho com valor padrão, chaves de preferência/JSON, ids de menu e ícones
        if re.match(r'\s*(function|procedure|constructor|class )', ltxt):
            continue
        if re.search(r'(GetSetting|SetSetting|GetValue<[^>]*>|GetValue|FindValue|TryGetValue<[^>]*>|AddPair|'
                     r'HeroIcon|StartsWith|EndsWith|AddItem|AddSubmenu|SameText\(AID|AID\s*=|ID\s*:=|'
                     r'Register|AddParam|AppendFormat\(\'%s|MatchText|ContainsText|IndexText|'
                     r'AddStat|AddWidget|SetItemDetail|TimeSetting|\bId\s*=)\(?\s*$', before):
            if not re.search(r'AddItem\([^)]*,\s*$', before):   # 2º argumento do AddItem é a legenda
                continue
        if qualifies(text):
            out.append((a, b, text, line))
    return s, out


def cmd_scan():
    total = 0
    for u in UI_UNITS:
        s, c = candidates(os.path.join(SRC, u))
        total += len(c)
        for a, b, text, line in c:
            print(f'{u}:{line}: {text[:90]!r}')
    print('total', total, file=sys.stderr)


def cmd_wrap():
    for u in UI_UNITS:
        p = os.path.join(SRC, u)
        raw = open(p, 'rb').read()
        crlf = b'\r\n' in raw
        s, c = candidates(p)
        for a, b, text, line in reversed(c):
            s = s[:a] + 'Tr(' + s[a:b] + ')' + s[b:]
        for t in TABLES:
            s = re.sub(r'(?<![\w.])(?<!Tr\()(' + t + r'\[[^\]]+\])', r'Tr(\1)', s)
        if 'Vigia.I18n' not in s:
            s = re.sub(r'(\nimplementation\s*\n\s*uses\s*\n)', r'\1  Vigia.I18n,\n', s, count=1)
        out = s.replace('\r\n', '\n')
        if crlf: out = out.replace('\n', '\r\n')
        open(p, 'w', encoding='utf-8', newline='').write(out)
        print(u, len(c))


def all_keys():
    keys = []
    for f in os.listdir(SRC):
        if not f.endswith(('.pas', '.inc')): continue
        s = open(os.path.join(SRC, f), encoding='utf-8').read()
        toks = tokens(s)
        for a, b, text, line in groups(s):
            if re.search(r'\bTr\(\s*$', s[max(0, a - 10):a]):
                keys.append(text)
        for t in TABLES:
            m = re.search(t + r'\s*:\s*array[^=]*=\s*\((.*?)\);', s, re.S)
            if m:
                keys += [g[2] for g in groups(m.group(1))]
    seen = []
    for k in keys:
        if k not in seen and qualifies(k):
            seen.append(k)
    return seen


def esc(t): return t.replace('\\', '\\\\').replace('\t', '\\t').replace('\r\n', '\\n').replace('\n', '\\n')
def unesc(t): return t.replace('\\n', '\n').replace('\\t', '\t').replace('\\\\', '\\')


def cmd_keys():
    keys = all_keys()
    open(os.path.join(ROOT, 'tools', 'i18n_keys.txt'), 'w', encoding='utf-8').write(
        '\n'.join(esc(k) for k in keys) + '\n')
    print(len(keys), 'chaves')


def pas_lit(t):
    """Literal Delphi; quebra em pedaços de até 200 (limite de 255 por literal)."""
    t = t.replace('\r\n', '\n')
    parts = []
    for line_i, seg in enumerate(t.split('\n')):
        if line_i: parts.append('sLineBreak')
        for k in range(0, max(len(seg), 1), 200):
            piece = seg[k:k + 200]
            if piece or not seg: parts.append("'" + piece.replace("'", "''") + "'")
    parts = [p for p in parts if p != "''"] or ["''"]
    return ' + '.join(parts)


def cmd_gen():
    pairs = []
    for line in open(os.path.join(ROOT, 'tools', 'i18n_en.tsv'), encoding='utf-8'):
        line = line.rstrip('\n')
        if not line or (line.startswith('#') and '	' not in line): continue
        pt, en = line.split('\t', 1)
        pt, en = unesc(pt), unesc(en)
        # Espaço das pontas faz parte da frase montada no código: acompanha a chave.
        if pt.endswith(' ') and not en.endswith(' '): en += ' '
        if pt.startswith(' ') and not en.startswith(' '): en = ' ' + en
        pairs.append((pt, en))
    missing = [k for k in all_keys() if k not in dict(pairs)]
    body = ',\n'.join(f'    ({pas_lit(pt)},\n     {pas_lit(en)})' for pt, en in pairs)
    unit = ("unit Vigia.I18n.En;\n\n{ Gerado por tools/i18n.py a partir de tools/i18n_en.tsv. Não editar à mão. }\n\n"
            "interface\n\nconst\n"
            f"  EnPairs: array[0..{len(pairs) - 1}, 0..1] of string = (\n{body});\n\nimplementation\n\nend.\n")
    open(os.path.join(SRC, 'Vigia.I18n.En.pas'), 'w', encoding='utf-8', newline='').write(unit.replace('\n', '\r\n'))
    print(len(pairs), 'traduções;', len(missing), 'chaves sem tradução')
    for k in missing[:40]:
        print('  falta:', esc(k)[:100])


if __name__ == '__main__':
    {'scan': cmd_scan, 'wrap': cmd_wrap, 'keys': cmd_keys, 'gen': cmd_gen}[sys.argv[1]]()
