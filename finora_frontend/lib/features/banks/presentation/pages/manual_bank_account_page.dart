import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart' as di;

/// Página para crear cuentas bancarias manuales sin Plaid (RF-10 Manual Mode)
///
/// El usuario puede añadir cuentas de efectivo, ahorro u otras cuentas
/// sin necesidad de conectarse con ningún banco externo.
class ManualBankAccountPage extends StatefulWidget {
  const ManualBankAccountPage({super.key});

  @override
  State<ManualBankAccountPage> createState() => _ManualBankAccountPageState();
}

class _ManualBankAccountPageState extends State<ManualBankAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0.00');
  final _institutionCtrl = TextEditingController();

  String _accountType = 'current';
  String _currency = 'EUR';
  bool _isSaving = false;

  final List<(String, String, IconData)> _accountTypeOptions = [
    ('current', 'Cuenta corriente', Icons.account_balance_rounded),
    ('savings', 'Cuenta de ahorro', Icons.savings_rounded),
    ('investment', 'Inversión', Icons.trending_up_rounded),
    ('cash', 'Efectivo', Icons.payments_rounded),
    ('other', 'Otro', Icons.more_horiz_rounded),
  ];

  final List<String> _currencies = ['EUR', 'USD', 'GBP', 'CHF', 'JPY'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ibanCtrl.dispose();
    _balanceCtrl.dispose();
    _institutionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final balanceStr = _balanceCtrl.text.replaceAll(',', '.');
      final balanceValue = double.tryParse(balanceStr) ?? 0.0;
      final balanceCents = (balanceValue * 100).round();

      final apiClient = di.sl<ApiClient>();
      await apiClient.post(
        '/banks/accounts/manual',
        data: {
          'account_name': _nameCtrl.text.trim(),
          'account_type': _accountType,
          'iban': _ibanCtrl.text.trim().isEmpty
              ? null
              : _ibanCtrl.text.trim().toUpperCase(),
          'balance_cents': balanceCents,
          'currency': _currency,
          'institution_name': _institutionCtrl.text.trim().isEmpty
              ? _accountTypeOptions.firstWhere((e) => e.$1 == _accountType).$2
              : _institutionCtrl.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cuenta creada correctamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la cuenta: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryLight,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Nueva cuenta manual', style: AppTypography.titleLarge()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipo de cuenta
              _sectionLabel('Tipo de cuenta'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _accountTypeOptions.map((opt) {
                  final selected = _accountType == opt.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _accountType = opt.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.gray200,
                          width: 1.5,
                        ),
                        boxShadow: selected ? AppColors.shadowSoft : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            opt.$3,
                            size: 18,
                            color: selected
                                ? AppColors.white
                                : AppColors.gray600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            opt.$2,
                            style: AppTypography.bodySmall(
                              color: selected
                                  ? AppColors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Nombre de la cuenta
              _sectionLabel('Nombre de la cuenta *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Ej: Mi cuenta corriente BBVA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
              ),
              const SizedBox(height: 16),

              // Entidad / banco (opcional)
              _sectionLabel('Banco o entidad (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _institutionCtrl,
                decoration: InputDecoration(
                  hintText: 'Ej: BBVA, Santander, Efectivo…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                ),
              ),
              const SizedBox(height: 16),

              // IBAN (opcional)
              _sectionLabel('IBAN (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ibanCtrl,
                decoration: InputDecoration(
                  hintText: 'ES00 0000 0000 0000 0000 0000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return newValue.copyWith(text: newValue.text.toUpperCase());
                  }),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final clean = v.replaceAll(' ', '');
                  if (clean.length < 15 || clean.length > 34) {
                    return 'IBAN inválido (entre 15 y 34 caracteres)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Balance inicial + moneda
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Saldo inicial'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _balanceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            suffixText: _currency,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Moneda'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          items: _currencies
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: AppTypography.bodyMedium(),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _currency = v ?? 'EUR'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Las cuentas manuales no se sincronizan automáticamente. '
                        'Puedes añadir transacciones y actualizar el saldo manualmente.',
                        style: AppTypography.bodySmall(
                          color: AppColors.infoDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón guardar
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Crear cuenta',
                        style: AppTypography.labelLarge(color: AppColors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
  );
}
