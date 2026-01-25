import 'package:flutter/material.dart';

/// Paleta de colores de Finora
///
/// Diseñada para una aplicación de finanzas personales:
/// - Azul: Confianza, seguridad, profesionalismo
/// - Verde: Crecimiento, dinero, éxito financiero
/// - Gradientes modernos para UI atractiva
class AppColors {
  AppColors._();

  // ============================================
  // COLORES PRIMARIOS
  // ============================================

  /// Azul principal - Color de marca
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySoft = Color(0xFFDBEAFE);

  /// Variaciones del primario
  static const MaterialColor primarySwatch =
      MaterialColor(0xFF2563EB, <int, Color>{
        50: Color(0xFFEFF6FF),
        100: Color(0xFFDBEAFE),
        200: Color(0xFFBFDBFE),
        300: Color(0xFF93C5FD),
        400: Color(0xFF60A5FA),
        500: Color(0xFF3B82F6),
        600: Color(0xFF2563EB),
        700: Color(0xFF1D4ED8),
        800: Color(0xFF1E40AF),
        900: Color(0xFF1E3A8A),
      });

  // ============================================
  // COLORES SECUNDARIOS
  // ============================================

  /// Verde - Éxito, ganancias, crecimiento
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondarySoft = Color(0xFFD1FAE5);

  /// Púrpura - Premium, sofisticado
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentLight = Color(0xFFA78BFA);
  static const Color accentDark = Color(0xFF7C3AED);
  static const Color accentSoft = Color(0xFFEDE9FE);

  // ============================================
  // COLORES SEMÁNTICOS
  // ============================================

  /// Éxito - Para ganancias, metas cumplidas
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF86EFAC);
  static const Color successDark = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);

  /// Advertencia - Para alertas de presupuesto
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);

  /// Error - Para gastos excesivos, errores
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);

  /// Info - Para información general
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFF7DD3FC);
  static const Color infoDark = Color(0xFF0284C7);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // ============================================
  // COLORES DE FINANZAS
  // ============================================

  /// Ingreso - Dinero que entra
  static const Color income = Color(0xFF22C55E);
  static const Color incomeLight = Color(0xFF4ADE80);
  static const Color incomeDark = Color(0xFF15803D);

  /// Gasto - Dinero que sale
  static const Color expense = Color(0xFFEF4444);
  static const Color expenseLight = Color(0xFFF87171);
  static const Color expenseDark = Color(0xFFB91C1C);

  /// Ahorro - Dinero guardado
  static const Color savings = Color(0xFF8B5CF6);
  static const Color savingsLight = Color(0xFFA78BFA);
  static const Color savingsDark = Color(0xFF6D28D9);

  /// Inversión - Dinero invertido
  static const Color investment = Color(0xFF06B6D4);
  static const Color investmentLight = Color(0xFF22D3EE);
  static const Color investmentDark = Color(0xFF0891B2);

  // ============================================
  // COLORES NEUTROS
  // ============================================

  /// Blanco
  static const Color white = Color(0xFFFFFFFF);

  /// Negro
  static const Color black = Color(0xFF000000);

  /// Grises
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

  /// Fondo claro
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Fondo oscuro
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF334155);

  // ============================================
  // COLORES DE TEXTO
  // ============================================

  /// Texto en tema claro
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);
  static const Color textDisabledLight = Color(0xFFCBD5E1);

  /// Texto en tema oscuro
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);
  static const Color textDisabledDark = Color(0xFF475569);

  // ============================================
  // GRADIENTES
  // ============================================

  /// Gradiente primario (horizontal)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, Color(0xFF7C3AED)],
  );

  /// Gradiente primario (vertical)
  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryLight, primary],
  );

  /// Gradiente de éxito (para ganancias)
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
  );

  /// Gradiente de fondo premium
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF7C3AED)],
  );

  /// Gradiente de card
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
  );

  /// Gradiente de fondo suave
  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
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
      color: black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Sombra media
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Sombra fuerte
  static List<BoxShadow> get shadowStrong => [
    BoxShadow(
      color: black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra de color (para botones)
  static List<BoxShadow> shadowColor(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  // ============================================
  // COLORES POR CATEGORÍA (Para gráficos)
  // ============================================

  static const List<Color> categoryColors = [
    Color(0xFF3B82F6), // Azul
    Color(0xFF22C55E), // Verde
    Color(0xFFF59E0B), // Amarillo
    Color(0xFFEF4444), // Rojo
    Color(0xFF8B5CF6), // Púrpura
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Naranja
    Color(0xFFEC4899), // Rosa
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
  ];

  /// Obtiene color para una categoría por índice
  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }
}
