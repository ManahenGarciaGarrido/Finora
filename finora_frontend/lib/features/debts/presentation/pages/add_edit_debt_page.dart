import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/debt_entity.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';
import '../bloc/debt_state.dart';

class AddEditDebtPage extends StatefulWidget {
  final DebtEntity? debt;
  const AddEditDebtPage({super.key, this.debt});

  @override
  State<AddEditDebtPage> createState() => _AddEditDebtPageState();
}

class _AddEditDebtPageState extends State<AddEditDebtPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _creditor;
  late final TextEditingController _amount;
  late final TextEditingController _remaining;
  late final TextEditingController _interest;
  late final TextEditingController _monthly;
  late final TextEditingController _notes;
  String _type = 'own';
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _name = TextEditingController(text: d?.name ?? '');
    _creditor = TextEditingController(text: d?.creditorName ?? '');
    _amount = TextEditingController(
      text: d != null ? d.amount.toStringAsFixed(2) : '',
    );
    _remaining = TextEditingController(
      text: d != null ? d.remainingAmount.toStringAsFixed(2) : '',
    );
    _interest = TextEditingController(
      text: d != null ? d.interestRate.toStringAsFixed(2) : '',
    );
    _monthly = TextEditingController(
      text: d?.monthlyPayment != null
          ? d!.monthlyPayment!.toStringAsFixed(2)
          : '',
    );
    _notes = TextEditingController(text: d?.notes ?? '');
    _type = d?.type ?? 'own';
    _dueDate = d?.dueDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _creditor.dispose();
    _amount.dispose();
    _remaining.dispose();
    _interest.dispose();
    _monthly.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final isEdit = widget.debt != null;

    return BlocProvider(
      create: (_) => di.sl<DebtBloc>(),
      child: BlocListener<DebtBloc, DebtState>(
        listener: (ctx, state) {
          if (state is DebtCreated || state is DebtUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.debtSaved),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is DebtError) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceLight,
              elevation: 0,
              title: Text(
                isEdit ? s.editDebt : s.addDebt,
                style: AppTypography.titleMedium(),
              ),
              leading: const BackButton(),
              actions: [
                TextButton(
                  onPressed: _saving ? null : () => _submit(ctx, s),
                  child: Text(s.save),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Type selector
                  Row(
                    children: [
                      Expanded(
                        child: _typeButton(
                          ctx,
                          s.debtTypeOwn,
                          'own',
                          Icons.credit_card_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _typeButton(
                          ctx,
                          s.debtTypeOwed,
                          'owed',
                          Icons.account_balance_wallet_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: s.debtName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? s.fieldRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _creditor,
                    decoration: InputDecoration(
                      labelText: s.creditorName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amount,
                          decoration: InputDecoration(
                            labelText: s.originalAmount,
                            prefixText: '€ ',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            final n = double.tryParse(
                              v?.replaceAll(',', '.') ?? '',
                            );
                            return (n == null || n <= 0)
                                ? s.amountInvalid
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _remaining,
                          decoration: InputDecoration(
                            labelText: s.remainingAmount,
                            prefixText: '€ ',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            final n = double.tryParse(
                              v?.replaceAll(',', '.') ?? '',
                            );
                            return (n == null || n < 0)
                                ? s.amountInvalid
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _interest,
                          decoration: InputDecoration(
                            labelText: s.interestRate,
                            suffixText: '%',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _monthly,
                          decoration: InputDecoration(
                            labelText: s.monthlyPayment,
                            prefixText: '€ ',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.dueDate),
                    subtitle: Text(
                      _dueDate != null
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : s.optional,
                      style: AppTypography.bodySmall(color: AppColors.gray500),
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2050),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    decoration: InputDecoration(
                      labelText: s.note,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeButton(
    BuildContext ctx,
    String label,
    String value,
    IconData icon,
  ) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.gray400,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodyMedium(
                color: selected ? AppColors.primary : AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext ctx, dynamic s) {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _name.text.trim(),
      'type': _type,
      'creditor_name': _creditor.text.trim().isEmpty
          ? null
          : _creditor.text.trim(),
      'amount': double.parse(_amount.text.replaceAll(',', '.')),
      'remaining_amount': double.parse(_remaining.text.replaceAll(',', '.')),
      'interest_rate': _interest.text.isEmpty
          ? 0
          : double.tryParse(_interest.text.replaceAll(',', '.')) ?? 0,
      'monthly_payment': _monthly.text.isEmpty
          ? null
          : double.tryParse(_monthly.text.replaceAll(',', '.')),
      'due_date': _dueDate?.toIso8601String().split('T').first,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };
    if (widget.debt != null) {
      ctx.read<DebtBloc>().add(UpdateDebt(widget.debt!.id, data));
    } else {
      ctx.read<DebtBloc>().add(CreateDebt(data));
    }
  }
}
