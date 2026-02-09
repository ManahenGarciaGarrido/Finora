/**
 * GDPR Audit Middleware
 *
 * Middleware para auditoría de acceso a datos personales
 * según el Reglamento General de Protección de Datos (GDPR)
 *
 * Requisito: RNF-04 Cumplimiento GDPR
 */

// Almacenamiento en memoria para auditoría (en producción usar base de datos)
const auditLog = [];
const dataBreaches = [];
const PRIVACY_EMAIL = process.env.PRIVACY_EMAIL || 'privacy@finora.app';
const BREACH_NOTIFICATION_HOURS = 72;

/**
 * Tipos de eventos GDPR auditables
 */
const GDPRAuditEventTypes = {
  DATA_ACCESS: 'DATA_ACCESS',
  DATA_MODIFICATION: 'DATA_MODIFICATION',
  DATA_DELETION: 'DATA_DELETION',
  DATA_EXPORT: 'DATA_EXPORT',
  CONSENT_GIVEN: 'CONSENT_GIVEN',
  CONSENT_WITHDRAWN: 'CONSENT_WITHDRAWN',
  DATA_BREACH: 'DATA_BREACH',
  LOGIN_SUCCESS: 'LOGIN_SUCCESS',
  LOGIN_FAILURE: 'LOGIN_FAILURE',
  ACCOUNT_CREATED: 'ACCOUNT_CREATED',
  ACCOUNT_DELETED: 'ACCOUNT_DELETED',
};

/**
 * Registra un evento de auditoría GDPR
 * @param {Object} event - Evento a registrar
 */
const logAuditEvent = (event) => {
  const auditEntry = {
    id: `audit_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    timestamp: new Date().toISOString(),
    ...event,
    metadata: {
      ...event.metadata,
      gdprCompliant: true,
      auditVersion: '1.0.0',
    },
  };

  auditLog.push(auditEntry);

  // En producción, esto se enviaría a un sistema de logging seguro
  if (process.env.NODE_ENV === 'development') {
    console.log('[GDPR Audit]', JSON.stringify(auditEntry, null, 2));
  }

  return auditEntry;
};

/**
 * Middleware de auditoría GDPR
 * Registra automáticamente accesos a endpoints con datos personales
 */
const gdprAuditMiddleware = (req, res, next) => {
  const startTime = Date.now();

  // Capturar la respuesta original
  const originalSend = res.send;

  res.send = function(body) {
    const responseTime = Date.now() - startTime;

    // Determinar el tipo de evento basado en el método y ruta
    let eventType = GDPRAuditEventTypes.DATA_ACCESS;

    if (req.method === 'POST' && req.path.includes('consent')) {
      eventType = GDPRAuditEventTypes.CONSENT_GIVEN;
    } else if (req.method === 'DELETE' && req.path.includes('consent')) {
      eventType = GDPRAuditEventTypes.CONSENT_WITHDRAWN;
    } else if (req.method === 'DELETE') {
      eventType = GDPRAuditEventTypes.DATA_DELETION;
    } else if (req.method === 'PUT' || req.method === 'PATCH') {
      eventType = GDPRAuditEventTypes.DATA_MODIFICATION;
    } else if (req.path.includes('export')) {
      eventType = GDPRAuditEventTypes.DATA_EXPORT;
    }

    // Registrar evento de auditoría
    logAuditEvent({
      eventType,
      userId: req.user?.userId || 'anonymous',
      action: `${req.method} ${req.path}`,
      ipAddress: req.ip || req.connection.remoteAddress,
      userAgent: req.headers['user-agent'],
      statusCode: res.statusCode,
      responseTime: `${responseTime}ms`,
      metadata: {
        path: req.path,
        method: req.method,
        query: Object.keys(req.query).length > 0 ? '[REDACTED]' : undefined,
        hasBody: Object.keys(req.body || {}).length > 0,
      },
    });

    return originalSend.call(this, body);
  };

  next();
};

/**
 * Registra una brecha de seguridad
 * Según GDPR, debe notificarse en 72 horas
 * @param {Object} breachInfo - Información de la brecha
 */
const registerDataBreach = (breachInfo) => {
  const breach = {
    id: `breach_${Date.now()}`,
    timestamp: new Date().toISOString(),
    notificationDeadline: new Date(Date.now() + BREACH_NOTIFICATION_HOURS * 60 * 60 * 1000).toISOString(),
    status: 'DETECTED',
    dpoNotified: false,
    authorityNotified: false,
    affectedUsersNotified: false,
    ...breachInfo,
  };

  dataBreaches.push(breach);

  // Registrar en auditoría
  logAuditEvent({
    eventType: GDPRAuditEventTypes.DATA_BREACH,
    severity: 'CRITICAL',
    breachId: breach.id,
    metadata: {
      affectedDataTypes: breachInfo.affectedDataTypes,
      estimatedAffectedUsers: breachInfo.estimatedAffectedUsers,
      notificationDeadline: breach.notificationDeadline,
    },
  });

  // En producción, notificar inmediatamente al responsable
  console.error(`[GDPR BREACH ALERT] Data breach detected: ${breach.id}`);
  console.error(`Privacy team must be notified: ${PRIVACY_EMAIL}`);
  console.error(`Notification deadline: ${breach.notificationDeadline}`);

  return breach;
};

/**
 * Obtiene el registro de auditoría para un usuario
 * @param {string} userId - ID del usuario
 * @returns {Array} - Entradas de auditoría del usuario
 */
const getUserAuditLog = (userId) => {
  return auditLog.filter(entry => entry.userId === userId);
};

/**
 * Obtiene todas las brechas de seguridad
 * @returns {Array} - Lista de brechas
 */
const getDataBreaches = () => {
  return dataBreaches;
};

/**
 * Obtiene estadísticas de auditoría
 * @returns {Object} - Estadísticas
 */
const getAuditStats = () => {
  const stats = {
    totalEvents: auditLog.length,
    eventsByType: {},
    lastEvent: auditLog[auditLog.length - 1] || null,
    breachCount: dataBreaches.length,
    pendingBreachNotifications: dataBreaches.filter(b => !b.authorityNotified).length,
  };

  auditLog.forEach(entry => {
    stats.eventsByType[entry.eventType] = (stats.eventsByType[entry.eventType] || 0) + 1;
  });

  return stats;
};

/**
 * Información de contacto de privacidad
 */
const getPrivacyContactInfo = () => {
  return {
    role: 'Equipo de Privacidad',
    email: PRIVACY_EMAIL,
    contactInstructions: 'Para ejercer sus derechos GDPR, contacte al equipo de privacidad a través del email proporcionado.',
  };
};

module.exports = {
  gdprAuditMiddleware,
  logAuditEvent,
  registerDataBreach,
  getUserAuditLog,
  getDataBreaches,
  getAuditStats,
  getPrivacyContactInfo,
  GDPRAuditEventTypes,
  PRIVACY_EMAIL,
};
