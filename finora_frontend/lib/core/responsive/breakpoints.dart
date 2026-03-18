import 'package:flutter/material.dart';

/// Sistema de breakpoints responsive para Finora
/// Soporta desde smartphones 4.7" (320x568px) hasta tablets 12" (2048x2732px)
///
/// Requisito: RNF-12 Diseño Responsive
class Breakpoints {
  Breakpoints._();

  // ============================================
  // BREAKPOINTS DE ANCHO
  // ============================================

  /// Móvil pequeño (4.7" - iPhone SE, etc.)
  static const double mobileSmall = 320;

  /// Móvil mediano (5.5" - 6.1")
  static const double mobileMedium = 375;

  /// Móvil grande (6.5"+)
  static const double mobileLarge = 414;

  /// Tablet pequeño (7" - 8")
  static const double tabletSmall = 600;

  /// Tablet mediano (9" - 10")
  static const double tabletMedium = 768;

  /// Tablet grande (11" - 12")
  static const double tabletLarge = 1024;

  /// Desktop
  static const double desktop = 1200;

  /// Desktop grande
  static const double desktopLarge = 1440;

  // ============================================
  // BREAKPOINTS DE ALTURA
  // ============================================

  /// Altura mínima (iPhone SE landscape)
  static const double heightSmall = 568;

  /// Altura media
  static const double heightMedium = 667;

  /// Altura grande
  static const double heightLarge = 812;

  /// Altura extra grande (tablets)
  static const double heightXLarge = 1024;
}

/// Enum para tipos de dispositivo
enum DeviceType {
  mobileSmall,
  mobileMedium,
  mobileLarge,
  tabletSmall,
  tabletMedium,
  tabletLarge,
  desktop,
}

/// Enum para orientación
enum DeviceOrientation {
  portrait,
  landscape,
}

/// Clase de utilidades para responsive design
class ResponsiveUtils {
  final BuildContext context;

  ResponsiveUtils(this.context);

  /// Obtiene el MediaQuery
  MediaQueryData get _mediaQuery => MediaQuery.of(context);

  /// Ancho de la pantalla
  double get screenWidth => _mediaQuery.size.width;

  /// Alto de la pantalla
  double get screenHeight => _mediaQuery.size.height;

  /// Pixel ratio del dispositivo
  double get pixelRatio => _mediaQuery.devicePixelRatio;

  /// Safe area padding
  EdgeInsets get safePadding => _mediaQuery.padding;

  /// View insets (teclado, etc.)
  EdgeInsets get viewInsets => _mediaQuery.viewInsets;

  /// Orientación actual
  Orientation get orientation => _mediaQuery.orientation;

  /// ¿Está en portrait?
  bool get isPortrait => orientation == Orientation.portrait;

  /// ¿Está en landscape?
  bool get isLandscape => orientation == Orientation.landscape;

  /// Tipo de dispositivo actual
  DeviceType get deviceType {
    final width = screenWidth;

    if (width < Breakpoints.mobileMedium) return DeviceType.mobileSmall;
    if (width < Breakpoints.mobileLarge) return DeviceType.mobileMedium;
    if (width < Breakpoints.tabletSmall) return DeviceType.mobileLarge;
    if (width < Breakpoints.tabletMedium) return DeviceType.tabletSmall;
    if (width < Breakpoints.tabletLarge) return DeviceType.tabletMedium;
    if (width < Breakpoints.desktop) return DeviceType.tabletLarge;
    return DeviceType.desktop;
  }

  /// ¿Es móvil?
  bool get isMobile => screenWidth < Breakpoints.tabletSmall;

  /// ¿Es tablet?
  bool get isTablet =>
      screenWidth >= Breakpoints.tabletSmall &&
      screenWidth < Breakpoints.desktop;

  /// ¿Es desktop?
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// ¿Es pantalla pequeña?
  bool get isSmallScreen => screenWidth < Breakpoints.mobileMedium;

  /// ¿Es pantalla grande?
  bool get isLargeScreen => screenWidth >= Breakpoints.tabletMedium;

  /// Número de columnas recomendadas para grid
  int get gridColumns {
    if (isMobile) return isPortrait ? 2 : 3;
    if (isTablet) return isPortrait ? 3 : 4;
    return 6;
  }

  /// Padding horizontal adaptativo
  double get horizontalPadding {
    if (screenWidth < Breakpoints.mobileMedium) return 16;
    if (screenWidth < Breakpoints.tabletSmall) return 20;
    if (screenWidth < Breakpoints.tabletMedium) return 24;
    if (screenWidth < Breakpoints.tabletLarge) return 32;
    return 48;
  }

  /// Padding vertical adaptativo
  double get verticalPadding {
    if (screenHeight < Breakpoints.heightMedium) return 12;
    if (screenHeight < Breakpoints.heightLarge) return 16;
    if (screenHeight < Breakpoints.heightXLarge) return 20;
    return 24;
  }

  /// Tamaño de fuente base adaptativo
  double get baseFontSize {
    if (screenWidth < Breakpoints.mobileMedium) return 14;
    if (screenWidth < Breakpoints.tabletSmall) return 16;
    if (screenWidth < Breakpoints.tabletMedium) return 17;
    return 18;
  }

  /// Escala de texto adaptativa
  double get textScaleFactor {
    final width = screenWidth;
    if (width < Breakpoints.mobileSmall) return 0.85;
    if (width < Breakpoints.mobileMedium) return 0.9;
    if (width < Breakpoints.mobileLarge) return 1.0;
    if (width < Breakpoints.tabletSmall) return 1.0;
    if (width < Breakpoints.tabletMedium) return 1.05;
    if (width < Breakpoints.tabletLarge) return 1.1;
    return 1.15;
  }

  /// Ancho máximo del contenido
  double get maxContentWidth {
    if (isMobile) return double.infinity;
    if (isTablet) return 720;
    return 960;
  }

  /// Tamaño de icono adaptativo
  double get iconSize {
    if (screenWidth < Breakpoints.mobileMedium) return 20;
    if (screenWidth < Breakpoints.tabletSmall) return 24;
    if (screenWidth < Breakpoints.tabletMedium) return 28;
    return 32;
  }

  /// Alto de botón adaptativo
  double get buttonHeight {
    if (screenWidth < Breakpoints.mobileMedium) return 44;
    if (screenWidth < Breakpoints.tabletSmall) return 48;
    if (screenWidth < Breakpoints.tabletMedium) return 52;
    return 56;
  }

  /// Radio de borde adaptativo
  double get borderRadius {
    if (screenWidth < Breakpoints.tabletSmall) return 12;
    if (screenWidth < Breakpoints.tabletMedium) return 16;
    return 20;
  }

  /// Espaciado entre elementos
  double get spacing {
    if (screenWidth < Breakpoints.mobileMedium) return 8;
    if (screenWidth < Breakpoints.tabletSmall) return 12;
    if (screenWidth < Breakpoints.tabletMedium) return 16;
    return 20;
  }

  /// Valor adaptativo basado en tipo de dispositivo
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Porcentaje del ancho de pantalla
  double wp(double percentage) => screenWidth * (percentage / 100);

  /// Porcentaje del alto de pantalla
  double hp(double percentage) => screenHeight * (percentage / 100);

  /// Escala basada en ancho (base 375 - iPhone X)
  double sw(double size) => size * (screenWidth / 375);

  /// Escala basada en alto (base 812 - iPhone X)
  double sh(double size) => size * (screenHeight / 812);

  /// Escala de tamaño de fuente (basado en ancho, base 375 - iPhone X)
  double sp(double size) => size * (screenWidth / 375);
}

/// Extension para acceso fácil a ResponsiveUtils
extension ResponsiveExtension on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);

  /// Accesos directos
  double get screenWidth => responsive.screenWidth;
  double get screenHeight => responsive.screenHeight;
  bool get isMobile => responsive.isMobile;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;
  bool get isPortrait => responsive.isPortrait;
  bool get isLandscape => responsive.isLandscape;
  DeviceType get deviceType => responsive.deviceType;
}
