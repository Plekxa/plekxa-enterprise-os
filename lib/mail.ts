import nodemailer from 'nodemailer';

type MailInput = {
  to: string;
  subject: string;
  text: string;
  html?: string;
};

export async function sendMail(input: MailInput): Promise<{
  sent: boolean;
  reason?: string;
}> {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || '587');
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || process.env.SMTP_SENDER_EMAIL;

  if (!host || !user || !pass || !from) {
    return { sent: false, reason: 'SMTP environment variables are incomplete.' };
  }

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure: process.env.SMTP_SECURE === 'true' || port === 465,
    auth: { user, pass },
  });

  await transporter.sendMail({
    from,
    to: input.to,
    subject: input.subject,
    text: input.text,
    html: input.html,
  });

  return { sent: true };
}
