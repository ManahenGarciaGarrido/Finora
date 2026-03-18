# Finora Backend API

API REST segura para la aplicación Finora - Gestión Financiera Personal.

## 🚀 Características

- ✅ **Node.js + Express** - Framework robusto y escalable
- ✅ **HTTPS/TLS 1.3** - Comunicaciones seguras (automático en Render)
- ✅ **JWT Authentication** - Tokens seguros para autenticación
- ✅ **Bcrypt** - Hashing seguro de contraseñas
- ✅ **Rate Limiting** - Protección contra ataques de fuerza bruta
- ✅ **Helmet** - Security headers
- ✅ **CORS** - Configuración flexible de orígenes
- ✅ **Validation** - express-validator para validación de inputs
- ✅ **Logging** - Morgan para logging de requests

## 📦 Estructura del Proyecto

```
finora_backend/
├── server.js                 # Servidor principal
├── routes/
│   ├── auth.js              # Endpoints de autenticación
│   ├── user.js              # Endpoints de usuario
│   └── health.js            # Health checks
├── package.json             # Dependencias
├── .env.example             # Variables de entorno ejemplo
├── .gitignore               # Git ignore
└── README.md                # Este archivo
```

## 🔧 Instalación Local

### Requisitos

- Node.js 18+
- npm o yarn

### Pasos

1. **Clonar el repositorio**
   ```bash
   git clone <tu-repo-url>
   cd finora_backend
   ```

2. **Instalar dependencias**
   ```bash
   npm install
   ```

3. **Configurar variables de entorno**
   ```bash
   cp .env.example .env
   # Editar .env con tus valores
   ```

4. **Iniciar el servidor**
   ```bash
   # Desarrollo (con nodemon)
   npm run dev

   # Producción
   npm start
   ```

5. **Verificar**
   ```bash
   curl http://localhost:3000/health
   ```

## 🌐 Deployment en Render (GRATIS)

### ¿Por qué Render?

**Render** es la mejor opción gratuita en 2026 porque:

- ✅ **Free tier real** - No requiere tarjeta de crédito
- ✅ **HTTPS/TLS automático** - Certificados SSL gratis y renovación automática
- ✅ **TLS 1.3 soportado** - Cumple requisitos de seguridad
- ✅ **PostgreSQL gratis** - 90 días, luego $7/mes (opcional)
- ✅ **Deployment continuo** - Desde GitHub/GitLab
- ✅ **Auto-scaling** - Según demanda
- ✅ **Logs en tiempo real** - Debugging fácil

### Limitaciones del Free Tier

- ⚠️ Servicio se "duerme" tras 15 minutos de inactividad
- ⚠️ Primera request después de dormir toma ~30 segundos (cold start)
- ⚠️ 750 horas/mes de uso (suficiente para desarrollo y testing)
- ⚠️ Sin soporte prioritario

**Para producción**, considera el plan Pro ($7/mes) que mantiene el servicio siempre activo.

### Pasos para Deploy en Render

#### 1. Preparar el Repositorio

```bash
# Asegurarse de que el código está en Git
git init
git add .
git commit -m "Initial commit - Finora API"

# Crear repositorio en GitHub
# Subir código
git remote add origin <tu-repo-url>
git branch -M main
git push -u origin main
```

#### 2. Crear Cuenta en Render

1. Ir a https://render.com
2. Registrarse con GitHub (recomendado)
3. Autorizar acceso a tus repositorios

#### 3. Crear Web Service

1. **Dashboard** → **New +** → **Web Service**

2. **Conectar repositorio:**
   - Seleccionar tu repositorio `finora_backend`
   - Click en **Connect**

3. **Configurar servicio:**
   - **Name:** `finora-api` (o el nombre que prefieras)
   - **Region:** Elegir más cercano a tus usuarios
   - **Branch:** `main`
   - **Runtime:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Instance Type:** `Free`

4. **Variables de entorno:**
   Click en **Advanced** → **Add Environment Variable**

   ```
   NODE_ENV = production
   JWT_SECRET = tu-secret-key-super-seguro-minimo-32-caracteres-aqui
   ALLOWED_ORIGINS = https://tu-app-flutter.com
   ```

5. **Click en "Create Web Service"**

6. **Esperar deployment** (2-3 minutos)

#### 4. Verificar Deployment

Una vez completado, Render te dará una URL:
```
https://finora-api.onrender.com
```

**Probar:**
```bash
# Health check
curl https://finora-api.onrender.com/health

# Info API
curl https://finora-api.onrender.com/

# Registro
curl -X POST https://finora-api.onrender.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

#### 5. Deployment Automático

Render automáticamente despliega cuando haces push a la rama `main`:

```bash
git add .
git commit -m "Add new feature"
git push origin main
# Render detecta el push y despliega automáticamente
```

### Monitorear Logs

```bash
# En Render Dashboard → Tu servicio → Logs
# Verás logs en tiempo real
```

### Configurar Custom Domain (Opcional)

1. En Render Dashboard → Tu servicio → **Settings**
2. **Custom Domains** → **Add Custom Domain**
3. Ingresar tu dominio: `api.finora.com`
4. Configurar DNS:
   - Tipo: `CNAME`
   - Name: `api`
   - Value: `finora-api.onrender.com`

**HTTPS/TLS es automático** - Render gestiona certificados SSL.

## 📡 API Endpoints

### Health Check

```bash
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "uptime": 3600.5,
  "timestamp": "2026-01-14T10:00:00.000Z",
  "environment": "production",
  "version": "1.0.0"
}
```

### Authentication

#### Register

```bash
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "name": "John Doe"
}
```

**Response (201):**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "name": "John Doe",
    "createdAt": "2026-01-14T10:00:00.000Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "24h"
}
```

#### Login

```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response (200):**
```json
{
  "message": "Login successful",
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "24h"
}
```

#### Logout

```bash
POST /api/v1/auth/logout
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Logout successful",
  "note": "Please remove the token from client storage"
}
```

#### Refresh Token

```bash
POST /api/v1/auth/refresh
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Token refreshed successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "24h"
}
```

### User

#### Get Profile

```bash
GET /api/v1/user/profile
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Profile retrieved successfully",
  "user": {
    "userId": "uuid-here",
    "email": "user@example.com"
  }
}
```

#### Update Profile

```bash
PUT /api/v1/user/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Updated Name"
}
```

#### Delete Account

```bash
DELETE /api/v1/user/delete
Authorization: Bearer <token>
```

## 🔒 Seguridad

### TLS/HTTPS

- ✅ **Render proporciona HTTPS automático** con certificados SSL gratuitos
- ✅ **TLS 1.3 soportado** por defecto
- ✅ **Renovación automática** de certificados
- ✅ **HSTS headers** configurados con Helmet

### Autenticación

- ✅ **JWT tokens** con expiración de 24 horas
- ✅ **Bcrypt** para hashing de contraseñas (10 rounds)
- ✅ **Rate limiting** en endpoints de autenticación (5 requests/15min)

### Headers de Seguridad (Helmet)

```javascript
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### CORS

Configurado para aceptar requests solo de orígenes permitidos (configurable en `.env`).

## 🔄 Añadir Nuevos Endpoints

### 1. Crear nuevo archivo de rutas

```javascript
// routes/transactions.js
const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({ transactions: [] });
});

router.post('/', (req, res) => {
  res.json({ message: 'Transaction created' });
});

module.exports = router;
```

### 2. Registrar ruta en server.js

```javascript
const transactionRoutes = require('./routes/transactions');
app.use('/api/v1/transactions', transactionRoutes);
```

### 3. Commit y push

```bash
git add .
git commit -m "Add transactions endpoints"
git push origin main
# Render despliega automáticamente
```

## 🗃️ Añadir Base de Datos (PostgreSQL)

### En Render

1. **Dashboard** → **New +** → **PostgreSQL**
2. **Name:** `finora-db`
3. **Instance Type:** `Free` (90 días gratis)
4. **Create Database**

5. **Conectar con tu Web Service:**
   - En tu Web Service → **Environment**
   - Add: `DATABASE_URL` = `<connection-string-from-postgres>`

### En el código

```javascript
// Instalar pg
npm install pg

// db.js
const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

module.exports = pool;
```

## 📊 Monitoreo

### Logs en Render

```
Dashboard → Tu servicio → Logs
```

### Métricas

```
Dashboard → Tu servicio → Metrics
- CPU usage
- Memory usage
- Request count
- Response times
```

### Alertas

Configurar en **Settings** → **Alerts** para recibir notificaciones por email.

## 🚀 Upgrade a Plan Pro

Si necesitas:
- Sin cold starts (servicio siempre activo)
- Más CPU/RAM
- Soporte prioritario

**Plan Pro:** $7/mes

```
Dashboard → Tu servicio → Settings → Plan → Upgrade to Pro
```

## 📝 Notas Importantes

### Cold Starts

El free tier tiene cold starts después de 15 minutos de inactividad. La primera request tarda ~30 segundos.

**Solución:**
- Hacer ping periódico con un cron job externo
- Upgrade a Pro ($7/mes)

### Logs

Los logs se mantienen por 7 días en free tier.

### Backups

El free tier de PostgreSQL **NO incluye backups automáticos**. Para backups, considera:
- Plan Pro de PostgreSQL ($7/mes) - incluye backups automáticos
- Exportar datos manualmente
- Usar otro servicio de DB (Supabase tiene free tier con backups)

## 🔗 Recursos

- [Documentación Render](https://render.com/docs)
- [Express.js](https://expressjs.com/)
- [JWT](https://jwt.io/)
- [Helmet](https://helmetjs.github.io/)

## 📄 Licencia

ISC

## 👨‍💻 Autor

Finora Team
