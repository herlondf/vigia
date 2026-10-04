# 5. AI assistant

The mascot in the window corner opens the chat. The assistant knows your issues, due dates and recent alerts.

## Set up

**Configurações › Assistente de IA** (Settings › AI assistant):

1. **Provedor** (Provider): Anthropic (Claude), OpenAI, xAI (Grok), DeepSeek, Groq, OpenRouter, Ollama (local) or another OpenAI-compatible API.
2. **Endereço da API** (API address): prefilled. Change it only for your own gateway or a remote Ollama.
3. **Chave** (Key): paste it and click **Salvar**. It is stored in the Credential Manager, one per provider.
4. **Modelo** (Model): type it, or click **Listar** to pick from the provider's list.
5. **Preço** (Price): Claude comes with the public price. For others, fill it in to see the cost.

> **Tools** (acting on Jira/GitHub and on the screen) only work with **Anthropic**. Other providers answer with text only.

## What to ask

Questions about your data:
- "What is due this week?"
- "Which issues are flagged and why?"
- "Summarize APP-123." (the assistant reads description and comments)

Actions (every write asks **Allow / Deny** in the chat):

| Ask | Tool |
|---|---|
| "Log 2h on PROJ-1 today, layout review" | Log work (Jira) |
| "Comment on PROJ-1 that the fix is live" | Comment |
| "Move PROJ-1 to In Progress" | Change status |
| "Flag PROJ-1: waiting for the customer" | Impediment (Jira) |
| "Assign PROJ-1 to me" | Assign |
| "Create an issue in project ABC: ..." | Create issue |
| "Open PROJ-1" / "Follow owner/repo#12" | Open on screen / Follow |
| "Create tag #Payments with the words payment, pix" | Create tag |
| "Show only overdue issues of tag #Payments" | Filter the list |

The assistant refuses status changes that need fields on the Jira screen. Use **right-click › Mudar status** instead.

## Thread summary

In the issue panel, the sparkle icon summarizes the comments. It also writes a draft reply in the comment box. **Nothing is sent** until you click send.

## Automatic AI (optional)

**Configurações › IA automática** (Automatic AI). Everything starts off.

| Option | What it does |
|---|---|
| Resumo do dia escrito pela IA (AI daily summary) | At the summary time, a short text on where to start |
| Alerta de risco (Risk alert) | Once a day, up to 3 issues likely to slip or get stuck |
| Rascunho de horas no fim do dia (End-of-day worklog draft) | At 5:30 pm on weekdays, suggests missing work logs. Ask the assistant "log the worklog draft" to log them |
| Causa da falha do CI (CI failure cause) | When one of your PRs turns red, reads the job log and explains |

## Spending control

- **Limite por mês (US$)** (Monthly cap): when reached, chat and automatic tasks stop until the month turns. `0` = no cap.
- **Modelo das tarefas automáticas** (Model for automatic tasks): a cheaper model for the tasks above. On Anthropic the default is `claude-haiku-4-5`.
- **Uso da IA** (AI usage): questions, tokens and cost for the month, in dollars and reais (daily rate).

Next: [Troubleshooting](06-troubleshooting.md)
