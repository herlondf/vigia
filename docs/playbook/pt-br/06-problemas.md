# 6. Problemas comuns

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| Faixa "Falha na busca" no topo | Rede, VPN ou token | Leia a mensagem. Jira interno: ligue a VPN. Token vencido: edite a conta e cole um novo |
| "Testar conexão" fala de escopo | Token do GitHub sem `repo` ou `notifications` | Crie um token classic com os escopos de [Contas](02-contas.md#github) |
| Sem comentários e menções do GitHub | Token fine-grained | Use token classic |
| Prazo do Projects não aparece | Falta `read:project` ou o nome do campo está errado | Adicione o escopo e confira o nome exato do campo no Projects |
| Instalei e não chegou aviso nenhum | Primeira busca só registra o estado | Espere a próxima mudança. **Mostrar aviso** testa o popup |
| Avisos não aparecem à noite | Não perturbe ligado | **Configurações › Notificações › Não perturbe** |
| Uma issue parou de avisar | Silenciada | Botão direito › **Reativar avisos** |
| Chip "Sprint" não aparece | Nenhuma issue sua em sprint ativa, ou Jira sem Agile | Normal. Ele só aparece com itens |
| Assistente não executa ações | Provedor não é Anthropic | Troque para Anthropic em **Assistente de IA** |
| "Limite de US$ ... do mês atingido" | Teto mensal | Aumente em **IA automática › Limite por mês**, ou espere o mês virar |
| Abri pelo menu Iniciar e nada aconteceu | Janela já estava aberta atrás de outra | Duplo clique no ícone da bandeja |

## Onde ficam os dados

- Banco: `%LOCALAPPDATA%\Vigia\vigia.db`.
- Tokens: Credential Manager do Windows, entradas `Vigia:<id da conta>` e `Vigia:ai:<provedor>`.
- Programa: `%LOCALAPPDATA%\Programs\Vigia`.

## Começar do zero

1. Saia do Vigia (botão direito no ícone › **Sair**).
2. Apague `%LOCALAPPDATA%\Vigia\vigia.db`.
3. Abra o Vigia de novo e cadastre as contas.

Os tokens antigos ficam no Credential Manager até você apagar.

## Reportar um problema

Abra uma issue em [herlondf/vigia](https://github.com/herlondf/vigia/issues). Diga a versão (aparece no título da janela) e o que você fez antes do erro. Nunca cole tokens.
