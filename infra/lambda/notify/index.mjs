// Consumidor da fila de eventos de empréstimo (LOAN_CREATED / LOAN_RETURNED).
// Ponto de partida: apenas loga o evento. Estenda para enviar e-mail/SNS,
// gerar relatório, etc.
export const handler = async (event) => {
  const failures = [];

  for (const record of event.Records ?? []) {
    try {
      const body = JSON.parse(record.body);
      console.log(
        `[loan-event] type=${body.type} loanId=${body.loanId} ` +
          `user=${body.userEmail} book="${body.bookTitle}"`,
      );
      // TODO: notificação real (e-mail/SNS/etc.)
    } catch (err) {
      console.error('Falha ao processar mensagem', record.messageId, err);
      failures.push({ itemIdentifier: record.messageId });
    }
  }

  // Reportar apenas as mensagens que falharam (partial batch response)
  return { batchItemFailures: failures };
};
