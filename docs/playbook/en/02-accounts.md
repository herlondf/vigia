# 2. Accounts

Each account has its own token, alert rules and on/off switch. You can have several of the same kind.

## Add an account

1. **Contas** (Accounts) tab › **Nova conta** (New account).
2. Pick the **Provedor** (Provider) and fill in its fields (below).
3. Click **Testar conexão** (Test connection). You should see "Conectado como ..." (Connected as ...).
4. Choose the alerts and due-date thresholds (**Avisos** column). Only the alerts the provider supports are shown.
5. **Salvar** (Save). The token goes to the Windows Credential Manager. It never goes to the database.

To edit, click the account. While editing, leave the token empty to keep the saved one.

## GitHub

| Field | Value |
|---|---|
| URL base | `https://api.github.com` (GitHub Enterprise: `https://<server>/api/v3`) |
| Token de acesso | **Classic** personal access token |

Create it at **GitHub › Settings › Developer settings › Personal access tokens › Tokens (classic)** with these scopes:

- `repo`: issues and PRs, private repositories included;
- `notifications`: comments and mentions;
- `read:project` (optional): GitHub Projects dates as due dates.

> **Fine-grained** tokens cannot read notifications or Projects. **Testar conexão** tells you when a scope is missing.

Search options (**Busca** column):
- **Meus PRs** (My PRs): your open PRs, with approval, requested changes and CI.
- **Issues dos meus repositórios** (Issues in my repositories): everything open in your repositories (up to 1000).
- **Issues em que fui mencionado** (Issues where I was mentioned).
- **Busca extra** (Extra search): a GitHub query, e.g. `repo:owner/app label:bug`.
- **Só destes / Ignorar repositórios ou donos** (Only / Ignore repositories or owners): `owner/repo` or `owner`, comma separated.
- **Campo de data do Projects** (Projects date field): name of a date field in Projects (e.g. `Due`). It becomes the issue due date.

## Jira Server / Data Center

| Field | Value |
|---|---|
| URL base | Jira address, e.g. `https://jira.company.com` |
| Token de acesso | Personal Access Token |

Create it in Jira: **profile picture › Profile › Personal Access Tokens › Create token**.

> Company Jira servers often require a VPN. Without it, polling fails and the error shows at the top of the window.

## Jira Cloud

| Field | Value |
|---|---|
| URL base | `https://<company>.atlassian.net` |
| E-mail da conta Atlassian | Your login e-mail |
| Token de acesso | API token |

Create the API token at [id.atlassian.com › Security › API tokens](https://id.atlassian.com/manage-profile/security/api-tokens).

## Jira options (Server and Cloud)

- **Busca extra** (Extra search): JQL, e.g. `project = ABC AND labels = urgent`.
- **Só destes / Ignorar projetos** (Only / Ignore projects): comma-separated project keys.
- **Campo da data de entrega** (Due date field): name or id of a custom date field. Empty uses the standard **Due date**.

## Due dates and interval

- **Avisar com** (Warn with): days before the due date for the "due soon" alert.
- **Laranja até / Vermelho até** (Orange up to / Red up to): colour of the due-date badge in the list.
- **Buscar a cada** (Poll every): minutes for this account only. `0` uses the value in **Configurações › Geral**.
- **Conta ligada** (Account enabled): turn it off to pause the account without deleting it.

Next: [Daily use](03-daily-use.md)
