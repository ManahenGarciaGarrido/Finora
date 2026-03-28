import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_service.dart';

/// Página de personalización de colores de la app.
///
/// - Selector de 10 paletas preestablecidas con preview visual.
/// - Editor personalizado: elige color para cada rol (primary, secondary,
///   accent, income/success, expense/error, background).
/// - Los cambios se aplican al instante y se persisten.
class ThemeCustomizationPage extends StatefulWidget {
  const ThemeCustomizationPage({super.key});

  @override
  State<ThemeCustomizationPage> createState() => _ThemeCustomizationPageState();
}

class _ThemeCustomizationPageState extends State<ThemeCustomizationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late String _selectedId;
  late AppThemePalette _customPalette;
  bool _customModified = false;

  // Color swatches for the inline picker (material-ish palette)
  static const List<Color> _swatches = [
    Color(0xFF0F172A),
    Color(0xFF1E3A8A),
    Color(0xFF1E40AF),
    Color(0xFF2563EB),
    Color(0xFF0369A1),
    Color(0xFF0891B2),
    Color(0xFF0F766E),
    Color(0xFF065F46),
    Color(0xFF059669),
    Color(0xFF16A34A),
    Color(0xFF4D7C0F),
    Color(0xFF78350F),
    Color(0xFF92400E),
    Color(0xFFD97706),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFDC2626),
    Color(0xFF9F1239),
    Color(0xFF86198F),
    Color(0xFF7C3AED),
    Color(0xFF4338CA),
    Color(0xFF312E81),
    Color(0xFF1F2937),
    Color(0xFF374151),
    Color(0xFF475569),
    Color(0xFF64748B),
    Color(0xFF6B7280),
    Color(0xFF9CA3AF),
    Color(0xFF047857),
    Color(0xFFB45309),
    Color(0xFF991B1B),
    Color(0xFFC2410C),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _selectedId = ThemeService().currentPalette.id;
    _initCustomPalette();
  }

  void _initCustomPalette() {
    final current = ThemeService().currentPalette;
    _customPalette = AppThemePalette(
      id: 'custom',
      name: 'Personalizado',
      primary: current.primary,
      primaryLight: current.primaryLight,
      primaryDark: current.primaryDark,
      primarySoft: current.primarySoft,
      secondary: current.secondary,
      accent: current.accent,
      success: current.success,
      error: current.error,
      income: current.income,
      expense: current.expense,
      backgroundLight: current.backgroundLight,
      surface: current.surface,
      primaryGradient: current.primaryGradient,
      cardGradient: current.cardGradient,
    );
  }

  Future<void> _applyPreset(String id) async {
    setState(() => _selectedId = id);
    await ThemeService().setPalette(id);
  }

  Future<void> _applyCustom() async {
    setState(() {
      _selectedId = 'custom';
      _customModified = false;
    });
    await ThemeService().setCustomPalette(_customPalette);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Colores personalizados aplicados'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _updateCustomColor(String role, Color color) {
    setState(() {
      _customModified = true;
      final p = _customPalette;
      switch (role) {
        case 'primary':
          _customPalette = AppThemePalette(
            id: 'custom',
            name: 'Personalizado',
            primary: color,
            primaryLight: color.withValues(alpha: 0.7),
            primaryDark: _darken(color, 0.2),
            primarySoft: color.withValues(alpha: 0.1),
            secondary: p.secondary,
            accent: p.accent,
            success: p.success,
            error: p.error,
            income: p.income,
            expense: p.expense,
            // Al cambiar el primario se actualiza surface automáticamente
            // (tinte suave del nuevo color) salvo que el usuario lo haya
            // cambiado explícitamente mediante el picker "Superficie/Tarjetas".
            backgroundLight: p.backgroundLight,
            surface: color.withValues(alpha: 0.08),
            primaryGradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [color, _lighten(color, 0.15)],
            ),
            cardGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_darken(color, 0.1), color],
            ),
          );
        case 'secondary':
          _customPalette = AppThemePalette(
            id: 'custom',
            name: 'Personalizado',
            primary: p.primary,
            primaryLight: p.primaryLight,
            primaryDark: p.primaryDark,
            primarySoft: p.primarySoft,
            secondary: color,
            accent: p.accent,
            success: p.success,
            error: p.error,
            income: p.income,
            expense: p.expense,
            backgroundLight: p.backgroundLight,
            surface: p.surface,
            primaryGradient: p.primaryGradient,
            cardGradient: p.cardGradient,
          );
        case 'accent':
          _customPalette = AppThemePalette(
            id: 'custom',
            name: 'Personalizado',
            primary: p.primary,
            primaryLight: p.primaryLight,
            primaryDark: p.primaryDark,
            primarySoft: p.primarySoft,
            secondary: p.secondary,
            accent: color,
            success: p.success,
            error: p.error,
            income: p.income,
            expense: p.expense,
            backgroundLight: p.backgroundLight,
            surface: p.surface,
            primaryGradient: p.primaryGradient,
            cardGradient: p.cardGradient,
          );
        case 'income':
          _customPalette = AppThemePalette(
            id: 'custom',
            name: 'Personalizado',
            primary: p.primary,
            primaryLight: p.primaryLight,
            primaryDark: p.primaryDark,
            primarySoft: p.primarySoft,
            secondary: p.secondary,
            accent: p.accent,
            success: color,
            error: p.error,
            income: color,
            expense: p.expense,
            backgroundLight: p.backgroundLight,
            surface: p.surface,
            primaryGradient: p.primaryGradient,
            cardGradient: p.cardGradient,
          );
        case 'expense':
          _customPalette = AppThemePalette(
            id: 'custom',
            name: 'Personalizado',
            primary: p.primary,
            primaryLight: p.primaryLight,
            primaryDark: p.primaryDark,
            primarySoft: p.primarySoft,
            secondary: p.secondary,
            accent: p.accent,
            success: p.success,
            error: color,
            income: p.income,
            expense: color,
            backgroundLight: p.backgroundLight,
            surface: p.surface,
            primaryGradient: p.primaryGradient,
            cardGradient: p.cardGradient,
          );
        case 'background':
          _customPalette = AppThemePalette(
            id: 'custom',
            name: 'Personalizado',
            primary: p.primary,
            primaryLight: p.primaryLight,
            primaryDark: p.primaryDark,
            primarySoft: p.primarySoft,
            secondary: p.secondary,
            accent: p.accent,
            success: p.success,
            error: p.error,
            income: p.income,
            expense: p.expense,
            backgroundLight: color,
            surface: p.surface,
            primaryGradient: p.primaryGradient,
            cardGradient: p.cardGradient,
          );
        case 'surface':
          _customPalette = AppThemePalette(
            id: 'custom',
            name: 'Personalizado',
            primary: p.primary,
            primaryLight: p.primaryLight,
            primaryDark: p.primaryDark,
            primarySoft: p.primarySoft,
            secondary: p.secondary,
            accent: p.accent,
            success: p.success,
            error: p.error,
            income: p.income,
            expense: p.expense,
            backgroundLight: p.backgroundLight,
            surface: color,
            primaryGradient: p.primaryGradient,
            cardGradient: p.cardGradient,
          );
      }
    });
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text('Personalizar colores', style: AppTypography.titleMedium()),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Paletas'),
            Tab(text: 'Personalizado'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildPresetsTab(), _buildCustomTab()],
      ),
    );
  }

  // ──────────────────────────────────────────
  // TAB 1: Preset palettes
  // ──────────────────────────────────────────
  Widget _buildPresetsTab() {
    final palettes = ThemeService().palettes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elige una paleta de colores para toda la app. El cambio se aplica al instante.',
            style: AppTypography.bodyMedium(color: AppColors.gray600),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: palettes.length,
            itemBuilder: (_, i) => _PaletteCard(
              palette: palettes[i],
              isSelected: _selectedId == palettes[i].id,
              onTap: () => _applyPreset(palettes[i].id),
            ),
          ),
          if (_selectedId == 'custom') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.palette_rounded, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Usando paleta personalizada. Ve a la pestaña "Personalizado" para editarla.',
                      style: AppTypography.bodySmall(color: AppColors.infoDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // TAB 2: Custom editor
  // ──────────────────────────────────────────
  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personaliza cada color individualmente. Toca un color para abrirlo en el selector.',
            style: AppTypography.bodyMedium(color: AppColors.gray600),
          ),
          const SizedBox(height: 8),
          // Live preview strip
          _buildPreviewStrip(),
          const SizedBox(height: 20),

          _sectionTitle('Colores principales'),
          _ColorRow(
            label: 'Primario',
            subtitle: 'Botones, indicadores, AppBar activo',
            color: _customPalette.primary,
            onChanged: (c) => _updateCustomColor('primary', c),
            swatches: _swatches,
          ),
          _ColorRow(
            label: 'Secundario',
            subtitle: 'Acciones secundarias, chips',
            color: _customPalette.secondary,
            onChanged: (c) => _updateCustomColor('secondary', c),
            swatches: _swatches,
          ),
          _ColorRow(
            label: 'Acento',
            subtitle: 'Resaltados y elementos terciarios',
            color: _customPalette.accent,
            onChanged: (c) => _updateCustomColor('accent', c),
            swatches: _swatches,
          ),

          const SizedBox(height: 8),
          _sectionTitle('Colores financieros'),
          _ColorRow(
            label: 'Ingresos / Éxito',
            subtitle: 'Transacciones positivas, mensajes OK',
            color: _customPalette.income,
            onChanged: (c) => _updateCustomColor('income', c),
            swatches: _swatches,
          ),
          _ColorRow(
            label: 'Gastos / Error',
            subtitle: 'Transacciones negativas, mensajes de error',
            color: _customPalette.expense,
            onChanged: (c) => _updateCustomColor('expense', c),
            swatches: _swatches,
          ),

          const SizedBox(height: 8),
          _sectionTitle('Fondos'),
          _ColorRow(
            label: 'Fondo principal',
            subtitle: 'Color de fondo de las pantallas',
            color: _customPalette.backgroundLight,
            onChanged: (c) => _updateCustomColor('background', c),
            swatches: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFEFF6FF),
              const Color(0xFFF0FDF4),
              const Color(0xFFFFFBEB),
              const Color(0xFFFFF7ED),
              const Color(0xFFFDF4FF),
              const Color(0xFFFFF1F2),
              const Color(0xFFFFFFFF),
              const Color(0xFFF9FAFB),
              const Color(0xFFF3F4F6),
              const Color(0xFFE5E7EB),
            ],
          ),
          _ColorRow(
            label: 'Superficie / Tarjetas',
            subtitle: 'Fondo de tarjetas y paneles',
            color: _customPalette.surface,
            onChanged: (c) => _updateCustomColor('surface', c),
            swatches: [
              const Color(0xFFFFFFFF),
              const Color(0xFFF9FAFB),
              const Color(0xFFF3F4F6),
              const Color(0xFFE5E7EB),
              const Color(0xFFEFF6FF),
              const Color(0xFFF0FDF4),
              const Color(0xFFFFFBEB),
              const Color(0xFFFDF4FF),
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFE0F2FE),
              const Color(0xFFECFDF5),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _applyCustom,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                _customModified
                    ? 'Aplicar cambios personalizados'
                    : 'Usar paleta personalizada',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _initCustomPalette,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Restablecer desde paleta actual'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPreviewStrip() {
    final p = _customPalette;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: p.primaryGradient,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                gradient: p.primaryGradient,
              ),
              child: Center(
                child: Text(
                  'Primary',
                  style: AppTypography.labelSmall(color: Colors.white),
                ),
              ),
            ),
          ),
          Container(
            width: 56,
            color: p.secondary,
            child: Center(
              child: Text(
                '2nd',
                style: AppTypography.labelSmall(color: AppColors.cardLight),
              ),
            ),
          ),
          Container(
            width: 56,
            color: p.income,
            child: Center(
              child: Icon(
                Icons.arrow_upward_rounded,
                color: AppColors.cardLight,
                size: 18,
              ),
            ),
          ),
          Container(
            width: 56,
            decoration: BoxDecoration(
              color: p.expense,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: const Icon(
                Icons.arrow_downward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppTypography.titleSmall(color: AppColors.gray700),
    ),
  );
}

// ──────────────────────────────────────────
// Preset palette card widget
// ──────────────────────────────────────────
class _PaletteCard extends StatelessWidget {
  final AppThemePalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaletteCard({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? palette.primary : AppColors.gray200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppColors.shadowSoft,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(
            children: [
              // Gradient header
              Expanded(
                child: Container(
                  decoration: BoxDecoration(gradient: palette.primaryGradient),
                  child: Stack(
                    children: [
                      // Color chips
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Row(
                          children: [
                            _chip(palette.secondary),
                            const SizedBox(width: 4),
                            _chip(palette.accent),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Name
              Container(
                color: AppColors.surfaceLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: palette.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        palette.name,
                        style: AppTypography.labelSmall(
                          color: isSelected
                              ? palette.primary
                              : AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(Color c) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: c,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
    ),
  );
}

// ──────────────────────────────────────────
// Color row + inline picker
// ──────────────────────────────────────────
class _ColorRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final List<Color> swatches;
  final ValueChanged<Color> onChanged;

  const _ColorRow({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.swatches,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray300),
              boxShadow: AppColors.shadowSoft,
            ),
          ),
        ),
        title: Text(label, style: AppTypography.bodyMedium()),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall(color: AppColors.gray500),
        ),
        trailing: TextButton(
          onPressed: () => _showPicker(context),
          child: Text(
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: AppTypography.labelSmall(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ColorPickerSheet(
        label: label,
        initial: color,
        swatches: swatches,
        onSelected: (c) {
          onChanged(c);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ──────────────────────────────────────────
// Color picker bottom sheet
// ──────────────────────────────────────────
class _ColorPickerSheet extends StatefulWidget {
  final String label;
  final Color initial;
  final List<Color> swatches;
  final ValueChanged<Color> onSelected;

  const _ColorPickerSheet({
    required this.label,
    required this.initial,
    required this.swatches,
    required this.onSelected,
  });

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late Color _current;
  late TextEditingController _hexCtrl;
  String? _hexError;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _hexCtrl = TextEditingController(text: _toHex(_current));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  String _toHex(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

  void _applyHex(String raw) {
    final cleaned = raw.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      try {
        final value = int.parse('FF$cleaned', radix: 16);
        setState(() {
          _current = Color(value);
          _hexError = null;
        });
      } catch (_) {
        setState(() => _hexError = 'Hex inválido');
      }
    } else if (cleaned.length == 8) {
      try {
        final value = int.parse(cleaned, radix: 16);
        setState(() {
          _current = Color(value);
          _hexError = null;
        });
      } catch (_) {
        setState(() => _hexError = 'Hex inválido');
      }
    } else {
      setState(() => _hexError = 'Usa formato RRGGBB (6 caracteres)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with preview
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _current,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: AppTypography.titleSmall()),
                    Text(
                      '#${_toHex(_current)}',
                      style: AppTypography.bodySmall(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => widget.onSelected(_current),
                child: const Text('Aplicar'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hex input
          TextField(
            controller: _hexCtrl,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
              LengthLimitingTextInputFormatter(7),
            ],
            decoration: InputDecoration(
              prefixText: '#',
              labelText: 'Código hexadecimal',
              hintText: 'RRGGBB',
              errorText: _hexError,
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: () => _applyHex(_hexCtrl.text),
              ),
            ),
            onSubmitted: _applyHex,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),

          // Swatches grid
          Text('Colores sugeridos', style: AppTypography.labelMedium()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.swatches.map((c) {
              final isSelected = _current.toARGB32() == c.toARGB32();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _current = c;
                    _hexCtrl.text = _toHex(c);
                    _hexError = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: isSelected ? 36 : 32,
                  height: isSelected ? 36 : 32,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
