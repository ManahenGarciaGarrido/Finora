import 'dart:async';
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
import '../../../banks/presentation/bloc/bank_bloc.dart';
import '../../../banks/presentation/bloc/bank_event.dart';
import '../../../banks/presentation/bloc/bank_state.dart';
import '../../../banks/domain/entities/bank_account_entity.dart';
import '../../../banks/domain/entities/bank_card_entity.dart';
import '../../../banks/presentation/pages/institution_selector_sheet.dart';
import '../../../banks/presentation/pages/bank_connecting_page.dart';
import '../../../banks/presentation/pages/bank_account_setup_page.dart';
import '../../../banks/presentation/pages/bank_account_selection_page.dart';
import '../../../banks/presentation/widgets/notification_bell.dart';

/// Página de Cuentas (RF-10)
///
/// Muestra el balance calculado desde transacciones y las cuentas bancarias
/// conectadas a través de Open Banking PSD2 (GoCardless).
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

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

  Future<void> _loadCashPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final done = prefs.getBool('cash_setup_done') ?? false;
    setState(() {
      _cashSetupDone = done;
      _cashInitialCents = prefs.getInt('cash_initial_cents') ?? 0;
    });
    if (!done && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCashSetupDialog(context);
      });
    }
  }

  Future<void> _saveCashPrefs(int cents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cash_initial_cents', cents);
    await prefs.setBool('cash_setup_done', true);
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
        title: const Text('Dinero en efectivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cuánto efectivo tienes ahora mismo?',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 4),
            Text(
              'A partir de aquí, Finora irá sumando tus ingresos y restando tus gastos en efectivo.',
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
              decoration: const InputDecoration(
                prefixText: '€ ',
                hintText: '0,00',
                border: OutlineInputBorder(),
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

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()},$decPart €';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SafeArea(
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
                    Text('Cuentas', style: AppTypography.headlineSmall()),
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
    );
  }

  Widget _buildTransactionBalance(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
        final expenses = state is TransactionsLoaded
            ? state.totalExpenses
            : 0.0;
        final balance = income - expenses;

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
                    'Balance de transacciones',
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
                      'Datos reales',
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
                                  'Ingresos',
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
                                  'Gastos',
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
                        'Efectivo',
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
            context.read<BankBloc>().add(const LoadBankAccounts());
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
            context.read<BankBloc>().add(const LoadBankAccounts());
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
              content: Text('Error al conectar: ${state.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is BankAccountsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cuentas: ${state.message}'),
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
                        'El consentimiento PSD2 expira en ${state.consentDaysRemaining} días. Renuévalo en Ajustes.',
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
              ? '${state.imported} nueva${state.imported == 1 ? '' : 's'} transacci${state.imported == 1 ? 'ón' : 'ones'} importada${state.imported == 1 ? '' : 's'}'
              : 'Sincronización completada — sin novedades';
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
              title: const Text('Sesión bancaria expirada'),
              content: const Text(
                'Tu sesión con el banco ha caducado. '
                'Reconecta la cuenta para seguir importando transacciones automáticamente.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Ahora no'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _connectBank(context);
                  },
                  child: const Text('Reconectar'),
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
                Text('Cuentas bancarias', style: AppTypography.titleMedium()),
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
                        const Icon(
                          Icons.arrow_downward_rounded,
                          size: 10,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+$_lastImportedCount nueva${_lastImportedCount == 1 ? '' : 's'}',
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
                          '${accounts.length} conectada${accounts.length == 1 ? '' : 's'}',
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (accounts.isEmpty)
              _buildEmptyBanksCard(context)
            else
              ...accounts.map(
                (acct) => _BankAccountCard(
                  account: acct,
                  onDisconnect: () => _confirmDisconnect(context, acct),
                  onEdit: () => _openEditCardsSheet(context, acct),
                ),
              ),
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
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text('Conecta tu banco', style: AppTypography.titleMedium()),
              const SizedBox(height: 6),
              Text(
                'Sincroniza automáticamente tus cuentas bancarias mediante Open Banking PSD2.',
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
                        'Conectar cuenta',
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
            'Sin cuentas conectadas',
            style: AppTypography.titleSmall(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Conecta tu banco para sincronizar automáticamente tus movimientos',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
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

  void _confirmDisconnect(BuildContext context, BankAccountEntity account) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desconectar banco'),
        content: Text(
          '¿Seguro que quieres desconectar "${account.institutionName ?? account.accountName}"? '
          'Se eliminarán las cuentas asociadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BankBloc>().add(
                DisconnectBankRequested(account.connectionId),
              );
            },
            child: Text(
              'Desconectar',
              style: TextStyle(color: AppColors.error),
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
                'Uso por método de pago',
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
                            Text(method, style: AppTypography.titleSmall()),
                            Text(
                              '$count transacciones',
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
                child: const Icon(
                  Icons.sync_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Importando transacciones...',
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
            child: const LinearProgressIndicator(
              value: null, // indeterminate
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sincronizando con tu banco mediante Open Banking PSD2...',
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

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
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
          'Última sync: ${_formatRelative(lastSyncAt)}',
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
          const SizedBox(
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
                const Icon(
                  Icons.refresh_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  'Sincronizar',
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

  const _BankAccountCard({
    required this.account,
    required this.onDisconnect,
    required this.onEdit,
  });

  /// Returns a human-readable relative time string for the last sync.
  String _formatSyncTime(DateTime lastSyncAt) {
    final diff = DateTime.now().difference(lastSyncAt);
    if (diff.inSeconds < 60) return 'hace un momento';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'hace $m min';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'hace $h h';
    }
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) {
      return 'hace ${diff.inDays} días';
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
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_balance_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      )
                    : const Icon(
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
                  if (v == 'edit') onEdit();
                  if (v == 'disconnect') onDisconnect();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.credit_card_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text('Editar tarjetas'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
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
                          'Desconectar',
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
                    'Saldo disponible',
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
                        'Sincronizado ${_formatSyncTime(account.lastSyncAt!)}',
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
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        Text('Tarjetas', style: AppTypography.titleLarge()),
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
                    icon: const Icon(
                      Icons.add_card_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Añadir',
                      style: AppTypography.labelMedium(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
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
                        'Sin tarjetas — pulsa Añadir',
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
      if (data != null && mounted) {
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
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
          Text('Añadir tarjeta', style: AppTypography.titleLarge()),
          const SizedBox(height: 20),
          Text(
            'Tipo',
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
            'Nombre',
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: AppTypography.bodyMedium(),
            decoration: InputDecoration(
              hintText: 'Ej. Visa BBVA',
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
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Últimos 4 dígitos (opcional)',
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
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
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
                  const SnackBar(content: Text('Introduce un nombre')),
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
                  'Añadir tarjeta',
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
