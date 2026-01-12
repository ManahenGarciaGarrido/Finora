# Arquitectura Clean y Modular - Finora

## 📋 RNF-22: Arquitectura Limpia y Modular

Este documento describe la implementación de Clean Architecture en el proyecto Finora, cumpliendo con todos los criterios de aceptación del requisito RNF-22.

---

## ✅ Criterios de Aceptación Cumplidos

### 1. Capa de Presentación (UI, Widgets, ViewModels) ✓

**Ubicación:** `lib/features/*/presentation/`

La capa de presentación contiene:
- **BLoC (ViewModels):** Gestión de estado usando el patrón BLoC
  - `auth_bloc.dart` - Lógica de presentación
  - `auth_event.dart` - Eventos de UI
  - `auth_state.dart` - Estados de UI
- **Pages:** Pantallas de la aplicación
  - `login_page.dart` - Página de inicio de sesión
- **Widgets:** Componentes reutilizables de UI
  - `login_form.dart` - Formulario de login

**Características:**
- No contiene lógica de negocio
- Depende únicamente de la capa de dominio (use cases)
- Utiliza BLoC para separar la lógica de presentación de la UI

### 2. Capa de Dominio (Entities, Use Cases, Repositories) ✓

**Ubicación:** `lib/features/*/domain/`

La capa de dominio contiene:
- **Entities:** Objetos de negocio puros
  - `user.dart` - Entidad de usuario (sin dependencias externas)
- **Repositories (Interfaces):** Contratos para acceso a datos
  - `auth_repository.dart` - Interface del repositorio
- **Use Cases:** Lógica de negocio encapsulada
  - `login_usecase.dart` - Caso de uso de login
  - `register_usecase.dart` - Caso de uso de registro
  - `logout_usecase.dart` - Caso de uso de logout

**Características:**
- Completamente independiente de frameworks y librerías externas
- Define interfaces (contratos) que la capa de datos debe implementar
- Contiene la lógica de negocio de la aplicación
- No conoce cómo se almacenan o recuperan los datos

### 3. Capa de Datos (Data Sources, Models, Repository Implementations) ✓

**Ubicación:** `lib/features/*/data/`

La capa de datos contiene:
- **Models:** Extensiones de entities con serialización
  - `user_model.dart` - Modelo con JSON serialization
- **Data Sources:** Acceso a datos remotos y locales
  - **Remote:** `auth_remote_datasource.dart` - API calls
  - **Local:** `auth_local_datasource.dart` - Caché local
- **Repository Implementations:** Implementaciones de las interfaces del dominio
  - `auth_repository_impl.dart` - Implementación del repositorio

**Características:**
- Implementa las interfaces definidas en la capa de dominio
- Coordina entre fuentes de datos remotas y locales
- Convierte excepciones en failures
- Maneja la lógica de caché y sincronización

### 4. Separación Clara de Responsabilidades ✓

Cada capa tiene responsabilidades bien definidas:

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                         │
│  (UI, Widgets, BLoC - Gestión de estado y presentación) │
│                          ↓                              │
│                      DOMAIN                             │
│    (Entities, Use Cases, Repositories - Lógica negocio) │
│                          ↓                              │
│                        DATA                             │
│  (Models, DataSources, Repositories - Acceso a datos)   │
└─────────────────────────────────────────────────────────┘
```

**Principio:** Las dependencias fluyen hacia adentro (hacia el dominio)

### 5. Dependency Injection Implementada ✓

**Ubicación:** `lib/core/di/injection_container.dart`

Implementación usando **get_it** como service locator:

```dart
// Registro de dependencias
await init();

// BLoCs (Factory - nueva instancia cada vez)
sl.registerFactory(() => AuthBloc(...));

// Use Cases (Singleton)
sl.registerLazySingleton(() => LoginUseCase(sl()));

// Repositories (Singleton)
sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(...));

// Data Sources (Singleton)
sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(...));
```

**Beneficios:**
- Facilita el testing (mocking de dependencias)
- Centraliza la configuración de dependencias
- Permite cambiar implementaciones fácilmente

### 6. Principio de Inversión de Dependencias ✓

**Implementación:**

1. **Dominio define interfaces:**
```dart
// lib/features/authentication/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<Either<Failure, User>> login({...});
}
```

2. **Data implementa las interfaces:**
```dart
// lib/features/authentication/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Either<Failure, User>> login({...}) async { ... }
}
```

3. **Presentation depende de abstracciones:**
```dart
// Use cases dependen de la interface, no de la implementación
class LoginUseCase {
  final AuthRepository repository; // Interface, no implementación
  LoginUseCase(this.repository);
}
```

**Resultado:** Las capas superiores no dependen de las inferiores, sino de abstracciones.

### 7. Testabilidad de Cada Capa ✓

**Tests implementados:**

#### Domain Layer Tests
**Ubicación:** `test/unit/features/authentication/domain/`
- `login_usecase_test.dart` - Tests de lógica de negocio
- Mockea el repository usando Mockito
- Valida reglas de negocio (email format, password strength, etc.)

#### Data Layer Tests
**Ubicación:** `test/unit/features/authentication/data/`
- `auth_repository_impl_test.dart` - Tests de coordinación de datos
- Mockea data sources y network info
- Valida conversión de excepciones a failures
- Valida lógica de caché

#### Presentation Layer Tests
**Ubicación:** `test/unit/features/authentication/presentation/`
- `auth_bloc_test.dart` - Tests de lógica de presentación
- Mockea use cases
- Valida flujo de estados
- Usa bloc_test para testing declarativo

**Beneficios:**
- Cada capa puede testearse independientemente
- Mocking fácil gracias a dependency injection
- Tests rápidos sin dependencias externas

### 8. Módulos Independientes y Reutilizables ✓

**Estructura modular:**

```
lib/
├── core/                          # Módulos compartidos
│   ├── constants/                 # Constantes reutilizables
│   ├── errors/                    # Manejo de errores centralizado
│   ├── network/                   # Cliente HTTP reutilizable
│   └── di/                        # DI compartida
│
└── features/                      # Features independientes
    └── authentication/            # Módulo de autenticación
        ├── data/
        ├── domain/
        └── presentation/
```

**Características:**
- Cada feature es independiente
- Core contiene utilidades compartidas
- Features pueden ser extraídos a packages separados
- Fácil agregar nuevos features sin afectar existentes

### 9. Sin Dependencias Circulares ✓

**Flujo de dependencias:**

```
Presentation → Domain ← Data
     ↓           ↑         ↓
     └───────── Core ──────┘
```

**Reglas:**
- ✅ Presentation puede depender de Domain
- ✅ Data puede depender de Domain
- ✅ Todas las capas pueden depender de Core
- ❌ Domain NO puede depender de Data o Presentation
- ❌ No hay dependencias circulares

**Verificación:**
- Domain no importa nada de Data o Presentation
- Data implementa interfaces de Domain
- Presentation usa use cases de Domain

---

## 📊 Diagrama de Arquitectura

```
┌────────────────────────────────────────────────────────────────┐
│                          MAIN.DART                             │
│              (Dependency Injection Setup)                      │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                        │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   BLoC       │  │    Pages     │  │   Widgets    │          │
│  │ (ViewModel)  │  │   (Screens)  │  │ (Components) │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         ↓                 ↓                  ↓                 │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                             │
│                    (Business Logic)                            │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Entities    │  │  Use Cases   │  │ Repositories │          │
│  │   (User)     │  │   (Login)    │  │ (Interfaces) │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                              ↑                 │
└──────────────────────────────────────────────┼─────────────────┘
                                               │ implements
┌──────────────────────────────────────────────┼─────────────────┐
│                        DATA LAYER            ↓                 │
│                   (Data Management)                            │
│                                                                │
│  ┌──────────────┐  ┌────────────────────┐  ┌──────────────┐    │
│  │   Models     │  │   DataSources      │  │ Repositories │    │
│  │ (UserModel)  │  │ Remote │ Local     │  │    (Impl)    │    │
│  └──────────────┘  └────────────────────┘  └──────────────┘    │
│                            ↓                                   │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│                         CORE                                   │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Constants   │  │    Errors    │  │   Network    │          │
│  │   Network    │  │      DI      │  │   Storage    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Datos

### Ejemplo: Login de Usuario

```
1. USER ACTION
   LoginForm (Widget) → onPressed()

2. EVENT
   LoginForm emite → LoginRequested(email, password)

3. BLOC
   AuthBloc recibe evento → llama LoginUseCase

4. USE CASE
   LoginUseCase:
   - Valida email y password
   - Llama AuthRepository.login()

5. REPOSITORY
   AuthRepositoryImpl:
   - Verifica conectividad (NetworkInfo)
   - Llama AuthRemoteDataSource
   - Cachea resultado en AuthLocalDataSource
   - Convierte Exception → Failure
   - Retorna Either<Failure, User>

6. DATA SOURCE (Remote)
   AuthRemoteDataSourceImpl:
   - Llama API usando ApiClient
   - Parsea JSON → UserModel
   - Maneja errores → Exception

7. BACK TO USE CASE
   Recibe resultado → lo pasa a BLoC

8. BACK TO BLOC
   Emite estado:
   - Success → Authenticated(user)
   - Error → AuthError(message)

9. UI UPDATE
   LoginPage escucha estado → actualiza UI
```

---

## 🧪 Testing Strategy

### Unit Tests
- **Domain:** Testear use cases con mocked repositories
- **Data:** Testear repositories con mocked data sources
- **Presentation:** Testear BLoCs con mocked use cases

### Integration Tests
- Testear flujos completos sin mocks
- Verificar interacción entre capas

### Widget Tests
- Testear widgets individuales
- Verificar interacción con BLoC

---

## 📦 Estructura de Archivos

```
finora_frontend/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── api_endpoints.dart
│   │   │   ├── storage_keys.dart
│   │   │   └── theme_constants.dart
│   │   ├── errors/
│   │   │   ├── failures.dart
│   │   │   ├── exceptions.dart
│   │   │   └── error_handler.dart
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   └── network_info.dart
│   │   └── di/
│   │       └── injection_container.dart
│   │
│   ├── features/
│   │   └── authentication/
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   ├── auth_remote_datasource.dart
│   │       │   │   └── auth_local_datasource.dart
│   │       │   ├── models/
│   │       │   │   └── user_model.dart
│   │       │   └── repositories/
│   │       │       └── auth_repository_impl.dart
│   │       │
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   │   └── user.dart
│   │       │   ├── repositories/
│   │       │   │   └── auth_repository.dart
│   │       │   └── usecases/
│   │       │       ├── login_usecase.dart
│   │       │       ├── register_usecase.dart
│   │       │       └── logout_usecase.dart
│   │       │
│   │       └── presentation/
│   │           ├── bloc/
│   │           │   ├── auth_bloc.dart
│   │           │   ├── auth_event.dart
│   │           │   └── auth_state.dart
│   │           ├── pages/
│   │           │   └── login_page.dart
│   │           └── widgets/
│   │               └── login_form.dart
│   │
│   └── main.dart
│
└── test/
    └── unit/
        └── features/
            └── authentication/
                ├── data/
                │   └── repositories/
                │       └── auth_repository_impl_test.dart
                ├── domain/
                │   └── usecases/
                │       └── login_usecase_test.dart
                └── presentation/
                    └── bloc/
                        └── auth_bloc_test.dart
```

---

## 🎯 Ventajas de Esta Arquitectura

1. **Mantenibilidad:** Código organizado y fácil de mantener
2. **Testabilidad:** Cada capa puede testearse independientemente
3. **Escalabilidad:** Fácil agregar nuevos features
4. **Reusabilidad:** Componentes reutilizables
5. **Independencia:** Capas desacopladas
6. **Flexibilidad:** Fácil cambiar implementaciones

---

## 📚 Referencias

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)

---

## ✅ Verificación de Cumplimiento RNF-22

| Criterio | Estado | Ubicación |
|----------|--------|-----------|
| Capa de Presentación | ✅ | `features/*/presentation/` |
| Capa de Dominio | ✅ | `features/*/domain/` |
| Capa de Datos | ✅ | `features/*/data/` |
| Separación de responsabilidades | ✅ | Cada capa tiene responsabilidades claras |
| Dependency Injection | ✅ | `core/di/injection_container.dart` |
| Inversión de dependencias | ✅ | Repositorios usan interfaces |
| Testabilidad | ✅ | Tests para cada capa en `test/` |
| Módulos independientes | ✅ | Features separados |
| Sin dependencias circulares | ✅ | Domain no depende de Data/Presentation |

**Resultado:** ✅ **Todos los criterios cumplidos**
