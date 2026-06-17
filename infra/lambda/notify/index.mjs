import { SESv2Client, SendEmailCommand } from '@aws-sdk/client-sesv2';

const ses = new SESv2Client({});
const FROM = process.env.SES_FROM;

function buildEmail(body) {
  const isCreated = body.type === 'LOAN_CREATED';

  const subject = isCreated
    ? 'Empréstimo confirmado — BiblioSys'
    : 'Devolução registrada — BiblioSys';

  const action = isCreated
    ? `Você pegou emprestado o livro "${body.bookTitle}".`
    : `Você devolveu o livro "${body.bookTitle}". Obrigado!`;

  const text =
    `Olá, ${body.userName || 'leitor'}!\n\n` +
    `${action}\n\n` +
    `Empréstimo: ${body.loanId}\n` +
    `Data: ${body.timestamp}\n\n` +
    `— BiblioSys`;

  return { subject, text };
}

export const handler = async (event) => {
  const failures = [];

  for (const record of event.Records ?? []) {
    try {
      const body = JSON.parse(record.body);

      if (!body.userEmail) {
        console.warn(`[loan-event] sem userEmail, pulando loanId=${body.loanId}`);
        continue;
      }

      const { subject, text } = buildEmail(body);

      await ses.send(
        new SendEmailCommand({
          FromEmailAddress: FROM,
          Destination: { ToAddresses: [body.userEmail] },
          Content: {
            Simple: {
              Subject: { Data: subject, Charset: 'UTF-8' },
              Body: { Text: { Data: text, Charset: 'UTF-8' } },
            },
          },
        }),
      );

      console.log(
        `[loan-event] email enviado type=${body.type} ` +
          `loanId=${body.loanId} to=${body.userEmail}`,
      );
    } catch (err) {
      console.error('Falha ao processar/enviar', record.messageId, err);
      failures.push({ itemIdentifier: record.messageId });
    }
  }

  return { batchItemFailures: failures };
};