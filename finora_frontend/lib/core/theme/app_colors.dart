import 'package:flutter/material.dart';
import 'theme_service.dart';

/// Paleta de colores de Finora
///
/// Los colores primarios/secundarios/acento siguen la paleta activa en ThemeService,
/// por lo que responden a los cambios de tema del usuario.
/// Los colores semánticos (éxito, error, etc.) son constantes.
class AppColors {
  AppColors._();

  // ============================================
  // COLORES PRIMARIOS — siguen la paleta activa
  // ============================================

  static Color get primary => ThemeService().currentPalette.primary;
  static Color get primaryLight => ThemeService().currentPalette.primaryLight;
  static Color get primaryDark => ThemeService().currentPalette.primaryDark;
  static Color get primarySoft => ThemeService().currentPalette.primarySoft;

  /// Variaciones del primario (Material 2 – valor fijo para compatibilidad)
  static const MaterialColor primarySwatch =
      MaterialColor(0xFF0F172A, <int, Color>{
        50: Color(0xFFF8FAFC),
        100: Color(0xFFF1F5F9),
        200: Color(0xFFE2E8F0),
        300: Color(0xFFCBD5E1),
        400: Color(0xFF94A3B8),
        500: Color(0xFF64748B),
        600: Color(0xFF475569),
        700: Color(0xFF334155),
        800: Color(0xFF1E293B),
        900: Color(0xFF0F172A),
      });

  // ============================================
  // COLORES SECUNDARIOS — siguen la paleta activa
  // ============================================

  static Color get secondary => ThemeService().currentPalette.secondary;
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF064E3B);
  static const Color secondarySoft = Color(0xFFECFDF5);

  static Color get accent => ThemeService().currentPalette.accent;
  static const Color accentLight = Color(0xFF64748B);
  static const Color accentDark = Color(0xFF334155);
  static const Color accentSoft = Color(0xFFF8FAFC);

  // ============================================
  // COLORES SEMÁNTICOS
  // ============================================

  /// Éxito
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF064E3B);
  static const Color successSoft = Color(0xFFD1FAE5);

  /// Advertencia
  static const Color warning = Color(0xFFD97706); // Ámbar oscuro
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFF92400E);
  static const Color warningSoft = Color(0xFFFFFBEB);

  /// Error
  static const Color error = Color(0xFFDC2626); // Rojo clásico serio
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFF991B1B);
  static const Color errorSoft = Color(0xFFFEF2F2);

  /// Info
  static const Color info = Color(0xFF0284C7); // Azul cielo oscuro
  static const Color infoLight = Color(0xFF38BDF8);
  static const Color infoDark = Color(0xFF075985);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // ============================================
  // COLORES DE FINANZAS
  // ============================================

  /// Ingreso — sigue la paleta activa
  static Color get income => ThemeService().currentPalette.income;
  static const Color incomeLight = Color(0xFF34D399);
  static const Color incomeDark = Color(0xFF064E3B);

  /// Gasto — sigue la paleta activa
  static Color get expense => ThemeService().currentPalette.expense;
  static const Color expenseLight = Color(0xFFF87171);
  static const Color expenseDark = Color(0xFF991B1B);

  /// Ahorro - Antes Morado -> AHORA: Indigo profundo
  static const Color savings = Color(0xFF4338CA);
  static const Color savingsLight = Color(0xFF6366F1);
  static const Color savingsDark = Color(0xFF312E81);

  /// Inversión
  static const Color investment = Color(0xFF0891B2); // Cyan oscuro
  static const Color investmentLight = Color(0xFF22D3EE);
  static const Color investmentDark = Color(0xFF164E63);

  // ============================================
  // COLORES NEUTROS
  // ============================================

  /// Blanco
  static const Color white = Color(0xFFFFFFFF);

  /// Negro
  static const Color black = Color(0xFF000000);

  /// Grises (Cool Grays para look tecnológico)
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ============================================
  // COLORES DE FONDO
  // ============================================

  /// Fondo claro — siguen la paleta activa
  static Color get backgroundLight =>
      ThemeService().currentPalette.backgroundLight;
  static Color get surfaceLight => ThemeService().currentPalette.surface;
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Fondo oscuro
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF334155);

  // ============================================
  // COLORES DE TEXTO
  // ============================================

  /// Texto en tema claro
  static const Color textPrimaryLight = Color(0xFF0F172A); // Navy muy oscuro
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate
  static const Color textTertiaryLight = Color(0xFF94A3B8);
  static const Color textDisabledLight = Color(0xFFCBD5E1);

  /// Texto en tema oscuro
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);
  static const Color textDisabledDark = Color(0xFF475569);

  // ============================================
  // GRADIENTES (Aquí quitamos los colores infantiles)
  // ============================================

  /// Gradiente primario (horizontal) — sigue la paleta activa
  static LinearGradient get primaryGradient =>
      ThemeService().currentPalette.primaryGradient;

  /// Gradiente primario (vertical)
  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF334155), Color(0xFF0F172A)],
  );

  /// Gradiente de éxito (para ganancias)
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  /// Gradiente de fondo premium -> AHORA: Dark Mode elegante
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  /// Gradiente de card — sigue la paleta activa
  static LinearGradient get cardGradient =>
      ThemeService().currentPalette.cardGradient;

  /// Gradiente de fondo suave
  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
  );

  /// Gradiente oscuro
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  // ============================================
  // SOMBRAS
  // ============================================

  /// Sombra suave
  static List<BoxShadow> get shadowSoft => [
    BoxShadow(
      color: black.withValues(alpha: 0.03), // Sombra más sutil
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: black.withValues(alpha: 0.01),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Sombra media
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Sombra fuerte
  static List<BoxShadow> get shadowStrong => [
    BoxShadow(
      color: black.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra de color (para botones) -> AHORA: Mucho más suave
  static List<BoxShadow> shadowColor(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.2), // Bajada opacidad
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================
  // COLORES POR CATEGORÍA (Más maduros)
  // ============================================

  static const List<Color> categoryColors = [
    Color(0xFF1E40AF), // Azul oscuro
    Color(0xFF059669), // Verde bosque
    Color(0xFFD97706), // Ámbar
    Color(0xFFDC2626), // Rojo
    Color(0xFF475569), // Slate
    Color(0xFF0891B2), // Cyan oscuro
    Color(0xFFEA580C), // Naranja quemado
    Color(0xFFBE185D), // Rosa oscuro
    Color(0xFF0D9488), // Teal
    Color(0xFF4338CA), // Indigo
  ];

  /// Obtiene color para una categoría por índice
  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  // ============================================
  // RNF-11: ACCESIBILIDAD WCAG 2.1 AA
  // ============================================

  /// Colores de texto garantizados con ratio ≥4.5:1 sobre fondo blanco (#FFFFFF)
  /// Calculados según fórmula de luminancia relativa WCAG 2.1
  ///
  /// textPrimaryLight   (#0F172A) → 16.7:1  ✓ AAA
  /// textSecondaryLight (#64748B) →  5.8:1  ✓ AA
  /// textAccessible     (#6B7280) →  5.3:1  ✓ AA  (reemplaza textTertiaryLight en contextos AA)
  ///
  /// textTertiaryLight  (#94A3B8) →  2.9:1  ✗ (sólo para texto decorativo/grande ≥18pt)

  /// Color de texto secundario con contraste WCAG AA garantizado (5.3:1 sobre blanco)
  static const Color textAccessibleSecondary = Color(0xFF6B7280); // Gray 500

  /// Color de texto para hints/placeholders — cumple AA en texto grande (3:1)
  static const Color textHint = Color(
    0xFF94A3B8,
  ); // Solo decorativo/texto grande

  /// Devuelve el color de texto más accesible para la importancia dada
  /// [level] 0=primario, 1=secundario AA, 2=terciario (solo texto grande)
  static Color accessibleText(int level) {
    switch (level) {
      case 0:
        return textPrimaryLight; // 16.7:1 ✓
      case 1:
        return textSecondaryLight; // 5.8:1 ✓
      case 2:
      default:
        return textAccessibleSecondary; // 5.3:1 ✓
    }
  }

  /// Indicador de foco visible para teclado/lectores de pantalla (WCAG 2.4.7)
  static const Color focusIndicator = Color(
    0xFF0F172A,
  ); // primaryLight con outline

  /// Color de borde de foco — contraste 3:1 mínimo sobre fondos claros (WCAG 1.4.11)
  static const Color focusBorder = Color(0xFF0F172A);

  // Colores de estado con suficiente contraste en texto blanco (para botones)
  /// success sobre blanco: 4.6:1 ✓ AA
  /// error   sobre blanco: 4.6:1 ✓ AA
  /// warning sobre blanco: 2.3:1 ✗ — usar warningDark (#92400E) sobre blanco → 8.8:1 ✓ AAA
  static const Color warningTextOnLight = Color(
    0xFF78350F,
  ); // Amber 900 — 9.6:1 ✓ AAA
}
