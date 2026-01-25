# Integración Flutter con Finora API

Guía completa para integrar tu app Flutter con la API desplegada en Render.

## 📋 Resumen

Esta guía te mostrará cómo:
1. Configurar la URL de la API en Flutter
2. Probar la integración localmente
3. Probar con la API en Render
4. Usar los servicios de seguridad implementados (TLS 1.3, AES-256)

---

## 🔧 Configuración de Flutter

### 1. Actualizar API Endpoints

Edita `finora_frontend/lib/core/constants/api_endpoints.dart`:

```dart
/// API endpoints for backend communication
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  // Base URL - Configurable por entorno
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://finora-api.onrender.com/api/v1', // URL de Render
  );

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // User endpoints
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String deleteAccount = '/user/delete';

  // ... otros endpoints ...
}
```

### 2. Configurar Certificado SSL (Certificate Pinning)

Para máxima seguridad, obtén el fingerprint del certificado de Render:

```bash
# Obtener certificado SSL de Render
openssl s_client -connect finora-api.onrender.com:443 < /dev/null 2>/dev/null | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform der | \
  openssl dgst -sha256 -binary | \
  openssl enc -base64
```

Actualiza `finora_frontend/lib/core/constants/security_config.dart`:

```dart
/// Certificate fingerprints (SHA-256) for pinning
static const Map<String, List<String>> certificatePins = {
  'finora-api.onrender.com': [
    'sha256/TU_FINGERPRINT_AQUI==',
    // Backup certificate si tienes
  ],
};
```

---

## 🧪 Testing Local

### Backend Local

```bash
cd finora_backend
npm install
npm run dev
# Server corriendo en http://localhost:3000
```

### Flutter con Backend Local

**Opción 1: Android Emulator**

```dart
// En api_endpoints.dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api/v1', // 10.0.2.2 = localhost en emulador
);
```

**Opción 2: iOS Simulator**

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);
```

**Opción 3: Dispositivo Físico**

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.X:3000/api/v1', // Tu IP local
);
```

**Probar:**

```bash
# Terminal 1: Backend
cd finora_backend
npm run dev

# Terminal 2: Flutter
cd finora_frontend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

---

## 🚀 Testing con Render

### Configurar para Producción

```dart
// api_endpoints.dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://finora-api.onrender.com/api/v1',
);
```

### Ejecutar App

```bash
cd finora_frontend

# Android
flutter run --dart-define=API_BASE_URL=https://finora-api.onrender.com/api/v1

# iOS
flutter run --dart-define=API_BASE_URL=https://finora-api.onrender.com/api/v1

# Release build
flutter build apk --release --dart-define=API_BASE_URL=https://finora-api.onrender.com/api/v1
```

---

## 💻 Actualizar AuthRemoteDataSource

Ya tienes implementado `auth_remote_datasource.dart`, pero necesitas asegurarte que use los endpoints correctos:

```dart
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      if (response.statusCode == 201) {
        // Guardar token
        final token = response.data['token'] as String;
        apiClient.setToken(token);

        // Retornar usuario
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(
          message: 'Registration failed',
          code: response.statusCode,
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // Guardar token
        final token = response.data['token'] as String;
        apiClient.setToken(token);

        // Retornar usuario
        return UserModel.fromJson(response.data['user']);
      } else {
        throw AuthenticationException(
          message: 'Invalid credentials',
          code: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw ServerException(
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
      apiClient.clearToken();
    } catch (e) {
      // Logout siempre limpia el token localmente
      apiClient.clearToken();
    }
  }
}
```

---

## 🔐 Flujo de Autenticación Completo

### 1. Registro

```dart
// En tu UI
void _handleRegister() async {
  try {
    // El AuthBloc llamará a register usecase
    context.read<AuthBloc>().add(
      RegisterEvent(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text,
      ),
    );
  } catch (e) {
    // Manejo de errores
  }
}
```

**Lo que sucede:**
1. Flutter → `POST https://finora-api.onrender.com/api/v1/auth/register`
2. Request cifrado con TLS 1.3 ✅
3. Backend valida datos
4. Backend hashea password con bcrypt (10 rounds)
5. Backend guarda usuario
6. Backend genera JWT token
7. Backend responde con `{ user, token }`
8. Flutter guarda token **cifrado con AES-256** ✅

### 2. Login

```dart
// En tu UI
void _handleLogin() async {
  context.read<AuthBloc>().add(
    LoginEvent(
      email: emailController.text,
      password: passwordController.text,
    ),
  );
}
```

**Lo que sucede:**
1. Flutter → `POST https://finora-api.onrender.com/api/v1/auth/login`
2. Request cifrado con TLS 1.3 ✅
3. Backend busca usuario por email
4. Backend verifica password con bcrypt.compare()
5. Backend genera JWT token
6. Backend responde con `{ user, token }`
7. Flutter guarda token **cifrado con AES-256** en SecureStorage ✅

### 3. Peticiones Autenticadas

```dart
// Cualquier petición después de login
final response = await apiClient.get(
  ApiEndpoints.userProfile,
);
// El ApiClient automáticamente añade: Authorization: Bearer <token>
```

**Lo que sucede:**
1. Flutter lee token cifrado de SecureStorage
2. Flutter descifra token con AES-256
3. Flutter añade header: `Authorization: Bearer <token>`
4. Request cifrado con TLS 1.3 ✅
5. Backend verifica JWT token
6. Backend responde con datos

---

## 🔒 Verificación de Seguridad

### 1. TLS 1.3 en Acción

```dart
// El SecureHttpClient automáticamente:
// - Rechaza conexiones HTTP
// - Valida certificados SSL
// - Usa TLS 1.3
```

**Probar con curl:**

```bash
# Debe funcionar (HTTPS)
curl https://finora-api.onrender.com/health

# Debe fallar (HTTP)
curl http://finora-api.onrender.com/health
# Error: Connection refused o redirect a HTTPS
```

### 2. Tokens Cifrados

```dart
// Al hacer login:
final token = response.data['token'];

// Se guarda cifrado automáticamente:
await authLocalDataSource.saveToken(token);
// Internamente usa: SecureStorageService.write(encrypt: true)

// Al leer:
final savedToken = await authLocalDataSource.getToken();
// Internamente usa: SecureStorageService.read(decrypt: true)
```

**Verificar en dispositivo:**

```bash
# Android - Inspeccionar shared_prefs
adb shell
cd /data/data/com.finora.app/
cat shared_prefs/*.xml
# ✅ NO debe haber tokens en texto plano

# Los tokens están en flutter_secure_storage (Keystore)
# ✅ Cifrados con AES-256
```

### 3. Certificate Pinning

Si configuraste certificate pinning, la app rechazará conexiones man-in-the-middle:

```dart
// Probar con Charles Proxy:
// 1. Configurar proxy en dispositivo
// 2. Abrir app
// 3. Intentar login
// ✅ Debe fallar con: "SSL certificate verification failed"
```

---

## 🐛 Troubleshooting

### Error: "Connection refused"

**Causa:** Backend no está corriendo o URL incorrecta

**Solución:**
```bash
# Verificar que backend está up
curl https://finora-api.onrender.com/health

# Verificar URL en api_endpoints.dart
```

### Error: "SSL certificate verification failed"

**Causa:** Certificate pinning configurado incorrectamente

**Solución:**
```dart
// Temporalmente deshabilitar pinning para debug
// En security_config.dart:
static const bool certificatePinningEnabled = false; // Solo para DEBUG
```

### Error: "Token expired"

**Causa:** Token JWT expiró (24 horas)

**Solución:**
```dart
// Implementar refresh token
final response = await apiClient.post(
  ApiEndpoints.refreshToken,
);
final newToken = response.data['token'];
await authLocalDataSource.saveToken(newToken);
```

### Cold Start en Render (Free Tier)

**Síntoma:** Primera request tarda ~30 segundos

**Solución:**
```dart
// Añadir loading indicator
// O hacer ping periódico al backend
// O upgrade a Render Pro ($7/mes)
```

### CORS Error

**Síntoma:** "CORS policy: No 'Access-Control-Allow-Origin' header"

**Solución:**
```bash
# En Render, configurar variable de entorno:
ALLOWED_ORIGINS = https://tu-dominio.com

# O permitir todos (solo para desarrollo):
ALLOWED_ORIGINS = *
```

---

## 📱 Ejemplo Completo de Login

### UI (login_page.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Navegar a home
            Navigator.of(context).pushReplacementNamed('/home');
          } else if (state is AuthError) {
            // Mostrar error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    if (state is AuthLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(
                              LoginEvent(
                                email: _emailController.text,
                                password: _passwordController.text,
                              ),
                            );
                          }
                        },
                        child: const Text('Login'),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

---

## 🎯 Comandos Útiles

```bash
# Ejecutar app con API de Render
flutter run --dart-define=API_BASE_URL=https://finora-api.onrender.com/api/v1

# Ejecutar app con API local
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# Build release con API de producción
flutter build apk --release --dart-define=API_BASE_URL=https://finora-api.onrender.com/api/v1

# Ver logs de network
flutter run -v | grep -i "http"

# Test de conexión
curl -X POST https://finora-api.onrender.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123","name":"Test User"}'
```

---

## ✅ Checklist de Integración

- [ ] API desplegada en Render
- [ ] URL actualizada en `api_endpoints.dart`
- [ ] `auth_remote_datasource.dart` implementado
- [ ] Login funciona desde Flutter
- [ ] Registro funciona desde Flutter
- [ ] Token se guarda cifrado en SecureStorage
- [ ] Peticiones autenticadas funcionan
- [ ] TLS 1.3 verificado (solo HTTPS)
- [ ] Certificate pinning configurado (opcional)
- [ ] Error handling implementado
- [ ] Loading states en UI
- [ ] Testing en emulador/simulador
- [ ] Testing en dispositivo físico

---

## 📚 Próximos Pasos

1. **Añadir más endpoints** en backend (transacciones, etc.)
2. **Implementar refresh token automático**
3. **Añadir PostgreSQL** para persistencia real
4. **Configurar CI/CD** para deployment automático
5. **Monitorear logs** en Render
6. **Considerar upgrade a Pro** si necesitas sin cold starts

---

## 🆘 Soporte

Si tienes problemas:

1. **Logs de Render:** Dashboard → Tu servicio → Logs
2. **Logs de Flutter:** `flutter logs` o Android Studio Logcat
3. **Test API manualmente:** Postman o curl
4. **Verificar HTTPS:** https://www.ssllabs.com/ssltest/

---

**¡Listo!** Tu app Flutter ahora está conectada de forma segura con tu API en Render usando TLS 1.3 y almacenamiento cifrado AES-256. 🎉🔒
