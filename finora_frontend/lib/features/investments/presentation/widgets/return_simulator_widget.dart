import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/currency_service.dart';

class ReturnSimulatorWidget extends StatefulWidget {
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSimulate;

  const ReturnSimulatorWidget({super.key, required this.onSimulate});

  @override
  State<ReturnSimulatorWidget> createState() => _ReturnSimulatorWidgetState();
}

class _ReturnSimulatorWidgetState extends State<ReturnSimulatorWidget> {
  final _formKey = GlobalKey<FormState>();
  final _monthly = TextEditingController(text: '200');
  final _years = TextEditingController(text: '20');
  final _rate = TextEditingController(text: '7');
  bool _loading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _monthly.dispose();
    _years.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final result = await widget.onSimulate({
        'monthly_amount': double.parse(_monthly.text.replaceAll(',', '.')),
        'years': int.parse(_years.text),
        'annual_return': double.parse(_rate.text.replaceAll(',', '.')),
      });
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final fmt = CurrencyService().format;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.simulatorTitle, style: AppTypography.titleSmall()),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _monthly,
                decoration: InputDecoration(
                  labelText: s.monthlyInvestment,
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _years,
                      decoration: InputDecoration(
                        labelText: s.investmentYears,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n <= 0 || n > 50)
                            ? s.fieldRequired
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rate,
                      decoration: InputDecoration(
                        labelText: s.expectedReturn,
                        suffixText: '%',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final n = double.tryParse(
                          v?.replaceAll(',', '.') ?? '',
                        );
                        return (n == null || n < 0) ? s.amountInvalid : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _simulate,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.show_chart_rounded),
                  label: Text(s.simulate),
                ),
              ),
            ],
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 24),
          _buildResults(s, fmt),
        ],
      ],
    );
  }

  Widget _buildResults(dynamic s, Function fmt) {
    final r = _result!;
    final breakdown = r['yearly_breakdown'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.finalAmount, style: AppTypography.bodyMedium()),
                  Text(
                    fmt((r['final_amount'] as num).toDouble()),
                    style: AppTypography.titleSmall(
                      color: AppColors.successDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.totalInvested,
                    style: AppTypography.bodySmall(color: AppColors.gray600),
                  ),
                  Text(
                    fmt((r['total_invested'] as num).toDouble()),
                    style: AppTypography.bodyMedium(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.totalReturns,
                    style: AppTypography.bodySmall(color: AppColors.gray600),
                  ),
                  Text(
                    fmt((r['total_returns'] as num).toDouble()),
                    style: AppTypography.bodyMedium(color: AppColors.success),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (breakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${s.investmentYears} ─',
            style: AppTypography.labelSmall(color: AppColors.gray500),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: breakdown.map<Widget>((entry) {
                final balance = (entry['balance'] as num).toDouble();
                final maxBalance = (breakdown.last['balance'] as num)
                    .toDouble();
                final heightFraction = maxBalance > 0
                    ? balance / maxBalance
                    : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (heightFraction * 90).clamp(4.0, 90.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry['year']}',
                          style: AppTypography.labelSmall(
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
