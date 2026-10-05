# 4. Avisos

## Quando o Vigia avisa

O Vigia busca a cada 5 minutos (ajustável) e compara com a busca anterior. Avisa o que mudou, conforme os avisos ligados na conta:

| Aviso | Quando |
|---|---|
| Fui associado | A issue passou a ser sua |
| Novo comentário | Outra pessoa comentou |
| Menção | Alguém citou você |
| Mudança de status | O status mudou |
| Prazo chegando / vencido | Pelos dias de **Avisar com** da conta |
| Review de PR pedido | Pediram sua revisão (GitHub) |
| Sinalizada | Marcaram impedimento (Jira) |
| PR aprovado / Mudanças pedidas | Revisão no seu PR (GitHub) |
| CI falhou | O CI do seu PR ficou vermelho (GitHub) |

- Na **primeira busca** de uma conta aparece só "Acompanhando N itens". Os avisos começam depois.
- Muitos avisos de uma vez viram um só, com a lista das chaves.
- **Ver no Vigia** no aviso abre a issue.
- **Responder** abre uma caixa no próprio aviso: escreva e aperte Enter para comentar sem abrir o Vigia.
- **Silenciar** para os avisos da issue até amanhã às 8h.

## Estilo do aviso

**Configurações › Notificações › Estilo do aviso**:
- **Popup do Vigia**: no canto da tela, com os botões Dispensar e Ver no Vigia. Com o mouse em cima, ele espera.
- **Notificação do Windows**: o aviso padrão do sistema.

**Tempo na tela** define quantos segundos o popup fica. **Mostrar aviso** testa o estilo.

## Silenciar uma issue

Botão direito na issue:
- **Silenciar até amanhã**: sem avisos até amanhã às 8h.
- **Silenciar até mudar status**: volta a avisar quando o status mudar.
- **Reativar avisos**: desfaz.

O histórico da issue continua registrando enquanto ela está silenciada.

## Não perturbe

**Configurações › Notificações › Não perturbe**: nesse horário os avisos esperam e chegam juntos quando o silêncio acaba.

## Resumo do dia

**Configurações › Notificações › Resumo do dia**: um aviso por dia, no horário escolhido. Mostra o que vence, o que está impedido e os comentários das últimas 24 h. Com a IA ligada, o texto é escrito por ela (ver [Assistente](05-assistente.md)).

Próximo: [Assistente de IA](05-assistente.md)
