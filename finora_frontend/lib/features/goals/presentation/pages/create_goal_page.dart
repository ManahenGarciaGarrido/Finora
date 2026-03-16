import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/app_settings_service.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import 'goals_page.dart' show goalIconsMap;

/// RF-18 / CU-03: Formulario de creación de objetivo de ahorro con análisis IA
class CreateGoalPage extends StatefulWidget {
  const CreateGoalPage({super.key});

  @override
  State<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends State<CreateGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedIcon = 'other';
  String _selectedColor = '#6C63FF';
  DateTime? _deadline;
  String? _category;
  bool _isSubmitting = false;

  static const _colors = [
    '#6C63FF',
    '#3B82F6',
    '#22c55e',
    '#f59e0b',
    '#ef4444',
    '#EC4899',
    '#8B5CF6',
    '#0EA5E9',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final categories = s.goalCategoriesList;

    return BlocListener<GoalBloc, GoalState>(
      listener: (context, state) {
        if (state is GoalCreated) {
          setState(() => _isSubmitting = false);
          _showAiResult(context, state);
        } else if (state is GoalError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: Text(s.createGoal, style: AppTypography.titleMedium()),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Nombre
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(s.goalName),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDec(s.goalNameHint),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? s.goalNameRequired
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Cantidad objetivo
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(s.goalTargetAmountLabel),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountCtrl,
                      decoration: _inputDec('0,00').copyWith(suffixText: AppSettingsService().currentCurrency.symbol),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return s.goalAmountRequired;
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0) return s.goalAmountPositive;
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Icono y color (HU-07: personalizable)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(s.goalIconLabel),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: goalIconsMap.entries.map((e) {
                        final selected = e.key == _selectedIcon;
                        final color = Color(
                          int.parse(
                            _selectedColor.replaceAll('#', 'FF'),
                            radix: 16,
                          ),
                        );
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIcon = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.withValues(alpha: 0.15)
                                  : AppColors.gray100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              e.value,
                              size: 22,
                              color: selected ? color : AppColors.gray400,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _Label('Color'),
                    const SizedBox(height: 8),
                    Row(
                      children: _colors.map((hex) {
                        final c = Color(
                          int.parse(hex.replaceAll('#', 'FF'), radix: 16),
                        );
                        final selected = hex == _selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
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
              ),
              const SizedBox(height: 12),

              // Fecha límite (opcional)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(s.goalDeadlineOptional),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gray200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.gray400,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _deadline == null
                                  ? s.goalNoDeadline
                                  : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                              style: AppTypography.bodyMedium(
                                color: _deadline == null
                                    ? AppColors.gray400
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const Spacer(),
                            if (_deadline != null)
                              GestureDetector(
                                onTap: () => setState(() => _deadline = null),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.gray400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Categoría (opcional)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(s.goalCategoryOptional),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: _inputDec(s.goalSelectCategory),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _category = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Nota (opcional)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(s.goalNoteOptional),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: _inputDec(s.goalNoteHint),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Aviso de análisis IA (CU-03)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.goalAiHint,
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón crear
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.gray200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          s.goalAnalyzeAndCreate,
                          style: AppTypography.labelMedium(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', '.'));
    context.read<GoalBloc>().add(
      CreateGoal(
        name: _nameCtrl.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        targetAmount: amount,
        deadline: _deadline,
        category: _category,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
  }

  /// CU-03 paso 10: Mostrar resultado del análisis IA tras crear el objetivo
  void _showAiResult(BuildContext context, GoalCreated state) {
    final s = AppLocalizations.of(context);
    final goal = state.goal;
    final feasibility = goal.aiFeasibility;
    final explanation = goal.aiExplanation;
    final monthly = goal.monthlyTarget;

    Color fColor;
    String fLabel;
    IconData fIcon;
    switch (feasibility) {
      case 'viable':
        fColor = AppColors.success;
        fLabel = s.goalFeasibleLabel;
        fIcon = Icons.check_circle_rounded;
        break;
      case 'difficult':
        fColor = AppColors.warning;
        fLabel = s.goalDifficultLabel;
        fIcon = Icons.warning_amber_rounded;
        break;
      case 'not_viable':
        fColor = AppColors.error;
        fLabel = s.goalNotViableLabel;
        fIcon = Icons.error_rounded;
        break;
      default:
        Navigator.pop(context);
        return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(fIcon, color: fColor),
            const SizedBox(width: 8),
            Text(fLabel, style: AppTypography.titleSmall(color: fColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (explanation != null) ...[
              Text(explanation, style: AppTypography.bodyMedium()),
              const SizedBox(height: 12),
            ],
            if (monthly != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.savings_rounded, color: fColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.goalMonthlySuggested(monthly.toStringAsFixed(2)),
                        style: AppTypography.labelMedium(color: fColor),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // create page
            },
            child: Text(s.understood, style: AppTypography.labelMedium()),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.bodyMedium(color: AppColors.gray400),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.gray200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.gray200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ─── Helpers visuales ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.labelMedium());
  }
}
