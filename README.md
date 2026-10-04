<p align="center">
  <img src="docs/images/logo.svg" width="120" alt="Vigia">
</p>

<h1 align="center">Vigia</h1>

<p align="center">
  <b>Suas issues do GitHub e do Jira na bandeja do Windows.</b><br>
  Avisa o que mudou, mostra o que vence e deixa você agir sem abrir o navegador.
</p>

<p align="center">
  <a href="https://github.com/herlondf/vigia/releases/latest"><img src="https://img.shields.io/github/v/release/herlondf/vigia?label=vers%C3%A3o&color=6366f1" alt="Versão"></a>
  <img src="https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows" alt="Windows 10 e 11">
  <img src="https://img.shields.io/badge/Delphi-VCL%20%2B%20Skia-E62431" alt="Delphi VCL + Skia">
  <img src="https://img.shields.io/badge/instala%C3%A7%C3%A3o-sem%20admin-22c55e" alt="Instalação sem admin">
</p>

<p align="center">
  <img src="docs/images/dashboard.png" width="820" alt="Dashboard do Vigia">
</p>

---

## Por que usar

- **Um lugar só.** GitHub, Jira Server/DC e Jira Cloud, quantas contas você quiser.
- **Aviso que importa.** Associação, comentário, menção, status, prazo, review, PR aprovado, CI vermelho. Você escolhe por conta.
- **Age dali mesmo.** Comentar, registrar horas, mudar status, atribuir, marcar impedimento. Sempre com confirmação.
- **Assistente com IA.** Pergunte "o que vence esta semana?" ou peça "lance 2h na PROJ-1".
- **Seguro.** Tokens ficam no Credential Manager do Windows. Nada vai para arquivo ou banco.

## Como é

<table>
  <tr>
    <td width="50%"><img src="docs/images/issues.png" alt="Lista de issues"></td>
    <td width="50%"><img src="docs/images/detail.png" alt="Painel da issue"></td>
  </tr>
  <tr>
    <td><b>Issues</b>: filtros rápidos, tags suas, agrupamento por repositório ou projeto.</td>
    <td><b>Painel da issue</b>: comentários, histórico de avisos e detalhes, sem sair do app.</td>
  </tr>
  <tr>
    <td><img src="docs/images/actions.png" alt="Menu de ações"></td>
    <td><img src="docs/images/assistant.png" alt="Assistente"></td>
  </tr>
  <tr>
    <td><b>Ações</b>: atribuir, label, aprovar PR, prioridade, impedimento.</td>
    <td><b>Assistente</b>: responde sobre suas issues e executa ações com sua permissão.</td>
  </tr>
  <tr>
    <td><img src="docs/images/settings-ai.png" alt="IA automática"></td>
    <td><img src="docs/images/settings.png" alt="Configurações"></td>
  </tr>
  <tr>
    <td><b>IA automática</b> (opcional): resumo do dia, riscos, rascunho de horas, causa do CI. Com limite de gasto.</td>
    <td><b>Configurações</b>: intervalo de busca, tema, estilo do aviso, não perturbe.</td>
  </tr>
</table>

<p align="center">
  <img src="docs/images/toast.png" width="380" alt="Aviso do Vigia"><br>
  <sub>O aviso aparece no canto da tela. "Ver no Vigia" abre a issue.</sub>
</p>

## Instalar

1. Baixe `Vigia-Setup-<versão>.exe` na [última release](https://github.com/herlondf/vigia/releases/latest).
2. Rode o instalador. Ele instala só para o seu usuário, sem pedir administrador.
3. Abra o Vigia pelo menu Iniciar e cadastre uma conta em **Contas › Nova conta**.

O passo a passo de cada provedor está no [playbook](docs/playbook/pt-br/README.md).

## Compilar do código

> **Aviso:** o Vigia usa a suíte de componentes [ComponentesUI](https://github.com/herlondf/componentesui), que hoje é **privada**. Sem acesso a ela não dá para compilar. O instalador da release funciona para qualquer pessoa.

Precisa do RAD Studio 12 (Studio 22.0), da ComponentesUI e do Inno Setup 6. A ComponentesUI é procurada em `..\Delphi\ComponentesUI`. Para outro lugar, use a variável `VIGIA_CUI` ou `-CuiRoot`.

```powershell
pwsh ci/build-release.ps1      # Release + self-check + dist\Vigia-Setup-<versão>.exe
```

Na IDE: abra `src\Vigia.dproj`. O caminho da suíte é a propriedade `CUI` do projeto.

Release no GitHub: `pwsh ci/release.ps1`. Liga o runner self-hosted, cria a tag, espera o workflow publicar e desliga o runner.

## Documentação

| | |
|---|---|
| [Playbook](docs/playbook/pt-br/README.md) | Manual: instalar, configurar contas, uso diário, assistente, problemas comuns |
| [CHANGELOG](docs/CHANGELOG.md) | O que mudou em cada versão |

<p align="center"><sub>Mascote baseado na coruja do <a href="https://github.com/googlefonts/noto-emoji">Noto Emoji</a> (Google, Apache 2.0).</sub></p>

---

<p align="center"><sub>🇺🇸 Read this in English: <a href="README_en.md">README_en.md</a></sub></p>
