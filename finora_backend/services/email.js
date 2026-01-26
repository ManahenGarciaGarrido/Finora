const nodemailer = require('nodemailer');

// Create transporter based on environment
const createTransporter = () => {
  const isProduction = process.env.NODE_ENV === 'production';

  // For development/testing with MailHog
  if (!isProduction || process.env.SMTP_HOST === 'mailhog') {
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'localhost',
      port: parseInt(process.env.SMTP_PORT) || 1025,
      secure: false,
      ignoreTLS: true
    });
  }

  // For production with real SMTP
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT) || 587,
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });
};

const transporter = createTransporter();

// Verify transporter connection
const verifyConnection = async () => {
  try {
    await transporter.verify();
    console.log('Email service is ready');
    return true;
  } catch (error) {
    console.error('Email service error:', error.message);
    return false;
  }
};

// Send verification email
const sendVerificationEmail = async (to, name, verificationToken) => {
  const appUrl = process.env.APP_URL || 'http://localhost:3000';
  const verificationLink = `${appUrl}/api/v1/auth/verify-email?token=${verificationToken}`;

  const mailOptions = {
    from: process.env.EMAIL_FROM || 'noreply@finora.com',
    to: to,
    subject: 'Verifica tu cuenta de Finora',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Verificar Email - Finora</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .header h1 { color: white; margin: 0; font-size: 28px; }
          .content { background: white; padding: 40px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
          .button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 40px; text-decoration: none; border-radius: 25px; font-weight: bold; margin: 20px 0; }
          .button:hover { opacity: 0.9; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
          .warning { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 5px; margin: 20px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Finora</h1>
          </div>
          <div class="content">
            <h2>Hola ${name},</h2>
            <p>Gracias por registrarte en Finora. Para completar tu registro y comenzar a usar la aplicacion, por favor verifica tu direccion de correo electronico.</p>

            <div style="text-align: center;">
              <a href="${verificationLink}" class="button">Verificar mi Email</a>
            </div>

            <p>O copia y pega el siguiente enlace en tu navegador:</p>
            <p style="word-break: break-all; color: #667eea;">${verificationLink}</p>

            <div class="warning">
              <strong>Importante:</strong> Este enlace expirara en 24 horas. Si no solicitaste este registro, puedes ignorar este correo.
            </div>

            <p>Saludos,<br>El equipo de Finora</p>
          </div>
          <div class="footer">
            <p>Este es un correo automatico, por favor no respondas a este mensaje.</p>
            <p>&copy; 2024 Finora. Todos los derechos reservados.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
      Hola ${name},

      Gracias por registrarte en Finora. Para completar tu registro, verifica tu email haciendo clic en el siguiente enlace:

      ${verificationLink}

      Este enlace expirara en 24 horas.

      Si no solicitaste este registro, puedes ignorar este correo.

      Saludos,
      El equipo de Finora
    `
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Verification email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending verification email:', error);
    return { success: false, error: error.message };
  }
};

// Send password reset email
const sendPasswordResetEmail = async (to, name, resetToken) => {
  const appUrl = process.env.APP_URL || 'http://localhost:3000';
  const resetLink = `${appUrl}/api/v1/auth/reset-password?token=${resetToken}`;

  const mailOptions = {
    from: process.env.EMAIL_FROM || 'noreply@finora.com',
    to: to,
    subject: 'Restablecer contrasena - Finora',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Restablecer Contrasena - Finora</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .header h1 { color: white; margin: 0; font-size: 28px; }
          .content { background: white; padding: 40px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
          .button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 40px; text-decoration: none; border-radius: 25px; font-weight: bold; margin: 20px 0; }
          .warning { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Finora</h1>
          </div>
          <div class="content">
            <h2>Hola ${name},</h2>
            <p>Recibimos una solicitud para restablecer la contrasena de tu cuenta de Finora.</p>

            <div style="text-align: center;">
              <a href="${resetLink}" class="button">Restablecer Contrasena</a>
            </div>

            <p>O copia y pega el siguiente enlace en tu navegador:</p>
            <p style="word-break: break-all; color: #667eea;">${resetLink}</p>

            <div class="warning">
              <strong>Importante:</strong> Este enlace expirara en 1 hora. Si no solicitaste restablecer tu contrasena, ignora este correo y tu contrasena permanecera sin cambios.
            </div>

            <p>Saludos,<br>El equipo de Finora</p>
          </div>
          <div class="footer">
            <p>Este es un correo automatico, por favor no respondas a este mensaje.</p>
            <p>&copy; 2024 Finora. Todos los derechos reservados.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
      Hola ${name},

      Recibimos una solicitud para restablecer la contrasena de tu cuenta de Finora.

      Haz clic en el siguiente enlace para restablecer tu contrasena:

      ${resetLink}

      Este enlace expirara en 1 hora.

      Si no solicitaste restablecer tu contrasena, ignora este correo.

      Saludos,
      El equipo de Finora
    `
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Password reset email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending password reset email:', error);
    return { success: false, error: error.message };
  }
};

// Send welcome email after verification
const sendWelcomeEmail = async (to, name) => {
  const mailOptions = {
    from: process.env.EMAIL_FROM || 'noreply@finora.com',
    to: to,
    subject: 'Bienvenido a Finora!',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Bienvenido a Finora</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .header h1 { color: white; margin: 0; font-size: 28px; }
          .content { background: white; padding: 40px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
          .feature { display: flex; align-items: center; margin: 15px 0; padding: 15px; background: #f8f9fa; border-radius: 8px; }
          .feature-icon { font-size: 24px; margin-right: 15px; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Bienvenido a Finora!</h1>
          </div>
          <div class="content">
            <h2>Hola ${name},</h2>
            <p>Tu cuenta ha sido verificada exitosamente. Ya puedes comenzar a usar Finora para gestionar tus finanzas personales.</p>

            <h3>Que puedes hacer con Finora:</h3>

            <div class="feature">
              <span class="feature-icon">📊</span>
              <div>
                <strong>Seguimiento de gastos</strong>
                <p style="margin: 5px 0 0 0; color: #666;">Registra y categoriza todos tus gastos facilmente.</p>
              </div>
            </div>

            <div class="feature">
              <span class="feature-icon">💰</span>
              <div>
                <strong>Control de presupuesto</strong>
                <p style="margin: 5px 0 0 0; color: #666;">Establece limites y recibe alertas cuando te acerques a ellos.</p>
              </div>
            </div>

            <div class="feature">
              <span class="feature-icon">📈</span>
              <div>
                <strong>Reportes detallados</strong>
                <p style="margin: 5px 0 0 0; color: #666;">Visualiza tus habitos financieros con graficos claros.</p>
              </div>
            </div>

            <p>Si tienes alguna pregunta, no dudes en contactarnos.</p>

            <p>Saludos,<br>El equipo de Finora</p>
          </div>
          <div class="footer">
            <p>&copy; 2024 Finora. Todos los derechos reservados.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
      Hola ${name},

      Tu cuenta ha sido verificada exitosamente. Ya puedes comenzar a usar Finora para gestionar tus finanzas personales.

      Saludos,
      El equipo de Finora
    `
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Welcome email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending welcome email:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  verifyConnection,
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendWelcomeEmail
};
