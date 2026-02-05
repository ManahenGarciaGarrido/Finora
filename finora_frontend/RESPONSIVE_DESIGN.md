# Sistema de Diseño Responsive - Finora

## RNF-12: Diseño Responsive

Este documento describe la implementación del sistema de diseño responsive en la aplicación Finora, que soporta dispositivos desde smartphones 4.7" (320x568px) hasta tablets 12" (2048x2732px).

---

## Índice

1. [Breakpoints](#breakpoints)
2. [Utilidades Responsive](#utilidades-responsive)
3. [Widgets Responsive](#widgets-responsive)
4. [Sistema de Colores](#sistema-de-colores)
5. [Tipografía](#tipografía)
6. [Componentes](#componentes)
7. [Ejemplos de Uso](#ejemplos-de-uso)

---

## Breakpoints

### Definición de Breakpoints

| Nombre | Ancho (px) | Dispositivos |
|--------|------------|--------------|
| `mobileSmall` | 320 | iPhone SE, móviles pequeños |
| `mobileMedium` | 375 | iPhone X, móviles estándar |
| `mobileLarge` | 414 | iPhone Plus, móviles grandes |
| `tabletSmall` | 600 | Tablets 7-8" |
| `tabletMedium` | 768 | Tablets 9-10" |
| `tabletLarge` | 1024 | Tablets 11-12" |
| `desktop` | 1200 | Desktop |

### Archivo de Breakpoints

```dart
// lib/core/responsive/breakpoints.dart

class Breakpoints {
  static const double mobileSmall = 320;
  static const double mobileMedium = 375;
  static const double mobileLarge = 414;
  static const double tabletSmall = 600;
  static const double tabletMedium = 768;
  static const double tabletLarge = 1024;
  static const double desktop = 1200;
}
```

---

## Utilidades Responsive

### ResponsiveUtils

Clase que proporciona información del dispositivo y valores adaptativos.

```dart
final responsive = ResponsiveUtils(context);

// Información del dispositivo
responsive.screenWidth      // Ancho de pantalla
responsive.screenHeight     // Alto de pantalla
responsive.isMobile         // ¿Es móvil?
responsive.isTablet         // ¿Es tablet?
responsive.isPortrait       // ¿Está en portrait?
responsive.deviceType       // Tipo de dispositivo

// Valores adaptativos
responsive.horizontalPadding   // Padding horizontal según pantalla
responsive.verticalPadding     // Padding vertical según pantalla
responsive.baseFontSize        // Tamaño de fuente base
responsive.iconSize            // Tamaño de iconos
responsive.buttonHeight        // Alto de botones
responsive.borderRadius        // Radio de bordes
responsive.spacing             // Espaciado entre elementos

// Funciones de escala
responsive.wp(10)   // 10% del ancho de pantalla
responsive.hp(10)   // 10% del alto de pantalla
responsive.sw(16)   // Escala basada en ancho (base 375px)
responsive.sh(16)   // Escala basada en alto (base 812px)

// Valor condicional
responsive.value(
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
)
```

### Extension Context

```dart
// Acceso directo desde context
context.screenWidth
context.isMobile
context.isTablet
context.isPortrait
context.deviceType
```

---

## Widgets Responsive

### ResponsiveBuilder

Construye diferentes layouts según el tipo de dispositivo.

```dart
ResponsiveBuilder(
  mobile: (context) => MobileLayout(),
  tablet: (context) => TabletLayout(),
  desktop: (context) => DesktopLayout(),
)
```

### OrientationBuilder

Construye según la orientación del dispositivo.

```dart
OrientationBuilder(
  portrait: (context) => PortraitLayout(),
  landscape: (context) => LandscapeLayout(),
)
```

### ResponsivePadding

Aplica padding adaptativo automáticamente.

```dart
ResponsivePadding(
  horizontal: true,
  vertical: false,
  child: YourWidget(),
)
```

### ResponsiveCenter

Centra contenido con ancho máximo responsive.

```dart
ResponsiveCenter(
  maxWidth: 600,
  child: YourContent(),
)
```

### ResponsiveGrid

Grid que ajusta columnas según el dispositivo.

```dart
ResponsiveGrid(
  children: items,
  columns: null, // Auto según dispositivo
  spacing: 16,
  childAspectRatio: 1.0,
)
```

### ResponsiveVisibility

Muestra/oculta según breakpoint.

```dart
ResponsiveVisibility(
  visibleOnMobile: true,
  visibleOnTablet: true,
  visibleOnDesktop: false,
  child: MobileOnlyWidget(),
)
```

### ResponsiveRowColumn

Cambia entre Row y Column automáticamente.

```dart
ResponsiveRowColumn(
  children: [Widget1(), Widget2()],
  // Row en landscape/tablet, Column en portrait/mobile
)
```

---

## Sistema de Colores

### Colores Primarios

| Color | Valor | Uso |
|-------|-------|-----|
| `primary` | #2563EB | Color principal de la app |
| `primaryLight` | #60A5FA | Variante clara |
| `primaryDark` | #1D4ED8 | Variante oscura |
| `primarySoft` | #DBEAFE | Fondo suave |

### Colores de Finanzas

| Color | Valor | Uso |
|-------|-------|-----|
| `income` | #22C55E | Ingresos, ganancias |
| `expense` | #EF4444 | Gastos, pérdidas |
| `savings` | #8B5CF6 | Ahorros |
| `investment` | #06B6D4 | Inversiones |

### Colores Semánticos

| Color | Valor | Uso |
|-------|-------|-----|
| `success` | #22C55E | Operaciones exitosas |
| `warning` | #F59E0B | Alertas |
| `error` | #EF4444 | Errores |
| `info` | #0EA5E9 | Información |

### Gradientes

```dart
AppColors.primaryGradient       // Gradiente principal
AppColors.successGradient       // Gradiente de éxito
AppColors.premiumGradient       // Gradiente premium
AppColors.cardGradient          // Gradiente para cards
```

### Sombras

```dart
AppColors.shadowSoft      // Sombra suave
AppColors.shadowMedium    // Sombra media
AppColors.shadowStrong    // Sombra fuerte
AppColors.shadowColor(color)  // Sombra con color
```

---

## Tipografía

### Escala Tipográfica

| Estilo | Tamaño | Peso | Uso |
|--------|--------|------|-----|
| `displayLarge` | 57px | Bold | Números grandes |
| `displayMedium` | 45px | Bold | Títulos principales |
| `displaySmall` | 36px | SemiBold | Subtítulos importantes |
| `headlineLarge` | 32px | SemiBold | Secciones principales |
| `headlineMedium` | 28px | SemiBold | Subtítulos |
| `headlineSmall` | 24px | SemiBold | Títulos de cards |
| `titleLarge` | 22px | Medium | Títulos de página |
| `titleMedium` | 16px | Medium | Títulos de lista |
| `titleSmall` | 14px | Medium | Títulos pequeños |
| `bodyLarge` | 16px | Regular | Texto principal |
| `bodyMedium` | 14px | Regular | Texto estándar |
| `bodySmall` | 12px | Regular | Texto pequeño |
| `labelLarge` | 14px | Medium | Botones |
| `labelMedium` | 12px | Medium | Labels |
| `labelSmall` | 11px | Medium | Captions |

### Estilos Especiales

```dart
AppTypography.moneyLarge()      // Montos grandes
AppTypography.moneyMedium()     // Montos medianos
AppTypography.moneySmall()      // Montos pequeños
AppTypography.percentage()      // Porcentajes
AppTypography.link()            // Enlaces
AppTypography.button()          // Botones
AppTypography.input()           // Campos de texto
AppTypography.hint()            // Placeholders
AppTypography.error()           // Errores
```

---

## Componentes

### AnimatedGradientBackground

Fondo animado con gradiente y burbujas.

```dart
AnimatedGradientBackground(
  showBubbles: true,
  bubbleCount: 6,
  child: YourContent(),
)
```

### CustomTextField

Campo de texto con animaciones y validación visual.

```dart
CustomTextField(
  controller: _controller,
  label: 'Email',
  hint: 'tu@email.com',
  prefixIcon: Icons.email_outlined,
  errorText: _error,
  obscureText: false,
  showPasswordToggle: false,
  showSuccessState: true,
  isLoading: false,
  onChanged: (value) {},
  validator: (value) {},
)
```

### AnimatedButton / GradientButton

Botones con animaciones y estados.

```dart
GradientButton(
  text: 'Continuar',
  onPressed: _handlePress,
  isLoading: false,
  isSuccess: false,
  icon: Icons.arrow_forward,
)

AnimatedButton(
  text: 'Cancelar',
  onPressed: _handleCancel,
  isOutlined: true,
)
```

### TextLinkButton

Botón de texto estilo enlace.

```dart
TextLinkButton(
  text: '¿Olvidaste tu contraseña?',
  onPressed: _handleForgotPassword,
  underline: true,
)
```

---

## Ejemplos de Uso

### Pantalla con Layout Responsive

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBuilder(
        mobile: (context) => _buildMobileLayout(context),
        tablet: (context) => _buildTabletLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
      ),
      child: Column(
        children: [
          // Contenido móvil
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Row(
      children: [
        // Sidebar
        NavigationRail(...),
        // Contenido
        Expanded(
          child: ResponsiveCenter(
            child: // Contenido centrado
          ),
        ),
      ],
    );
  }
}
```

### Card Adaptativa

```dart
Widget _buildCard(BuildContext context) {
  final responsive = ResponsiveUtils(context);

  return Container(
    padding: EdgeInsets.all(
      responsive.value(mobile: 16.0, tablet: 24.0),
    ),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(responsive.borderRadius),
      boxShadow: AppColors.shadowSoft,
    ),
    child: Column(
      children: [
        Text(
          'Título',
          style: responsive.isMobile
              ? AppTypography.titleMedium()
              : AppTypography.titleLarge(),
        ),
        // ...
      ],
    ),
  );
}
```

---

## Archivos de Implementación

```
lib/core/
├── responsive/
│   ├── breakpoints.dart         # Breakpoints y utilidades
│   └── responsive_builder.dart  # Widgets responsive
├── theme/
│   ├── app_colors.dart          # Paleta de colores
│   ├── app_typography.dart      # Sistema tipográfico
│   └── app_theme.dart           # Tema completo
└── ...

lib/shared/widgets/
├── animated_gradient_background.dart
├── custom_text_field.dart
└── animated_button.dart

lib/features/
├── authentication/
│   └── presentation/pages/
│       └── register_page.dart   # Pantalla de registro (RF-01)
└── home/
    └── presentation/pages/
        └── home_page.dart       # Dashboard responsive
```

---

## Verificación de Criterios

| Criterio | Estado | Implementación |
|----------|--------|----------------|
| Interfaz funcional en 4.7" (320x568px) | ✅ | Breakpoint mobileSmall |
| Interfaz optimizada para tablets 12" | ✅ | Breakpoint tabletLarge |
| Breakpoints definidos | ✅ | 7 breakpoints |
| Portrait y landscape soportados | ✅ | OrientationBuilder |
| Textos legibles sin zoom | ✅ | Tipografía adaptativa |
| Elementos sin overlap | ✅ | Layout adaptativo |
| Imágenes/gráficos escalables | ✅ | Widgets responsive |
| Layout adaptativo | ✅ | ResponsiveBuilder |

---

*Última actualización: Enero 2024*
*Versión: 1.0.0*
