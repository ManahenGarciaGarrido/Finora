import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Paleta de colores de un tema de la app
class AppThemePalette {
  final String id;
  final String name;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primarySoft;
  final Color secondary;
  final Color accent;
  // Semantic colors (with defaults matching AppColors)
  final Color success;
  final Color error;
  final Color income;
  final Color expense;
  final Color backgroundLight;
  final Color surface;
  final LinearGradient primaryGradient;
  final LinearGradient cardGradient;

  const AppThemePalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primarySoft,
    required this.secondary,
    required this.accent,
    this.success = const Color(0xFF059669),
    this.error = const Color(0xFFDC2626),
    this.income = const Color(0xFF059669),
    this.expense = const Color(0xFFDC2626),
    this.backgroundLight = const Color(0xFFF8FAFC),
    this.surface = const Color(0xFFFFFFFF),
    required this.primaryGradient,
    required this.cardGradient,
  });

  /// Serialise to JSON map (for SharedPreferences)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primary': primary.toARGB32(),
    'primaryLight': primaryLight.toARGB32(),
    'primaryDark': primaryDark.toARGB32(),
    'primarySoft': primarySoft.toARGB32(),
    'secondary': secondary.toARGB32(),
    'accent': accent.toARGB32(),
    'success': success.toARGB32(),
    'error': error.toARGB32(),
    'income': income.toARGB32(),
    'expense': expense.toARGB32(),
    'backgroundLight': backgroundLight.toARGB32(),
    'surface': surface.toARGB32(),
    'gradStart': primaryGradient.colors.first.toARGB32(),
    'gradEnd': primaryGradient.colors.last.toARGB32(),
    'cardStart': cardGradient.colors.first.toARGB32(),
    'cardEnd': cardGradient.colors.last.toARGB32(),
  };

  factory AppThemePalette.fromJson(Map<String, dynamic> j) {
    Color c(String k, int def) => Color(j[k] is int ? j[k] as int : def);
    final gradStart = c('gradStart', 0xFF0F172A);
    final gradEnd = c('gradEnd', 0xFF334155);
    final cardStart = c('cardStart', 0xFF1E40AF);
    final cardEnd = c('cardEnd', 0xFF1E3A8A);
    return AppThemePalette(
      id: j['id']?.toString() ?? 'custom',
      name: j['name']?.toString() ?? 'Personalizado',
      primary: c('primary', 0xFF0F172A),
      primaryLight: c('primaryLight', 0xFF334155),
      primaryDark: c('primaryDark', 0xFF020617),
      primarySoft: c('primarySoft', 0xFFF1F5F9),
      secondary: c('secondary', 0xFF059669),
      accent: c('accent', 0xFF475569),
      success: c('success', 0xFF059669),
      error: c('error', 0xFFDC2626),
      income: c('income', 0xFF059669),
      expense: c('expense', 0xFFDC2626),
      backgroundLight: c('backgroundLight', 0xFFF8FAFC),
      surface: c('surface', 0xFFFFFFFF),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [gradStart, gradEnd],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cardStart, cardEnd],
      ),
    );
  }
}

/// Servicio de temas — gestiona la paleta activa y la persiste.
///
/// Para usar en la app:
///   ThemeService().currentPalette  → paleta activa
///   ThemeService().setPalette(id)  → cambiar paleta y notificar
///   ThemeService().paletteNotifier → ValueNotifier para escuchar cambios
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _prefKey = 'app_theme_palette';

  final ValueNotifier<AppThemePalette> paletteNotifier = ValueNotifier(
    _palettes.first,
  );

  AppThemePalette get currentPalette => paletteNotifier.value;

  static final List<AppThemePalette> _palettes = [
    // 1. Navy (original)
    const AppThemePalette(
      id: 'navy',
      name: 'Navy Clásico',
      primary: Color(0xFF0F172A),
      primaryLight: Color(0xFF334155),
      primaryDark: Color(0xFF020617),
      primarySoft: Color(0xFFF1F5F9),
      secondary: Color(0xFF059669),
      accent: Color(0xFF475569),
      surface: Color(0xFFF1F5F9),
      backgroundLight: Color(0xFFE9EEF4),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF0F172A), Color(0xFF334155)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
      ),
    ),
    // 2. Índigo / Morado
    const AppThemePalette(
      id: 'indigo',
      name: 'Índigo',
      primary: Color(0xFF4338CA),
      primaryLight: Color(0xFF6366F1),
      primaryDark: Color(0xFF312E81),
      primarySoft: Color(0xFFEEF2FF),
      secondary: Color(0xFF059669),
      accent: Color(0xFF7C3AED),
      surface: Color(0xFFEEF2FF),
      backgroundLight: Color(0xFFE0E7FF),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4338CA), Color(0xFF312E81)],
      ),
    ),
    // 3. Esmeralda / Verde
    const AppThemePalette(
      id: 'emerald',
      name: 'Esmeralda',
      primary: Color(0xFF065F46),
      primaryLight: Color(0xFF059669),
      primaryDark: Color(0xFF022C22),
      primarySoft: Color(0xFFECFDF5),
      secondary: Color(0xFF0891B2),
      accent: Color(0xFF10B981),
      surface: Color(0xFFECFDF5),
      backgroundLight: Color(0xFFD1FAE5),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF065F46), Color(0xFF059669)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF065F46), Color(0xFF064E3B)],
      ),
    ),
    // 4. Azul océano
    const AppThemePalette(
      id: 'ocean',
      name: 'Océano Azul',
      primary: Color(0xFF0369A1),
      primaryLight: Color(0xFF0284C7),
      primaryDark: Color(0xFF0C4A6E),
      primarySoft: Color(0xFFE0F2FE),
      secondary: Color(0xFF059669),
      accent: Color(0xFF0891B2),
      surface: Color(0xFFE0F2FE),
      backgroundLight: Color(0xFFBAE6FD),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF0369A1), Color(0xFF0891B2)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0369A1), Color(0xFF075985)],
      ),
    ),
    // 5. Rojo Crimson
    const AppThemePalette(
      id: 'crimson',
      name: 'Crimson',
      primary: Color(0xFF991B1B),
      primaryLight: Color(0xFFDC2626),
      primaryDark: Color(0xFF450A0A),
      primarySoft: Color(0xFFFFF1F2),
      secondary: Color(0xFF059669),
      accent: Color(0xFFE11D48),
      surface: Color(0xFFFFF1F2),
      backgroundLight: Color(0xFFFFE4E6),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF991B1B), Color(0xFF7F1D1D)],
      ),
    ),
    // 6. Ámbar / Dorado
    const AppThemePalette(
      id: 'amber',
      name: 'Ámbar Dorado',
      primary: Color(0xFF92400E),
      primaryLight: Color(0xFFD97706),
      primaryDark: Color(0xFF451A03),
      primarySoft: Color(0xFFFFFBEB),
      secondary: Color(0xFF059669),
      accent: Color(0xFFF59E0B),
      surface: Color(0xFFFFFBEB),
      backgroundLight: Color(0xFFFEF3C7),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF92400E), Color(0xFFD97706)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF78350F), Color(0xFF92400E)],
      ),
    ),
    // 7. Rosa Fucsia
    const AppThemePalette(
      id: 'fuchsia',
      name: 'Fucsia',
      primary: Color(0xFF86198F),
      primaryLight: Color(0xFFC026D3),
      primaryDark: Color(0xFF4A044E),
      primarySoft: Color(0xFFFDF4FF),
      secondary: Color(0xFF059669),
      accent: Color(0xFFD946EF),
      surface: Color(0xFFFDF4FF),
      backgroundLight: Color(0xFFFAE8FF),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF86198F), Color(0xFFC026D3)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF701A75), Color(0xFF86198F)],
      ),
    ),
    // 8. Pizarra Grafito
    const AppThemePalette(
      id: 'graphite',
      name: 'Grafito',
      primary: Color(0xFF1F2937),
      primaryLight: Color(0xFF374151),
      primaryDark: Color(0xFF111827),
      primarySoft: Color(0xFFF3F4F6),
      secondary: Color(0xFF059669),
      accent: Color(0xFF6B7280),
      surface: Color(0xFFF3F4F6),
      backgroundLight: Color(0xFFE5E7EB),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF1F2937), Color(0xFF374151)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF111827), Color(0xFF1F2937)],
      ),
    ),
    // 9. Teal / Turquesa
    const AppThemePalette(
      id: 'teal',
      name: 'Turquesa',
      primary: Color(0xFF0F766E),
      primaryLight: Color(0xFF0D9488),
      primaryDark: Color(0xFF042F2E),
      primarySoft: Color(0xFFF0FDFA),
      secondary: Color(0xFF7C3AED),
      accent: Color(0xFF14B8A6),
      surface: Color(0xFFF0FDFA),
      backgroundLight: Color(0xFFCCFBF1),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF134E4A), Color(0xFF0F766E)],
      ),
    ),
    // 10. Naranja quemado
    const AppThemePalette(
      id: 'orange',
      name: 'Naranja',
      primary: Color(0xFFC2410C),
      primaryLight: Color(0xFFEA580C),
      primaryDark: Color(0xFF431407),
      primarySoft: Color(0xFFFFF7ED),
      secondary: Color(0xFF059669),
      accent: Color(0xFFF97316),
      surface: Color(0xFFFFF7ED),
      backgroundLight: Color(0xFFFED7AA),
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFC2410C), Color(0xFFEA580C)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9A3412), Color(0xFFC2410C)],
      ),
    ),
  ];

  static const String _customPrefKey = 'app_custom_palette';

  List<AppThemePalette> get palettes => List.unmodifiable(_palettes);

  AppThemePalette? getPaletteById(String id) {
    try {
      return _palettes.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_prefKey) ?? 'navy';
      if (id == 'custom') {
        final customJson = prefs.getString(_customPrefKey);
        if (customJson != null) {
          final palette = AppThemePalette.fromJson(
            Map<String, dynamic>.from(jsonDecode(customJson) as Map),
          );
          paletteNotifier.value = palette;
          return;
        }
      }
      final palette = getPaletteById(id) ?? _palettes.first;
      paletteNotifier.value = palette;
    } catch (_) {}
  }

  Future<void> setPalette(String id) async {
    final palette = getPaletteById(id);
    if (palette == null) return;
    paletteNotifier.value = palette;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, id);
    } catch (_) {}
  }

  /// Saves and applies a fully custom palette
  Future<void> setCustomPalette(AppThemePalette palette) async {
    paletteNotifier.value = palette;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, 'custom');
      await prefs.setString(_customPrefKey, jsonEncode(palette.toJson()));
    } catch (_) {}
  }

  /// Returns the saved custom palette, or null if none saved
  Future<AppThemePalette?> loadCustomPalette() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_customPrefKey);
      if (json == null) return null;
      return AppThemePalette.fromJson(
        Map<String, dynamic>.from(jsonDecode(json) as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
