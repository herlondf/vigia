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

## Idioma

**Configurações › Geral › Idioma**: português, inglês ou automático (segue o Windows). Vale ao reabrir o Vigia.

## Atalho global

**Win+Alt+V** abre o Vigia de qualquer programa; de novo, esconde. Liga e desliga em **Configurações › Geral › Atalho global**.

## Atualizar

O Vigia procura versão nova uma vez por dia. Quando acha, avisa: clique no aviso, ou em **Atualizar para x.y.z** no menu da bandeja. Ele baixa, confere o arquivo, instala e volta aberto. Contas, tags e tokens continuam.

Em **Configurações › Geral › Atualizações**:
- **Só avisar** (padrão), **Instalar sozinho** (atualiza com a janela fechada, sem perguntar) ou **Não procurar**;
- **Procurar agora** confere na hora.

Também dá para rodar o instalador novo por cima, baixado da página de releases.

## Backup e troca de máquina

**Configurações › Backup**:
- **Exportar...** salva contas, tags, issues acompanhadas à mão e preferências num arquivo `.json`.
- **Importar...** traz de volta. Conta com o mesmo nome e provedor é atualizada; as outras entram.

Os tokens vão no arquivo cifrados pelo Windows. No mesmo usuário do Windows eles voltam sozinhos. Em outro usuário ou outra máquina, a conta volta sem token: edite a conta e cole o token de novo.

Desinstalar e instalar de novo na mesma máquina não perde nada: banco e tokens ficam. O backup serve para trocar de máquina ou guardar uma cópia.

## Desinstalar

**Configurações do Windows › Aplicativos › Vigia › Desinstalar.** O desinstalador fecha o Vigia e tira o "Iniciar com o Windows".

Ficam no computador, de propósito:
- o banco em `%LOCALAPPDATA%\Vigia\vigia.db` (contas, tags, histórico);
- os tokens no Credential Manager do Windows (entradas `Vigia:...`).

Para apagar tudo, depois de desinstalar: apague a pasta `%LOCALAPPDATA%\Vigia`. Depois remova as entradas `Vigia:` em **Painel de Controle › Gerenciador de Credenciais › Credenciais do Windows**.

Próximo: [Contas](02-contas.md)
