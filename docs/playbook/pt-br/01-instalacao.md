# 1. Instalação

## Instalar

1. Baixe `Vigia-Setup-<versão>.exe` na [página de releases](https://github.com/herlondf/vigia/releases/latest).
2. Rode o arquivo. Não pede administrador: instala só para o seu usuário em `%LOCALAPPDATA%\Programs\Vigia`.
3. Marque **Executar Vigia** no fim, ou abra pelo menu Iniciar.

Atalho na área de trabalho é opcional, numa caixa do instalador.

## Abrir e fechar

- O Vigia vive na **bandeja** (perto do relógio). O ícone é um "V".
- Duplo clique no ícone, ou o atalho do menu Iniciar, abre a janela.
- **Fechar a janela só esconde.** A busca continua na bandeja.
- Para sair de vez: botão direito no ícone › **Sair**.

| Ícone da bandeja | Quer dizer |
|---|---|
| Azul com "V" | Nada novo desde a última vez que você abriu a janela |
| Azul com número | Quantos avisos chegaram desde então (até "9+") |
| Vermelho | Alguma issue com prazo vencido |

## Iniciar com o Windows

**Configurações › Geral › Iniciar com o Windows**, ou botão direito no ícone da bandeja. Vale só para o seu usuário.

## Atualizar

O Vigia procura versão nova uma vez por dia. Quando acha, avisa: clique no aviso, ou em **Atualizar para x.y.z** no menu da bandeja. Ele baixa, confere o arquivo, instala e volta aberto. Contas, tags e tokens continuam.

Em **Configurações › Geral › Atualizações**:
- **Só avisar** (padrão), **Instalar sozinho** (atualiza com a janela fechada, sem perguntar) ou **Não procurar**;
- **Procurar agora** confere na hora.

Também dá para rodar o instalador novo por cima, baixado da página de releases.

## Desinstalar

**Configurações do Windows › Aplicativos › Vigia › Desinstalar.** O desinstalador fecha o Vigia e tira o "Iniciar com o Windows".

Ficam no computador, de propósito:
- o banco em `%LOCALAPPDATA%\Vigia\vigia.db` (contas, tags, histórico);
- os tokens no Credential Manager do Windows (entradas `Vigia:...`).

Para apagar tudo, depois de desinstalar: apague a pasta `%LOCALAPPDATA%\Vigia`. Depois remova as entradas `Vigia:` em **Painel de Controle › Gerenciador de Credenciais › Credenciais do Windows**.

Próximo: [Contas](02-contas.md)
