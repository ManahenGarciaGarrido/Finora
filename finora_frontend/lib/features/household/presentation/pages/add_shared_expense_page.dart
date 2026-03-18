import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/household_member_entity.dart';

/// Returns a Map< String, dynamic > with 'description', 'amount', and 'splits' on success.
class AddSharedExpensePage extends StatefulWidget {
  final List<HouseholdMemberEntity> members;
  const AddSharedExpensePage({super.key, required this.members});

  @override
  State<AddSharedExpensePage> createState() => _AddSharedExpensePageState();
}

class _AddSharedExpensePageState extends State<AddSharedExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  // Map from userId -> percentage (as double)
  late Map<String, double> _splits;

  @override
  void initState() {
    super.initState();
    _initEqualSplits();
  }

  void _initEqualSplits() {
    if (widget.members.isEmpty) {
      _splits = {};
      return;
    }
    final equal = (100.0 / widget.members.length);
    _splits = {for (final m in widget.members) m.userId: equal};
    // Round to avoid floating point drift — give remainder to first member
    final total = _splits.values.fold(0.0, (a, b) => a + b);
    final diff = 100.0 - total;
    if (_splits.isNotEmpty && diff.abs() > 0.001) {
      final first = _splits.keys.first;
      _splits[first] = (_splits[first]! + diff);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final total = _splits.values.fold(0.0, (a, b) => a + b);
    if ((total - 100).abs() > 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los porcentajes deben sumar 100%')),
      );
      return;
    }
    Navigator.pop(context, {
      'description': _descController.text.trim(),
      'amount': double.parse(_amountController.text.replaceAll(',', '.')),
      'splits': _splits.entries
          .map((e) => {'user_id': e.key, 'percentage': e.value})
          .toList(),
    });
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
        title: Text(s.addSharedExpense, style: AppTypography.titleMedium()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF039BE5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF039BE5).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF039BE5),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.addSharedExpense,
                    style: AppTypography.titleMedium(
                      color: const Color(0xFF039BE5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // How it works info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.householdExpenseHowTitle,
                        style: AppTypography.titleSmall(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.householdExpenseHowBody,
                    style: AppTypography.bodySmall(color: AppColors.gray700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    s.description,
                    style: AppTypography.labelSmall(color: AppColors.gray600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.description_outlined),
                      hintText: 'Supermercado, Netflix…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? s.enterAccountNameError
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  Text(
                    s.amount,
                    style: AppTypography.labelSmall(color: AppColors.gray600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      prefixText: '€ ',
                      prefixIcon: const Icon(Icons.euro_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                      return (n == null || n <= 0)
                          ? s.invalidAmountError
                          : null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Splits section
                  if (widget.members.isNotEmpty) ...[
                    Text(
                      s.householdExpenseHowTitle,
                      style: AppTypography.labelSmall(color: AppColors.gray600),
                    ),
                    const SizedBox(height: 8),
                    ...widget.members.map((m) {
                      final pct = _splits[m.userId] ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.12,
                              ),
                              child: Text(
                                (m.name?.isNotEmpty == true
                                    ? m.name![0].toUpperCase()
                                    : '?'),
                                style: AppTypography.labelSmall(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                m.name ?? m.email ?? m.userId,
                                style: AppTypography.bodyMedium(),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: pct.toStringAsFixed(1),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  suffixText: '%',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (v) {
                                  final val = double.tryParse(
                                    v.replaceAll(',', '.'),
                                  );
                                  if (val != null) {
                                    setState(() => _splits[m.userId] = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Total indicator
                    Builder(
                      builder: (ctx) {
                        final total = _splits.values.fold(0.0, (a, b) => a + b);
                        final ok = (total - 100).abs() < 0.5;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              ok
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              color: ok ? AppColors.success : AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Total: ${total.toStringAsFixed(1)}%',
                              style: AppTypography.labelSmall(
                                color: ok ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(s.addSharedExpense),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
