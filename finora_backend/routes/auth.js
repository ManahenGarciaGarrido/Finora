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

    const { email, password, name, termsAccepted, privacyAccepted } = req.body;

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
    await emailService.sendPasswordResetEmail(email, user.name, resetToken);

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

module.exports = router;
