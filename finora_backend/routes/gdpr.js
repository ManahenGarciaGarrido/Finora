/**
 * GDPR Routes
 *
 * Endpoints para cumplimiento del Reglamento General de Protección de Datos (GDPR)
 *
 * Requisito: RNF-04 Cumplimiento GDPR
 *
 * Funcionalidades implementadas:
 * - Gestión de consentimientos (BD real)
 * - Exportación de datos del usuario (Portabilidad - Art. 20)
 * - Derecho al olvido (Eliminación completa - Art. 17)
 * - Información sobre tratamiento de datos
 * - Historial de consentimientos
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const db = require('../services/db');
const {
  logAuditEvent,
  GDPRAuditEventTypes,
} = require('../middleware/gdprAudit');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// ============================================
// AUTHENTICATION MIDDLEWARE
// ============================================

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'No token provided',
    });
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid token',
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Token expired',
      });
    }
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Authentication failed',
    });
  }
};

// ============================================
// TIPOS DE CONSENTIMIENTO
// ============================================

const ConsentTypes = {
  ESSENTIAL: 'essential',
  ANALYTICS: 'analytics',
  MARKETING: 'marketing',
  THIRD_PARTY: 'third_party',
  PERSONALIZATION: 'personalization',
  DATA_PROCESSING: 'data_processing',
};

const ConsentDescriptions = {
  [ConsentTypes.ESSENTIAL]: {
    name: 'Cookies y datos esenciales',
    description: 'Necesarios para el funcionamiento básico de la aplicación. Incluye autenticación, seguridad y preferencias de sesión.',
    required: true,
    legalBasis: 'Ejecución de contrato (Art. 6.1.b GDPR)',
  },
  [ConsentTypes.ANALYTICS]: {
    name: 'Análisis y mejora del servicio',
    description: 'Nos permite analizar cómo usas la aplicación para mejorar la experiencia de usuario.',
    required: false,
    legalBasis: 'Consentimiento (Art. 6.1.a GDPR)',
  },
  [ConsentTypes.MARKETING]: {
    name: 'Comunicaciones de marketing',
    description: 'Te enviaremos ofertas, novedades y consejos financieros personalizados.',
    required: false,
    legalBasis: 'Consentimiento (Art. 6.1.a GDPR)',
  },
  [ConsentTypes.THIRD_PARTY]: {
    name: 'Compartir datos con terceros',
    description: 'Compartir información con socios para ofrecerte productos financieros relevantes.',
    required: false,
    legalBasis: 'Consentimiento (Art. 6.1.a GDPR)',
  },
  [ConsentTypes.PERSONALIZATION]: {
    name: 'Personalización del servicio',
    description: 'Usar tus datos financieros para personalizar recomendaciones y alertas.',
    required: false,
    legalBasis: 'Consentimiento (Art. 6.1.a GDPR)',
  },
  [ConsentTypes.DATA_PROCESSING]: {
    name: 'Procesamiento de datos financieros',
    description: 'Procesar tus transacciones y datos bancarios para ofrecerte análisis financiero.',
    required: true,
    legalBasis: 'Ejecución de contrato (Art. 6.1.b GDPR)',
  },
};

// ============================================
// POLÍTICA DE PRIVACIDAD
// ============================================

/**
 * GET /api/v1/gdpr/privacy-policy
 * Obtiene la política de privacidad completa
 */
router.get('/privacy-policy', (req, res) => {
  const privacyPolicy = {
    version: '2.0.0',
    lastUpdated: '2026-02-01',
    effectiveDate: '2026-02-01',
    language: 'es',
    controller: {
      name: 'Finora App',
      address: 'Madrid, España',
      email: 'privacy@finora.app',
    },
    sections: [
      {
        id: 'introduction',
        title: '1. Introducción',
        content: 'Esta Política de Privacidad describe cómo Finora ("nosotros", "nuestro" o "la Aplicación") recopila, usa, almacena y protege su información personal de acuerdo con el Reglamento General de Protección de Datos (GDPR) de la Unión Europea.',
      },
      {
        id: 'data_collected',
        title: '2. Datos que recopilamos',
        content: 'Recopilamos los siguientes tipos de datos:',
        items: [
          'Datos de identificación: nombre, email, teléfono',
          'Datos financieros: transacciones, saldos, categorías de gasto',
          'Datos de uso: interacciones con la app, preferencias',
          'Datos técnicos: dispositivo, sistema operativo, IP',
        ],
      },
      {
        id: 'legal_basis',
        title: '3. Base legal para el tratamiento',
        content: 'Procesamos sus datos personales bajo las siguientes bases legales:',
        items: [
          'Ejecución de contrato: para proporcionar nuestros servicios',
          'Consentimiento: para marketing y análisis',
          'Interés legítimo: para seguridad y prevención de fraude',
          'Obligación legal: para cumplir requisitos regulatorios',
        ],
      },
      {
        id: 'data_retention',
        title: '4. Conservación de datos',
        content: 'Conservamos sus datos personales durante el tiempo necesario para cumplir con los fines descritos en esta política:',
        items: [
          'Datos de cuenta: mientras la cuenta esté activa + 5 años',
          'Datos financieros: 7 años por requisitos legales',
          'Datos de marketing: hasta retirada del consentimiento',
          'Logs de seguridad: 2 años',
        ],
      },
      {
        id: 'user_rights',
        title: '5. Sus derechos',
        content: 'Bajo el GDPR, usted tiene los siguientes derechos:',
        items: [
          'Derecho de acceso: obtener copia de sus datos',
          'Derecho de rectificación: corregir datos inexactos',
          'Derecho de supresión: eliminar sus datos ("derecho al olvido")',
          'Derecho de portabilidad: recibir sus datos en formato estructurado',
          'Derecho de oposición: oponerse al tratamiento',
          'Derecho a retirar el consentimiento: en cualquier momento',
          'Derecho a presentar reclamación: ante la autoridad de control',
        ],
      },
      {
        id: 'data_security',
        title: '6. Seguridad de los datos',
        content: 'Implementamos medidas técnicas y organizativas apropiadas:',
        items: [
          'Cifrado AES-256 para datos en reposo',
          'TLS 1.3 para datos en tránsito',
          'Almacenamiento seguro con Keychain/KeyStore',
          'Autenticación multifactor disponible',
          'Auditorías de seguridad regulares',
        ],
      },
      {
        id: 'international_transfers',
        title: '7. Transferencias internacionales',
        content: 'Sus datos se procesan dentro del Espacio Económico Europeo (EEE). En caso de transferencias fuera del EEE, garantizamos protección adecuada mediante cláusulas contractuales tipo o decisiones de adecuación de la Comisión Europea.',
      },
      {
        id: 'cookies',
        title: '8. Cookies y tecnologías similares',
        content: 'Utilizamos cookies y tecnologías similares para mejorar su experiencia. Puede gestionar sus preferencias de cookies en cualquier momento desde la configuración de la aplicación.',
      },
      {
        id: 'changes',
        title: '9. Cambios en la política',
        content: 'Nos reservamos el derecho de modificar esta política. Le notificaremos cualquier cambio significativo a través de la aplicación o por email.',
      },
      {
        id: 'contact',
        title: '10. Contacto',
        content: 'Para ejercer sus derechos o realizar consultas sobre privacidad, contacte con nosotros en: privacy@finora.app',
      },
    ],
  };

  res.status(200).json({
    message: 'Privacy policy retrieved successfully',
    privacyPolicy,
  });
});

// ============================================
// GESTIÓN DE CONSENTIMIENTOS (BD REAL)
// ============================================

/**
 * GET /api/v1/gdpr/consents
 * Obtiene los tipos de consentimiento disponibles
 */
router.get('/consents', (req, res) => {
  res.status(200).json({
    message: 'Consent types retrieved successfully',
    consentTypes: ConsentDescriptions,
  });
});

/**
 * GET /api/v1/gdpr/consents/user
 * Obtiene los consentimientos actuales del usuario desde la BD
 */
router.get('/consents/user', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    const result = await db.query(
      `SELECT consent_type, granted, updated_at
       FROM user_consents_current
       WHERE user_id = $1
       ORDER BY consent_type`,
      [userId]
    );

    // Build consents map
    const consents = {};
    let lastUpdated = null;
    for (const row of result.rows) {
      consents[row.consent_type] = row.granted;
      if (!lastUpdated || new Date(row.updated_at) > new Date(lastUpdated)) {
        lastUpdated = row.updated_at;
      }
    }

    // If no consents found, return defaults (all required = true, others = false)
    if (result.rows.length === 0) {
      Object.keys(ConsentDescriptions).forEach(key => {
        consents[key] = ConsentDescriptions[key].required;
      });
      lastUpdated = new Date().toISOString();
    }

    res.status(200).json({
      message: 'User consents retrieved successfully',
      userId,
      consents,
      lastUpdated,
    });
  } catch (error) {
    console.error('Error fetching user consents:', error);
    res.status(500).json({
      error: 'Server Error',
      message: 'Error al obtener los consentimientos',
    });
  }
});

/**
 * POST /api/v1/gdpr/consents
 * Registra o actualiza los consentimientos del usuario en BD
 */
router.post('/consents', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { consents } = req.body;

    if (!consents || typeof consents !== 'object') {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Consents object is required',
      });
    }

    // Validate required consents
    const requiredConsents = Object.entries(ConsentDescriptions)
      .filter(([_, desc]) => desc.required)
      .map(([key]) => key);

    for (const required of requiredConsents) {
      if (consents[required] !== true) {
        return res.status(400).json({
          error: 'Bad Request',
          message: `El consentimiento '${required}' es obligatorio para usar el servicio`,
          requiredConsents,
        });
      }
    }

    const ipAddress = req.ip;
    const userAgent = req.headers['user-agent'];

    // Update each consent in a transaction
    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');

      for (const [consentType, granted] of Object.entries(consents)) {
        if (!ConsentDescriptions[consentType]) continue;

        // Upsert current consent
        await client.query(
          `INSERT INTO user_consents_current (user_id, consent_type, granted, updated_at)
           VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
           ON CONFLICT (user_id, consent_type)
           DO UPDATE SET granted = $3, updated_at = CURRENT_TIMESTAMP`,
          [userId, consentType, granted]
        );

        // Record in history
        await client.query(
          `INSERT INTO user_consents_history (user_id, consent_type, granted, action, ip_address, user_agent)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [userId, consentType, granted, 'CONSENT_UPDATED', ipAddress, userAgent]
        );
      }

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }

    // Audit log
    logAuditEvent({
      eventType: GDPRAuditEventTypes.CONSENT_GIVEN,
      userId,
      action: 'Consent preferences updated',
      metadata: {
        consentsGiven: Object.keys(consents).filter(k => consents[k]),
        consentsWithdrawn: Object.keys(consents).filter(k => !consents[k]),
      },
    });

    res.status(200).json({
      message: 'Consentimientos guardados correctamente',
      consents,
    });
  } catch (error) {
    console.error('Error saving consents:', error);
    res.status(500).json({
      error: 'Server Error',
      message: 'Error al guardar los consentimientos',
    });
  }
});

/**
 * DELETE /api/v1/gdpr/consents/:consentType
 * Retira un consentimiento específico
 */
router.delete('/consents/:consentType', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { consentType } = req.params;

    if (!ConsentDescriptions[consentType]) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid consent type',
      });
    }

    if (ConsentDescriptions[consentType].required) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Este consentimiento es obligatorio. Para retirarlo, debes eliminar tu cuenta.',
      });
    }

    const ipAddress = req.ip;
    const userAgent = req.headers['user-agent'];

    // Update current consent
    await db.query(
      `INSERT INTO user_consents_current (user_id, consent_type, granted, updated_at)
       VALUES ($1, $2, FALSE, CURRENT_TIMESTAMP)
       ON CONFLICT (user_id, consent_type)
       DO UPDATE SET granted = FALSE, updated_at = CURRENT_TIMESTAMP`,
      [userId, consentType]
    );

    // Record in history
    await db.query(
      `INSERT INTO user_consents_history (user_id, consent_type, granted, action, ip_address, user_agent)
       VALUES ($1, $2, FALSE, $3, $4, $5)`,
      [userId, consentType, 'CONSENT_WITHDRAWN', ipAddress, userAgent]
    );

    logAuditEvent({
      eventType: GDPRAuditEventTypes.CONSENT_WITHDRAWN,
      userId,
      action: `Consent withdrawn: ${consentType}`,
      metadata: { consentType },
    });

    res.status(200).json({
      message: `Consentimiento '${consentType}' retirado correctamente`,
    });
  } catch (error) {
    console.error('Error withdrawing consent:', error);
    res.status(500).json({
      error: 'Server Error',
      message: 'Error al retirar el consentimiento',
    });
  }
});

// ============================================
// HISTORIAL DE CONSENTIMIENTOS (BD REAL)
// ============================================

/**
 * GET /api/v1/gdpr/consents/history
 * Obtiene el historial de cambios de consentimiento del usuario desde BD
 */
router.get('/consents/history', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    const result = await db.query(
      `SELECT consent_type, granted, action, ip_address, user_agent, created_at
       FROM user_consents_history
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 100`,
      [userId]
    );

    res.status(200).json({
      message: 'Consent history retrieved successfully',
      history: result.rows.map(row => ({
        consentType: row.consent_type,
        granted: row.granted,
        action: row.action,
        timestamp: row.created_at,
        ipAddress: row.ip_address,
      })),
    });
  } catch (error) {
    console.error('Error fetching consent history:', error);
    res.status(500).json({
      error: 'Server Error',
      message: 'Error al obtener el historial de consentimientos',
    });
  }
});

// ============================================
// EXPORTACIÓN DE DATOS (PORTABILIDAD) - Art. 20 GDPR
// ============================================

/**
 * GET /api/v1/gdpr/export
 * Exporta TODOS los datos reales del usuario en formato JSON
 */
router.get('/export', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get user personal data
    const userResult = await db.query(
      `SELECT id, email, name, email_verified, terms_accepted, terms_accepted_at,
              privacy_accepted, privacy_accepted_at, created_at, updated_at
       FROM users WHERE id = $1`,
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];

    // Get transactions
    const transactionsResult = await db.query(
      `SELECT id, amount, type, category, description, date, payment_method, created_at
       FROM transactions WHERE user_id = $1 ORDER BY date DESC`,
      [userId]
    );

    // Get categories
    const categoriesResult = await db.query(
      `SELECT id, name, type, icon, color, is_predefined, display_order, created_at
       FROM categories WHERE user_id = $1 ORDER BY type, display_order`,
      [userId]
    );

    // Get current consents
    const consentsResult = await db.query(
      `SELECT consent_type, granted, updated_at
       FROM user_consents_current WHERE user_id = $1`,
      [userId]
    );

    // Get consent history
    const historyResult = await db.query(
      `SELECT consent_type, granted, action, created_at
       FROM user_consents_history WHERE user_id = $1 ORDER BY created_at DESC`,
      [userId]
    );

    const exportData = {
      exportMetadata: {
        exportDate: new Date().toISOString(),
        format: 'json',
        gdprArticle: 'Artículo 20 - Derecho a la portabilidad de datos',
        requestedBy: user.email,
      },
      personalData: {
        userId: user.id,
        email: user.email,
        name: user.name,
        emailVerified: user.email_verified,
        termsAccepted: user.terms_accepted,
        termsAcceptedAt: user.terms_accepted_at,
        privacyAccepted: user.privacy_accepted,
        privacyAcceptedAt: user.privacy_accepted_at,
        registrationDate: user.created_at,
        lastUpdated: user.updated_at,
      },
      consents: {
        current: consentsResult.rows,
        history: historyResult.rows,
      },
      financialData: {
        transactions: transactionsResult.rows,
        totalTransactions: transactionsResult.rows.length,
      },
      categories: categoriesResult.rows,
      dataProcessingInfo: {
        purposes: [
          'Gestión de finanzas personales',
          'Análisis de gastos',
          'Recomendaciones financieras',
        ],
        legalBasis: 'Consentimiento y ejecución de contrato',
        recipients: ['Ningún tercero actualmente'],
        retentionPeriod: '7 años para datos financieros',
      },
    };

    logAuditEvent({
      eventType: GDPRAuditEventTypes.DATA_EXPORT,
      userId,
      action: 'User data exported',
      metadata: { format: 'json' },
    });

    res.status(200).json({
      message: 'Datos exportados correctamente',
      data: exportData,
    });
  } catch (error) {
    console.error('Error exporting user data:', error);
    res.status(500).json({
      error: 'Server Error',
      message: 'Error al exportar los datos',
    });
  }
});

// ============================================
// DERECHO AL OLVIDO (ELIMINACIÓN REAL) - Art. 17 GDPR
// ============================================

/**
 * DELETE /api/v1/gdpr/delete-account
 * Elimina REALMENTE todos los datos del usuario de la BD
 */
router.delete('/delete-account', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { confirmDeletion, reason } = req.body;

    if (confirmDeletion !== 'DELETE_MY_ACCOUNT') {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Para confirinar la eliminación, envía confirmDeletion: "DELETE_MY_ACCOUNT"',
      });
    }

    // Log before deletion
    logAuditEvent({
      eventType: GDPRAuditEventTypes.ACCOUNT_DELETED,
      userId,
      action: 'Account deletion requested - Right to be forgotten',
      metadata: {
        reason: reason || 'Not specified',
        gdprArticle: 'Article 17 - Right to erasure',
        deletionDate: new Date().toISOString(),
      },
    });

    // Delete everything in a transaction
    const client = await db.pool.connect();
    try {
      await client.query('BEGIN');

      // Delete consent history
      await client.query('DELETE FROM user_consents_history WHERE user_id = $1', [userId]);
      // Delete current consents
      await client.query('DELETE FROM user_consents_current WHERE user_id = $1', [userId]);
      // Delete transactions
      await client.query('DELETE FROM transactions WHERE user_id = $1', [userId]);
      // Delete categories
      await client.query('DELETE FROM categories WHERE user_id = $1', [userId]);
      // Delete GDPR consents (old table)
      await client.query('DELETE FROM gdpr_consents WHERE user_id = $1', [userId]);
      // Delete audit logs (anonymize rather than delete for legal compliance)
      await client.query(
        `UPDATE audit_logs SET user_id = NULL, details = jsonb_set(COALESCE(details, '{}'), '{anonymized}', 'true')
         WHERE user_id = $1`,
        [userId]
      );
      // Finally delete the user
      await client.query('DELETE FROM users WHERE id = $1', [userId]);

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }

    const deletionReceipt = {
      receiptId: `del_${Date.now()}_${String(userId).substring(0, 8)}`,
      userId,
      deletionDate: new Date().toISOString(),
      dataDeleted: [
        'Información personal',
        'Datos financieros (transacciones)',
        'Categorías',
        'Registros de consentimiento',
        'Historial de consentimientos',
      ],
      gdprCompliance: {
        article: 'Artículo 17 - Derecho de supresión ("derecho al olvido")',
        processingTime: 'Inmediato',
      },
    };

    res.status(200).json({
      message: 'Cuenta y todos los datos asociados han sido eliminados permanentemente',
      deletionReceipt,
    });
  } catch (error) {
    console.error('Error deleting account:', error);
    res.status(500).json({
      error: 'Server Error',
      message: 'Error al eliminar la cuenta',
    });
  }
});

// ============================================
// INFORMACIÓN SOBRE TRATAMIENTO DE DATOS
// ============================================

/**
 * GET /api/v1/gdpr/data-processing
 * Obtiene información sobre cómo se procesan los datos
 */
router.get('/data-processing', (req, res) => {
  const dataProcessingInfo = {
    controller: {
      name: 'Finora App',
      contact: 'privacy@finora.app',
    },
    purposes: [
      {
        purpose: 'Gestión de cuenta',
        description: 'Crear y mantener su cuenta de usuario',
        legalBasis: 'Ejecución de contrato',
        dataCategories: ['Datos de identificación', 'Credenciales'],
        retention: 'Mientras la cuenta esté activa + 5 años',
      },
      {
        purpose: 'Análisis financiero',
        description: 'Proporcionar análisis de sus finanzas personales',
        legalBasis: 'Ejecución de contrato',
        dataCategories: ['Transacciones', 'Saldos', 'Categorías'],
        retention: '7 años (requisito legal)',
      },
      {
        purpose: 'Mejora del servicio',
        description: 'Analizar uso para mejorar la experiencia',
        legalBasis: 'Interés legítimo / Consentimiento',
        dataCategories: ['Datos de uso', 'Preferencias'],
        retention: '2 años',
      },
      {
        purpose: 'Comunicaciones',
        description: 'Enviar notificaciones y marketing',
        legalBasis: 'Consentimiento',
        dataCategories: ['Email', 'Preferencias de comunicación'],
        retention: 'Hasta retirada de consentimiento',
      },
      {
        purpose: 'Seguridad',
        description: 'Prevenir fraude y proteger la plataforma',
        legalBasis: 'Interés legítimo',
        dataCategories: ['Logs de acceso', 'IP', 'Dispositivo'],
        retention: '2 años',
      },
    ],
    dataMinimization: {
      principle: 'Solo recopilamos datos estrictamente necesarios',
      practices: [
        'Campos opcionales claramente identificados',
        'No recopilamos datos sensibles innecesarios',
        'Revisión periódica de necesidad de datos',
      ],
    },
    thirdParties: {
      current: [],
      note: 'Actualmente no compartimos datos con terceros',
    },
    internationalTransfers: {
      status: 'Datos procesados en el EEE',
      safeguards: 'Cláusulas contractuales tipo si fuera necesario',
    },
    automatedDecisions: {
      status: 'No realizamos decisiones automatizadas con efectos legales',
      note: 'Las recomendaciones son sugerencias, no decisiones vinculantes',
    },
  };

  res.status(200).json({
    message: 'Data processing information retrieved successfully',
    dataProcessing: dataProcessingInfo,
  });
});

// ============================================
// AUDITORÍA
// ============================================

/**
 * GET /api/v1/gdpr/audit/stats
 * Obtiene estadísticas de auditoría GDPR
 */
router.get('/audit/stats', authenticateToken, (req, res) => {
  const { getAuditStats } = require('../middleware/gdprAudit');
  const stats = getAuditStats();

  res.status(200).json({
    message: 'Audit stats retrieved successfully',
    stats,
  });
});

module.exports = router;
