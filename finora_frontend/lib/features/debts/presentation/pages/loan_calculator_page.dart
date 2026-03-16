import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../../../core/services/currency_service.dart';

class LoanCalculatorPage extends StatefulWidget {
  final bool isMortgage;
  const LoanCalculatorPage({super.key, this.isMortgage = false});

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final _apiClient = di.sl<ApiClient>();
  final _formKey = GlobalKey<FormState>();
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _months = TextEditingController();
  final _extra = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _months.dispose();
    _extra.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final endpoint = widget.isMortgage
          ? '/debts/calculate/mortgage'
          : '/debts/calculate/loan';
      final data = {
        'principal': double.parse(_principal.text.replaceAll(',', '.')),
        'annual_rate': double.parse(_rate.text.replaceAll(',', '.')),
        'months': int.parse(_months.text),
        if (widget.isMortgage && _extra.text.isNotEmpty)
          'early_payment':
              double.tryParse(_extra.text.replaceAll(',', '.')) ?? 0,
      };
      final r = await _apiClient.post(endpoint, data: data);
      setState(() {
        _result = r.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final fmt = CurrencyService().format;
    final title = widget.isMortgage ? s.mortgageCalculator : s.loanCalculator;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(title, style: AppTypography.titleMedium()),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _principal,
                  decoration: InputDecoration(
                    labelText: s.principal,
                    prefixText: '€ ',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    return (n == null || n <= 0) ? s.amountInvalid : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rate,
                  decoration: InputDecoration(
                    labelText: s.annualRate,
                    suffixText: '%',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    return (n == null || n < 0) ? s.amountInvalid : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _months,
                  decoration: InputDecoration(
                    labelText: s.termMonths,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n <= 0) ? s.fieldRequired : null;
                  },
                ),
                if (widget.isMortgage) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _extra,
                    decoration: InputDecoration(
                      labelText: s.extraPaymentLabel,
                      prefixText: '€ ',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _calculate,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.calculate_rounded),
                    label: Text(s.calculate),
                  ),
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildResult(s, fmt),
          ],
        ],
      ),
    );
  }

  Widget _buildResult(dynamic s, Function fmt) {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          _resultRow(
            s.monthlyPaymentResult,
            fmt((r['monthly_payment'] as num).toDouble()),
            AppColors.primary,
          ),
          const Divider(height: 20),
          _resultRow(
            s.totalInterest,
            fmt((r['total_interest'] as num).toDouble()),
            AppColors.error,
          ),
          const SizedBox(height: 8),
          _resultRow(
            s.totalPayment,
            fmt((r['total_payment'] as num).toDouble()),
            AppColors.gray600,
          ),
          if (r['savings_with_early'] != null) ...[
            const Divider(height: 20),
            _resultRow(
              s.savingsWithExtra,
              fmt((r['savings_with_early'] as num).toDouble()),
              AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(color: AppColors.gray600)),
        Text(value, style: AppTypography.titleSmall(color: color)),
      ],
    );
  }
}
