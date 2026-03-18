import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Full-page create / edit budget form.
/// Pass [category] + [currentLimit] to open in edit mode.
class CreateEditBudgetPage extends StatefulWidget {
  final String? category;
  final double? currentLimit;

  const CreateEditBudgetPage({super.key, this.category, this.currentLimit});

  @override
  State<CreateEditBudgetPage> createState() => _CreateEditBudgetPageState();
}

class _CreateEditBudgetPageState extends State<CreateEditBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _catController;
  late final TextEditingController _limitController;
  bool _saving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _catController = TextEditingController(text: widget.category ?? '');
    _limitController = TextEditingController(
      text: widget.currentLimit != null
          ? widget.currentLimit!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _catController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final s = AppLocalizations.of(context);
    try {
      await di.sl<ApiClient>().post(
        '/budget',
        data: {
          'category': widget.category ?? _catController.text.trim(),
          'monthly_limit': double.parse(
            _limitController.text.replaceAll(',', '.'),
          ),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.budgetSavedMsg),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getTranslatedCategory(String key, AppLocalizations s) {
    switch (key.toLowerCase().trim()) {
      case 'alimentación':
      case 'food':
        return s.nutrition;
      case 'transporte':
      case 'transport':
        return s.transport;
      case 'ocio':
      case 'leisure':
        return s.leisure;
      case 'salud':
      case 'health':
        return s.health;
      case 'vivienda':
      case 'housing':
        return s.housing;
      case 'servicios':
      case 'services':
        return s.services;
      default:
        if (key.isEmpty) return '';
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          _isEditing ? s.editBudgetTitle : s.newBudgetTitle,
          style: AppTypography.titleMedium(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_chart_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEditing ? s.editBudgetTitle : s.newBudgetTitle,
                      style: AppTypography.titleMedium(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.createFirstBudgetInfo,
                      style: AppTypography.bodySmall(
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Category field (disabled when editing)
              Text(
                s.name,
                style: AppTypography.labelSmall(color: AppColors.gray600),
              ),
              const SizedBox(height: 8),
              if (_isEditing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Text(
                    _getTranslatedCategory(widget.category!, s),
                    style: AppTypography.bodyMedium(color: AppColors.gray600),
                  ),
                )
              else
                TextFormField(
                  controller: _catController,
                  decoration: InputDecoration(
                    hintText: 'Alimentación, Ocio…',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? s.enterAccountNameError
                      : null,
                ),
              const SizedBox(height: 20),

              // Monthly limit field
              Text(
                s.monthlyLimitLabel,
                style: AppTypography.labelSmall(color: AppColors.gray600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _limitController,
                decoration: InputDecoration(
                  prefixText: '€ ',
                  prefixIcon: const Icon(Icons.euro_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  return (n == null || n <= 0) ? s.invalidAmountError : null;
                },
              ),
              const SizedBox(height: 40),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(s.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
