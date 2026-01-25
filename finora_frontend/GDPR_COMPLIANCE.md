# Cumplimiento GDPR - Finora App

## RNF-04: Cumplimiento del Reglamento General de Protección de Datos (GDPR)

Este documento describe la implementación del cumplimiento GDPR en la aplicación Finora, según el requisito RNF-04.

---

## Índice

1. [Resumen de Implementación](#resumen-de-implementación)
2. [Criterios de Aceptación](#criterios-de-aceptación)
3. [Arquitectura GDPR](#arquitectura-gdpr)
4. [Endpoints del Backend](#endpoints-del-backend)
5. [Funcionalidades del Frontend](#funcionalidades-del-frontend)
6. [Derechos del Usuario](#derechos-del-usuario)
7. [Seguridad de Datos](#seguridad-de-datos)
8. [Auditoría y Logging](#auditoría-y-logging)
9. [Flujos de Usuario](#flujos-de-usuario)
10. [Testing](#testing)

---

## Resumen de Implementación

| Criterio | Estado | Implementación |
|----------|--------|----------------|
| Política de privacidad clara y accesible | ✅ | Endpoint API + UI |
| Consentimiento explícito para recopilación de datos | ✅ | Sistema de consentimientos |
| Opción de exportar todos los datos del usuario | ✅ | Endpoint de exportación |
| Derecho al olvido (eliminación completa) | ✅ | Endpoint de eliminación |
| Transparencia en uso de datos | ✅ | Info de procesamiento |
| Minimización de datos | ✅ | Documentado y validado |
| Notificación de brechas en 72h | ✅ | Sistema de alertas |
| Registro de consentimientos | ✅ | Historial auditable |
| DPO designado | ✅ | Información de contacto |
| Privacy by design | ✅ | Arquitectura segura |

---

## Criterios de Aceptación

### 1. Política de Privacidad Clara y Accesible

**Implementación:**
- Endpoint: `GET /api/v1/gdpr/privacy-policy`
- UI: Página de privacidad con modal de política completa
- Contenido estructurado en secciones

**Archivos:**
- Backend: `/finora_backend/routes/gdpr.js`
- Frontend: `/lib/features/settings/presentation/pages/privacy_page.dart`

### 2. Consentimiento Explícito

**Implementación:**
- Tipos de consentimiento definidos:
  - `essential` - Requerido para funcionamiento básico
  - `analytics` - Análisis de uso (opcional)
  - `marketing` - Comunicaciones (opcional)
  - `third_party` - Compartir con terceros (opcional)
  - `personalization` - Personalización (opcional)
  - `data_processing` - Procesamiento financiero (requerido)

**Endpoints:**
- `GET /api/v1/gdpr/consents` - Tipos disponibles
- `GET /api/v1/gdpr/consents/user` - Consentimientos del usuario
- `POST /api/v1/gdpr/consents` - Actualizar consentimientos
- `DELETE /api/v1/gdpr/consents/:type` - Retirar consentimiento

**Archivos:**
- Backend: `/finora_backend/routes/gdpr.js`
- Frontend: `/lib/features/settings/domain/entities/consent.dart`

### 3. Exportación de Datos (Portabilidad)

**Implementación (Art. 20 GDPR):**
- Endpoint: `GET /api/v1/gdpr/export`
- Formato: JSON estructurado
- Datos incluidos:
  - Información personal
  - Consentimientos y su historial
  - Datos financieros
  - Registro de actividad
  - Información de procesamiento

**Archivos:**
- Backend: `/finora_backend/routes/gdpr.js`
- Frontend: `/lib/features/settings/domain/usecases/export_user_data_usecase.dart`

### 4. Derecho al Olvido

**Implementación (Art. 17 GDPR):**
- Endpoint: `DELETE /api/v1/gdpr/delete-account`
- Confirmación requerida: `confirmDeletion: "DELETE_MY_ACCOUNT"`
- Recibo de eliminación con detalles
- Datos retenidos por requisitos legales documentados

**Archivos:**
- Backend: `/finora_backend/routes/gdpr.js`
- Frontend: `/lib/features/settings/domain/usecases/delete_account_usecase.dart`

### 5. Transparencia en Uso de Datos

**Implementación:**
- Endpoint: `GET /api/v1/gdpr/data-processing`
- Información detallada sobre:
  - Propósitos del tratamiento
  - Base legal de cada procesamiento
  - Categorías de datos
  - Períodos de retención
  - Políticas de minimización

### 6. Minimización de Datos

**Principios aplicados:**
- Solo se recopilan datos estrictamente necesarios
- Campos opcionales claramente identificados
- No se recopilan datos sensibles innecesarios
- Revisión periódica de necesidad de datos

### 7. Notificación de Brechas (72h)

**Implementación:**
- Función: `registerDataBreach()` en middleware GDPR
- Registro automático de brechas
- Deadline de 72 horas calculado
- Notificación a DPO
- Tracking de notificaciones a autoridad y usuarios

**Archivo:** `/finora_backend/middleware/gdprAudit.js`

### 8. Registro de Consentimientos

**Implementación:**
- Historial completo de cambios
- Endpoint: `GET /api/v1/gdpr/consents/history`
- Datos registrados:
  - Timestamp
  - Acción (otorgado/retirado)
  - IP del usuario
  - User agent
  - Consentimientos afectados

### 9. DPO Designado

**Implementación:**
- Endpoint: `GET /api/v1/gdpr/dpo`
- Email: `dpo@finora.app`
- Responsabilidades documentadas
- Tiempo de respuesta: máximo 30 días

### 10. Privacy by Design

**Implementación:**
- Cifrado AES-256 para datos en reposo
- TLS 1.3 para datos en tránsito
- Almacenamiento seguro nativo (Keychain/KeyStore)
- Middleware de auditoría GDPR
- Validación de consentimientos requeridos

---

## Arquitectura GDPR

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND                                 │
├─────────────────────────────────────────────────────────────────┤
│  Presentation Layer                                              │
│  ├── PrivacyPage (UI para gestión de privacidad)                │
│  └── Widgets de consentimiento                                   │
├─────────────────────────────────────────────────────────────────┤
│  Domain Layer                                                    │
│  ├── Entities (Consent, PrivacyPolicy, UserDataExport)          │
│  ├── Repositories (GDPRRepository - abstract)                   │
│  └── UseCases                                                    │
│      ├── ExportUserDataUseCase                                  │
│      ├── DeleteAccountUseCase                                   │
│      ├── GetUserConsentsUseCase                                 │
│      ├── UpdateConsentsUseCase                                  │
│      ├── WithdrawConsentUseCase                                 │
│      └── GetPrivacyInfoUseCase                                  │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer                                                      │
│  ├── Models (ConsentModel, PrivacyPolicyModel, etc.)            │
│  ├── DataSources (GDPRRemoteDataSource)                         │
│  └── Repositories (GDPRRepositoryImpl)                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS/TLS 1.3
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         BACKEND                                  │
├─────────────────────────────────────────────────────────────────┤
│  Routes: /api/v1/gdpr/*                                         │
│  ├── GET  /privacy-policy                                       │
│  ├── GET  /data-processing                                      │
│  ├── GET  /dpo                                                  │
│  ├── GET  /consents                                             │
│  ├── GET  /consents/user                                        │
│  ├── POST /consents                                             │
│  ├── DELETE /consents/:type                                     │
│  ├── GET  /consents/history                                     │
│  ├── GET  /export                                               │
│  └── DELETE /delete-account                                     │
├─────────────────────────────────────────────────────────────────┤
│  Middleware                                                      │
│  └── gdprAuditMiddleware (auditoría de acceso a datos)          │
├─────────────────────────────────────────────────────────────────┤
│  Utilidades                                                      │
│  ├── logAuditEvent() - Registro de eventos                      │
│  ├── registerDataBreach() - Notificación de brechas             │
│  ├── getUserAuditLog() - Log de usuario                         │
│  └── getDPOInfo() - Información del DPO                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Endpoints del Backend

### Política de Privacidad

```http
GET /api/v1/gdpr/privacy-policy

Response:
{
  "message": "Privacy policy retrieved successfully",
  "privacyPolicy": {
    "version": "1.0.0",
    "lastUpdated": "2024-01-15",
    "effectiveDate": "2024-01-15",
    "language": "es",
    "controller": { ... },
    "sections": [ ... ]
  }
}
```

### Gestión de Consentimientos

```http
POST /api/v1/gdpr/consents
Authorization: Bearer <token>
Content-Type: application/json

{
  "consents": {
    "essential": true,
    "analytics": true,
    "marketing": false,
    "third_party": false,
    "personalization": true,
    "data_processing": true
  }
}

Response:
{
  "message": "Consents saved successfully",
  "consents": {
    "userId": "...",
    "consents": { ... },
    "lastUpdated": "2024-01-15T10:30:00Z",
    "history": [ ... ]
  }
}
```

### Exportación de Datos

```http
GET /api/v1/gdpr/export
Authorization: Bearer <token>

Response:
{
  "message": "User data exported successfully",
  "data": {
    "exportMetadata": {
      "exportDate": "2024-01-15T10:30:00Z",
      "format": "json",
      "gdprArticle": "Article 20 - Right to data portability",
      "requestedBy": "user@email.com"
    },
    "personalData": { ... },
    "consents": { ... },
    "financialData": { ... },
    "activityLog": [ ... ],
    "dataProcessingInfo": { ... }
  }
}
```

### Eliminación de Cuenta

```http
DELETE /api/v1/gdpr/delete-account
Authorization: Bearer <token>
Content-Type: application/json

{
  "confirmDeletion": "DELETE_MY_ACCOUNT",
  "reason": "Ya no necesito el servicio"
}

Response:
{
  "message": "Account and all associated data have been deleted",
  "deletionReceipt": {
    "receiptId": "del_1705312200_abc12345",
    "userId": "...",
    "deletionDate": "2024-01-15T10:30:00Z",
    "dataDeleted": [ ... ],
    "retainedForLegal": [ ... ],
    "gdprCompliance": {
      "article": "Article 17 - Right to erasure",
      "processingTime": "Immediate",
      "backupDeletion": "30 days"
    }
  }
}
```

---

## Funcionalidades del Frontend

### Página de Privacidad (`PrivacyPage`)

La página proporciona una interfaz completa para:

1. **Información GDPR**
   - Resumen del cumplimiento
   - Enlace a política de privacidad completa

2. **Gestión de Consentimientos**
   - Toggle para cada tipo de consentimiento
   - Consentimientos requeridos marcados y no editables
   - Descripción de cada consentimiento
   - Base legal indicada

3. **Derechos del Usuario**
   - Exportar datos (botón)
   - Rectificar datos (enlace a perfil)
   - Ver historial de consentimientos
   - Ver información de tratamiento

4. **Contacto DPO**
   - Email del DPO
   - Responsabilidades listadas
   - Tiempo de respuesta

5. **Zona de Peligro**
   - Eliminación de cuenta
   - Confirmación en dos pasos
   - Campo para motivo opcional

---

## Derechos del Usuario

| Derecho | Artículo GDPR | Implementación |
|---------|---------------|----------------|
| Acceso | Art. 15 | Exportación de datos |
| Rectificación | Art. 16 | Edición de perfil |
| Supresión | Art. 17 | Eliminación de cuenta |
| Portabilidad | Art. 20 | Exportación JSON |
| Oposición | Art. 21 | Retiro de consentimientos |
| No decisiones automatizadas | Art. 22 | Documentado en política |

---

## Seguridad de Datos

### Cifrado en Reposo
- **Algoritmo:** AES-256-GCM
- **Gestión de claves:** Keychain (iOS) / KeyStore (Android)
- **Versionado de claves:** Soportado para rotación

### Cifrado en Tránsito
- **Protocolo:** TLS 1.3 exclusivamente
- **Certificate pinning:** Configurado
- **HTTP:** Bloqueado (solo HTTPS)

### Almacenamiento Seguro
- Tokens: Cifrados con AES-256
- Datos de usuario: Cifrados con AES-256
- Datos financieros: Cifrados con AES-256

---

## Auditoría y Logging

### Tipos de Eventos Auditados

```javascript
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
```

### Estructura del Registro

```javascript
{
  id: "audit_1705312200_abc123xyz",
  timestamp: "2024-01-15T10:30:00Z",
  eventType: "CONSENT_GIVEN",
  userId: "user_123",
  action: "POST /api/v1/gdpr/consents",
  ipAddress: "192.168.1.1",
  userAgent: "Finora/1.0 (iOS 17.0)",
  statusCode: 200,
  responseTime: "45ms",
  metadata: {
    gdprCompliant: true,
    auditVersion: "1.0.0"
  }
}
```

---

## Flujos de Usuario

### Flujo de Registro con Consentimientos

```
1. Usuario inicia registro
2. Se muestran consentimientos requeridos y opcionales
3. Usuario acepta consentimientos requeridos (obligatorio)
4. Usuario selecciona consentimientos opcionales
5. Se registra el consentimiento con timestamp
6. Se crea la cuenta
7. Se registra evento de auditoría ACCOUNT_CREATED
```

### Flujo de Exportación de Datos

```
1. Usuario accede a Privacidad > Exportar datos
2. Se muestra información sobre qué se exportará
3. Usuario confirma exportación
4. Backend recopila todos los datos del usuario
5. Se genera JSON estructurado
6. Se registra evento DATA_EXPORT
7. Usuario descarga/recibe el archivo
```

### Flujo de Eliminación de Cuenta

```
1. Usuario accede a Privacidad > Eliminar cuenta
2. Se muestra advertencia con lista de datos a eliminar
3. Usuario escribe "ELIMINAR" para confirmar
4. Usuario opcionalmente indica motivo
5. Backend elimina todos los datos personales
6. Se genera recibo de eliminación
7. Se registra evento ACCOUNT_DELETED
8. Usuario recibe confirmación
```

---

## Testing

### Tests de Backend

```bash
# Test de política de privacidad
curl -X GET https://api.finora.com/v1/gdpr/privacy-policy

# Test de consentimientos (requiere auth)
curl -X POST https://api.finora.com/v1/gdpr/consents \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"consents": {"essential": true, "analytics": true, "data_processing": true}}'

# Test de exportación
curl -X GET https://api.finora.com/v1/gdpr/export \
  -H "Authorization: Bearer <token>"

# Test de eliminación
curl -X DELETE https://api.finora.com/v1/gdpr/delete-account \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"confirmDeletion": "DELETE_MY_ACCOUNT"}'
```

### Checklist de Verificación

- [ ] Política de privacidad accesible sin autenticación
- [ ] Consentimientos requeridos no pueden desactivarse
- [ ] Consentimientos opcionales pueden activarse/desactivarse
- [ ] Historial de consentimientos registra cambios
- [ ] Exportación incluye todos los datos del usuario
- [ ] Eliminación requiere confirmación explícita
- [ ] Recibo de eliminación se proporciona
- [ ] Eventos de auditoría se registran correctamente
- [ ] DPO información es accesible

---

## Archivos de Implementación

### Backend
```
finora_backend/
├── middleware/
│   └── gdprAudit.js          # Middleware de auditoría GDPR
├── routes/
│   └── gdpr.js               # Endpoints GDPR
└── server.js                  # Configuración con rutas GDPR
```

### Frontend
```
finora_frontend/lib/features/settings/
├── data/
│   ├── datasources/
│   │   └── gdpr_remote_datasource.dart
│   ├── models/
│   │   ├── consent_model.dart
│   │   ├── privacy_policy_model.dart
│   │   └── user_data_export_model.dart
│   └── repositories/
│       └── gdpr_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── consent.dart
│   │   ├── privacy_policy.dart
│   │   └── user_data_export.dart
│   ├── repositories/
│   │   └── gdpr_repository.dart
│   └── usecases/
│       ├── delete_account_usecase.dart
│       ├── export_user_data_usecase.dart
│       ├── get_privacy_info_usecase.dart
│       └── manage_consents_usecase.dart
└── presentation/
    └── pages/
        └── privacy_page.dart
```

---

*Última actualización: Enero 2026*
*Versión del documento: 1.0.0*
