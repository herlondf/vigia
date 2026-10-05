# 1. Installation

## Install

1. Download `Vigia-Setup-<version>.exe` from the [releases page](https://github.com/herlondf/vigia/releases/latest).
2. Run it. It does not ask for admin rights: it installs for your user only, in `%LOCALAPPDATA%\Programs\Vigia`.
3. Tick **Executar Vigia** (Run Vigia) at the end, or open it from the Start menu.

A desktop shortcut is optional, in a checkbox of the installer.

## Open and close

- Vigia lives in the **system tray** (next to the clock). The icon is a "V".
- Double-click the icon, or use the Start menu shortcut, to open the window.
- **Closing the window only hides it.** Polling keeps running in the tray.
- To quit: right-click the icon › **Sair** (Quit).

| Tray icon | Meaning |
|---|---|
| Blue with "V" | Nothing new since you last opened the window |
| Blue with a number | Alerts received since then (up to "9+") |
| Red | Some issue is past its due date |

## Start with Windows

**Configurações › Geral › Iniciar com o Windows** (Settings › General › Start with Windows), or right-click the tray icon. It applies to your user only.

## Update

Vigia checks for a new version once a day. When it finds one, it tells you: click the alert, or **Atualizar para x.y.z** (Update to x.y.z) in the tray menu. It downloads, verifies the file, installs and reopens. Accounts, tags and tokens are kept.

In **Configurações › Geral › Atualizações** (Settings › General › Updates):
- **Só avisar** (notify only, default), **Instalar sozinho** (install by itself while the window is closed) or **Não procurar** (never check);
- **Procurar agora** (check now) checks right away.

You can also run the new installer over the old one, downloaded from the releases page.

## Backup and moving to another machine

**Configurações › Backup**:
- **Exportar...** (Export) saves accounts, tags, manually followed issues and preferences to a `.json` file.
- **Importar...** (Import) brings them back. An account with the same name and provider is updated; the others are added.

Tokens go into the file encrypted by Windows. For the same Windows user they come back by themselves. For another user or machine, the account comes back without a token: edit it and paste the token again.

Uninstalling and installing again on the same machine loses nothing: database and tokens stay. Backup is for moving to another machine or keeping a copy.

## Uninstall

**Windows Settings › Apps › Vigia › Uninstall.** The uninstaller closes Vigia and removes the "start with Windows" entry.

Kept on purpose:
- the database at `%LOCALAPPDATA%\Vigia\vigia.db` (accounts, tags, history);
- the tokens in the Windows Credential Manager (`Vigia:...` entries).

To erase everything after uninstalling, delete the `%LOCALAPPDATA%\Vigia` folder. Then remove the `Vigia:` entries in **Control Panel › Credential Manager › Windows Credentials**.

Next: [Accounts](02-accounts.md)
