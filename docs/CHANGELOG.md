# Changelog

## [0.22.0] - 2026-10-04
### Added
- Backup: Configurações › Backup › Exportar/Importar. Contas, tags, issues acompanhadas à mão e preferências num arquivo `.json`. Tokens vão cifrados (DPAPI do Windows) e voltam sozinhos no mesmo usuário do Windows; em outra máquina a conta pede o token de novo. Importar atualiza a conta de mesmo nome e provedor em vez de duplicar.
### Changed
- Tela de conta mostra só os avisos do provedor: GitHub sem "Sinalizada"; Jira sem review, PR aprovado, mudanças pedidas e CI.
- Textos de dica (cinza, sob uma opção ou campo) menores e em itálico em todo o app (suíte: `TUILabel.Italic`, dica do `TUIInput`).
### Fixed
- Campos de texto da tela de conta encolhiam para uma linha, com o texto "riscado" pela borda (suíte: `TUIInput` recalcula a altura quando a dica muda). A dica não aparece mais duplicada dentro do campo.

## [0.21.0] - 2026-10-04
### Added
- Atualização automática: o Vigia instalado procura release nova uma vez por dia, avisa e se atualiza com um clique (baixa, confere o SHA-256 informado pelo GitHub, instala em silêncio e volta aberto). Em Configurações › Geral › Atualizações: Só avisar, Instalar sozinho ou Não procurar, e o botão Procurar agora.
- Item "Atualizar para x.y.z" no menu da bandeja quando há versão nova.

## [0.20.0] - 2026-10-04
### Added
- Instalador por usuário (Inno Setup, sem administrador) em `%LOCALAPPDATA%\Programs\Vigia`, com atalho no menu Iniciar, opção de atalho na área de trabalho e desinstalador. Banco e tokens ficam ao desinstalar.
- Release automática: tag `v<versão>` gera o instalador no runner self-hosted e publica no GitHub. `ci/release.ps1` liga o runner antes e desliga depois.
- Versão no título da janela.
- README com imagens (pt-br e inglês) e playbook de uso nas duas línguas.
### Changed
- Abrir o Vigia de novo (menu Iniciar) com ele já na bandeja mostra a janela.
- Caminho da ComponentesUI nos projetos vira a propriedade `CUI` (o CI compila de outra pasta).
### Fixed
- Comentários duplicados no painel ao abrir a issue com duplo clique.
### Removed
- Código sem uso: desenho de contas em lista, heatmap de eventos, pílulas e avatares antigos, botão de busca, tons duplicados.

## [0.19.0] - 2026-10-03
### Added
- Menu da issue › Ações: atribuir a mim, adicionar label, aprovar PR, abrir job do CI que falhou; no Jira também registrar horas, mudar prioridade e marcar/tirar impedimento com motivo (vira comentário). Toda ação pede confirmação.
- Mudar status: transição do Jira que pede campos (ex.: Resolução) mostra os campos na tela.
- Painel da issue: aba Detalhes (descrição, anexos, ligações); linha do CI (clique abre o job) e revisores do PR; botão de IA que resume a conversa e põe um rascunho de resposta na caixa (não envia).
- Horas lançadas no Jira (hoje e semana) no rodapé e na tela de registrar tempo.
- Chip "Sprint" (Jira com sprint ativa; some quando não há itens).
- Assistente com ferramentas: registrar horas, comentar, listar/mudar status, impedimento, atribuir, criar issue, abrir issue na tela, acompanhar, criar tag, filtrar a lista e ler detalhes. Escrita pede Permitir/Negar no chat.
- IA automática (Configurações, tudo desligado): resumo do dia escrito pela IA, alerta de risco diário, rascunho de horas às 17:30, causa provável quando o CI de um PR falha.
- Limite de gasto mensal (chat e automáticas param) e modelo barato para as tarefas automáticas.
- GitHub: cache por ETag (304 não gasta limite), escopos do token conferidos no "Testar conexão", data do Projects v2 como prazo (campo na conta), notificação marcada como lida ao abrir a issue.
- Lista agrupada por repositório/projeto (chip Agrupar; clique no cabeçalho recolhe).
- Comentários do GitHub com markdown convertido em texto.
### Changed
- Dashboard só é refeito quando os dados mudam.
- Silenciadas lidas de uma vez por busca.
- Lista vazia diz quais filtros estão ligados e oferece limpar.
- Avisos de PR aprovado, mudanças e CI trazem revisores e o job.
### Fixed
- Rosca com uma fatia zerada não desenhava o anel (suíte: `DrawSweep`).
- Mascote para de animar com a janela na bandeja.

## [0.18.0] - 2026-10-03
### Added
- Mascote com cenas por situação: atrasada (alerta e suor), prazo perto (relógio), novidade (pulinhos e brilhos, 5 s após aviso novo); idle mais ativo (olha, inclina, pulinho).
- Chat da IA abre em círculo a partir do FAB e fecha voltando para ele (suíte: `TUIOverlayHost.RevealOrigin` + `HideAnimated`).
- Modais (conta, tags, status, registrar tempo) entram esmaecendo.
### Changed
- Barra de progresso da busca no rodapé, embaixo dos atalhos.
- Seletor de repositório mais largo (suíte: `TUIDropdown.PopupWidth`) e sempre logo após o de conta.
- Campos da conta e das tags com rótulo na borda e fonte normal.
- Painel da issue: ícones numa linha própria acima do caminho; sem o texto "Button".
- Dica de tags com exemplos genéricos (#Bug, #Feature).
### Fixed
- FAB mais alto na aba Issues.
- Lista de repositórios rola com a roda e mostra a posição (suíte: `TUIDropdown` com rolagem).
- Rastros ao rolar rápido nas Configurações (suíte: `TUIScrollArea` repinta o conteúdo a cada passo).

## [0.17.0] - 2026-10-03
### Added
- Rodapé com atalhos em todas as abas (Ctrl K, F5, Ctrl 1-4, Esc), clicáveis; o FAB fica sempre no mesmo lugar.
- Ctrl+K: digitar PROJ-123 ou dono/repo#12 oferece "Acompanhar".
- Custo da IA em real, pequeno, sob o valor em dólar (cotação do dia, AwesomeAPI, buscada uma vez por dia).
### Changed
- Cabeçalho: saem o texto de itens/atualização (vira dica do anel) e o botão "Buscar · Ctrl K".
- Aba Issues sem o rodapé de acompanhar.
- Abas só são recriadas quando os contadores mudam (o sublinhado não reanima a cada busca).

## [0.16.0] - 2026-10-03
### Added
- GitHub: "Issues dos meus repositórios" (privados incluídos com token de acesso total), até 1000 issues.
- Seletor de repositório no cabeçalho (aparece com GitHub na tela); vale para Issues, Dashboard e Ctrl+K.
- Dashboard no GitHub: "Por tipo" (issues/PRs), "Meus PRs" (em review, mudanças, aprovados, CI falhou), "Por repositório"; número "Meus PRs" no lugar de "Impedidas". Tudo clicável.
- Seletor de conta mostra o tipo (GitHub, Jira) à direita (suíte: `TUIDropdown.SetItemDetail`).
### Changed
- Tags são por conta: chips, submenu, tela de tags e Dashboard mostram só as da conta. As existentes foram para a conta do Jira; nome único por conta.
- Cards sem dados mostram um aviso ("Nenhuma issue com prazo") em vez de 100%.
### Fixed
- Roda do mouse sobre lista de card que não rola agora rola a página (suíte: `TUIVirtualList` repassa ao pai).

## [0.15.0] - 2026-10-03
### Added
- Conta, coluna "Busca": meus PRs no GitHub (GraphQL: decisão de review e CI do último commit), issues em que fui mencionado, busca extra (query do GitHub ou JQL), só/ignorar repositórios, donos ou projetos, intervalo de busca por conta.
- Avisos novos: PR aprovado, mudanças pedidas, CI falhou. Ligados nas contas existentes.
- Lista: selos Aprovado / Mudanças pedidas / CI falhou / CI rodando / CI ok; etiquetas "meu PR", "mencionado", "busca"; chip "Meus PRs".
- Janela abre e fecha com esmaecer e leve deslize.
### Changed
- Troca de aba prepara a página antes da transição (Configurações travava o começo do deslize).

## [0.14.0] - 2026-10-02
### Changed
- Mascote do assistente agora é a coruja do rig (`assets/mascot/vigia-rig.svg`), com 7 estados animados em Lottie: idle (respira e pisca), sleepy (pálpebras fechadas e "Z"), listening (inclina a cabeça, orelhas em pé), thinking (olhar para cima e "…"), acting (lupa e olhos varrendo), speaking (bico mexendo), error (treme e "!").
- Robô antigo guardado em `assets/assistant-robo/`.
### Fixed
- Tela de conta: campos sem cortar o texto; switch "Conta ligada" desligado agora mostra o trilho (suíte: borda no `TUIToggle` desligado); campo de entrega só no Jira; "Sinalizada" desabilitada no GitHub.
- GitHub: token sem acesso a /notifications não derruba a busca.
- Piscar branco nos gráficos de barras do Dashboard ao passar o mouse (suíte: `TUIChart` não apaga mais o fundo).

## [0.13.0] - 2026-10-02
### Changed
- Dashboard: números mais baixos; saíram "Avisos por dia" e o mapa de calor; entrou "Pendências por #tag"; "Atividade recente" virou lista.
- Dashboard clicável: cada número, fatia, barra e o anel abrem a aba Issues já filtrada; filtro extra aparece como chip "✕" removível.
- Tela de tags: abas Consulta / Cadastro; lista virtual igual à de issues, com canetinha azul e lixeira vermelha (segundo clique confirma); campos sem cortar o texto.
- Palavras da tag aceitam vírgula ou ponto e vírgula.
### Fixed
- Contador das abas Comentários/Histórico some ao abrir a aba.

## [0.12.0] - 2026-10-02
### Added
- Tags do usuário para agrupar issues (ex.: Pagamentos, Mobile): por palavra no título ou marcação manual pelo botão direito. Chips com contador na aba Issues e selo na linha. Tela "Gerenciar tags".
### Changed
- Detalhe: sem contador regressivo, título menor, só "Responsável", botão de comentar com ícone de balão.
- Avisos internos (toast) no canto inferior direito.
- Tags com `#` (chip, selo e menu). Menu da issue tem o submenu "Tag ›" (abre ao passar o mouse, com o menu principal aberto): Gerenciar tags, separador, uma linha por tag (✓ nas marcadas).
- Tela de tags em duas abas (Tags e Cadastro) com FAB: "+" na lista vira disquete no cadastro, com animação; "×" ao lado, Esc ou a aba Tags cancelam.
- Aba Issues: linhas "Filtros" e "Tags" com rótulo; contador em pílula no chip (suíte: `TUIFilterChip.Count`). Botão "Gerenciar tags" saiu da tela.

## [0.11.0] - 2026-10-02
### Changed
- Detalhe da issue: cabeçalho fixo com ícones (registrar tempo, abrir, fechar); título, selos e prazo rolam junto; abas Comentários e Histórico.
- Comentários em lista de leitura (todos à esquerda, "Você" nos seus), wiki do Jira limpo (tabela, código, negrito, links).
- Botão redondo de enviar dentro da caixa de comentário.
- Registrar tempo: atalhos 30 min a 8h, nota em várias linhas, botões com espaço, divisória no rodapé.
### Fixed
- Texto do comentário vazando do balão (palavra longa sem quebra).

## [0.10.0] - 2026-10-02
### Added
- Assistente com outros provedores: Anthropic, OpenAI, Grok, DeepSeek, Groq, OpenRouter, Ollama e endereço próprio. Modelo editável e botão "Listar".
- Chave da IA por provedor no Credential Manager (`Vigia:ai:<provedor>`).
- Painel "Uso da IA": perguntas, tokens e custo no mês, custo por dia (tabela `ai_usage`).
### Fixed
- Ampulheta a cada segundo: cursor de espera do FireDAC (`SilentMode`) e leitura do intervalo em cache.
- Pontinho no botão de tema (foco por teclado desligado).
- Configurações: linhas mais altas, campos de preço mais largos, barra de rolagem sempre visível e acompanhando a posição.

## [0.9.0] - 2026-10-02
### Added
- Comentar e registrar tempo pelo detalhe; silenciar issue; resumo do dia; não perturbe.
- Dashboard: entregas no prazo, funil, mapa de calor; boas-vindas no primeiro uso.
- Contas em cartões com atividade de 14 dias.
- Anel da próxima busca no cabeçalho; dicas nos selos.
### Changed
- Animações: abertura do chat a partir do botão, troca de abas, detalhe deslizando, brilho nas linhas alteradas, aviso deslizando, esqueleto no formato da linha.

## [0.8.0] - 2026-10-02
### Added
- Seletor de conta no topo, valendo para lista, Dashboard e Ctrl+K.
- Dashboard: próximas entregas e atividade recente.
- Indicador de estado no cabeçalho e mascote animado no assistente.
### Changed
- Abre no Dashboard e mantém a aba depois de cada busca.
- Busca da aba Issues substituída pelo Ctrl+K; botão Atualizar substituído por Ctrl+K/F5.

## [0.7.0] - 2026-10-01
### Added
- Aviso de área de trabalho com o visual da ComponentesUI (padrão), com "Ver no Vigia".
- Configurações: estilo do aviso, tempo na tela e botão de teste.
### Changed
- Configurações reorganizadas em seções com linhas.
- Dashboard e Configurações rolam.
### Fixed
- Borda serrilhada e bloco de fundo em volta do botão do assistente.
- Lista aparecia com moldura de seleção ao abrir.

## [0.6.0] - 2026-10-01
### Removed
- Agenda, Quadro e menu lateral.
### Added
- Mudar status da issue pelo botão direito na lista.
- Configurações gerais: iniciar com o Windows, intervalo de busca e tema.
### Changed
- Navegação por abas no topo (Dashboard, Issues, Contas, Configurações).
- Assistente IA em botão flutuante à direita, com acesso a contas, issues e avisos recentes.

## [0.5.0] - 2026-10-01
### Added
- Menu lateral com Issues, Quadro, Agenda, Painel, Contas, Configurações e Assistente IA.
- Quadro (Kanban), Agenda de prazos e Painel com números e gráficos.
- Detalhe lateral da issue com contagem regressiva até a entrega e comentários.
- Paleta de comandos (Ctrl+K), menu de contexto da suíte, filtro rápido "Impedidas" e contadores nos filtros.
- Assistente IA (Claude) com as issues como contexto.
### Changed
- Duplo clique abre o detalhe (antes abria o navegador).

## [0.4.0] - 2026-10-01
### Changed
- Lista em 3 linhas (chave, título, selos); data/hora da atualização vira selo à direita, abaixo do vínculo.
- Campos, seleção e botões com 36 px de altura.
- Botão de tema virou sol/lua girando, com transição circular.

## [0.3.0] - 2026-10-01
### Added
- Selos na linha da issue: status com cor, Impedida, Entrega com cor por prazo, data e hora da última atualização.
- Conta: quadro Prazo com campo da data de entrega (Jira) e dias para laranja e vermelho.
- Aviso "Sinalizada" quando uma issue recebe o Flagged.
### Changed
- Número de comentários saiu da lista.

## [0.2.0] - 2026-10-01
### Changed
- Lista de issues e de contas em `TUIVirtualList`: rolagem sem travar, sem recriar janelas a cada busca.
- Tela de conta em dois quadros (Conexão, Avisos), teste de conexão mostra o resultado no próprio quadro.
- Uma instância por usuário do Windows (antes: uma por sessão).
### Added
- Selos coloridos, filtros rápidos, busca por texto, estado vazio, esqueleto, faixa de erro.
- Histórico de avisos por issue (linha do tempo) e menu de contexto com Copiar chave e Desfazer.
- Tema claro/escuro seguindo o Windows, botão de tema, barra de título escura.
- Cabeçalho com contagem e próxima busca; badge de não lidos na aba.
- Atalhos F5, Ctrl+F, Esc, Enter, Ctrl+C.
### Fixed
- Abrir uma conta para editar apagava os dados lidos (o prazo era salvo como 0).

## [0.1.0] - 2026-10-01
### Added
- Ícone da tray próprio com contador de avisos não vistos e vermelho para prazo vencido.
- "Iniciar com o Windows" no menu da tray.
- Guia de uso em `docs/USER_GUIDE.md`.
- Aba Issues: lista das issues acompanhadas, filtro por conta, clique abre no navegador.
- Acompanhar issue à mão (`PROJ-123` ou `dono/repo#12`), conferida na API antes de salvar; "Parar de acompanhar" no botão direito.
- Avisos: busca automática a cada 5 min, comparação com o último estado salvo e toast por tipo de evento ligado na conta.
- Clique no toast (ou no balão da tray) abre a issue no navegador.
- Busca de issues: GitHub (assignee, review pedido, manuais, notifications) e Jira Server/Cloud (assignee, watcher, manuais) com paginação.
- "Atualizar agora" mostra quantos itens cada conta trouxe.
- Cadastro de contas (GitHub, Jira Server/DC, Jira Cloud) com switch, regras de aviso e prazo em dias.
- Token por conta no Windows Credential Manager.
- Botão "Testar conexão" (`/user` no GitHub, `/myself` no Jira).
- Self-check de console em `tests/`.
- Esqueleto do app: tray com menu, toast de teste, instância única.
