import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/services/currency_service.dart';
import 'package:finora_frontend/shared/widgets/skeleton_loader.dart';
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

  // ── IRPF Wizard state ───────────────────────────────────────────────────
  int _irpfStep = 0; // 0..4
  int _maritalStatus = 0; // 0=soltero, 1=casado, 2=viudo
  int _children = 0;
  int _disability = 0; // 0, 33, 65, 75
  final _salaryCtrl = TextEditingController();
  final _freelanceCtrl = TextEditingController();
  final _rentalCtrl = TextEditingController();
  final _capitalGainsCtrl = TextEditingController();
  final _pensionCtrl = TextEditingController();
  final _housingCtrl = TextEditingController();
  final _donationsCtrl = TextEditingController();

  double _parseCtrl(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;

  double _computePersonalMinimum() {
    double min = 5550.0;
    // Mínimo por descendientes (valores aproximados 2024)
    const childDeductions = [2400.0, 2700.0, 4000.0, 4500.0];
    for (int i = 0; i < _children && i < childDeductions.length; i++) {
      min += childDeductions[i];
    }
    if (_children > 4) min += 4500.0 * (_children - 4);
    // Mínimo por discapacidad del contribuyente
    if (_disability >= 75) {
      min += 12000.0;
    } else if (_disability >= 65) {
      min += 9000.0;
    } else if (_disability >= 33) {
      min += 3000.0;
    }
    return min;
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _salaryCtrl.dispose();
    _freelanceCtrl.dispose();
    _rentalCtrl.dispose();
    _capitalGainsCtrl.dispose();
    _pensionCtrl.dispose();
    _housingCtrl.dispose();
    _donationsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
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
          } else if (state is FiscalExportReady) {
            _shareExportFile(state.filePath, state.format, s);
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
                isScrollable: !responsive.isTablet,
                tabAlignment: responsive.isTablet
                    ? TabAlignment.fill
                    : TabAlignment.start,
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
                : Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: responsive.isTablet ? 800 : double.infinity,
                      ),
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _buildDeductibles(ctx, s),
                          _buildIrpf(ctx, s),
                          _buildCalendar(ctx, s),
                          _buildExport(ctx, s),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _shareExportFile(String path, String format, dynamic s) async {
    try {
      final file = XFile(
        path,
        mimeType: format == 'xlsx'
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'text/csv',
      );
      await Share.shareXFiles([file], subject: s.exportShareTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildDeductibles(BuildContext ctx, dynamic s) {
    final fmt = CurrencyService().format;
    return Column(
      children: [
        if (_totalDeductible > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _deductibles.isEmpty
                      ? s.noFiscalData
                      : '${_deductibles.length} gastos deducibles',
                  style: AppTypography.bodySmall(color: AppColors.gray500),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showAllTransactionsSheet(ctx, s),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(s.markDeductible),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cardLight,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (_deductibles.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 56,
                    color: AppColors.gray300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.noFiscalData,
                    style: AppTypography.bodyMedium(color: AppColors.gray500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pulsa "Marcar como deducible" para etiquetar gastos',
                    style: AppTypography.bodySmall(color: AppColors.gray400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _deductibles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final t = _deductibles[i];
                return _deductibleTile(ctx, t, fmt, s);
              },
            ),
          ),
      ],
    );
  }

  Widget _deductibleTile(
    BuildContext ctx,
    FiscalTransactionEntity t,
    Function fmt,
    dynamic s,
  ) {
    final categoryColor = _categoryColor(t.fiscalCategory);
    return ListTile(
      tileColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.gray200),
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: categoryColor.withValues(alpha: 0.15),
        child: Icon(
          _categoryIcon(t.fiscalCategory),
          size: 18,
          color: categoryColor,
        ),
      ),
      title: Text(
        t.description,
        style: AppTypography.bodyMedium(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _categoryLabel(t.fiscalCategory, s),
        style: AppTypography.bodySmall(color: categoryColor),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            fmt(t.amount),
            style: AppTypography.titleSmall(color: AppColors.primary),
          ),
          Text(
            t.date.substring(0, 10),
            style: AppTypography.bodySmall(color: AppColors.gray400),
          ),
        ],
      ),
      onTap: () => _showTagDialog(ctx, t, s),
    );
  }

  Color _categoryColor(String? cat) {
    switch (cat) {
      case 'freelance':
        return const Color(0xFF6C63FF);
      case 'donation':
        return const Color(0xFF4CAF50);
      case 'capital_gain':
        return const Color(0xFFFF9800);
      default:
        return AppColors.gray500;
    }
  }

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'freelance':
        return Icons.work_rounded;
      case 'donation':
        return Icons.volunteer_activism_rounded;
      case 'capital_gain':
        return Icons.trending_up_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  String _categoryLabel(String? cat, dynamic s) {
    switch (cat) {
      case 'freelance':
        return s.fiscalCategoryFreelance;
      case 'donation':
        return s.fiscalCategoryDonation;
      case 'capital_gain':
        return s.fiscalCategoryCapitalGain;
      case 'other':
        return s.fiscalCategoryOther;
      default:
        return cat ?? '';
    }
  }

  void _showAllTransactionsSheet(BuildContext ctx, dynamic s) {
    // Capturamos el bloc ANTES de abrir el sheet para evitar problemas de contexto.
    // NO disparamos LoadAllTransactions aquí: lo hace el propio sheet en su initState
    // para evitar que la página principal muestre el skeleton loader mientras el sheet está abierto.
    final bloc = ctx.read<FiscalBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _AllTransactionsSheet(
          onTag: (id, cat) {
            bloc.add(TagTransaction(id, fiscalCategory: cat));
          },
          s: s,
        ),
      ),
    );
  }

  void _showTagDialog(BuildContext ctx, FiscalTransactionEntity t, dynamic s) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.tagAsFiscal),
        content: RadioGroup<String>(
          groupValue: t.fiscalCategory ?? '',
          onChanged: (v) {
            Navigator.pop(context);
            ctx.read<FiscalBloc>().add(
              TagTransaction(t.id, fiscalCategory: v!.isEmpty ? null : v),
            );
          },
          child: Column(
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
                  leading: Radio<String>(value: entry.key),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── IRPF Wizard ────────────────────────────────────────────────────────────

  Widget _buildIrpf(BuildContext ctx, dynamic s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título del simulador
          Text(s.irpfSimulatorTitle, style: AppTypography.titleMedium()),
          const SizedBox(height: 12),
          // Indicador de pasos
          _buildStepIndicator(s),
          const SizedBox(height: 20),
          // Contenido del paso actual
          _buildCurrentStep(ctx, s),
          const SizedBox(height: 20),
          // Botones de navegación
          _buildStepNavButtons(ctx, s),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(dynamic s) {
    const stepTitles = ['1', '2', '3', '4', '5'];
    return Row(
      children: List.generate(5, (i) {
        final isActive = i == _irpfStep;
        final isDone = i < _irpfStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  color: isDone || isActive
                      ? AppColors.primary
                      : AppColors.gray200,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.primary
                      : isActive
                      ? AppColors.primary
                      : AppColors.gray200,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          stepTitles[i],
                          style: AppTypography.bodySmall(
                            color: isActive ? Colors.white : AppColors.gray500,
                          ),
                        ),
                ),
              ),
              if (i < 4)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    color: isDone ? AppColors.primary : AppColors.gray200,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(BuildContext ctx, dynamic s) {
    switch (_irpfStep) {
      case 0:
        return _buildStep1(s);
      case 1:
        return _buildStep2(s);
      case 2:
        return _buildStep3(s);
      case 3:
        return _buildStep4(s);
      case 4:
        return _buildStep5(ctx, s);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.irpfStep1Title, style: AppTypography.titleSmall()),
        const SizedBox(height: 4),
        Text(
          s.irpfStep1Subtitle,
          style: AppTypography.bodySmall(color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        // Estado civil
        Text(
          s.irpfMaritalStatusLabel,
          style: AppTypography.labelSmall(color: AppColors.gray600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(s.irpfMaritalSingle)),
            ButtonSegment(value: 1, label: Text(s.irpfMaritalMarried)),
            ButtonSegment(value: 2, label: Text(s.irpfMaritalWidow)),
          ],
          selected: {_maritalStatus},
          onSelectionChanged: (v) => setState(() => _maritalStatus = v.first),
          style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
        const SizedBox(height: 16),
        // Hijos a cargo
        Text(
          s.irpfChildrenLabel,
          style: AppTypography.labelSmall(color: AppColors.gray600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.outlined(
              icon: const Icon(Icons.remove),
              onPressed: _children > 0
                  ? () => setState(() => _children--)
                  : null,
            ),
            const SizedBox(width: 16),
            Text('$_children', style: AppTypography.titleMedium()),
            const SizedBox(width: 16),
            IconButton.outlined(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _children++),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Discapacidad
        Text(
          s.irpfDisabilityLabel,
          style: AppTypography.labelSmall(color: AppColors.gray600),
        ),
        const SizedBox(height: 8),
        RadioGroup<int>(
          groupValue: _disability,
          onChanged: (v) => setState(() => _disability = v!),
          child: Column(
            children: [
              ...[
                [0, s.irpfDisabilityNone],
                [33, s.irpfDisability33],
                [65, s.irpfDisability65],
                [75, s.irpfDisability75],
              ].map(
                (item) => RadioListTile<int>(
                  dense: true,
                  title: Text(
                    item[1] as String,
                    style: AppTypography.bodySmall(),
                  ),
                  value: item[0] as int,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _infoBox(Icons.info_outline_rounded, s.irpfPersonalAllowanceInfo),
      ],
    );
  }

  Widget _buildStep2(dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.irpfStep2Title, style: AppTypography.titleSmall()),
        const SizedBox(height: 4),
        Text(
          s.irpfStep2Subtitle,
          style: AppTypography.bodySmall(color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _salaryCtrl,
          decoration: InputDecoration(
            labelText: s.irpfSalaryLabel,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.euro_rounded),
            filled: true,
            fillColor: AppColors.cardLight,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            if (_totalDeductible > 0) {
              // Aquí reutilizamos los ingresos totales registrados como referencia
              setState(
                () => _salaryCtrl.text = _totalDeductible.toStringAsFixed(2),
              );
            }
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(s.irpfUseTxIncome),
        ),
        const SizedBox(height: 12),
        _infoBox(Icons.lightbulb_outline_rounded, s.irpfSalaryInfo),
      ],
    );
  }

  Widget _buildStep3(dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.irpfStep3Title, style: AppTypography.titleSmall()),
        const SizedBox(height: 4),
        Text(
          s.irpfStep3Subtitle,
          style: AppTypography.bodySmall(color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        _amountField(
          _freelanceCtrl,
          s.irpfFreelanceLabel,
          Icons.work_outline_rounded,
        ),
        const SizedBox(height: 12),
        _amountField(_rentalCtrl, s.irpfRentalLabel, Icons.home_work_outlined),
        const SizedBox(height: 12),
        _amountField(
          _capitalGainsCtrl,
          s.irpfCapitalGainsLabel,
          Icons.trending_up_rounded,
        ),
      ],
    );
  }

  Widget _buildStep4(dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.irpfStep4Title, style: AppTypography.titleSmall()),
        const SizedBox(height: 4),
        Text(
          s.irpfStep4Subtitle,
          style: AppTypography.bodySmall(color: AppColors.gray500),
        ),
        const SizedBox(height: 16),
        _amountFieldWithHint(
          _pensionCtrl,
          s.irpfPensionLabel,
          s.irpfPensionHint,
          Icons.savings_outlined,
        ),
        const SizedBox(height: 12),
        _amountFieldWithHint(
          _housingCtrl,
          s.irpfHousingDeductionLabel,
          s.irpfHousingDeductionHint,
          Icons.house_outlined,
        ),
        const SizedBox(height: 12),
        _amountFieldWithHint(
          _donationsCtrl,
          s.irpfDonationsLabel,
          s.irpfDonationsHint,
          Icons.volunteer_activism_rounded,
        ),
        const SizedBox(height: 12),
        // Gastos deducibles de la app (read-only)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.irpfAppDeductiblesLabel,
                      style: AppTypography.bodySmall(),
                    ),
                    Text(
                      CurrencyService().format(_totalDeductible),
                      style: AppTypography.titleSmall(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep5(BuildContext ctx, dynamic s) {
    final fmt = CurrencyService().format;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.irpfStep5Title, style: AppTypography.titleSmall()),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final salary = _parseCtrl(_salaryCtrl);
            final freelance = _parseCtrl(_freelanceCtrl);
            final rental = _parseCtrl(_rentalCtrl);
            final capital = _parseCtrl(_capitalGainsCtrl);
            final pension = _parseCtrl(_pensionCtrl);
            final housing = _parseCtrl(_housingCtrl);
            final donations = _parseCtrl(_donationsCtrl);
            final personalMin = _computePersonalMinimum();

            final totalIncome = salary + freelance + rental + capital;
            final extraDeductions =
                pension + housing + donations + _totalDeductible + personalMin;

            ctx.read<FiscalBloc>().add(
              EstimateIrpf(totalIncome, extraDeductions: extraDeductions),
            );
          },
          icon: const Icon(Icons.calculate_rounded),
          label: Text(s.irpfCalculateBtn),
        ),
        if (_irpfResult != null) ...[
          const SizedBox(height: 20),
          _resultCard(s, _irpfResult!, fmt),
          const SizedBox(height: 12),
          _buildIrpfInterpretation(s, _irpfResult!),
          const SizedBox(height: 12),
          _buildIrpfTips(s, _irpfResult!),
          const SizedBox(height: 16),
          _infoBox(Icons.info_outline_rounded, s.irpfRentaWebInfo),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(
                'https://www.agenciatributaria.gob.es/AEAT.sede/tramitacion/GI01.shtml',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(s.irpfOpenRentaWebBtn),
          ),
        ],
      ],
    );
  }

  Widget _buildIrpfInterpretation(dynamic s, IrpfResultEntity r) {
    final rate = r.effectiveRate;
    final String text;
    final Color color;
    if (rate < 15) {
      text = s.irpfResultInterpretationLow;
      color = AppColors.success;
    } else if (rate < 25) {
      text = s.irpfResultInterpretationMid;
      color = AppColors.primary;
    } else {
      text = s.irpfResultInterpretationHigh;
      color = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTypography.bodySmall(color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildIrpfTips(dynamic s, IrpfResultEntity r) {
    final tips = <String>[];
    final pension = _parseCtrl(_pensionCtrl);
    if (pension < 1500) tips.add(s.irpfTipPension);
    final donations = _parseCtrl(_donationsCtrl);
    if (donations < 150) tips.add(s.irpfTipDonations);
    if (tips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _infoBox(Icons.tips_and_updates_rounded, tip),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStepNavButtons(BuildContext ctx, dynamic s) {
    return Row(
      children: [
        if (_irpfStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _irpfStep--),
              child: Text(s.irpfPrevBtn),
            ),
          ),
        if (_irpfStep > 0) const SizedBox(width: 12),
        if (_irpfStep < 4)
          Expanded(
            child: FilledButton(
              onPressed: () => setState(() => _irpfStep++),
              child: Text(s.irpfNextBtn),
            ),
          ),
      ],
    );
  }

  Widget _amountField(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.cardLight,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _amountFieldWithHint(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: AppColors.cardLight,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            hint,
            style: AppTypography.bodySmall(color: AppColors.gray400),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.infoDark, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall(color: AppColors.infoDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(dynamic s, IrpfResultEntity r, Function fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Hero: impuesto a pagar ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'Impuesto estimado a pagar',
                style: AppTypography.bodyMedium(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                fmt(r.estimatedTax),
                style: AppTypography.displayLarge(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Tipo efectivo: ${r.effectiveRate.toStringAsFixed(1)}%',
                style: AppTypography.bodySmall(
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Desglose detallado ────────────────────────────────────────────
        Container(
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
              _row(
                s.irpfPersonalMinimum,
                '- ${fmt(_computePersonalMinimum())}',
              ),
              _row(s.totalDeductible, '- ${fmt(r.deductibleTotal)}'),
              _row(
                s.irpfTaxableBase,
                fmt(r.taxableBase),
                color: AppColors.gray600,
              ),
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
        ),
      ],
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
    final year = DateTime.now().year;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.download_rounded, color: AppColors.primary, size: 56),
          const SizedBox(height: 12),
          Text(
            s.exportSelectFormat,
            style: AppTypography.titleSmall(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            s.exportFiscalDesc,
            style: AppTypography.bodySmall(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Excel card
          _exportFormatCard(
            ctx: ctx,
            icon: Icons.table_chart_rounded,
            color: const Color(0xFF217346),
            title: 'Excel (.xlsx)',
            description: s.exportXlsxDesc,
            buttonLabel: 'Exportar Excel',
            onTap: () => ctx.read<FiscalBloc>().add(
              ExportFiscal(year: year, format: 'xlsx'),
            ),
          ),
          const SizedBox(height: 16),
          // CSV card
          _exportFormatCard(
            ctx: ctx,
            icon: Icons.description_rounded,
            color: const Color(0xFF0078D4),
            title: 'CSV',
            description: s.exportCsvDesc,
            buttonLabel: 'Exportar CSV',
            onTap: () => ctx.read<FiscalBloc>().add(
              ExportFiscal(year: year, format: 'csv'),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '* Los archivos exportados son compatibles con la Agencia Tributaria (AEAT) y Renta Web.',
              style: AppTypography.bodySmall(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _exportFormatCard({
    required BuildContext ctx,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall()),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.bodySmall(color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// ── All Transactions Bottom Sheet ─────────────────────────────────────────────

class _AllTransactionsSheet extends StatefulWidget {
  final void Function(String id, String? category) onTag;
  final dynamic s;

  const _AllTransactionsSheet({required this.onTag, required this.s});

  @override
  State<_AllTransactionsSheet> createState() => _AllTransactionsSheetState();
}

class _AllTransactionsSheetState extends State<_AllTransactionsSheet> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Dispara la carga desde dentro del sheet para no afectar el estado de la página principal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FiscalBloc>().add(const LoadAllTransactions());
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = CurrencyService().format;
    final s = widget.s;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.allExpensesTitle, style: AppTypography.titleSmall()),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar gasto...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<FiscalBloc, FiscalState>(
                buildWhen: (prev, current) =>
                    current is FiscalLoading ||
                    current is AllTransactionsLoaded ||
                    current is FiscalError,
                builder: (ctx, state) {
                  if (state is FiscalLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is FiscalError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: AppTypography.bodyMedium(
                                color: AppColors.gray600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => ctx.read<FiscalBloc>().add(
                                const LoadAllTransactions(),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is! AllTransactionsLoaded) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando transacciones...',
                            style: AppTypography.bodyMedium(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final all = state.transactions
                      .where(
                        (t) =>
                            _search.isEmpty ||
                            t.description.toLowerCase().contains(_search) ||
                            (t.category?.toLowerCase().contains(_search) ??
                                false),
                      )
                      .toList();
                  if (state.transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 56,
                              color: AppColors.gray300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay transacciones disponibles',
                              style: AppTypography.titleSmall(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Añade transacciones en la pantalla principal para poder '
                              'marcarlas como gastos deducibles aquí.',
                              style: AppTypography.bodySmall(
                                color: AppColors.gray500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (all.isEmpty) {
                    return Center(
                      child: Text(
                        'Sin resultados para "$_search"',
                        style: AppTypography.bodyMedium(
                          color: AppColors.gray500,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: all.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final t = all[i];
                      final isTagged = t.fiscalCategory != null;
                      return ListTile(
                        tileColor: isTagged
                            ? AppColors.primarySoft
                            : AppColors.surfaceLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isTagged
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.gray200,
                          ),
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isTagged
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.gray100,
                          child: Icon(
                            isTagged
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 18,
                            color: isTagged
                                ? AppColors.primary
                                : AppColors.gray400,
                          ),
                        ),
                        title: Text(
                          t.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium(),
                        ),
                        subtitle: Text(
                          isTagged
                              ? _catLabel(t.fiscalCategory, s)
                              : (t.category ?? ''),
                          style: AppTypography.bodySmall(
                            color: isTagged
                                ? AppColors.primary
                                : AppColors.gray500,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmt(t.amount),
                              style: AppTypography.titleSmall(
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              t.date.substring(0, 10),
                              style: AppTypography.bodySmall(
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showQuickTagMenu(ctx, t, s),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _catLabel(String? cat, dynamic s) {
    switch (cat) {
      case 'freelance':
        return s.fiscalCategoryFreelance;
      case 'donation':
        return s.fiscalCategoryDonation;
      case 'capital_gain':
        return s.fiscalCategoryCapitalGain;
      case 'other':
        return s.fiscalCategoryOther;
      default:
        return cat ?? '';
    }
  }

  void _showQuickTagMenu(
    BuildContext ctx,
    FiscalTransactionEntity t,
    dynamic s,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              t.description,
              style: AppTypography.titleSmall(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            const Divider(),
            for (final entry in {
              'freelance': s.fiscalCategoryFreelance,
              'donation': s.fiscalCategoryDonation,
              'capital_gain': s.fiscalCategoryCapitalGain,
              'other': s.fiscalCategoryOther,
            }.entries)
              ListTile(
                leading: Icon(
                  Icons.label_outline_rounded,
                  color: AppColors.primary,
                ),
                title: Text(entry.value),
                selected: t.fiscalCategory == entry.key,
                selectedColor: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  widget.onTag(t.id, entry.key);
                },
              ),
            if (t.fiscalCategory != null)
              ListTile(
                leading: Icon(Icons.label_off_rounded, color: AppColors.error),
                title: Text(
                  s.removeFiscalTag,
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onTag(t.id, null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
