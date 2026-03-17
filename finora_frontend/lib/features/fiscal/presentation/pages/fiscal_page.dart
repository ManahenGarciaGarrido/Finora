import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/currency_service.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../bloc/fiscal_bloc.dart';
import '../bloc/fiscal_event.dart';
import '../bloc/fiscal_state.dart';
import '../../domain/entities/fiscal_transaction_entity.dart';
import '../../domain/entities/irpf_result_entity.dart';
import '../../domain/entities/tax_event_entity.dart';

class FiscalPage extends StatefulWidget {
  const FiscalPage({super.key});

  @override
  State<FiscalPage> createState() => _FiscalPageState();
}

class _FiscalPageState extends State<FiscalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<FiscalTransactionEntity> _deductibles = [];
  double _totalDeductible = 0;
  IrpfResultEntity? _irpfResult;
  List<TaxEventEntity> _calendarEvents = [];
  final _incomeCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _incomeCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocProvider(
      create: (ctx) => di.sl<FiscalBloc>()..add(const LoadDeductibles()),
      child: BlocConsumer<FiscalBloc, FiscalState>(
        listener: (ctx, state) {
          if (state is DeductiblesLoaded) {
            setState(() {
              _deductibles = state.transactions;
              _totalDeductible = state.total;
            });
          } else if (state is IrpfEstimated) {
            setState(() => _irpfResult = state.result);
          } else if (state is CalendarLoaded) {
            setState(() => _calendarEvents = state.events);
          } else if (state is FiscalExported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.fiscalDataExported),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is FiscalError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (ctx, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceLight,
              elevation: 0,
              title: Text(s.fiscalTitle, style: AppTypography.titleMedium()),
              leading: const BackButton(),
              bottom: TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                isScrollable: true,
                tabs: [
                  Tab(text: s.deductibleExpensesTab),
                  Tab(text: s.irpfTab),
                  Tab(text: s.taxCalendarTab),
                  Tab(text: s.exportFiscalTab),
                ],
                onTap: (i) {
                  if (i == 2 && _calendarEvents.isEmpty) {
                    ctx.read<FiscalBloc>().add(const LoadCalendar());
                  }
                },
              ),
            ),
            body: state is FiscalLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonListLoader(count: 5, cardHeight: 70),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildDeductibles(ctx, s),
                      _buildIrpf(ctx, s),
                      _buildCalendar(ctx, s),
                      _buildExport(ctx, s),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDeductibles(BuildContext ctx, dynamic s) {
    final fmt = CurrencyService().format;
    if (_deductibles.isEmpty) {
      return Center(
        child: Text(
          s.noFiscalData,
          style: AppTypography.bodyMedium(color: AppColors.gray500),
        ),
      );
    }
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.totalDeductible,
                style: AppTypography.titleSmall(color: AppColors.primary),
              ),
              Text(
                fmt(_totalDeductible),
                style: AppTypography.titleMedium(color: AppColors.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _deductibles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = _deductibles[i];
              return ListTile(
                tileColor: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.gray200),
                ),
                title: Text(t.description),
                subtitle: Text(t.fiscalCategory ?? ''),
                trailing: Text(
                  fmt(t.amount),
                  style: AppTypography.titleSmall(color: AppColors.primary),
                ),
                onLongPress: () => _showTagDialog(ctx, t, s),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTagDialog(BuildContext ctx, FiscalTransactionEntity t, dynamic s) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.tagAsFiscal),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in {
              'freelance': s.fiscalCategoryFreelance,
              'donation': s.fiscalCategoryDonation,
              'capital_gain': s.fiscalCategoryCapitalGain,
              'other': s.fiscalCategoryOther,
              '': s.removeFiscalTag,
            }.entries)
              ListTile(
                title: Text(entry.value),
                leading: Radio<String>(
                  value: entry.key,
                  groupValue: t.fiscalCategory ?? '',
                  onChanged: (v) {
                    Navigator.pop(context);
                    ctx.read<FiscalBloc>().add(
                      TagTransaction(
                        t.id,
                        fiscalCategory: v!.isEmpty ? null : v,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIrpf(BuildContext ctx, dynamic s) {
    final fmt = CurrencyService().format;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _incomeCtrl,
            decoration: InputDecoration(
              labelText: s.annualIncomeLabel,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _extraCtrl,
            decoration: InputDecoration(
              labelText: s.deductionsLabel,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final income = double.tryParse(_incomeCtrl.text) ?? 0;
              final extra = double.tryParse(_extraCtrl.text) ?? 0;
              ctx.read<FiscalBloc>().add(
                EstimateIrpf(income, extraDeductions: extra),
              );
            },
            child: Text(s.irpfTab),
          ),
          if (_irpfResult != null) ...[
            const SizedBox(height: 24),
            _resultCard(s, _irpfResult!, fmt),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(dynamic s, IrpfResultEntity r, Function fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.estimatedTax, style: AppTypography.titleSmall()),
          const SizedBox(height: 12),
          _row(s.annualIncomeLabel, fmt(r.annualIncome)),
          _row(s.totalDeductible, '- ${fmt(r.deductibleTotal)}'),
          const Divider(),
          _row(s.estimatedTax, fmt(r.estimatedTax), color: AppColors.error),
          _row(s.netIncome, fmt(r.netIncome), color: AppColors.success),
          _row(s.effectiveRate, '${r.effectiveRate.toStringAsFixed(1)}%'),
          const SizedBox(height: 12),
          Text(s.taxBrackets, style: AppTypography.titleSmall()),
          const SizedBox(height: 8),
          for (final b in r.brackets.where((b) => b.taxableAmount > 0))
            _row('${(b.rate * 100).toStringAsFixed(0)}%', fmt(b.tax)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium(color: AppColors.gray600),
          ),
          Text(value, style: AppTypography.titleSmall(color: color)),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext ctx, dynamic s) {
    if (_calendarEvents.isEmpty) {
      return Center(
        child: Text(
          s.noFiscalData,
          style: AppTypography.bodyMedium(color: AppColors.gray500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _calendarEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = _calendarEvents[i];
        return ListTile(
          tileColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: e.isPast ? AppColors.gray200 : AppColors.primary,
            ),
          ),
          leading: Icon(
            e.type == 'annual' ? Icons.event_rounded : Icons.repeat_rounded,
            color: e.isPast ? AppColors.gray400 : AppColors.primary,
          ),
          title: Text(
            e.title,
            style: AppTypography.bodyMedium(
              color: e.isPast ? AppColors.gray400 : null,
            ),
          ),
          subtitle: Text(e.date),
          trailing: e.isPast
              ? Icon(Icons.check_circle_rounded, color: AppColors.gray400)
              : null,
        );
      },
    );
  }

  Widget _buildExport(BuildContext ctx, dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, color: AppColors.primary, size: 64),
            const SizedBox(height: 16),
            Text(
              s.exportFiscalDesc,
              style: AppTypography.bodyMedium(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ctx.read<FiscalBloc>().add(const ExportFiscal()),
              icon: const Icon(Icons.download_rounded),
              label: Text(s.exportFiscalBtn),
            ),
          ],
        ),
      ),
    );
  }
}
