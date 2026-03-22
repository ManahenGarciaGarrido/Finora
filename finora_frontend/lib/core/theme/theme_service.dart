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
    required this.primaryGradient,
    required this.cardGradient,
  });
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
      primarySoft: Color(0xFFF9FAFB),
      secondary: Color(0xFF059669),
      accent: Color(0xFF6B7280),
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
}
