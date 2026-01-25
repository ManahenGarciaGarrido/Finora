import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Widget que construye diferentes layouts según el tipo de dispositivo
///
/// Ejemplo de uso:
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    if (responsive.isDesktop && desktop != null) {
      return desktop!(context);
    }

    if (responsive.isTablet && tablet != null) {
      return tablet!(context);
    }

    return mobile(context);
  }
}

/// Widget que construye diferentes layouts según la orientación
class OrientationBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) portrait;
  final Widget Function(BuildContext context)? landscape;

  const OrientationBuilder({
    super.key,
    required this.portrait,
    this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    if (responsive.isLandscape && landscape != null) {
      return landscape!(context);
    }

    return portrait(context);
  }
}

/// Widget que aplica padding responsive automáticamente
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final bool horizontal;
  final bool vertical;
  final double? customHorizontal;
  final double? customVertical;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.horizontal = true,
    this.vertical = false,
    this.customHorizontal,
    this.customVertical,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal:
            horizontal ? (customHorizontal ?? responsive.horizontalPadding) : 0,
        vertical:
            vertical ? (customVertical ?? responsive.verticalPadding) : 0,
      ),
      child: child,
    );
  }
}

/// Widget que centra el contenido con ancho máximo responsive
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? responsive.maxContentWidth,
        ),
        padding: padding ??
            EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
        child: child,
      ),
    );
  }
}

/// Widget que crea un grid responsive
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? columns;
  final double? spacing;
  final double? runSpacing;
  final double childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columns,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final cols = columns ?? responsive.gridColumns;
    final gap = spacing ?? responsive.spacing;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: gap,
        mainAxisSpacing: runSpacing ?? gap,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Widget que muestra/oculta según el breakpoint
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    bool isVisible = false;

    if (responsive.isMobile && visibleOnMobile) isVisible = true;
    if (responsive.isTablet && visibleOnTablet) isVisible = true;
    if (responsive.isDesktop && visibleOnDesktop) isVisible = true;

    if (isVisible) return child;
    return replacement ?? const SizedBox.shrink();
  }
}

/// Widget de texto con tamaño responsive
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? mobileSize;
  final double? tabletSize;
  final double? desktopSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.mobileSize,
    this.tabletSize,
    this.desktopSize,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    double fontSize = responsive.baseFontSize;

    if (responsive.isDesktop && desktopSize != null) {
      fontSize = desktopSize!;
    } else if (responsive.isTablet && tabletSize != null) {
      fontSize = tabletSize!;
    } else if (responsive.isMobile && mobileSize != null) {
      fontSize = mobileSize!;
    }

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Widget de SizedBox con dimensiones responsive
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const ResponsiveSizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
  });

  /// Espaciado vertical pequeño
  const ResponsiveSizedBox.verticalSmall({super.key, this.child})
      : width = null,
        height = 8;

  /// Espaciado vertical medio
  const ResponsiveSizedBox.verticalMedium({super.key, this.child})
      : width = null,
        height = 16;

  /// Espaciado vertical grande
  const ResponsiveSizedBox.verticalLarge({super.key, this.child})
      : width = null,
        height = 24;

  /// Espaciado horizontal pequeño
  const ResponsiveSizedBox.horizontalSmall({super.key, this.child})
      : width = 8,
        height = null;

  /// Espaciado horizontal medio
  const ResponsiveSizedBox.horizontalMedium({super.key, this.child})
      : width = 16,
        height = null;

  /// Espaciado horizontal grande
  const ResponsiveSizedBox.horizontalLarge({super.key, this.child})
      : width = 24,
        height = null;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final scale = responsive.textScaleFactor;

    return SizedBox(
      width: width != null ? width! * scale : null,
      height: height != null ? height! * scale : null,
      child: child,
    );
  }
}

/// Layout que cambia entre Row y Column según orientación/breakpoint
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool? forceRow;
  final bool? forceColumn;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.forceRow,
    this.forceColumn,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    bool useRow = responsive.isLandscape || responsive.isTablet || responsive.isDesktop;

    if (forceRow == true) useRow = true;
    if (forceColumn == true) useRow = false;

    if (useRow) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}
