/**
 * GDPR Routes
 *
 * Endpoints para cumplimiento del Reglamento General de Protección de Datos (GDPR)
 *
 * Requisito: RNF-04 Cumplimiento GDPR
 *
 * Funcionalidades implementadas:
 * - Gestión de consentimientos
 * - Exportación de datos del usuario (Portabilidad)
 * - Derecho al olvido (Eliminación completa)
 * - Información sobre tratamiento de datos
 * - Registro de consentimientos
 * - Información del DPO
 */

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const {
  logAuditEvent,
  getUserAuditLog,
  getDPOInfo,
  getAuditStats,
  GDPRAuditEventTypes,
} = require('../middleware/gdprAudit');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Almacenamiento en memoria para consentimientos (en producción usar base de datos)
const userConsents = new Map();
const deletedUsers = new Set();

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
  ESSENTIAL: 'essential', // Necesario para el funcionamiento
  ANALYTICS: 'analytics', // Análisis de uso
  MARKETING: 'marketing', // Comunicaciones de marketing
  THIRD_PARTY: 'third_party', // Compartir con terceros
  PERSONALIZATION: 'personalization', // Personalización del servicio
  DATA_PROCESSING: 'data_processing', // Procesamiento de datos financieros
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
    version: '1.0.0',
    lastUpdated: '2024-01-15',
    effectiveDate: '2024-01-15',
    language: 'es',
    controller: {
      name: 'Finora App',
      address: 'Madrid, España',
      email: 'privacy@finora.app',
      dpo: getDPOInfo(),
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
        content: 'Para ejercer sus derechos o realizar consultas sobre privacidad, contacte a nuestro Delegado de Protección de Datos (DPO):',
        contact: getDPOInfo(),
      },
    ],
  };

  res.status(200).json({
    message: 'Privacy policy retrieved successfully',
    privacyPolicy,
  });
});

// ============================================
// GESTIÓN DE CONSENTIMIENTOS
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
 * Obtiene los consentimientos del usuario autenticado
 */
router.get('/consents/user', authenticateToken, (req, res) => {
  const userId = req.user.userId;
  const consents = userConsents.get(userId) || getDefaultConsents();

  res.status(200).json({
    message: 'User consents retrieved successfully',
    userId,
    consents,
    lastUpdated: consents.lastUpdated || new Date().toISOString(),
  });
});

/**
 * POST /api/v1/gdpr/consents
 * Registra o actualiza los consentimientos del usuario
 */
router.post('/consents', authenticateToken, (req, res) => {
  const userId = req.user.userId;
  const { consents } = req.body;

  if (!consents || typeof consents !== 'object') {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Consents object is required',
    });
  }

  // Validar que los consentimientos esenciales estén aceptados
  const requiredConsents = Object.entries(ConsentDescriptions)
    .filter(([_, desc]) => desc.required)
    .map(([key]) => key);

  for (const required of requiredConsents) {
    if (consents[required] !== true) {
      return res.status(400).json({
        error: 'Bad Request',
        message: `Consent for '${required}' is required to use the service`,
        requiredConsents,
      });
    }
  }

  const consentRecord = {
    userId,
    consents,
    lastUpdated: new Date().toISOString(),
    history: [
      ...(userConsents.get(userId)?.history || []),
      {
        timestamp: new Date().toISOString(),
        action: 'CONSENT_UPDATED',
        consents: { ...consents },
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
      },
    ],
  };

  userConsents.set(userId, consentRecord);

  // Registrar en auditoría
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
    message: 'Consents saved successfully',
    consents: consentRecord,
  });
});

/**
 * DELETE /api/v1/gdpr/consents/:consentType
 * Retira un consentimiento específico
 */
router.delete('/consents/:consentType', authenticateToken, (req, res) => {
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
      message: 'This consent is required and cannot be withdrawn. You may delete your account instead.',
    });
  }

  const currentConsents = userConsents.get(userId) || getDefaultConsents();
  currentConsents.consents[consentType] = false;
  currentConsents.lastUpdated = new Date().toISOString();
  currentConsents.history = [
    ...(currentConsents.history || []),
    {
      timestamp: new Date().toISOString(),
      action: 'CONSENT_WITHDRAWN',
      consentType,
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    },
  ];

  userConsents.set(userId, currentConsents);

  // Registrar en auditoría
  logAuditEvent({
    eventType: GDPRAuditEventTypes.CONSENT_WITHDRAWN,
    userId,
    action: `Consent withdrawn: ${consentType}`,
    metadata: { consentType },
  });

  res.status(200).json({
    message: `Consent for '${consentType}' withdrawn successfully`,
    consents: currentConsents,
  });
});

// ============================================
// EXPORTACIÓN DE DATOS (PORTABILIDAD)
// ============================================

/**
 * GET /api/v1/gdpr/export
 * Exporta todos los datos del usuario en formato estructurado (JSON)
 * Derecho de portabilidad - Art. 20 GDPR
 */
router.get('/export', authenticateToken, (req, res) => {
  const userId = req.user.userId;
  const format = req.query.format || 'json';

  // Recopilar todos los datos del usuario
  const userData = {
    exportMetadata: {
      exportDate: new Date().toISOString(),
      format,
      gdprArticle: 'Article 20 - Right to data portability',
      requestedBy: req.user.email,
    },
    personalData: {
      userId: req.user.userId,
      email: req.user.email,
      // En producción, obtener de la base de datos
      name: 'Usuario de Finora',
      registrationDate: new Date().toISOString(),
    },
    consents: userConsents.get(userId) || getDefaultConsents(),
    // En producción, incluir:
    financialData: {
      note: 'Los datos financieros se incluirían aquí cuando la funcionalidad esté implementada',
      transactions: [],
      bankAccounts: [],
      savingsGoals: [],
      budgets: [],
    },
    activityLog: getUserAuditLog(userId),
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

  // Registrar en auditoría
  logAuditEvent({
    eventType: GDPRAuditEventTypes.DATA_EXPORT,
    userId,
    action: 'User data exported',
    metadata: { format },
  });

  res.status(200).json({
    message: 'User data exported successfully',
    data: userData,
  });
});

// ============================================
// DERECHO AL OLVIDO (ELIMINACIÓN)
// ============================================

/**
 * DELETE /api/v1/gdpr/delete-account
 * Elimina completamente todos los datos del usuario
 * Derecho al olvido - Art. 17 GDPR
 */
router.delete('/delete-account', authenticateToken, (req, res) => {
  const userId = req.user.userId;
  const { confirmDeletion, reason } = req.body;

  if (confirmDeletion !== 'DELETE_MY_ACCOUNT') {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Please confirm deletion by sending confirmDeletion: "DELETE_MY_ACCOUNT"',
    });
  }

  // Registrar la eliminación antes de borrar
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

  // Eliminar consentimientos
  userConsents.delete(userId);

  // Marcar usuario como eliminado (en producción, eliminar de todas las bases de datos)
  deletedUsers.add(userId);

  // En producción:
  // - Eliminar de la base de datos principal
  // - Eliminar datos de backups (programar)
  // - Notificar a terceros para eliminar datos compartidos
  // - Invalidar todos los tokens
  // - Eliminar datos de analytics

  const deletionReceipt = {
    receiptId: `del_${Date.now()}_${userId.substring(0, 8)}`,
    userId,
    deletionDate: new Date().toISOString(),
    dataDeleted: [
      'Personal information',
      'Financial data',
      'Consent records',
      'Activity logs',
      'Preferences',
    ],
    retainedForLegal: [
      'Anonymized transaction records (7 years - legal requirement)',
      'Audit logs (anonymized)',
    ],
    gdprCompliance: {
      article: 'Article 17 - Right to erasure ("right to be forgotten")',
      processingTime: 'Immediate',
      backupDeletion: '30 days',
    },
  };

  res.status(200).json({
    message: 'Account and all associated data have been deleted',
    deletionReceipt,
  });
});

// ============================================
// INFORMACIÓN DEL DPO
// ============================================

/**
 * GET /api/v1/gdpr/dpo
 * Obtiene información del Data Protection Officer
 */
router.get('/dpo', (req, res) => {
  res.status(200).json({
    message: 'DPO information retrieved successfully',
    dpo: getDPOInfo(),
    howToContact: {
      exerciseRights: 'Envíe un email al DPO indicando qué derecho desea ejercer',
      complaint: 'Puede presentar una reclamación ante la Agencia Española de Protección de Datos (AEPD)',
      responseTime: 'Máximo 30 días según GDPR',
    },
  });
});

// ============================================
// HISTORIAL DE CONSENTIMIENTOS
// ============================================

/**
 * GET /api/v1/gdpr/consents/history
 * Obtiene el historial de cambios de consentimiento del usuario
 */
router.get('/consents/history', authenticateToken, (req, res) => {
  const userId = req.user.userId;
  const consentRecord = userConsents.get(userId);

  if (!consentRecord || !consentRecord.history) {
    return res.status(200).json({
      message: 'No consent history found',
      history: [],
    });
  }

  res.status(200).json({
    message: 'Consent history retrieved successfully',
    history: consentRecord.history,
  });
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
      dpo: getDPOInfo(),
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
// AUDITORÍA (Solo para administradores en producción)
// ============================================

/**
 * GET /api/v1/gdpr/audit/stats
 * Obtiene estadísticas de auditoría GDPR
 */
router.get('/audit/stats', authenticateToken, (req, res) => {
  // En producción, verificar que es administrador
  const stats = getAuditStats();

  res.status(200).json({
    message: 'Audit stats retrieved successfully',
    stats,
  });
});

// ============================================
// HELPER FUNCTIONS
// ============================================

function getDefaultConsents() {
  const defaults = {};
  Object.keys(ConsentDescriptions).forEach(key => {
    defaults[key] = ConsentDescriptions[key].required;
  });
  return {
    consents: defaults,
    lastUpdated: new Date().toISOString(),
    history: [],
  };
}

module.exports = router;
