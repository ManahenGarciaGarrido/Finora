# Guía de Pruebas de Seguridad - Comunicaciones TLS

## 🧪 Tests Unitarios

### Ejecutar Tests

```bash
# Ejecutar todos los tests de seguridad
flutter test test/unit/core/network/

# Ejecutar test específico
flutter test test/unit/core/network/secure_http_client_test.dart
flutter test test/unit/core/network/tls_validator_test.dart
```

### Cobertura de Tests

```bash
# Generar reporte de cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🔍 Pruebas de Integración

### 1. Prueba de Rechazo HTTP

**Objetivo:** Verificar que las conexiones HTTP son rechazadas

```dart
// En un test de integración o ejemplo
void testHttpRejection() async {
  final apiClient = ApiClient();

  try {
    // Esto debería fallar
    await apiClient.get('http://api.finora.com/endpoint');
    print('❌ FALLO: HTTP no fue rechazado');
  } catch (e) {
    if (e is SecurityException) {
      print('✅ ÉXITO: HTTP rechazado correctamente');
    } else {
      print('❌ FALLO: Error inesperado: $e');
    }
  }
}
```

### 2. Prueba de Certificado SSL

**Objetivo:** Verificar que certificados inválidos son rechazados

```bash
# Usando curl con certificado autofirmado (debe fallar)
curl -k https://self-signed.badssl.com/
```

### 3. Prueba de TLS 1.3

**Objetivo:** Verificar soporte de TLS 1.3

```dart
void testTlsSupport() async {
  final support = await TlsValidator.checkTlsSupport();
  print(support);

  if (support.isSupported && support.version.contains('1.3')) {
    print('✅ TLS 1.3 soportado');
  } else {
    print('⚠️ TLS 1.3 no soportado en esta plataforma');
  }
}
```

## 🛠️ Herramientas de Auditoría

### 1. SSL Labs Test

**Instrucciones:**
1. Visitar https://www.ssllabs.com/ssltest/
2. Ingresar dominio: `api.finora.com`
3. Esperar análisis completo
4. Verificar:
   - Grade: A o A+
   - Protocol Support: TLS 1.3
   - Certificate: Válido
   - Certificate Chain: Correcto

**Criterios de Éxito:**
- ✅ Overall Rating: A+
- ✅ Protocol Support: TLS 1.3 (mandatory)
- ✅ Certificate: 100/100
- ✅ Protocol Support: 100/100
- ✅ Key Exchange: 100/100
- ✅ Cipher Strength: 90/100+

### 2. Charles Proxy

**Instrucciones:**
1. Instalar Charles Proxy
2. Configurar certificado SSL en dispositivo
3. Iniciar captura de tráfico
4. Ejecutar app Finora
5. Intentar realizar peticiones

**Criterios de Éxito:**
- ✅ Sin certificate pinning: peticiones exitosas en Charles
- ✅ Con certificate pinning: peticiones fallan con error SSL
- ✅ Solo tráfico HTTPS visible (sin HTTP)

### 3. Wireshark

**Instrucciones:**
```bash
# Capturar tráfico de red
wireshark -i any -f "tcp port 443"

# Filtrar tráfico SSL/TLS
tcp.port == 443 && ssl
```

**Criterios de Éxito:**
- ✅ Solo protocolo TLS 1.3 en handshake
- ✅ Sin tráfico HTTP (puerto 80)
- ✅ Cifrado completo de payload

### 4. mitmproxy

**Instrucciones:**
```bash
# Iniciar mitmproxy
mitmproxy -p 8080

# Configurar proxy en dispositivo
# Host: IP de tu máquina
# Puerto: 8080
```

**Criterios de Éxito:**
- ✅ App rechaza conexión si certificate pinning activo
- ✅ Muestra error de certificado SSL
- ✅ No se puede interceptar tráfico

## 📊 Checklist de Verificación

### Pre-Producción

- [ ] Tests unitarios pasan al 100%
- [ ] Tests de integración exitosos
- [ ] SSL Labs score: A+
- [ ] Certificate pinning configurado
- [ ] Fingerprints de producción actualizados
- [ ] Prueba con Charles Proxy exitosa
- [ ] Prueba con Wireshark exitosa
- [ ] Verificación de TLS 1.3 en dispositivos reales

### Dispositivos de Prueba

- [ ] Android 10+ (API 29+)
- [ ] Android 11+
- [ ] iOS 13.0+
- [ ] iOS 14.0+
- [ ] iOS 15.0+

### Escenarios de Prueba

- [ ] Conexión HTTP rechazada
- [ ] Conexión HTTPS exitosa
- [ ] Certificado válido aceptado
- [ ] Certificado inválido rechazado
- [ ] Certificate pinning funcionando
- [ ] Man-in-the-middle bloqueado
- [ ] Downgrade attack prevenido

## 🚨 Casos de Fallo

### Escenario 1: HTTP Connection Allowed
```
❌ FALLO: Se permite conexión HTTP
Causa: allowHttpConnections = true en SecurityConfig
Solución: Cambiar a false en producción
```

### Escenario 2: Certificate Pinning Bypass
```
❌ FALLO: Charles Proxy puede interceptar tráfico
Causa: Certificate pinning no configurado correctamente
Solución: Verificar fingerprints en SecurityConfig
```

### Escenario 3: TLS Downgrade
```
❌ FALLO: Servidor acepta TLS 1.2
Causa: Configuración de servidor incorrecta
Solución: Configurar servidor para TLS 1.3 mínimo
```

## 📝 Reporte de Pruebas

### Template de Reporte

```markdown
# Reporte de Pruebas de Seguridad - [FECHA]

## Resumen Ejecutivo
- Tests Unitarios: [X/Y] pasados
- Tests Integración: [PASS/FAIL]
- SSL Labs Score: [A+/A/B/etc]
- Certificate Pinning: [ACTIVO/INACTIVO]

## Resultados Detallados

### Tests Unitarios
- SecureHttpClient: ✅ 4/4 tests pasados
- TlsValidator: ✅ 4/4 tests pasados

### Auditoría SSL
- SSL Labs: A+
- TLS 1.3: ✅ Soportado
- Certificado: ✅ Válido

### Interceptores
- Charles Proxy: ✅ Bloqueado
- Wireshark: ✅ Tráfico cifrado
- mitmproxy: ✅ Bloqueado

## Conclusiones
[Descripción de resultados]

## Acciones Requeridas
1. [Acción 1]
2. [Acción 2]
```

## 🔄 Automatización

### CI/CD Integration

```yaml
# .github/workflows/security-tests.yml
name: Security Tests

on: [push, pull_request]

jobs:
  security-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2

      - name: Run security tests
        run: flutter test test/unit/core/network/

      - name: Check SSL configuration
        run: |
          curl -v https://api.finora.com 2>&1 | grep "TLS 1.3"
```

## 📚 Referencias

- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [SSL Labs Grading Guide](https://github.com/ssllabs/research/wiki/SSL-Server-Rating-Guide)
- [Certificate Pinning Best Practices](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning)
