# 5. Assistente de IA

O mascote no canto da janela abre o chat. O assistente conhece suas issues, prazos e avisos recentes.

## Configurar

**Configurações › Assistente de IA**:

1. **Provedor**: Anthropic (Claude), OpenAI, xAI (Grok), DeepSeek, Groq, OpenRouter, Ollama (local) ou outro compatível com OpenAI.
2. **Endereço da API**: já vem preenchido. Troque só para gateway próprio ou Ollama remoto.
3. **Chave**: cole e clique em **Salvar**. Fica no Credential Manager, uma por provedor.
4. **Modelo**: digite, ou clique em **Listar** para escolher da lista do provedor.
5. **Preço**: Claude já vem com o preço público. Nos outros, preencha para ver o custo.

> As **ferramentas** (agir no Jira/GitHub e na tela) só funcionam com **Anthropic**. Os outros provedores respondem só com texto.

## O que pedir

Perguntas sobre os dados:
- "O que vence esta semana?"
- "Quais issues estão impedidas e por quê?"
- "Resuma a APP-123." (o assistente lê descrição e comentários)

Ações (cada escrita pede **Permitir / Negar** no chat):

| Peça | Ferramenta |
|---|---|
| "Lance 2h na PROJ-1 hoje, revisão do layout" | Registrar horas (Jira) |
| "Comente na PROJ-1 que o ajuste subiu" | Comentar |
| "Mova a PROJ-1 para Em Andamento" | Mudar status |
| "Marque a PROJ-1 como impedida: aguardando cliente" | Impedimento (Jira) |
| "Atribua a PROJ-1 para mim" | Atribuir |
| "Crie uma issue no projeto ABC: ..." | Criar issue |
| "Abra a PROJ-1" / "Acompanhe a dono/repo#12" | Abrir na tela / Acompanhar |
| "Crie a tag #Pagamentos com as palavras pagamento, pix" | Criar tag |
| "Mostre só as atrasadas da tag #Pagamentos" | Filtrar a lista |

Mudança de status que pede campos na tela do Jira é recusada pelo assistente. Use **botão direito › Mudar status**.

## Resumo da conversa

No painel da issue, o ícone de brilho resume os comentários. Ele também escreve um rascunho de resposta na caixa. **Nada é enviado** até você clicar em enviar.

## IA automática (opcional)

**Configurações › IA automática**. Tudo vem desligado.

| Opção | O que faz |
|---|---|
| Resumo do dia escrito pela IA | No horário do resumo, um texto curto de por onde começar |
| Alerta de risco | Uma vez por dia, até 3 issues com chance de atrasar ou travar |
| Rascunho de horas no fim do dia | Às 17:30 em dia útil, sugere lançamentos que faltam. Peça "lance o rascunho de horas" para o assistente lançar |
| Causa da falha do CI | Quando um PR seu fica vermelho, lê o log do job e explica |
| Triagem de issues novas | Sugere uma das suas tags e a prioridade para até 3 issues novas por busca. A sugestão aparece no painel ("IA sugere"); **Ações › Aplicar sugestão da IA** marca a tag e, no Jira, muda a prioridade (com confirmação). **Ações › Triar com IA** pede na hora |

## Controle de gasto

- **Limite por mês (US$)**: ao chegar nele, o chat e as tarefas automáticas param até o mês virar. `0` = sem limite.
- **Modelo das tarefas automáticas**: modelo mais barato para as tarefas acima. Na Anthropic o padrão é `claude-haiku-4-5`.
- **Uso da IA**: perguntas, tokens e custo do mês, em dólar e em real (cotação do dia).

Próximo: [Problemas comuns](06-problemas.md)
