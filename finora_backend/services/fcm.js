/**
 * RF-31: Servicio de notificaciones push via Firebase Cloud Messaging (FCM)
 *
 * Envía push notifications reales a dispositivos iOS y Android usando
 * Firebase Admin SDK. Si no hay credenciales configuradas, opera en modo
 * silent (solo notificaciones in-app en BD).
 *
 * Configuración requerida (variable de entorno):
 *   FIREBASE_SERVICE_ACCOUNT — JSON del service account de Firebase, codificado en base64
 *   o bien GOOGLE_APPLICATION_CREDENTIALS — ruta al archivo JSON del service account
 *
 * Para obtener credenciales:
 *   1. Firebase Console → Proyecto → Configuración → Cuentas de servicio
 *   2. Generar nueva clave privada → descarga JSON
 *   3. En producción: export FIREBASE_SERVICE_ACCOUNT=$(base64 -w0 serviceAccount.json)
 */

let admin = null;
let fcmApp = null;

/**
 * Inicializa Firebase Admin SDK si las credenciales están configuradas.
 * Si no hay credenciales, opera en modo degradado (solo in-app notifications).
 */
function initFirebase() {
  if (fcmApp) return; // ya inicializado

  try {
    admin = require('firebase-admin');

    // Opción 1: credenciales en variable de entorno (base64)
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(
        Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('utf8')
      );
      fcmApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('[FCM] Firebase Admin SDK inicializado con FIREBASE_SERVICE_ACCOUNT');
      return;
    }

    // Opción 2: credenciales por archivo (GOOGLE_APPLICATION_CREDENTIALS)
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      fcmApp = admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      console.log('[FCM] Firebase Admin SDK inicializado con GOOGLE_APPLICATION_CREDENTIALS');
      return;
    }

    console.warn('[FCM] Sin credenciales Firebase configuradas. Push notifications desactivadas.');
    console.warn('[FCM] Configura FIREBASE_SERVICE_ACCOUNT para activar push en producción.');
  } catch (err) {
    console.warn('[FCM] No se pudo inicializar Firebase Admin SDK:', err.message);
    admin = null;
  }
}

// Intentar inicializar al arrancar el módulo
initFirebase();

/**
 * RF-31: Envía una push notification a un token FCM específico.
 *
 * @param {string} token - Token FCM del dispositivo
 * @param {string} title - Título de la notificación
 * @param {string} body - Cuerpo del mensaje
 * @param {Object} [data] - Datos adicionales (payload para deep linking)
 * @returns {Promise<boolean>} true si se envió correctamente, false en caso contrario
 */
async function sendPushToToken(token, title, body, data = {}) {
  if (!admin || !fcmApp) {
    // Modo degradado: la notificación ya está guardada en BD (in-app)
    return false;
  }

  try {
    const message = {
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: {
          channelId: 'finora_default',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    };

    await admin.messaging().send(message);
    return true;
  } catch (err) {
    if (err.code === 'messaging/registration-token-not-registered' ||
        err.code === 'messaging/invalid-registration-token') {
      // Token expirado o inválido — se eliminará en la próxima limpieza
      console.warn(`[FCM] Token inválido: ${token.slice(0, 20)}...`);
    } else {
      console.error('[FCM] Error enviando push:', err.message);
    }
    return false;
  }
}

/**
 * RF-31: Envía una push notification a todos los dispositivos de un usuario.
 *
 * Consulta los tokens FCM del usuario en BD y envía a cada uno.
 * Respeta las preferencias de notificación (push_quiet_hours_enabled).
 *
 * @param {Object} db - Instancia de la BD
 * @param {string} userId - ID del usuario destinatario
 * @param {string} title - Título de la notificación
 * @param {string} body - Cuerpo del mensaje
 * @param {Object} [data] - Datos adicionales para deep linking
 * @returns {Promise<number>} Número de notificaciones enviadas exitosamente
 */
async function sendPushToUser(db, userId, title, body, data = {}) {
  if (!admin || !fcmApp) return 0;

  try {
    // Verificar horario silencioso
    const settingsResult = await db.query(
      `SELECT push_quiet_hours_enabled, push_quiet_start, push_quiet_end
       FROM notification_settings WHERE user_id = $1`,
      [userId]
    );

    if (settingsResult.rows.length > 0) {
      const { push_quiet_hours_enabled, push_quiet_start, push_quiet_end } = settingsResult.rows[0];
      if (push_quiet_hours_enabled && _isQuietHour(push_quiet_start, push_quiet_end)) {
        console.log(`[FCM] Horario silencioso activo para usuario ${userId}, omitiendo push`);
        return 0;
      }
    }

    // Obtener tokens FCM del usuario
    const tokenResult = await db.query(
      'SELECT token FROM push_tokens WHERE user_id = $1',
      [userId]
    );

    if (tokenResult.rows.length === 0) return 0;

    // Enviar a todos los dispositivos en paralelo
    const results = await Promise.all(
      tokenResult.rows.map(r => sendPushToToken(r.token, title, body, data))
    );

    return results.filter(Boolean).length;
  } catch (err) {
    console.error('[FCM] Error en sendPushToUser:', err.message);
    return 0;
  }
}

/**
 * Determina si la hora actual está dentro del horario silencioso configurado.
 * Soporta rangos que cruzan la medianoche (ej. 22:00 → 08:00).
 *
 * @param {string} startStr - Hora de inicio "HH:MM"
 * @param {string} endStr - Hora de fin "HH:MM"
 * @returns {boolean}
 */
function _isQuietHour(startStr, endStr) {
  const now = new Date();
  const nowMins = now.getHours() * 60 + now.getMinutes();
  const [sh, sm] = startStr.split(':').map(Number);
  const [eh, em] = endStr.split(':').map(Number);
  const startMins = sh * 60 + sm;
  const endMins = eh * 60 + em;

  // Si cruza la medianoche (ej. 22:00 → 08:00)
  if (startMins > endMins) {
    return nowMins >= startMins || nowMins < endMins;
  }
  return nowMins >= startMins && nowMins < endMins;
}

module.exports = { sendPushToUser, sendPushToToken };