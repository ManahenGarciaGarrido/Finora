# Setup y Solución de Errores

Este documento explica cómo configurar el proyecto y solucionar los errores comunes.

## 🔧 Requisitos Previos

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0

## 📦 Instalación de Dependencias

```bash
flutter pub get
```

## 🧪 Generar Archivos Mock para Tests

Los tests unitarios usan **Mockito** para generar mocks automáticamente. Los archivos `.mocks.dart` se generan usando `build_runner`.

### Opción 1: Usar el script (recomendado)

```bash
./generate_mocks.sh
```

### Opción 2: Comando manual

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Este comando generará los siguientes archivos:
- `test/unit/features/authentication/domain/usecases/login_usecase_test.mocks.dart`
- `test/unit/features/authentication/data/repositories/auth_repository_impl_test.mocks.dart`
- `test/unit/features/authentication/presentation/bloc/auth_bloc_test.mocks.dart`

## ⚠️ Errores Comunes y Soluciones

### Error: "Target of URI doesn't exist: '*.mocks.dart'"

**Causa:** Los archivos mock no han sido generados.

**Solución:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "Undefined class 'Mock*'"

**Causa:** Los archivos mock no han sido generados o están desactualizados.

**Solución:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: Conflictos en build_runner

**Solución:**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🏃 Ejecutar la Aplicación

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## 🧪 Ejecutar Tests

### Ejecutar todos los tests
```bash
flutter test
```

### Ejecutar tests específicos
```bash
# Tests de un feature específico
flutter test test/unit/features/authentication/

# Test de un archivo específico
flutter test test/unit/features/authentication/domain/usecases/login_usecase_test.dart
```

### Ejecutar tests con coverage
```bash
flutter test --coverage
```

## 🔍 Análisis de Código

### Verificar problemas
```bash
flutter analyze
```

### Formatear código
```bash
dart format .
```

## 🔄 Actualizar Dependencias

```bash
# Ver dependencias desactualizadas
flutter pub outdated

# Actualizar dependencias
flutter pub upgrade
```

## 📝 Notas Importantes

1. **Siempre genera los mocks** después de:
   - Agregar nuevos tests con `@GenerateMocks`
   - Modificar clases que son mockeadas
   - Clonar el repositorio por primera vez

2. **No comitees archivos `.mocks.dart`** al repositorio:
   - Estos archivos se generan automáticamente
   - Ya están incluidos en `.gitignore`

3. **Si cambias la estructura de una clase mockeada**, regenera los mocks:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## 🐛 Troubleshooting

### Problema: Build runner falla

**Solución 1:** Limpiar cache
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

**Solución 2:** Verificar versiones de dependencias
```bash
flutter pub upgrade
```

### Problema: Tests fallan después de cambios

**Solución:** Regenerar mocks
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📚 Recursos

- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Build Runner Documentation](https://pub.dev/packages/build_runner)
- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Clean Architecture](../ARCHITECTURE.md)

## ✅ Checklist de Setup

Después de clonar el repositorio, ejecuta estos comandos en orden:

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Generar mocks para tests
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Verificar que todo funciona
flutter analyze

# 4. Ejecutar tests
flutter test

# 5. Ejecutar la app
flutter run
```

Si todos los pasos se completan sin errores, ¡estás listo para desarrollar! 🎉
