# 3. Uso diário

## Topo da janela

- **Seletor de conta**: mostra uma conta ou todas.
- **Seletor de repositório** (com GitHub na tela): filtra por repositório. Vale para Issues, Dashboard e Ctrl+K.
- **Tema**: botão à direita troca claro e escuro.
- O anel à esquerda mostra o estado da busca. Passe o mouse para ver a hora da última.

## Atalhos

| Tecla | Faz |
|---|---|
| `Ctrl+K` | Busca issues e comandos; digitar `PROJ-123` ou `dono/repo#12` oferece **Acompanhar** |
| `F5` | Busca agora |
| `Ctrl+1` a `Ctrl+4` | Dashboard, Issues, Contas, Configurações |
| `Esc` | Fecha o painel ou esconde a janela |

Os atalhos também ficam no rodapé e são clicáveis.

## Dashboard

Números e gráficos para decidir por onde começar: acompanhadas, comigo, prazo perto, por status, por tag. No GitHub: por tipo, meus PRs e por repositório.

**Tudo é clicável.** O clique abre a aba Issues já filtrada.

## Issues

- **Filtros** (somam entre si): **Agora** (o que pede ação hoje: vence hoje ou venceu, menção, review pedido, PR com CI vermelho ou mudanças pedidas, issue sua impedida), Comigo, Atrasadas, Review, Manuais, Impedidas, Meus PRs e Sprint (Jira com sprint ativa).
- **Tags**: suas tags aparecem como chips. Somam entre si e filtram junto com os filtros.
- **Agrupar** (à direita, na linha das tags): separa a lista por repositório (GitHub) ou projeto (Jira). Clique no cabeçalho do grupo para recolher.
- Lista vazia mostra os filtros ligados e um botão para limpar.

Cada linha mostra chave, título, selos (status, prazo, impedida, tags) e, à direita, o vínculo (comigo, review, meu PR...) e a última atualização.

## Painel da issue

Clique numa issue para abrir o painel à direita.

- Ícones no topo: **IA** (resume a conversa e sugere resposta), **Registrar tempo** (Jira), **Abrir no navegador**, **Fechar**.
- **Comentários**: os últimos comentários. Escreva na caixa de baixo e envie pelo botão redondo.
- **Histórico**: os avisos que o Vigia deu desta issue.
- **Detalhes**: descrição, anexos e ligações.
- Em PR: linha do CI (clique abre o job que falhou) e revisores.

## Menu da issue (botão direito)

| Item | O que faz |
|---|---|
| Ver detalhes | Abre o painel |
| Mudar status... | Lista os status possíveis agora. Se a transição pede campos (ex.: Resolução), eles aparecem na tela |
| Abrir no navegador / Copiar chave | O nome diz |
| **Ações ›** | Atribuir a mim, Triar com IA, Aplicar sugestão da IA, Adicionar label (tag no Azure), Aprovar PR/MR, Abrir job que falhou. Jira e GitLab: Registrar horas. Jira: Mudar prioridade, Marcar/Tirar impedimento (o motivo vira comentário) |
| Silenciar até amanhã / até mudar status | Para os avisos desta issue (ver [Avisos](04-avisos.md)) |
| Tag › | Marca ou desmarca a issue numa tag, ou abre **Gerenciar tags** |
| Parar de acompanhar | Só nas issues acompanhadas à mão |

**Toda ação que grava no Jira ou no GitHub pede confirmação antes.**

## Janela mini

Botão direito no ícone da bandeja › **Janela mini**. Fica sempre por cima, com os números (Agora, Atrasadas, Comigo) e a lista "Agora". Clique numa linha para abrir a issue; arraste pelo topo para mover.

## Acompanhar uma issue que não é sua

`Ctrl+K`, digite `PROJ-123` (Jira), `dono/repo#12` (GitHub ou GitLab, `!5` para MR) ou `Projeto#123` (Azure DevOps) e escolha **Acompanhar**. O Vigia confere se ela existe antes de salvar.

## Tags

Tags agrupam issues por assunto ou projeto seu (ex.: `#Pagamentos`, `#Bug`). São locais e por conta.

1. Botão direito numa issue › **Tag › Gerenciar tags...**
2. Aba **Cadastro**: nome e palavras do título (separadas por vírgula ou ponto e vírgula). Issue com uma dessas palavras no título entra sozinha.
3. Para marcar uma issue à mão: botão direito › **Tag** › nome da tag.

## Horas

No Jira, o rodapé mostra quanto você já lançou hoje e na semana. A tela **Registrar tempo** tem atalhos de 30 min a 8 h.

Próximo: [Avisos](04-avisos.md)
