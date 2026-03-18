/// RNF-11: Servicio de Accesibilidad WCAG 2.1 AA
///
/// Proporciona:
/// - Wrappers semánticos listos para usar
/// - Verificación de ratio de contraste (4.5:1 texto normal, 3:1 texto grande)
/// - Constantes de tamaño mínimo de pulsación (44×44 pt)
/// - Helpers para anunciar cambios a lectores de pantalla
/// - ExcludeSemantics para elementos decorativos
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityService {
  AccessibilityService._();

  // ─── Tamaños mínimos ────────────────────────────────────────────────────────

  /// Tamaño mínimo de área de pulsación recomendado por WCAG (44×44 pt)
  static const double minTapTarget = 44.0;

  /// Tamaño mínimo para controles grandes (56×56 pt para acciones primarias)
  static const double minPrimaryTarget = 56.0;

  // ─── Anuncios de lectura ────────────────────────────────────────────────────

  /// Anuncia un mensaje al lector de pantalla activo (TalkBack / VoiceOver).
  static void announce(BuildContext context, String message) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      TextDirection.ltr,
    );
  }

  // ─── Wrappers semánticos ────────────────────────────────────────────────────

  /// Envuelve un widget con semántica de botón con etiqueta y hint opcionales.
  static Widget semanticButton({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      onTap: onTap,
      child: child,
    );
  }

  /// Envuelve un widget con semántica de campo de texto.
  static Widget semanticTextField({
    required Widget child,
    required String label,
    String? hint,
    String? value,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      textField: true,
      child: child,
    );
  }

  /// Excluye un widget decorativo de los lectores de pantalla.
  static Widget decorative(Widget child) => ExcludeSemantics(child: child);

  /// Widget con tap target mínimo garantizado (44×44 pt)
  static Widget minTapArea({
    required Widget child,
    required VoidCallback onTap,
    String? semanticLabel,
    String? semanticHint,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: minTapTarget,
            minHeight: minTapTarget,
          ),
          child: child,
        ),
      ),
    );
  }

  // ─── Contraste WCAG 2.1 AA ──────────────────────────────────────────────────

  /// Calcula la luminancia relativa de un color según WCAG.
  static double _relativeLuminance(Color color) {
    double linearize(int channel) {
      final srgb = channel / 255.0;
      return srgb <= 0.03928
          ? srgb / 12.92
          : ((srgb + 0.055) / 1.055) * ((srgb + 0.055) / 1.055);
    }

    final r = linearize(color.r.toInt());
    final g = linearize(color.g.toInt());
    final b = linearize(color.b.toInt());
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Devuelve el ratio de contraste entre dos colores.
  /// WCAG AA: ≥4.5:1 para texto normal, ≥3:1 para texto grande (18pt+/14pt bold)
  static double contrastRatio(Color foreground, Color background) {
    final l1 = _relativeLuminance(foreground);
    final l2 = _relativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 < l2 ? l1 : l2;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// True si el par de colores cumple WCAG AA para texto normal (4.5:1)
  static bool passesWcagAA(Color foreground, Color background) =>
      contrastRatio(foreground, background) >= 4.5;

  /// True si el par de colores cumple WCAG AA para texto grande (3:1)
  static bool passesWcagAALarge(Color foreground, Color background) =>
      contrastRatio(foreground, background) >= 3.0;
}

// ─── Widgets de accesibilidad reutilizables ───────────────────────────────────

/// Widget de tarjeta accesible que combina Semantics + tamaño mínimo de pulsación
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final String? semanticHint;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AccessibleCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.semanticHint,
    this.onTap,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: child,
    );

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      container: true,
      child: onTap != null
          ? GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: card,
            )
          : card,
    );
  }
}

/// Botón de icono con área de pulsación mínima de 44×44 pt (WCAG 2.5.5)
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double iconSize;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.tooltip,
    this.onPressed,
    this.color,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip ?? semanticLabel,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            AccessibilityService.minTapTarget / 2,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AccessibilityService.minTapTarget,
              minHeight: AccessibilityService.minTapTarget,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }
}

/// ListTile accesible con MergeSemantics para agrupar texto+subtítulo en un anuncio
class AccessibleListTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String semanticLabel;
  final String? semanticHint;
  final EdgeInsetsGeometry? contentPadding;

  const AccessibleListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.semanticLabel,
    this.semanticHint,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        hint: semanticHint,
        button: onTap != null,
        child: ListTile(
          leading: leading,
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: trailing,
          onTap: onTap,
          contentPadding: contentPadding,
          minVerticalPadding: AccessibilityService.minTapTarget / 2 - 16,
        ),
      ),
    );
  }
}
