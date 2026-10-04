# 2. Contas

Cada conta tem token, regras de aviso e liga/desliga próprios. Dá para ter várias do mesmo tipo.

## Cadastrar

1. Aba **Contas** › **Nova conta**.
2. Escolha o **Provedor** e preencha os campos do provedor (abaixo).
3. Clique em **Testar conexão**. Deve aparecer "Conectado como ...".
4. Escolha os avisos e os prazos (coluna **Avisos**).
5. **Salvar.** O token vai para o Credential Manager do Windows. Nunca vai para o banco.

Para editar, clique na conta. Na edição, deixe o token vazio para manter o salvo.

## GitHub

| Campo | Valor |
|---|---|
| URL base | `https://api.github.com` (GitHub Enterprise: `https://<servidor>/api/v3`) |
| Token de acesso | Personal access token **classic** |

Crie o token em **GitHub › Settings › Developer settings › Personal access tokens › Tokens (classic)**, com os escopos:

- `repo`: issues e PRs, inclusive de repositórios privados;
- `notifications`: comentários e menções;
- `read:project` (opcional): datas do GitHub Projects como prazo.

> Token **fine-grained** não lê notificações nem Projects. O **Testar conexão** avisa quando falta um escopo.

Opções de busca (coluna **Busca**):
- **Meus PRs**: seus PRs abertos, com aprovação, mudanças pedidas e CI.
- **Issues dos meus repositórios**: tudo aberto nos seus repositórios (até 1000).
- **Issues em que fui mencionado.**
- **Busca extra**: uma query do GitHub, ex.: `repo:dono/app label:bug`.
- **Só destes / Ignorar repositórios ou donos**: `dono/repo` ou `dono`, separados por vírgula.
- **Campo de data do Projects**: nome do campo de data no Projects (ex.: `Prazo`). Vira o prazo da issue.

## Jira Server / Data Center

| Campo | Valor |
|---|---|
| URL base | Endereço do Jira, ex.: `https://jira.empresa.com.br` |
| Token de acesso | Personal Access Token |

Crie o token no Jira: **foto do perfil › Perfil › Tokens de acesso pessoal › Criar token**.

> Jira interno da empresa costuma exigir VPN. Sem VPN, a busca falha e o erro aparece no topo da janela.

## Jira Cloud

| Campo | Valor |
|---|---|
| URL base | `https://<empresa>.atlassian.net` |
| E-mail da conta Atlassian | Seu e-mail de login |
| Token de acesso | API token |

Crie o API token em [id.atlassian.com › Segurança › Tokens de API](https://id.atlassian.com/manage-profile/security/api-tokens).

## Opções do Jira (Server e Cloud)

- **Busca extra**: JQL, ex.: `project = ABC AND labels = urgente`.
- **Só destes / Ignorar projetos**: chaves de projeto separadas por vírgula.
- **Campo da data de entrega**: nome ou id de um campo de data próprio (ex.: `Data Acordo Entrega`). Vazio usa a **Data limite** padrão.

## Prazos e intervalo

- **Avisar com**: quantos dias antes do prazo chega o aviso "Prazo chegando".
- **Laranja até / Vermelho até**: cor do selo de prazo na lista.
- **Buscar a cada**: minutos só desta conta. `0` usa o valor de **Configurações › Geral**.
- **Conta ligada**: desligue para pausar a conta sem apagar.

Próximo: [Uso diário](03-uso-diario.md)
