import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Sistema de tipografía responsive para Finora
///
/// Escala tipográfica basada en Material Design 3
/// con adaptaciones para diferentes tamaños de pantalla
class AppTypography {
  AppTypography._();

  // ============================================
  // FUENTES
  // ============================================

  /// Familia de fuentes principal (sans-serif moderna)
  static const String fontFamily = 'Inter';

  /// Familia de fuentes para números/dinero
  static const String fontFamilyMono = 'JetBrains Mono';

  // ============================================
  // PESOS DE FUENTE
  // ============================================

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ============================================
  // ESTILOS DE DISPLAY (Títulos grandes)
  // ============================================

  /// Display Large - Para pantallas de bienvenida, números grandes
  static TextStyle displayLarge({Color? color}) => TextStyle(
    fontSize: 57,
    fontWeight: bold,
    height: 1.12,
    letterSpacing: -0.25,
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Display Medium
  static TextStyle displayMedium({Color? color}) => TextStyle(
    fontSize: 45,
    fontWeight: bold,
    height: 1.16,
    letterSpacing: 0,
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Display Small
  static TextStyle displaySmall({Color? color}) => TextStyle(
    fontSize: 36,
    fontWeight: semiBold,
    height: 1.22,
    letterSpacing: 0,
    color: color ?? AppColors.textPrimaryLight,
  );

  // ============================================
  // ESTILOS DE HEADLINE (Encabezados)
  // ============================================

  /// Headline Large - Títulos de sección principales
  static TextStyle headlineLarge({Color? color}) => TextStyle(
    fontSize: 32,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0,
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Headline Medium - Subtítulos importantes
  static TextStyle headlineMedium({Color? color}) => TextStyle(
    fontSize: 28,
    fontWeight: semiBold,
    height: 1.29,
    letterSpacing: 0,
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Headline Small - Títulos de cards
  static TextStyle headlineSmall({Color? color}) => TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.33,
    letterSpacing: 0,
    color: color ?? AppColors.textPrimaryLight,
  );

  // ============================================
  // ESTILOS DE TITLE (Títulos)
  // ============================================

  /// Title Large - Títulos de página, nombres importantes
  static TextStyle titleLarge({Color? color}) => TextStyle(
    fontSize: 22,
    fontWeight: medium,
    height: 1.27,
    letterSpacing: 0,
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Title Medium - Títulos de lista, ítems
  static TextStyle titleMedium({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Title Small - Títulos pequeños
  static TextStyle titleSmall({Color? color}) => TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
    color: color ?? AppColors.textPrimaryLight,
  );

  // ============================================
  // ESTILOS DE BODY (Cuerpo de texto)
  // ============================================

  /// Body Large - Texto principal
  static TextStyle bodyLarge({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.5,
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Body Medium - Texto estándar
  static TextStyle bodyMedium({Color? color}) => TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
    color: color ?? AppColors.textSecondaryLight,
  );

  /// Body Small - Texto pequeño
  static TextStyle bodySmall({Color? color}) => TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
    color: color ?? AppColors.textSecondaryLight,
  );

  // ============================================
  // ESTILOS DE LABEL (Etiquetas)
  // ============================================

  /// Label Large - Botones, chips
  static TextStyle labelLarge({Color? color}) => TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Label Medium - Labels de formulario
  static TextStyle labelMedium({Color? color}) => TextStyle(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
    color: color ?? AppColors.textSecondaryLight,
  );

  /// Label Small - Captions, hints
  static TextStyle labelSmall({Color? color}) => TextStyle(
    fontSize: 11,
    fontWeight: medium,
    height: 1.45,
    letterSpacing: 0.5,
    color: color ?? AppColors.textTertiaryLight,
  );

  // ============================================
  // ESTILOS ESPECIALES
  // ============================================

  /// Estilo para montos de dinero (grande)
  static TextStyle moneyLarge({Color? color}) => TextStyle(
    fontSize: 36,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Estilo para montos de dinero (mediano)
  static TextStyle moneyMedium({Color? color}) => TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: -0.25,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Estilo para montos de dinero (pequeño)
  static TextStyle moneySmall({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.5,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Estilo para porcentajes
  static TextStyle percentage({Color? color, bool positive = true}) =>
      TextStyle(
        fontSize: 14,
        fontWeight: semiBold,
        height: 1.43,
        letterSpacing: 0,
        color: color ?? (positive ? AppColors.income : AppColors.expense),
      );

  /// Estilo para links
  static TextStyle link({Color? color}) => TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
    decoration: TextDecoration.underline,
    color: color ?? AppColors.primary,
  );

  /// Estilo para botones
  static TextStyle button({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.5,
    letterSpacing: 0.5,
    color: color ?? AppColors.white,
  );

  /// Estilo para inputs
  static TextStyle input({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
    color: color ?? AppColors.textPrimaryLight,
  );

  /// Estilo para placeholder/hint
  static TextStyle hint({Color? color}) => TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
    color: color ?? AppColors.textTertiaryLight,
  );

  /// Estilo para errores
  static TextStyle error() => TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
    color: AppColors.error,
  );

  /// Estilo para badges/chips
  static TextStyle badge({Color? color}) => TextStyle(
    fontSize: 10,
    fontWeight: semiBold,
    height: 1.4,
    letterSpacing: 0.5,
    color: color ?? AppColors.white,
  );

  // ============================================
  // TEXTO SCHEME (Para ThemeData)
  // ============================================

  /// TextTheme para tema claro
  static TextTheme get lightTextTheme => TextTheme(
    displayLarge: displayLarge(),
    displayMedium: displayMedium(),
    displaySmall: displaySmall(),
    headlineLarge: headlineLarge(),
    headlineMedium: headlineMedium(),
    headlineSmall: headlineSmall(),
    titleLarge: titleLarge(),
    titleMedium: titleMedium(),
    titleSmall: titleSmall(),
    bodyLarge: bodyLarge(),
    bodyMedium: bodyMedium(),
    bodySmall: bodySmall(),
    labelLarge: labelLarge(),
    labelMedium: labelMedium(),
    labelSmall: labelSmall(),
  );

  /// TextTheme para tema oscuro
  static TextTheme get darkTextTheme => TextTheme(
    displayLarge: displayLarge(color: AppColors.textPrimaryDark),
    displayMedium: displayMedium(color: AppColors.textPrimaryDark),
    displaySmall: displaySmall(color: AppColors.textPrimaryDark),
    headlineLarge: headlineLarge(color: AppColors.textPrimaryDark),
    headlineMedium: headlineMedium(color: AppColors.textPrimaryDark),
    headlineSmall: headlineSmall(color: AppColors.textPrimaryDark),
    titleLarge: titleLarge(color: AppColors.textPrimaryDark),
    titleMedium: titleMedium(color: AppColors.textPrimaryDark),
    titleSmall: titleSmall(color: AppColors.textPrimaryDark),
    bodyLarge: bodyLarge(color: AppColors.textPrimaryDark),
    bodyMedium: bodyMedium(color: AppColors.textSecondaryDark),
    bodySmall: bodySmall(color: AppColors.textSecondaryDark),
    labelLarge: labelLarge(color: AppColors.textPrimaryDark),
    labelMedium: labelMedium(color: AppColors.textSecondaryDark),
    labelSmall: labelSmall(color: AppColors.textTertiaryDark),
  );
}
