# 4. Alerts

## When Vigia alerts you

Vigia polls every 5 minutes (adjustable) and compares with the previous poll. It alerts what changed, according to the alerts enabled on the account:

| Alert | When |
|---|---|
| Fui associado (Assigned to me) | The issue became yours |
| Novo comentário (New comment) | Someone else commented |
| Menção (Mention) | Someone mentioned you |
| Mudança de status (Status change) | The status changed |
| Prazo chegando / vencido (Due soon / overdue) | Based on the account's **Avisar com** days |
| Review de PR pedido (Review requested) | Your review was requested (GitHub) |
| Sinalizada (Flagged) | An impediment was flagged (Jira) |
| PR aprovado / Mudanças pedidas (PR approved / Changes requested) | Review on your PR (GitHub) |
| CI falhou (CI failed) | Your PR's CI turned red (GitHub) |

- On an account's **first poll** you only get "Acompanhando N itens" (Following N items). Alerts start after that.
- Many alerts at once become a single one listing the keys.
- **Ver no Vigia** (Open in Vigia) on the alert opens the issue.
- **Responder** (Reply) opens a box in the alert itself: type and press Enter to comment without opening Vigia.
- **Silenciar** (Mute) stops alerts for the issue until tomorrow at 8 am.

## Alert style

**Configurações › Notificações › Estilo do aviso** (Settings › Notifications › Alert style):
- **Popup do Vigia**: in the screen corner, with Dismiss and Open buttons. It waits while the mouse is over it.
- **Notificação do Windows**: the standard system notification.

**Tempo na tela** (Time on screen) sets how many seconds the popup stays. **Mostrar aviso** (Show alert) tests the style.

## Mute an issue

Right-click the issue:
- **Silenciar até amanhã**: no alerts until tomorrow at 8 am.
- **Silenciar até mudar status**: alerts again when the status changes.
- **Reativar avisos**: undo.

The issue history keeps recording while it is muted.

## Do not disturb

**Configurações › Notificações › Não perturbe**: during this time alerts wait and arrive together when it ends.

## Daily summary

**Configurações › Notificações › Resumo do dia**: one alert a day at the chosen time. It shows what is due, what is flagged and the comments of the last 24 h. With AI enabled, the text is written by it (see [Assistant](05-assistant.md)).

Next: [AI assistant](05-assistant.md)
