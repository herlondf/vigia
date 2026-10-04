# 6. Troubleshooting

| Symptom | Likely cause | What to do |
|---|---|---|
| "Falha na busca" (Poll failed) banner at the top | Network, VPN or token | Read the message. Company Jira: connect the VPN. Expired token: edit the account and paste a new one |
| "Testar conexão" mentions scopes | GitHub token without `repo` or `notifications` | Create a classic token with the scopes in [Accounts](02-accounts.md#github) |
| No GitHub comments or mentions | Fine-grained token | Use a classic token |
| Projects due date missing | Missing `read:project`, or wrong field name | Add the scope and check the exact field name in Projects |
| Installed it and got no alerts | The first poll only records the state | Wait for the next change. **Mostrar aviso** tests the popup |
| No alerts at night | Do not disturb is on | **Configurações › Notificações › Não perturbe** |
| One issue stopped alerting | It is muted | Right-click › **Reativar avisos** |
| No "Sprint" chip | None of your issues is in an active sprint, or Jira has no Agile | Expected. It only shows up when there are items |
| Assistant does not run actions | Provider is not Anthropic | Switch to Anthropic in **Assistente de IA** |
| "Limite de US$ ... do mês atingido" (Monthly cap reached) | Monthly cap | Raise it in **IA automática › Limite por mês**, or wait for the next month |
| Opened from the Start menu and nothing happened | The window was already open behind another one | Double-click the tray icon |

## Where data lives

- Database: `%LOCALAPPDATA%\Vigia\vigia.db`.
- Tokens: Windows Credential Manager, entries `Vigia:<account id>` and `Vigia:ai:<provider>`.
- Program: `%LOCALAPPDATA%\Programs\Vigia`.

## Start from scratch

1. Quit Vigia (right-click the icon › **Sair**).
2. Delete `%LOCALAPPDATA%\Vigia\vigia.db`.
3. Open Vigia again and add your accounts.

Old tokens stay in the Credential Manager until you delete them.

## Report a problem

Open an issue at [herlondf/vigia](https://github.com/herlondf/vigia/issues). Include the version (shown in the window title) and what you did before the error. Never paste tokens.
