import 'dart:async';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_account_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_card_entity.dart';
import 'package:finora_frontend/features/banks/presentation/bloc/bank_bloc.dart';
import 'package:finora_frontend/features/banks/presentation/bloc/bank_event.dart';
import 'package:finora_frontend/features/banks/presentation/bloc/bank_state.dart';
import 'package:finora_frontend/features/banks/presentation/pages/bank_account_selection_page.dart';
import 'package:finora_frontend/features/banks/presentation/pages/bank_account_setup_page.dart';
import 'package:finora_frontend/features/banks/presentation/pages/bank_connecting_page.dart';
import 'package:finora_frontend/features/banks/presentation/pages/institution_selector_sheet.dart';
import 'package:finora_frontend/features/banks/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/currency_service.dart';
import 'package:finora_frontend/shared/widgets/skeleton_loader.dart';

/// Página de Cuentas (RF-10)
///
/// Muestra el balance calculado desde transacciones y las cuentas bancarias
/// conectadas a través de Open Banking PSD2 (GoCardless).
class AccountsPage extends StatefulWidget {
  /// RF-12: callback que se llama cuando el usuario quiere ver las transacciones
  /// de una cuenta bancaria específica. Recibe accountId y accountName.
  final void Function(String accountId, String accountName)?
  onViewAccountTransactions;

  /// Callback para volver a la pantalla de módulos cuando AccountsPage
  /// está integrada en el IndexedStack de HomePage.
  final VoidCallback? onBack;

  const AccountsPage({super.key, this.onViewAccountTransactions, this.onBack});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  int _cashInitialCents = 0;
  bool _cashSetupDone = false;

  /// HU-06: Fecha de la última sincronización exitosa (para indicador global).
  DateTime? _lastGlobalSyncAt;

  /// HU-06: Cantidad de transacciones importadas en la última sync.
  int _lastImportedCount = 0;

  /// RNF-07: Duración de la última sync en milisegundos.
  int? _lastSyncDurationMs;

  @override
  void initState() {
    super.initState();
    _loadCashPrefs();
    _loadLastSyncPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BankBloc>().add(const LoadBankAccounts());
        // RF-11: comprobar si procede sincronización periódica
        context.read<BankBloc>().add(const CheckPeriodicSyncRequested());
      }
    });
  }

  /// HU-06: Carga la fecha de última sync desde SharedPreferences.
  Future<void> _loadLastSyncPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('last_bank_import_ms');
    if (ms != null && mounted) {
      setState(() {
        _lastGlobalSyncAt = DateTime.fromMillisecondsSinceEpoch(ms);
      });
    }
  }

  /// RF-11: Pull-to-refresh — importa transacciones de todas las conexiones
  Future<void> _onPullToRefresh(BuildContext context) async {
    context.read<BankBloc>().add(const ImportBankTransactionsRequested());
    // Esperar hasta que el bloc resuelva el estado (máximo 30 s)
    await context
        .read<BankBloc>()
        .stream
        .firstWhere(
          (s) =>
              s is BankImportSuccess ||
              s is BankAccountsLoaded ||
              s is BankAccountsError ||
              s is BankTokenExpired,
          orElse: () => const BankAccountsLoaded([]),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => const BankAccountsLoaded([]),
        );
  }

  String _getUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.id;
    return 'default';
  }

  Future<void> _loadCashPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final userId = _getUserId();
    final done = prefs.getBool('cash_setup_done_$userId') ?? false;
    setState(() {
      _cashSetupDone = done;
      _cashInitialCents = prefs.getInt('cash_initial_cents_$userId') ?? 0;
    });
    if (!done && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCashSetupDialog(context);
      });
    }
  }

  Future<void> _saveCashPrefs(int cents) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _getUserId();
    await prefs.setInt('cash_initial_cents_$userId', cents);
    await prefs.setBool('cash_setup_done_$userId', true);
    if (!mounted) return;
    setState(() {
      _cashInitialCents = cents;
      _cashSetupDone = true;
    });
  }

  /// Calcula el balance de efectivo:
  /// dinero inicial configurado + Σ transacciones en efectivo
  double _cashBalance(TransactionState txState) {
    double balance = _cashInitialCents / 100.0;
    if (txState is TransactionsLoaded) {
      for (final t in txState.transactions) {
        if (t.paymentMethod == PaymentMethod.cash) {
          balance += t.isIncome ? t.amount : -t.amount;
        }
      }
    }
    return balance;
  }

  String _translatePaymentMethod(BuildContext context, String method) {
    final s = AppLocalizations.of(context);

    // Normalizamos: pasamos a minúsculas y quitamos espacios extra para asegurar el match
    final m = method.toLowerCase().trim();

    switch (m) {
      // --- Efectivo ---
      case 'efectivo':
      case 'cash':
        return s.paymentCash;

      // --- Tarjetas ---
      case 'tarjeta de débito':
      case 'débito':
      case 'debit card':
        return s.pmDebitCard;
      case 'tarjeta de crédito':
      case 'crédito':
      case 'credit card':
        return s.pmCreditCard;
      case 'tarjeta prepago':
      case 'prepago':
      case 'prepaid card':
        return s.pmPrepaidCard;
      case 'tarjeta':
      case 'card':
        return s.pmCard;

      // --- Transferencias ---
      case 'transferencia bancaria':
      case 'transferencia':
      case 'bank transfer':
      case 'transfer.': // Por si viene con el punto del label corto
        return s.pmBankTransfer;
      case 'transferencia sepa':
      case 'sepa':
        return s.pmSepa;
      case 'transferencia internacional':
      case 'wire':
        return s.pmWire;

      // --- Bancarios / Recibos ---
      case 'domiciliación/recibo':
      case 'recibo':
      case 'direct debit':
        return s.pmDirectDebit;
      case 'cheque':
      case 'check':
        return s.paymentCheque;
      case 'cupón/vale':
      case 'vale':
      case 'voucher':
        return s.pmVoucher;

      // --- Digitales (Nombres propios, se quedan igual) ---
      case 'bizum':
        return 'Bizum';
      case 'paypal':
        return 'PayPal';
      case 'apple pay':
        return 'Apple Pay';
      case 'google pay':
        return 'Google Pay';

      // --- Cripto ---
      case 'criptomonedas':
      case 'cripto':
      case 'crypto':
        return s.pmCrypto;

      // --- Fallback ---
      default:
        // Si no hay match, devolvemos el texto original capitalizado
        if (method.isEmpty) return '';
        return method[0].toUpperCase() + method.substring(1);
    }
  }

  Future<void> _showCashSetupDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _cashSetupDone
          ? (_cashInitialCents / 100.0).toStringAsFixed(2)
          : '',
    );
    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).cashMoney),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).howMuchCash,
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).cashSetupInfo,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              decoration: InputDecoration(
                prefixText: '${AppSettingsService().currentCurrency.symbol} ',
                hintText: '0,00',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final raw = controller.text
                  .replaceAll('.', '')
                  .replaceAll(',', '.');
              final amount = double.tryParse(raw) ?? 0.0;
              Navigator.pop(ctx, (amount * 100).round());
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _saveCashPrefs(result);
    }
  }

  String _formatCurrency(double amount) => CurrencyService().format(amount);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    if (responsive.isTablet) {
      return _buildTabletLayout(context);
    }

    return Material(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _onPullToRefresh(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    16,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onBack != null)
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: widget.onBack,
                              color: AppColors.textPrimaryLight,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          Text(
                            AppLocalizations.of(context).accounts,
                            style: AppTypography.headlineSmall(),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // HU-06: Campana de notificaciones in-app
                          const NotificationBell(),
                          const SizedBox(width: 4),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add_rounded),
                              onPressed: () => _connectBank(context),
                              color: AppColors.white,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Balance calculado desde transacciones
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    20,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: _buildTransactionBalance(context),
                ),
              ),

              // Tarjeta de efectivo
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    16,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: _buildCashCard(context),
                ),
              ),

              // Saldo de cuentas bancarias
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    20,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: _buildBankAccountsSection(context),
                ),
              ),

              // Conectar cuenta bancaria
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    20,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: _buildConnectBankCard(context),
                ),
              ),

              // Métodos de pago
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    20,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: _buildPaymentMethodsSummary(context),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: responsive.hp(12))),
            ],
          ), // CustomScrollView
        ), // RefreshIndicator
      ), // SafeArea
    );
  }

  // ─── Tablet Layout ───────────────────────────────────────────────────────────

  Widget _buildTabletLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Material(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _onPullToRefresh(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header — full width
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    16,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onBack != null)
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: widget.onBack,
                              color: AppColors.textPrimaryLight,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          Text(
                            AppLocalizations.of(context).accounts,
                            style: AppTypography.headlineSmall(),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const NotificationBell(),
                          const SizedBox(width: 4),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add_rounded),
                              onPressed: () => _connectBank(context),
                              color: AppColors.white,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Balance card — centered, constrained to 900px
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    20,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _buildTransactionBalance(context),
                    ),
                  ),
                ),
              ),

              // Cash card — centered, constrained to 900px
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    16,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _buildCashCard(context),
                    ),
                  ),
                ),
              ),

              // Bank accounts section — centered, constrained to 900px
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    20,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _buildBankAccountsSection(context),
                    ),
                  ),
                ),
              ),

              // Connect bank button — centered, constrained to 900px
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    20,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _buildConnectBankCard(context),
                    ),
                  ),
                ),
              ),

              // Payment methods — centered, constrained to 900px
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    20,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _buildPaymentMethodsSummary(context),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: responsive.hp(12))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionBalance(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
        final expenses = state is TransactionsLoaded
            ? state.totalExpenses
            : 0.0;
        // El efectivo inicial configurado no es una transacción, se suma aparte
        final balance = income - expenses + (_cashInitialCents / 100.0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.premiumGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.shadowColor(AppColors.primaryDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).transactionBalance,
                    style: AppTypography.labelMedium(
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppLocalizations.of(context).realData,
                      style: AppTypography.badge(color: AppColors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _formatCurrency(balance),
                style: AppTypography.moneyLarge(color: AppColors.white),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.successLight.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.south_west_rounded,
                              color: AppColors.successLight,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).incomes,
                                  style: AppTypography.labelSmall(
                                    color: AppColors.white.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatCurrency(income),
                                  style: AppTypography.titleSmall(
                                    color: AppColors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.white.withValues(alpha: 0.15),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.north_east_rounded,
                              color: AppColors.errorLight,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).expenses,
                                  style: AppTypography.labelSmall(
                                    color: AppColors.white.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatCurrency(expenses),
                                  style: AppTypography.titleSmall(
                                    color: AppColors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  // Tarjeta de efectivo
  // ──────────────────────────────────────────────────────────

  Widget _buildCashCard(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, txState) {
        final cashBalance = _cashBalance(txState);
        final isNegative = cashBalance < 0;
        return GestureDetector(
          onTap: () => _showCashSetupDialog(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).cashMoney,
                        style: AppTypography.bodySmall(
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        _formatCurrency(cashBalance),
                        style: AppTypography.moneyMedium(
                          color: isNegative
                              ? const Color(0xFFFFADAD)
                              : AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  // Bank accounts section (RF-10)
  // ──────────────────────────────────────────────────────────

  Widget _buildBankAccountsSection(BuildContext context) {
    return BlocConsumer<BankBloc, BankState>(
      listener: (context, state) {
        if (state is BankPendingAccountsReady && !state.isImporting) {
          // Sandbox mode: dejar al usuario elegir qué cuentas vincular
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<BankBloc>(),
                child: BankAccountSelectionPage(
                  connectionId: state.connectionId,
                  institutionName: state.institutionName,
                  pendingAccounts: state.pendingAccounts,
                ),
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              context.read<BankBloc>().add(const LoadBankAccounts());
            }
          });
        } else if (state is BankConnectPendingSetup) {
          // Mock mode: navigate to setup page to configure the account
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<BankBloc>(),
                child: BankAccountSetupPage(
                  connectionId: state.connectionId,
                  institutionName: state.institutionName,
                ),
              ),
            ),
          );
        } else if (state is BankConnectAuthUrlReady) {
          // Real mode: navigate to waiting page that polls until linked
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<BankBloc>(),
                child: BankConnectingPage(
                  connectionId: state.connectionId,
                  institutionName: state.institutionName,
                  authUrl: state.authUrl,
                ),
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              context.read<BankBloc>().add(const LoadBankAccounts());
            }
          });
        } else if (state is BankConnectSuccess) {
          // Reload transactions immediately so the dashboard and history
          // reflect the newly imported demo transactions without restart.
          context.read<TransactionBloc>().add(LoadTransactions());
        } else if (state is BankAccountsLoaded) {
          // HU-06: limpiar el contador de nuevas cuando se recarga sin importar
          if (_lastImportedCount > 0) {
            setState(() => _lastImportedCount = 0);
          }
        } else if (state is BankConnectFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).connectionError}: ${state.message}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          // RF-13: confirmación de desconexión exitosa con revocación de token
        } else if (state is BankDisconnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.link_off_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.accountName.isNotEmpty
                          ? '${state.accountName} ${AppLocalizations.of(context).disconnectedAccessRevoked}'
                          : AppLocalizations.of(
                              context,
                            ).accountDisconnectedAccessRevoked,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is BankAccountsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).accountsErrorPrefix} ${state.message}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          // RF-11 + HU-06: Actualizar indicador de última sync y contador de nuevas transacciones
        } else if (state is BankImportSuccess) {
          // HU-06 + RNF-07: actualizar indicador global de última sync + duración
          setState(() {
            _lastGlobalSyncAt = state.lastSyncAt ?? DateTime.now();
            _lastImportedCount = state.imported;
            _lastSyncDurationMs = state.durationMs;
          });
          // RNF-05: mostrar aviso de renovación de consentimiento si quedan ≤14 días
          if (state.consentDaysRemaining != null &&
              state.consentDaysRemaining! <= 14) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).psd2ExpiryMsg(state.consentDaysRemaining!),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 6),
              ),
            );
          }
          final msg = state.imported > 0
              ? '${state.imported} ${AppLocalizations.of(context).newLabel(state.imported)} ${AppLocalizations.of(context).transactionCountLabel(state.imported)} ${AppLocalizations.of(context).connectedLabel(state.imported)}'
              : AppLocalizations.of(context).syncCompleteNoNews;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.sync_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(msg),
                ],
              ),
              backgroundColor: state.imported > 0
                  ? AppColors.success
                  : AppColors.gray400,
              duration: const Duration(seconds: 4),
            ),
          );
          // RF-11: Token expirado — pedir re-autenticación
        } else if (state is BankTokenExpired) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context).bankSessionExpired),
              content: Text(
                '${AppLocalizations.of(context).bankSessionExpiredMsg}'
                '${AppLocalizations.of(context).bankReconnectInfo}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context).notNow),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _connectBank(context);
                  },
                  child: Text(AppLocalizations.of(context).reconnect),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        final accounts = state is BankAccountsLoaded
            ? state.accounts
            : state is BankImportSuccess
            ? state.accounts
            : state is BankConnectSuccess
            ? state.accounts
            : <BankAccountEntity>[];
        final isLoading =
            state is BankAccountsLoading ||
            state is BankSyncing ||
            state is BankDisconnecting ||
            state is BankImportInProgress; // RF-11

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).bankAccounts,
                  style: AppTypography.titleMedium(),
                ),
                const Spacer(),
                // HU-06: Badge de nuevas transacciones (visible tras la última sync)
                if (_lastImportedCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_downward_rounded,
                          size: 10,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+$_lastImportedCount ${AppLocalizations.of(context).newLabel(_lastImportedCount)}',
                          style: AppTypography.badge(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (accounts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 10,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${accounts.length} ${AppLocalizations.of(context).connectedLabel(accounts.length)}',
                          style: AppTypography.badge(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // HU-06 + RNF-07: Indicador global de última sincronización con duración
            if (_lastGlobalSyncAt != null) ...[
              const SizedBox(height: 6),
              _GlobalSyncBar(
                lastSyncAt: _lastGlobalSyncAt!,
                isSyncing: isLoading,
                durationMs: _lastSyncDurationMs,
                onSyncNow: () => context.read<BankBloc>().add(
                  const ImportBankTransactionsRequested(),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // RNF-07: Tarjeta de progreso visible mientras se sincroniza
            if (state is BankImportInProgress)
              const _SyncProgressCard()
            else if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: SkeletonListLoader(count: 3, cardHeight: 88),
              )
            else if (accounts.isEmpty)
              _buildEmptyBanksCard(context)
            else ...[
              // RF-12: Balance consolidado cuando hay múltiples cuentas
              if (accounts.length > 1) _buildConsolidatedBalance(accounts),
              ...accounts.map(
                (acct) => _BankAccountCard(
                  account: acct,
                  onDisconnect: () => _confirmDisconnect(context, acct),
                  onEdit: () => _openEditCardsSheet(context, acct),
                  // RF-12: navegar a transacciones filtradas por esta cuenta
                  onViewTransactions: widget.onViewAccountTransactions != null
                      ? () => widget.onViewAccountTransactions!(
                          acct.id,
                          acct.accountName,
                        )
                      : null,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildConnectBankCard(BuildContext context) {
    return BlocBuilder<BankBloc, BankState>(
      builder: (context, state) {
        final hasAccounts =
            (state is BankAccountsLoaded && state.accounts.isNotEmpty) ||
            (state is BankImportSuccess && state.accounts.isNotEmpty);
        if (hasAccounts) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.link_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context).connectBank,
                style: AppTypography.titleMedium(),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).syncPsd2Info,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _connectBank(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_link_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).connectAccount,
                        style: AppTypography.labelLarge(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyBanksCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 40,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).noConnectedAccounts,
            style: AppTypography.titleSmall(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).connectBankForSync,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
          ),
        ],
      ),
    );
  }

  // RF-12: Balance consolidado de todas las cuentas bancarias conectadas
  Widget _buildConsolidatedBalance(List<BankAccountEntity> accounts) {
    final totalCents = accounts.fold<int>(0, (sum, a) => sum + a.balanceCents);
    final total = totalCents / 100.0;
    final isNegative = total < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryDark.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).totalBankBalance,
                  style: AppTypography.labelSmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCurrency(total),
                  style: AppTypography.moneyMedium(
                    color: isNegative ? AppColors.error : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${accounts.length} ${AppLocalizations.of(context).accounts}',
              style: AppTypography.badge(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _connectBank(BuildContext context) {
    InstitutionSelectorSheet.show(context);
  }

  void _openEditCardsSheet(BuildContext context, BankAccountEntity account) {
    final bankBloc = context.read<BankBloc>();
    bankBloc.add(const LoadBankCards());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bankBloc,
        child: _EditCardsSheet(account: account),
      ),
    );
  }

  // RF-13: Confirmación mejorada de desconexión bancaria
  void _confirmDisconnect(BuildContext context, BankAccountEntity account) {
    final bankName = account.institutionName ?? account.accountName;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.link_off_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).disconnectBank,
                style: AppTypography.titleMedium(),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿${AppLocalizations.of(context).disconnect} "$bankName"?',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 12),
            // RF-13: Informar explícitamente qué pasa con las transacciones
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context).disconnectWarningTitle,
                        style: AppTypography.labelSmall(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildDisconnectInfoRow(
                    Icons.check_circle_outline_rounded,
                    AppColors.success,
                    AppLocalizations.of(context).disconnectHistoryKept,
                  ),
                  _buildDisconnectInfoRow(
                    Icons.sync_disabled_rounded,
                    AppColors.warning,
                    AppLocalizations.of(context).disconnectSyncStop,
                  ),
                  _buildDisconnectInfoRow(
                    Icons.delete_outline_rounded,
                    AppColors.error,
                    AppLocalizations.of(context).disconnectRevokeAccess,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // RF-13: pasar accountName para mostrarlo en el SnackBar de éxito
              context.read<BankBloc>().add(
                DisconnectBankRequested(
                  account.connectionId,
                  accountName: account.accountName,
                ),
              );
            },
            icon: const Icon(Icons.link_off_rounded, size: 16),
            label: Text(AppLocalizations.of(context).disconnect),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectInfoRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSummary(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionsLoaded || state.transactions.isEmpty) {
          return const SizedBox.shrink();
        }

        // Count transactions by payment method
        final methodCounts = <String, int>{};
        final methodAmounts = <String, double>{};
        for (final t in state.transactions) {
          final label = t.paymentMethod.label;
          methodCounts[label] = (methodCounts[label] ?? 0) + 1;
          methodAmounts[label] = (methodAmounts[label] ?? 0) + t.amount;
        }

        final sortedMethods = methodCounts.keys.toList()
          ..sort((a, b) => methodCounts[b]!.compareTo(methodCounts[a]!));

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).usageByPaymentMethod,
                style: AppTypography.titleMedium(),
              ),
              const SizedBox(height: 16),
              ...sortedMethods.map((method) {
                final count = methodCounts[method]!;
                final amount = methodAmounts[method]!;
                final icon = _getPaymentMethodIcon(method);
                final color = _getPaymentMethodColor(method);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _translatePaymentMethod(context, method),
                              style: AppTypography.titleSmall(),
                            ),
                            Text(
                              '$count ${AppLocalizations.of(context).transactions}',
                              style: AppTypography.bodySmall(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(amount),
                        style: AppTypography.titleSmall(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Efectivo':
        return Icons.payments_outlined;
      case 'Tarjeta de débito':
      case 'Tarjeta':
        return Icons.payment_rounded;
      case 'Tarjeta de crédito':
        return Icons.credit_card_rounded;
      case 'Tarjeta prepago':
        return Icons.contactless_rounded;
      case 'Transferencia bancaria':
      case 'Transferencia':
        return Icons.swap_horiz_rounded;
      case 'Transferencia SEPA':
        return Icons.account_balance_outlined;
      case 'Transferencia internacional':
        return Icons.language_rounded;
      case 'Bizum':
        return Icons.phone_android_rounded;
      case 'PayPal':
        return Icons.account_balance_wallet_outlined;
      case 'Apple Pay':
        return Icons.apple_rounded;
      case 'Google Pay':
        return Icons.g_mobiledata_rounded;
      case 'Domiciliación/Recibo':
        return Icons.autorenew_rounded;
      case 'Cheque':
        return Icons.article_outlined;
      case 'Cupón/Vale':
        return Icons.local_offer_outlined;
      case 'Criptomonedas':
        return Icons.currency_bitcoin_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'Efectivo':
        return AppColors.success;
      case 'Tarjeta de débito':
      case 'Tarjeta':
        return AppColors.primary;
      case 'Tarjeta de crédito':
        return Colors.deepOrange;
      case 'Tarjeta prepago':
        return Colors.teal;
      case 'Transferencia bancaria':
      case 'Transferencia':
        return AppColors.accent;
      case 'Transferencia SEPA':
      case 'Transferencia internacional':
        return Colors.indigo;
      case 'Bizum':
        return Colors.blue;
      case 'PayPal':
        return Colors.blue.shade800;
      case 'Apple Pay':
      case 'Google Pay':
        return Colors.grey.shade700;
      case 'Domiciliación/Recibo':
        return Colors.orange;
      case 'Criptomonedas':
        return Colors.amber.shade700;
      default:
        return AppColors.gray500;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// RNF-07: Sync progress card (shown while BankImportInProgress)
// ──────────────────────────────────────────────────────────────────────────────

class _SyncProgressCard extends StatefulWidget {
  const _SyncProgressCard();

  @override
  State<_SyncProgressCard> createState() => _SyncProgressCardState();
}

class _SyncProgressCardState extends State<_SyncProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _elapsed = 0;
  late final _timer = Stream.periodic(const Duration(seconds: 1), (i) => i + 1);
  StreamSubscription<int>? _sub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _sub = _timer.listen((s) {
      if (mounted) setState(() => _elapsed = s);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) => Transform.rotate(
                  angle: _controller.value * 6.28,
                  child: child,
                ),
                child: Icon(
                  Icons.sync_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppLocalizations.of(context).importingTransactions}...',
                style: AppTypography.labelMedium(color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                '${_elapsed}s',
                style: AppTypography.labelSmall(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: null, // indeterminate
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppLocalizations.of(context).syncingPsd2}...',
            style: AppTypography.labelSmall(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// HU-06: Global sync status bar
// ──────────────────────────────────────────────────────────────────────────────

class _GlobalSyncBar extends StatelessWidget {
  final DateTime lastSyncAt;
  final bool isSyncing;
  final VoidCallback onSyncNow;

  /// RNF-07: Duración de la última sync en ms (null si no disponible).
  final int? durationMs;

  const _GlobalSyncBar({
    required this.lastSyncAt,
    required this.isSyncing,
    required this.onSyncNow,
    this.durationMs,
  });

  String _formatRelative(DateTime dt, BuildContext context) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return AppLocalizations.of(context).justNow;
    if (diff.inMinutes < 60) {
      return AppLocalizations.of(context).agoMins(diff.inDays);
    }
    if (diff.inHours < 24) {
      return AppLocalizations.of(context).agoHours(diff.inDays);
    }
    if (diff.inDays == 1) return AppLocalizations.of(context).yesterday;
    if (diff.inDays < 7) {
      return AppLocalizations.of(context).agoDays(diff.inDays);
    }
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.sync_rounded,
          size: 12,
          color: AppColors.textTertiaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          '${AppLocalizations.of(context).lastSync}: ${_formatRelative(lastSyncAt, context)}',
          style: AppTypography.labelSmall(color: AppColors.textTertiaryLight),
        ),
        // RNF-07: Mostrar duración real de la última sync
        if (durationMs != null && durationMs! > 0) ...[
          const SizedBox(width: 4),
          Text(
            '(${(durationMs! / 1000).toStringAsFixed(1)}s)',
            style: AppTypography.labelSmall(color: AppColors.textTertiaryLight),
          ),
        ],
        const Spacer(),
        if (isSyncing)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 1.5,
            ),
          )
        else
          GestureDetector(
            onTap: onSyncNow,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 2),
                Text(
                  AppLocalizations.of(context).synchronize,
                  style: AppTypography.labelSmall(color: AppColors.primary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bank account card widget (RF-10)
// ──────────────────────────────────────────────────────────────────────────────

class _BankAccountCard extends StatelessWidget {
  final BankAccountEntity account;
  final VoidCallback onDisconnect;
  final VoidCallback onEdit;

  /// RF-12: navega a la pestaña de transacciones filtrada por esta cuenta
  final VoidCallback? onViewTransactions;

  const _BankAccountCard({
    required this.account,
    required this.onDisconnect,
    required this.onEdit,
    this.onViewTransactions,
  });

  /// Returns a human-readable relative time string for the last sync.
  String _formatSyncTime(DateTime lastSyncAt, BuildContext context) {
    final diff = DateTime.now().difference(lastSyncAt);
    if (diff.inSeconds < 60) return AppLocalizations.of(context).justNow;
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return AppLocalizations.of(context).agoMins(m);
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return AppLocalizations.of(context).agoHours(h);
    }
    if (diff.inDays == 1) return AppLocalizations.of(context).yesterday;
    if (diff.inDays < 7) {
      return AppLocalizations.of(context).agoDays(diff.inDays);
    }
    // Fallback to dd/MM/yyyy
    final d = lastSyncAt.day.toString().padLeft(2, '0');
    final mo = lastSyncAt.month.toString().padLeft(2, '0');
    final y = lastSyncAt.year;
    return '$d/$mo/$y';
  }

  String _formatBalance(double balance) {
    final isNeg = balance < 0;
    final abs = balance.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final buf = StringBuffer();
    for (int i = 0; i < parts[0].length; i++) {
      if (i > 0 && (parts[0].length - i) % 3 == 0) buf.write('.');
      buf.write(parts[0][i]);
    }
    return '${isNeg ? '-' : ''}${buf.toString()},${parts[1]} ${account.currency}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: account.institutionLogo != null
                    ? Image.network(
                        account.institutionLogo!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.account_balance_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      )
                    : Icon(
                        Icons.account_balance_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.accountName,
                      style: AppTypography.titleSmall(),
                    ),
                    if (account.institutionName != null)
                      Text(
                        account.institutionName!,
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              // Options menu
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'transactions') onViewTransactions?.call();
                  if (v == 'edit') onEdit();
                  if (v == 'disconnect') onDisconnect();
                },
                itemBuilder: (_) => [
                  // RF-12: Ver transacciones de esta cuenta
                  if (onViewTransactions != null)
                    PopupMenuItem(
                      value: 'transactions',
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context).viewTransactions),
                        ],
                      ),
                    ),
                  if (onViewTransactions != null) const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.credit_card_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context).editCards),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'disconnect',
                    child: Row(
                      children: [
                        Icon(
                          Icons.link_off_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).disconnect,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.gray400,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).availableBalance,
                    style: AppTypography.labelSmall(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatBalance(account.balance),
                    style: AppTypography.moneyMedium(),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'IBAN',
                    style: AppTypography.labelSmall(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(account.maskedIban, style: AppTypography.bodySmall()),
                ],
              ),
            ],
          ),
          if (account.lastSyncAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        size: 10,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${AppLocalizations.of(context).synchronized} ${_formatSyncTime(account.lastSyncAt!, context)}',
                        style: AppTypography.badge(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Edit cards bottom sheet
// ──────────────────────────────────────────────────────────────────────────────

class _EditCardsSheet extends StatefulWidget {
  final BankAccountEntity account;
  const _EditCardsSheet({required this.account});

  @override
  State<_EditCardsSheet> createState() => _EditCardsSheetState();
}

class _EditCardsSheetState extends State<_EditCardsSheet> {
  List<BankCardEntity> _cards = [];
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BankBloc, BankState>(
      listener: (ctx, state) {
        if (state is BankCardsLoaded) {
          setState(() {
            _cards = state.cards
                .where((c) => c.bankAccountId == widget.account.id)
                .toList();
            _loading = false;
          });
        } else if (state is BankCardAdded || state is BankCardDeleted) {
          ctx.read<BankBloc>().add(const LoadBankCards());
        }
      },
      builder: (ctx, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).cardsLabel,
                          style: AppTypography.titleLarge(),
                        ),
                        Text(
                          widget.account.accountName,
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddCardSheet(ctx),
                    icon: Icon(
                      Icons.add_card_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      AppLocalizations.of(context).add,
                      style: AppTypography.labelMedium(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: SkeletonListLoader(count: 2, cardHeight: 72),
                )
              else if (_cards.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card_outlined,
                        color: AppColors.gray300,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context).noCardsAdd,
                        style: AppTypography.bodyMedium(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...(_cards.map((card) => _buildCardTile(ctx, card))),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardTile(BuildContext ctx, BankCardEntity card) {
    final icon = card.cardType == 'credit'
        ? Icons.credit_card_rounded
        : card.cardType == 'prepaid'
        ? Icons.contactless_rounded
        : Icons.payment_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.cardName, style: AppTypography.titleSmall()),
                Text(
                  '${card.cardTypeLabel}${card.lastFour != null ? ' ••••${card.lastFour}' : ''}',
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: () =>
                ctx.read<BankBloc>().add(DeleteBankCardRequested(card.id)),
          ),
        ],
      ),
    );
  }

  void _showAddCardSheet(BuildContext ctx) {
    showModalBottomSheet<_CardData>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCardInSheet(),
    ).then((data) {
      if (data != null && ctx.mounted) {
        ctx.read<BankBloc>().add(
          AddBankCardRequested(
            bankAccountId: widget.account.id,
            cardName: data.name,
            cardType: data.type,
            lastFour: data.lastFour,
          ),
        );
      }
    });
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Simple data class for the add-card sheet result
// ──────────────────────────────────────────────────────────────────────────────

class _CardData {
  final String name;
  final String type;
  final String? lastFour;
  _CardData({required this.name, required this.type, this.lastFour});
}

// ──────────────────────────────────────────────────────────────────────────────
// Add card bottom sheet (used from the edit sheet)
// ──────────────────────────────────────────────────────────────────────────────

class _AddCardInSheet extends StatefulWidget {
  @override
  State<_AddCardInSheet> createState() => _AddCardInSheetState();
}

class _AddCardInSheetState extends State<_AddCardInSheet> {
  final _nameCtrl = TextEditingController();
  final _lastFourCtrl = TextEditingController();
  String _cardType = 'debit';

  static const _cardTypes = [
    ('debit', 'Débito'),
    ('credit', 'Crédito'),
    ('prepaid', 'Prepago'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastFourCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).addCardTitle,
            style: AppTypography.titleLarge(),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).type,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _cardTypes.map((t) {
              final selected = _cardType == t.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _cardType = t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.gray200,
                      ),
                    ),
                    child: Text(
                      t.$2,
                      style: AppTypography.labelMedium(
                        color: selected
                            ? AppColors.white
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).name,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: AppTypography.bodyMedium(),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).exampleCardName,
              hintStyle: AppTypography.bodyMedium(
                color: AppColors.textTertiaryLight,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).lastFourDigitsOptional,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lastFourCtrl,
            style: AppTypography.bodyMedium(),
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              hintText: '1234',
              counterText: '',
              hintStyle: AppTypography.bodyMedium(
                color: AppColors.textTertiaryLight,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).enterAccountNameError,
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                _CardData(
                  name: name,
                  type: _cardType,
                  lastFour: _lastFourCtrl.text.trim().isNotEmpty
                      ? _lastFourCtrl.text.trim()
                      : null,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).addCardTitle,
                  style: AppTypography.labelLarge(color: AppColors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
