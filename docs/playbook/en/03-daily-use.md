# 3. Daily use

## Top of the window

- **Account selector**: shows one account or all of them.
- **Repository selector** (with GitHub on screen): filters by repository. Applies to Issues, Dashboard and Ctrl+K.
- **Theme**: the button on the right switches light and dark.
- The ring on the left shows the polling state. Hover it to see the last poll time.

## Shortcuts

| Key | Does |
|---|---|
| `Ctrl+K` | Search issues and commands; typing `PROJ-123` or `owner/repo#12` offers **Acompanhar** (Follow) |
| `F5` | Poll now |
| `Ctrl+1` to `Ctrl+4` | Dashboard, Issues, Accounts, Settings |
| `Esc` | Close the panel or hide the window |

Shortcuts are also in the footer, and you can click them.

## Dashboard

Numbers and charts to decide where to start: followed, assigned to me, due soon, by status, by tag. On GitHub: by type, my PRs and by repository.

**Everything is clickable.** A click opens the Issues tab already filtered.

## Issues

- **Filters** (combined with OR): **Agora** (Now: what needs action today: due today or overdue, mention, review requested, PR with red CI or changes requested, your flagged issue), Comigo (assigned to me), Atrasadas (overdue), Review, Manuais (manually followed), Impedidas (flagged), Meus PRs (my PRs) and Sprint (Jira with an active sprint).
- **Tags**: your tags show up as chips. They combine with each other and with the filters.
- **Agrupar** (Group, on the right of the tags row): splits the list by repository (GitHub) or project (Jira). Click a group header to collapse it.
- An empty list shows the active filters and a button to clear them.

Each row shows key, title, badges (status, due date, flagged, tags) and, on the right, the link type (assigned, review, my PR...) and the last update.

## Issue panel

Click an issue to open the panel on the right.

- Top icons: **AI** (summarizes the thread and drafts a reply), **Log work** (Jira), **Open in browser**, **Close**.
- **Comentários** (Comments): the latest comments. Type in the box below and send with the round button.
- **Histórico** (History): the alerts Vigia raised for this issue.
- **Detalhes** (Details): description, attachments and links.
- On PRs: CI line (click opens the failed job) and reviewers.

## Issue menu (right-click)

| Item | What it does |
|---|---|
| Ver detalhes | Opens the panel |
| Mudar status... | Lists the statuses available now. If the transition needs fields (e.g. Resolution), they show up on screen |
| Abrir no navegador / Copiar chave | Open in browser / Copy key |
| **Ações ›** (Actions) | Assign to me, Triage with AI, Apply AI suggestion, Add label (tag on Azure), Approve PR/MR, Open failed job. Jira and GitLab: Log work. Jira: Change priority, Flag/Unflag impediment (the reason becomes a comment) |
| Silenciar até amanhã / até mudar status | Mute until tomorrow / until the status changes (see [Alerts](04-alerts.md)) |
| Tag › | Adds or removes the issue from a tag, or opens **Gerenciar tags** (Manage tags) |
| Parar de acompanhar | Stop following (manually followed issues only) |

**Every action that writes to Jira or GitHub asks for confirmation first.**

## Mini window

Right-click the tray icon › **Janela mini** (Mini window). It stays on top with the counters (Now, Overdue, Mine) and the "Now" list. Click a row to open the issue; drag the top to move it.

## Follow an issue that is not yours

`Ctrl+K`, type `PROJ-123` (Jira), `owner/repo#12` (GitHub or GitLab, `!5` for an MR) or `Project#123` (Azure DevOps) and choose **Acompanhar**. Vigia checks that it exists before saving.

## Tags

Tags group issues by your own topic or project (e.g. `#Payments`, `#Bug`). They are local and per account.

1. Right-click an issue › **Tag › Gerenciar tags...**
2. **Cadastro** (Edit) tab: name and title keywords (comma or semicolon separated). Issues with one of these words in the title join automatically.
3. To tag an issue by hand: right-click › **Tag** › tag name.

## Hours

On Jira, the footer shows how much you logged today and this week. The **Registrar tempo** (Log work) screen has shortcuts from 30 min to 8 h.

Next: [Alerts](04-alerts.md)
