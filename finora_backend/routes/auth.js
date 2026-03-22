const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../services/db');
const emailService = require('../services/email');

// JWT Secret (use environment variable in production)
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = '24h';

// ============================================
// PASSWORD VALIDATION HELPER
// ============================================

const isStrongPassword = (password) => {
  const minLength = password.length >= 8;
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;']/.test(password);

  return {
    isValid: minLength && hasUpperCase && hasNumber && hasSpecialChar,
    errors: {
      minLength: !minLength ? 'La contrasena debe tener al menos 8 caracteres' : null,
      hasUpperCase: !hasUpperCase ? 'La contrasena debe contener al menos una mayuscula' : null,
      hasNumber: !hasNumber ? 'La contrasena debe contener al menos un numero' : null,
      hasSpecialChar: !hasSpecialChar ? 'La contrasena debe contener al menos un caracter especial (!@#$%^&*...)' : null
    }
  };
};

// Generate verification token
const generateVerificationToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

// ============================================
// VALIDATION MIDDLEWARE
// ============================================

const registerValidation = [
  body('email')
    .isEmail().withMessage('Formato de email invalido')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 8 }).withMessage('La contrasena debe tener al menos 8 caracteres')
    .custom((value) => {
      const result = isStrongPassword(value);
      if (!result.isValid) {
        const errorMessages = Object.values(result.errors).filter(e => e !== null);
        throw new Error(errorMessages.join('. '));
      }
      return true;
    }),
  body('name')
    .trim()
    .notEmpty().withMessage('El nombre es requerido')
    .isLength({ min: 2 }).withMessage('El nombre debe tener al menos 2 caracteres'),
  body('termsAccepted')
    .optional()
    .isBoolean().withMessage('termsAccepted debe ser un valor booleano'),
  body('privacyAccepted')
    .optional()
    .isBoolean().withMessage('privacyAccepted debe ser un valor booleano')
];

const loginValidation = [
  body('email')
    .isEmail().withMessage('Formato de email invalido')
    .normalizeEmail(),
  body('password')
    .notEmpty().withMessage('La contrasena es requerida'),
];

// ============================================
// ROUTES
// ============================================

/**
 * POST /api/v1/auth/register
 * Register a new user
 */
router.post('/register', registerValidation, async (req, res) => {
  try {
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Error de Validacion',
        message: 'Los datos proporcionados no son validos',
        details: errors.array().map(err => ({
          field: err.path,
          message: err.msg
        }))
      });
    }

    const { email, password, name, termsAccepted, privacyAccepted, consents } = req.body;

    // Check if user already exists
    const existingUser = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        error: 'Conflicto',
        message: 'Ya existe un usuario con este correo electronico'
      });
    }

    // Hash password with bcrypt (10 rounds)
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate email verification token
    const verificationToken = generateVerificationToken();
    const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    // Create user in database
    const insertQuery = `
      INSERT INTO users (
        email, name, password,
        email_verification_token, email_verification_expires,
        terms_accepted, terms_accepted_at,
        privacy_accepted, privacy_accepted_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, email, name, email_verified, created_at, updated_at
    `;

    const now = new Date().toISOString();
    const result = await db.query(insertQuery, [
      email,
      name,
      hashedPassword,
      verificationToken,
      verificationExpires,
      termsAccepted || false,
      termsAccepted ? now : null,
      privacyAccepted || false,
      privacyAccepted ? now : null
    ]);

    const user = result.rows[0];

    // Seed predefined categories for this user (RF-15)
    try {
      await db.query('SELECT seed_categories_for_user($1)', [user.id]);
    } catch (seedError) {
      console.error('Error seeding categories for user:', seedError);
      // Non-fatal: continue registration even if category seeding fails
    }

    // Save GDPR consents
    try {
      const ipAddress = req.ip;
      const userAgent = req.headers['user-agent'];

      if (consents && typeof consents === 'object') {
        // User provided specific consent choices (scenario 3)
        const consentTypes = ['essential', 'analytics', 'marketing', 'third_party', 'personalization', 'data_processing'];
        for (const consentType of consentTypes) {
          const granted = consents[consentType] !== undefined ? consents[consentType] : true;
          // Required consents are always true
          const isRequired = consentType === 'essential' || consentType === 'data_processing';
          const finalValue = isRequired ? true : granted;

          await db.query(
            `INSERT INTO user_consents_current (user_id, consent_type, granted)
             VALUES ($1, $2, $3)
             ON CONFLICT (user_id, consent_type) DO UPDATE SET granted = $3, updated_at = CURRENT_TIMESTAMP`,
            [user.id, consentType, finalValue]
          );
          await db.query(
            `INSERT INTO user_consents_history (user_id, consent_type, granted, action, ip_address, user_agent)
             VALUES ($1, $2, $3, 'INITIAL_REGISTRATION', $4, $5)`,
            [user.id, consentType, finalValue, ipAddress, userAgent]
          );
        }
      } else {
        // No specific consents: all defaults ON (scenario 1 & 2)
        await db.query('SELECT seed_default_consents($1, $2, $3)', [user.id, ipAddress, userAgent]);
      }
    } catch (consentError) {
      console.error('Error saving initial consents:', consentError);
      // Non-fatal: continue registration
    }

    // Send verification email
    const emailResult = await emailService.sendVerificationEmail(email, name, verificationToken);

    if (!emailResult.success) {
      console.error('Failed to send verification email:', emailResult.error);
      // Don't fail registration, but inform the user
    }

    // Generate JWT token (user can login but with limited access until verified)
    const token = jwt.sign(
      { userId: user.id, email: user.email, emailVerified: false },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.status(201).json({
      message: 'Usuario registrado exitosamente. Por favor verifica tu correo electronico.',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        is_email_verified: user.email_verified || false,
        is_2fa_enabled: false,
        created_at: user.created_at,
        updated_at: user.updated_at
      },
      access_token: token,
      expiresIn: JWT_EXPIRES_IN,
      emailSent: emailResult.success,
      verificationRequired: true
    });

  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      error: 'Error Interno del Servidor',
      message: 'No se pudo registrar el usuario. Por favor intenta de nuevo.'
    });
  }
});

/**
 * GET /api/v1/auth/verify-email
 * Verify user email with token
 */
router.get('/verify-email', async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
      return res.status(400).json({
        error: 'Token Requerido',
        message: 'Se requiere un token de verificacion'
      });
    }

    // Find user with this verification token
    const result = await db.query(
      `SELECT id, email, name, email_verified, email_verification_expires
       FROM users
       WHERE email_verification_token = $1`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({
        error: 'Token Invalido',
        message: 'El token de verificacion no es valido o ya fue utilizado'
      });
    }

    const user = result.rows[0];

    // Check if already verified
    if (user.email_verified) {
      return res.status(400).json({
        error: 'Email Ya Verificado',
        message: 'Tu correo electronico ya ha sido verificado'
      });
    }

    // Check if token has expired
    if (new Date() > new Date(user.email_verification_expires)) {
      return res.status(400).json({
        error: 'Token Expirado',
        message: 'El token de verificacion ha expirado. Por favor solicita uno nuevo.'
      });
    }

    // Update user as verified
    await db.query(
      `UPDATE users
       SET email_verified = true,
           email_verification_token = NULL,
           email_verification_expires = NULL,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [user.id]
    );

    // Send welcome email
    await emailService.sendWelcomeEmail(user.email, user.name);

    // Return HTML response for browser
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Email Verificado - Finora</title>
        <style>
          body { font-family: 'Segoe UI', sans-serif; margin: 0; padding: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
          .container { background: white; padding: 50px; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); text-align: center; max-width: 400px; }
          .icon { font-size: 80px; margin-bottom: 20px; }
          h1 { color: #333; margin-bottom: 10px; }
          p { color: #666; line-height: 1.6; }
          .button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 40px; text-decoration: none; border-radius: 25px; font-weight: bold; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="icon">✅</div>
          <h1>Email Verificado!</h1>
          <p>Tu correo electronico ha sido verificado exitosamente. Ya puedes acceder a todas las funciones de Finora.</p>
          <a href="finora://verified" class="button">Abrir Finora</a>
        </div>
      </body>
      </html>
    `);

  } catch (error) {
    console.error('Verify email error:', error);
    res.status(500).json({
      error: 'Error Interno del Servidor',
      message: 'No se pudo verificar el email. Por favor intenta de nuevo.'
    });
  }
});

/**
 * POST /api/v1/auth/resend-verification
 * Resend verification email
 */
router.post('/resend-verification', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        error: 'Email Requerido',
        message: 'Se requiere un correo electronico'
      });
    }

    // Find user
    const result = await db.query(
      'SELECT id, name, email_verified FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      // Don't reveal if email exists for security
      return res.status(200).json({
        message: 'Si el correo existe, se enviara un nuevo enlace de verificacion'
      });
    }

    const user = result.rows[0];

    if (user.email_verified) {
      return res.status(400).json({
        error: 'Email Ya Verificado',
        message: 'Tu correo electronico ya ha sido verificado'
      });
    }

    // Generate new verification token
    const verificationToken = generateVerificationToken();
    const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);

    await db.query(
      `UPDATE users
       SET email_verification_token = $1,
           email_verification_expires = $2,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $3`,
      [verificationToken, verificationExpires, user.id]
    );

    // Send verification email
    const emailResult = await emailService.sendVerificationEmail(email, user.name, verificationToken);

    if (emailResult.success) {
      console.log(`Verification email resent to: ${email}`);
    } else {
      console.error(`Failed to resend verification email to: ${email}`, emailResult.error);
    }

    res.status(200).json({
      message: 'Se ha enviado un nuevo enlace de verificacion a tu correo electronico'
    });

  } catch (error) {
    console.error('Resend verification error:', error);
    res.status(500).json({
      error: 'Error Interno del Servidor',
      message: 'No se pudo enviar el email de verificacion'
    });
  }
});

/**
 * POST /api/v1/auth/login
 * Login user
 */
router.post('/login', loginValidation, async (req, res) => {
  try {
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Error de Validacion',
        message: 'Los datos proporcionados no son validos',
        details: errors.array().map(err => ({
          field: err.path,
          message: err.msg
        }))
      });
    }

    const { email, password } = req.body;

    // Find user by email
    const result = await db.query(
      'SELECT id, email, name, password, email_verified, created_at, updated_at FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: 'Autenticacion Fallida',
        message: 'Correo electronico o contrasena incorrectos'
      });
    }

    const user = result.rows[0];

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Autenticacion Fallida',
        message: 'Correo electronico o contrasena incorrectos'
      });
    }

    // Check if email is verified
    if (!user.email_verified) {
      return res.status(403).json({
        error: 'Cuenta No Verificada',
        message: 'Por favor verifica tu correo electronico antes de iniciar sesion',
        emailVerified: false,
        userId: user.id,
        email: user.email
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, emailVerified: user.email_verified },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.status(200).json({
      message: 'Inicio de sesion exitoso',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        is_email_verified: user.email_verified || false,
        is_2fa_enabled: false,
        created_at: user.created_at,
        updated_at: user.updated_at
      },
      access_token: token,
      expiresIn: JWT_EXPIRES_IN
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Error Interno del Servidor',
      message: 'No se pudo iniciar sesion'
    });
  }
});

/**
 * POST /api/v1/auth/logout
 * Logout user (client-side token removal)
 */
router.post('/logout', (req, res) => {
  res.status(200).json({
    message: 'Sesion cerrada exitosamente',
    note: 'Por favor elimina el token del almacenamiento local'
  });
});

/**
 * POST /api/v1/auth/refresh
 * Refresh JWT token
 */
router.post('/refresh', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'No Autorizado',
        message: 'No se proporciono token'
      });
    }

    const token = authHeader.substring(7);

    // Verify and decode token
    const decoded = jwt.verify(token, JWT_SECRET);

    // Get current user status from database
    const result = await db.query(
      'SELECT email_verified FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: 'No Autorizado',
        message: 'Usuario no encontrado'
      });
    }

    // Generate new token with updated email verification status
    const newToken = jwt.sign(
      {
        userId: decoded.userId,
        email: decoded.email,
        emailVerified: result.rows[0].email_verified
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.status(200).json({
      message: 'Token actualizado exitosamente',
      token: newToken,
      expiresIn: JWT_EXPIRES_IN
    });

  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'No Autorizado',
        message: 'Token invalido'
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'No Autorizado',
        message: 'Token expirado'
      });
    }
    console.error('Refresh token error:', error);
    res.status(500).json({
      error: 'Error Interno del Servidor',
      message: 'No se pudo actualizar el token'
    });
  }
});

/**
 * POST /api/v1/auth/biometric-token
 * Emite un token de larga duración (30 días) para login biométrico.
 * Requiere un token normal válido en Authorization header.
 */
router.post('/biometric-token', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No Autorizado', message: 'Token requerido' });
    }
    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, JWT_SECRET);

    const result = await db.query(
      'SELECT id, email, email_verified FROM users WHERE id = $1',
      [decoded.userId]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'No Autorizado', message: 'Usuario no encontrado' });
    }
    const user = result.rows[0];

    // Token de 30 días para uso biométrico
    const biometricToken = jwt.sign(
      { userId: user.id, email: user.email, emailVerified: user.email_verified, biometric: true },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(200).json({
      biometric_token: biometricToken,
      expires_in: '30d',
    });
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'No Autorizado', message: 'Token inválido o expirado' });
    }
    res.status(500).json({ error: 'Error Interno', message: error.message });
  }
});

/**
 * POST /api/v1/auth/forgot-password
 * Request password reset
 */
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        error: 'Email Requerido',
        message: 'Se requiere un correo electronico'
      });
    }

    // Find user
    const result = await db.query(
      'SELECT id, name FROM users WHERE email = $1',
      [email]
    );

    // Always return success to prevent email enumeration
    if (result.rows.length === 0) {
      return res.status(200).json({
        message: 'Si el correo existe, recibiras un enlace para restablecer tu contrasena'
      });
    }

    const user = result.rows[0];

    // Generate reset token
    const resetToken = generateVerificationToken();
    const resetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await db.query(
      `UPDATE users
       SET password_reset_token = $1,
           password_reset_expires = $2,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $3`,
      [resetToken, resetExpires, user.id]
    );

    // Send password reset email
    const emailResult = await emailService.sendPasswordResetEmail(email, user.name, resetToken);

    if (emailResult.success) {
      console.log(`Password reset email sent to: ${email}`);
    } else {
      console.error(`Failed to send password reset email to: ${email}`, emailResult.error);
    }

    res.status(200).json({
      message: 'Si el correo existe, recibiras un enlace para restablecer tu contrasena'
    });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      error: 'Error Interno del Servidor',
      message: 'No se pudo procesar la solicitud'
    });
  }
});

/**
 * GET /api/v1/auth/reset-password
 * Display password reset form (for email links)
 */
router.get('/reset-password', async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
      return res.status(400).send(`
        <!DOCTYPE html>
        <html lang="es">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Error - Finora</title>
          <style>
            body { font-family: Arial, sans-serif; background: #f5f5f5; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; max-width: 400px; }
            .error { color: #d32f2f; font-size: 24px; margin-bottom: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error">⚠️ Token no válido</div>
            <p>El enlace de restablecimiento no es válido.</p>
          </div>
        </body>
        </html>
      `);
    }

    // Verify token is valid
    const result = await db.query(
      `SELECT id, email, password_reset_expires FROM users
       WHERE password_reset_token = $1`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).send(`
        <!DOCTYPE html>
        <html lang="es">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Error - Finora</title>
          <style>
            body { font-family: Arial, sans-serif; background: #f5f5f5; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; max-width: 400px; }
            .error { color: #d32f2f; font-size: 24px; margin-bottom: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error">⚠️ Token inválido</div>
            <p>El token de restablecimiento no es válido o ya fue utilizado.</p>
          </div>
        </body>
        </html>
      `);
    }

    const user = result.rows[0];

    // Check if token has expired
    if (new Date() > new Date(user.password_reset_expires)) {
      return res.status(400).send(`
        <!DOCTYPE html>
        <html lang="es">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Error - Finora</title>
          <style>
            body { font-family: Arial, sans-serif; background: #f5f5f5; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; max-width: 400px; }
            .error { color: #d32f2f; font-size: 24px; margin-bottom: 20px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="error">⏰ Token expirado</div>
            <p>El token de restablecimiento ha expirado. Por favor solicita uno nuevo.</p>
          </div>
        </body>
        </html>
      `);
    }

    // Show password reset form
    return res.send(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Restablecer Contraseña - Finora</title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex; justify-content: center; align-items: center;
            min-height: 100vh; padding: 20px;
          }
          .container {
            background: white; padding: 40px; border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 450px; width: 100%;
          }
          h1 { color: #333; margin-bottom: 10px; font-size: 28px; text-align: center; }
          .subtitle { color: #666; margin-bottom: 30px; text-align: center; font-size: 14px; }
          .email-info { background: #f0f0f0; padding: 10px; border-radius: 5px; margin-bottom: 20px; text-align: center; color: #666; font-size: 14px; }
          .form-group { margin-bottom: 20px; }
          label { display: block; color: #333; font-weight: 500; margin-bottom: 8px; font-size: 14px; }
          input {
            width: 100%; padding: 12px; border: 2px solid #e0e0e0;
            border-radius: 8px; font-size: 16px; transition: border-color 0.3s;
          }
          input:focus { outline: none; border-color: #667eea; }
          .password-requirements {
            font-size: 12px; color: #666; margin-top: 8px;
            padding: 10px; background: #f9f9f9; border-radius: 5px;
          }
          .password-requirements div { margin: 4px 0; }
          .requirement { display: flex; align-items: center; }
          .requirement::before { content: '•'; margin-right: 8px; color: #999; }
          button {
            width: 100%; padding: 14px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; border: none; border-radius: 8px;
            font-size: 16px; font-weight: 600; cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
          }
          button:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4); }
          button:active { transform: translateY(0); }
          button:disabled { background: #ccc; cursor: not-allowed; transform: none; }
          .error { color: #d32f2f; font-size: 14px; margin-top: 10px; display: none; }
          .success { color: #2e7d32; font-size: 14px; margin-top: 10px; display: none; text-align: center; }
          .show { display: block; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🔐 Restablecer Contraseña</h1>
          <p class="subtitle">Ingresa tu nueva contraseña</p>
          <div class="email-info">
            📧 ${user.email}
          </div>

          <form id="resetForm" onsubmit="return false;">
            <div class="form-group">
              <label for="password">Nueva Contraseña</label>
              <input type="password" id="password" name="password" required autocomplete="new-password">
              <div class="password-requirements">
                <div class="requirement">Mínimo 8 caracteres</div>
                <div class="requirement">Al menos una letra mayúscula</div>
                <div class="requirement">Al menos un número</div>
                <div class="requirement">Al menos un carácter especial</div>
              </div>
            </div>

            <div class="form-group">
              <label for="confirmPassword">Confirmar Contraseña</label>
              <input type="password" id="confirmPassword" name="confirmPassword" required>
              <div class="error" id="error"></div>
            </div>

            <button type="submit" id="submitBtn">Restablecer Contraseña</button>
            <div class="success" id="success">
              ✅ Contraseña restablecida exitosamente. Puedes cerrar esta página y usar tu nueva contraseña en la aplicación.
            </div>
          </form>
        </div>

        <script>
          console.log('=== Reset Password Form Script Loaded ===');
          console.log('Current URL:', window.location.href);

          const form = document.getElementById('resetForm');
          const submitBtn = document.getElementById('submitBtn');
          const errorDiv = document.getElementById('error');
          const successDiv = document.getElementById('success');
          const passwordInput = document.getElementById('password');
          const confirmPasswordInput = document.getElementById('confirmPassword');

          // Extract token from URL
          const urlParams = new URLSearchParams(window.location.search);
          const resetToken = urlParams.get('token');

          console.log('Token extracted:', resetToken ? 'YES - ' + resetToken.substring(0, 10) + '...' : 'NO TOKEN FOUND');

          if (!resetToken) {
            console.error('ERROR: No token in URL!');
            errorDiv.textContent = 'Token no encontrado en la URL';
            errorDiv.classList.add('show');
            submitBtn.disabled = true;
          } else {
            console.log('Token found, form ready');
          }

          form.addEventListener('submit', async (e) => {
            console.log('Form submit event triggered');
            e.preventDefault();
            e.stopPropagation();

            const password = passwordInput.value;
            const confirmPassword = confirmPasswordInput.value;

            errorDiv.classList.remove('show');
            successDiv.classList.remove('show');

            // Validate passwords match
            if (password !== confirmPassword) {
              errorDiv.textContent = 'Las contraseñas no coinciden';
              errorDiv.classList.add('show');
              return;
            }

            // Validate password strength
            if (password.length < 8) {
              errorDiv.textContent = 'La contraseña debe tener al menos 8 caracteres';
              errorDiv.classList.add('show');
              return;
            }

            if (!/[A-Z]/.test(password)) {
              errorDiv.textContent = 'La contraseña debe tener al menos una letra mayúscula';
              errorDiv.classList.add('show');
              return;
            }

            if (!/[0-9]/.test(password)) {
              errorDiv.textContent = 'La contraseña debe tener al menos un número';
              errorDiv.classList.add('show');
              return;
            }

            if (!/[!@#$%^&*(),.?":{}|<>_\\-+=\\[\\]\\\\/\`~;']/.test(password)) {
              errorDiv.textContent = 'La contraseña debe tener al menos un carácter especial';
              errorDiv.classList.add('show');
              return;
            }

            // Submit to API
            console.log('Sending POST request with token:', resetToken ? resetToken.substring(0, 10) + '...' : 'NULL');
            submitBtn.disabled = true;
            submitBtn.textContent = 'Restableciendo...';

            try {
              const requestBody = {
                token: resetToken,
                password: password
              };
              console.log('Request body:', { ...requestBody, password: '***HIDDEN***' });

              const response = await fetch('/api/v1/auth/reset-password', {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify(requestBody)
              });

              console.log('Response status:', response.status);

              const data = await response.json();

              if (response.ok) {
                successDiv.classList.add('show');
                form.reset();
                submitBtn.style.display = 'none';
              } else {
                errorDiv.textContent = data.message || 'Error al restablecer la contraseña';
                errorDiv.classList.add('show');
                submitBtn.disabled = false;
                submitBtn.textContent = 'Restablecer Contraseña';
              }
            } catch (error) {
              errorDiv.textContent = 'Error de conexión. Por favor intenta de nuevo.';
              errorDiv.classList.add('show');
              submitBtn.disabled = false;
              submitBtn.textContent = 'Restablecer Contraseña';
            }
          });
        </script>
      </body>
      </html>
    `);

  } catch (error) {
    console.error('Reset password page error:', error);
    return res.status(500).send(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Error - Finora</title>
        <style>
          body { font-family: Arial, sans-serif; background: #f5f5f5; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
          .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; max-width: 400px; }
          .error { color: #d32f2f; font-size: 24px; margin-bottom: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="error">⚠️ Error del servidor</div>
          <p>No se pudo cargar la página. Por favor intenta de nuevo.</p>
        </div>
      </body>
      </html>
    `);
  }
});

/**
 * POST /api/v1/auth/reset-password
 * Reset password with token
 */
router.post('/reset-password', async (req, res) => {
  try {
    const { token, password } = req.body;

    if (!token || !password) {
      return res.status(400).json({
        error: 'Datos Incompletos',
        message: 'Se requiere token y nueva contrasena'
      });
    }

    // Validate password strength
    const passwordCheck = isStrongPassword(password);
    if (!passwordCheck.isValid) {
      const errorMessages = Object.values(passwordCheck.errors).filter(e => e !== null);
      return res.status(400).json({
        error: 'Contrasena Debil',
        message: errorMessages.join('. ')
      });
    }

    // Find user with reset token
    const result = await db.query(
      `SELECT id, password_reset_expires FROM users
       WHERE password_reset_token = $1`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({
        error: 'Token Invalido',
        message: 'El token de restablecimiento no es valido o ya fue utilizado'
      });
    }

    const user = result.rows[0];

    // Check if token has expired
    if (new Date() > new Date(user.password_reset_expires)) {
      return res.status(400).json({
        error: 'Token Expirado',
        message: 'El token de restablecimiento ha expirado. Por favor solicita uno nuevo.'
      });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Update password and clear reset token
    await db.query(
      `UPDATE users
       SET password = $1,
           password_reset_token = NULL,
           password_reset_expires = NULL,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
      [hashedPassword, user.id]
    );

    console.log(`Password reset successful for user ID: ${user.id}`);

    res.status(200).json({
      message: 'Contrasena restablecida exitosamente'
    });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      error: 'Error Interno del Servidor',
      message: 'No se pudo restablecer la contrasena'
    });
  }
});

/**
 * GET /api/v1/auth/password-requirements
 * Get password requirements for frontend
 */
router.get('/password-requirements', (req, res) => {
  res.json({
    requirements: [
      { id: 'minLength', description: 'Minimo 8 caracteres', regex: '.{8,}' },
      { id: 'uppercase', description: 'Al menos una mayuscula', regex: '[A-Z]' },
      { id: 'number', description: 'Al menos un numero', regex: '[0-9]' },
      { id: 'special', description: 'Al menos un caracter especial (!@#$%^&*...)', regex: '[!@#$%^&*(),.?":{}|<>_\\-+=\\[\\]\\\\/`~;\']' }
    ]
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
// RNF-03: Autenticación de dos factores (2FA) — TOTP (RFC 6238)
// ═══════════════════════════════════════════════════════════════════════════════

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Formato "Bearer TOKEN"

  if (!token) {
    return res.status(401).json({
      error: 'No Autorizado',
      message: 'Token de acceso no proporcionado'
    });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({
        error: 'Prohibido',
        message: 'Token inválido o expirado'
      });
    }
    
    // Guardamos los datos del usuario decodificados en el objeto request
    req.user = user;
    next();
  });
};

/** Genera secreto TOTP de 20 bytes en base32 (compatible con Google Authenticator). */
function _generateTotpSecret() {
  const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  const bytes = crypto.randomBytes(20);
  let bits = 0, value = 0, result = '';
  for (const byte of bytes) {
    value = (value << 8) | byte; bits += 8;
    while (bits >= 5) { result += CHARS[(value >>> (bits - 5)) & 31]; bits -= 5; }
  }
  if (bits > 0) result += CHARS[(value << (5 - bits)) & 31];
  return result;
}

/** Decodifica base32 a Buffer. */
function _base32Decode(base32) {
  const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  const str = base32.toUpperCase().replace(/=+$/, '');
  let bits = 0, value = 0;
  const bytes = [];
  for (const c of str) {
    const idx = CHARS.indexOf(c);
    if (idx === -1) continue;
    value = (value << 5) | idx; bits += 5;
    if (bits >= 8) { bytes.push((value >>> (bits - 8)) & 255); bits -= 8; }
  }
  return Buffer.from(bytes);
}

/** Calcula código TOTP para un instante dado. RFC 6238 / RFC 4226. */
function _getTotpCode(secret, time = Date.now()) {
  const T = Math.floor(time / 1000 / 30);
  const buf = Buffer.alloc(8);
  buf.writeUInt32BE(Math.floor(T / 0x100000000), 0);
  buf.writeUInt32BE(T >>> 0, 4);
  const hmac = crypto.createHmac('sha1', _base32Decode(secret)).update(buf).digest();
  const offset = hmac[hmac.length - 1] & 0xf;
  const code = (
    ((hmac[offset] & 0x7f) << 24) | ((hmac[offset + 1] & 0xff) << 16) |
    ((hmac[offset + 2] & 0xff) << 8) | (hmac[offset + 3] & 0xff)
  ) % 1_000_000;
  return String(code).padStart(6, '0');
}

/** Verifica código TOTP admitiendo ventana ±1 período (±30 s). */
function _verifyTotp(secret, code) {
  const now = Date.now();
  return [-30000, 0, 30000].some(delta => _getTotpCode(secret, now + delta) === String(code).padStart(6, '0'));
}

/** Genera 8 códigos de recuperación XXXX-XXXX. */
function _generateRecoveryCodes() {
  return Array.from({ length: 8 }, () => {
    const h = crypto.randomBytes(4).toString('hex').toUpperCase();
    return `${h.slice(0, 4)}-${h.slice(4)}`;
  });
}

/**
 * POST /api/v1/auth/2fa/setup
 * RNF-03: Genera secreto TOTP + URI otpauth:// para mostrar QR en el cliente.
 * No activa 2FA hasta confirmar con /2fa/verify.
 */
router.post('/2fa/setup', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const userResult = await db.query('SELECT email FROM users WHERE id = $1', [userId]);
    if (!userResult.rows.length) return res.status(404).json({ error: 'Not Found' });

    const secret = _generateTotpSecret();
    await db.query('UPDATE users SET totp_secret_pending = $1, updated_at = NOW() WHERE id = $2', [secret, userId]);

    const issuer = encodeURIComponent('Finora');
    const account = encodeURIComponent(userResult.rows[0].email);
    const otpauthUri = `otpauth://totp/${issuer}:${account}?secret=${secret}&issuer=${issuer}&algorithm=SHA1&digits=6&period=30`;

    res.json({ secret, otpauth_uri: otpauthUri });
  } catch (err) {
    console.error('2fa/setup error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

/**
 * POST /api/v1/auth/2fa/verify
 * RNF-03: Verifica primer código TOTP y activa 2FA definitivamente.
 * Devuelve códigos de recuperación (solo una vez).
 */
router.post('/2fa/verify', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { code } = req.body;
    if (!code || !/^\d{6}$/.test(String(code))) {
      return res.status(422).json({ error: 'Validation Error', message: 'Código de 6 dígitos requerido' });
    }

    const r = await db.query('SELECT totp_secret_pending FROM users WHERE id = $1', [userId]);
    if (!r.rows.length || !r.rows[0].totp_secret_pending) {
      return res.status(400).json({ error: 'Bad Request', message: 'Llama primero a /2fa/setup' });
    }

    if (!_verifyTotp(r.rows[0].totp_secret_pending, code)) {
      return res.status(401).json({ error: 'Invalid Code', message: 'Código incorrecto o expirado' });
    }

    const recoveryCodes = _generateRecoveryCodes();
    const recoveryHashes = recoveryCodes.map(c => crypto.createHash('sha256').update(c).digest('hex'));

    await db.query(
      `UPDATE users SET totp_secret = $1, totp_secret_pending = NULL,
       is_2fa_enabled = TRUE, totp_recovery_codes = $2, updated_at = NOW() WHERE id = $3`,
      [r.rows[0].totp_secret_pending, JSON.stringify(recoveryHashes), userId]
    );

    res.json({
      success: true,
      recovery_codes: recoveryCodes,
      warning: 'Guarda estos códigos en un lugar seguro. No se mostrarán de nuevo.',
    });
  } catch (err) {
    console.error('2fa/verify error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

/**
 * POST /api/v1/auth/2fa/validate
 * RNF-03: Valida código TOTP durante el login cuando 2FA está activo.
 * Recibe: { temp_token, code }
 */
router.post('/2fa/validate', async (req, res) => {
  try {
    const { temp_token, code } = req.body;
    if (!temp_token || !code) {
      return res.status(422).json({ error: 'Validation Error', message: 'temp_token y code requeridos' });
    }

    let payload;
    try { payload = jwt.verify(temp_token, JWT_SECRET); } catch {
      return res.status(401).json({ error: 'Unauthorized', message: 'Token inválido o expirado' });
    }
    if (!payload['2fa_pending']) {
      return res.status(400).json({ error: 'Bad Request', message: 'Token no es de tipo 2fa_pending' });
    }

    const userResult = await db.query(
      'SELECT id, totp_secret, totp_recovery_codes FROM users WHERE id = $1 AND is_2fa_enabled = TRUE',
      [payload.userId]
    );
    if (!userResult.rows.length) {
      return res.status(401).json({ error: 'Unauthorized', message: '2FA no activo' });
    }

    const user = userResult.rows[0];
    const codeStr = String(code).trim();
    let valid = _verifyTotp(user.totp_secret, codeStr);

    // Intentar código de recuperación si TOTP falla
    if (!valid && user.totp_recovery_codes) {
      const codes = JSON.parse(user.totp_recovery_codes);
      const hash = crypto.createHash('sha256').update(codeStr.toUpperCase()).digest('hex');
      const idx = codes.indexOf(hash);
      if (idx !== -1) {
        valid = true;
        codes.splice(idx, 1);
        await db.query('UPDATE users SET totp_recovery_codes = $1 WHERE id = $2', [JSON.stringify(codes), user.id]);
      }
    }

    if (!valid) return res.status(401).json({ error: 'Invalid Code', message: 'Código incorrecto o expirado' });

    const accessToken = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '24h' });
    res.json({ access_token: accessToken, token_type: 'Bearer' });
  } catch (err) {
    console.error('2fa/validate error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

/**
 * POST /api/v1/auth/2fa/disable
 * RNF-03: Desactiva 2FA (requiere contraseña actual).
 */
router.post('/2fa/disable', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { password } = req.body;
    if (!password) return res.status(422).json({ error: 'Validation Error', message: 'password requerida' });

    const userResult = await db.query('SELECT password, is_2fa_enabled FROM users WHERE id = $1', [userId]);
    if (!userResult.rows.length) return res.status(404).json({ error: 'Not Found' });

    const user = userResult.rows[0];
    if (!user.is_2fa_enabled) return res.status(400).json({ error: 'Bad Request', message: '2FA no estaba activo' });

    const bcrypt = require('bcryptjs');
    if (!(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ error: 'Unauthorized', message: 'Contraseña incorrecta' });
    }

    await db.query(
      `UPDATE users SET is_2fa_enabled = FALSE, totp_secret = NULL,
       totp_secret_pending = NULL, totp_recovery_codes = NULL, updated_at = NOW() WHERE id = $1`,
      [userId]
    );
    res.json({ success: true, message: '2FA desactivado correctamente' });
  } catch (err) {
    console.error('2fa/disable error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

/**
 * GET /api/v1/auth/2fa/status
 * RNF-03: Estado del 2FA del usuario.
 */
router.get('/2fa/status', authenticateToken, async (req, res) => {
  try {
    const r = await db.query('SELECT is_2fa_enabled FROM users WHERE id = $1', [req.user.userId]);
    res.json({ is_2fa_enabled: r.rows[0]?.is_2fa_enabled || false });
  } catch (err) {
    console.error('2fa/status error:', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;