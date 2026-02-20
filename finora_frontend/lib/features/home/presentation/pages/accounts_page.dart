import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../banks/presentation/bloc/bank_bloc.dart';
import '../../../banks/presentation/bloc/bank_event.dart';
import '../../../banks/presentation/bloc/bank_state.dart';
import '../../../banks/domain/entities/bank_account_entity.dart';
import '../../../banks/presentation/pages/institution_selector_sheet.dart';
import '../../../banks/presentation/pages/bank_connecting_page.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BankBloc>().add(const LoadBankAccounts());
      }
    });
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
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 16,
                responsive.horizontalPadding, 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cuentas', style: AppTypography.headlineSmall()),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => _connectBank(context),
                      color: AppColors.white,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Balance calculado desde transacciones
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 20,
                responsive.horizontalPadding, 0,
              ),
              child: _buildTransactionBalance(context),
            ),
          ),

          // Saldo de cuentas bancarias - placeholder
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 20,
                responsive.horizontalPadding, 0,
              ),
              child: _buildBankAccountsSection(context),
            ),
          ),

          // Conectar cuenta bancaria
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 20,
                responsive.horizontalPadding, 0,
              ),
              child: _buildConnectBankCard(context),
            ),
          ),

          // Métodos de pago
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 20,
                responsive.horizontalPadding, 0,
              ),
              child: _buildPaymentMethodsSummary(context),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: responsive.hp(12))),
        ],
      ),
    );
  }

  Widget _buildTransactionBalance(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
        final expenses = state is TransactionsLoaded ? state.totalExpenses : 0.0;
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              color: AppColors.successLight.withValues(alpha: 0.2),
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
                                    color: AppColors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  _formatCurrency(income),
                                  style: AppTypography.titleSmall(color: AppColors.white),
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
                              color: AppColors.errorLight.withValues(alpha: 0.2),
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
                                    color: AppColors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  _formatCurrency(expenses),
                                  style: AppTypography.titleSmall(color: AppColors.white),
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
  // Bank accounts section (RF-10)
  // ──────────────────────────────────────────────────────────

  Widget _buildBankAccountsSection(BuildContext context) {
    return BlocConsumer<BankBloc, BankState>(
      listener: (context, state) {
        if (state is BankConnectAuthUrlReady) {
          // Navigate to connecting page after institution selector closes
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<BankBloc>(),
                child: BankConnectingPage(
                  connectionId: state.connectionId,
                  institutionName: state.institutionName,
                ),
              ),
            ),
          ).then((_) {
            // Reload accounts when user returns
            context.read<BankBloc>().add(const LoadBankAccounts());
          });
        }
      },
      builder: (context, state) {
        final accounts = state is BankAccountsLoaded ? state.accounts : <BankAccountEntity>[];
        final isLoading = state is BankAccountsLoading || state is BankSyncing || state is BankDisconnecting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Text('Cuentas bancarias', style: AppTypography.titleMedium()),
                const Spacer(),
                if (accounts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 10, color: AppColors.success),
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
            const SizedBox(height: 12),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2,
                  ),
                ),
              )
            else if (accounts.isEmpty)
              _buildEmptyBanksCard(context)
            else
              ...accounts.map((acct) => _BankAccountCard(
                    account: acct,
                    onSync: () => context
                        .read<BankBloc>()
                        .add(SyncBankRequested(acct.connectionId)),
                    onDisconnect: () => _confirmDisconnect(context, acct),
                  )),
          ],
        );
      },
    );
  }

  Widget _buildConnectBankCard(BuildContext context) {
    return BlocBuilder<BankBloc, BankState>(
      builder: (context, state) {
        final hasAccounts = state is BankAccountsLoaded && state.accounts.isNotEmpty;
        if (hasAccounts) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
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
                child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 14),
              Text('Conecta tu banco', style: AppTypography.titleMedium()),
              const SizedBox(height: 6),
              Text(
                'Sincroniza automáticamente tus cuentas bancarias mediante Open Banking PSD2.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _connectBank(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_link_rounded, color: AppColors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Conectar cuenta',
                          style: AppTypography.labelLarge(color: AppColors.white)),
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
          Icon(Icons.account_balance_outlined, size: 40, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text(
            'Sin cuentas conectadas',
            style: AppTypography.titleSmall(color: AppColors.textSecondaryLight),
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
              context
                  .read<BankBloc>()
                  .add(DisconnectBankRequested(account.connectionId));
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
              Text('Uso por método de pago', style: AppTypography.titleMedium()),
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
                              style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
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
        return Icons.money_rounded;
      case 'Tarjeta':
        return Icons.credit_card_rounded;
      case 'Transferencia':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'Efectivo':
        return AppColors.success;
      case 'Tarjeta':
        return AppColors.primary;
      case 'Transferencia':
        return AppColors.accent;
      default:
        return AppColors.gray500;
    }
  }

}

// ──────────────────────────────────────────────────────────────────────────────
// Bank account card widget (RF-10)
// ──────────────────────────────────────────────────────────────────────────────

class _BankAccountCard extends StatelessWidget {
  final BankAccountEntity account;
  final VoidCallback onSync;
  final VoidCallback onDisconnect;

  const _BankAccountCard({
    required this.account,
    required this.onSync,
    required this.onDisconnect,
  });

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
                    Text(account.accountName, style: AppTypography.titleSmall()),
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
                  if (v == 'sync') onSync();
                  if (v == 'disconnect') onDisconnect();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'sync',
                    child: Row(
                      children: [
                        Icon(Icons.sync_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Sincronizar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'disconnect',
                    child: Row(
                      children: [
                        Icon(Icons.link_off_rounded, size: 18,
                            color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Desconectar',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert_rounded,
                    color: AppColors.gray400, size: 20),
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
                        color: AppColors.textTertiaryLight),
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
                        color: AppColors.textTertiaryLight),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.maskedIban,
                    style: AppTypography.bodySmall(),
                  ),
                ],
              ),
            ],
          ),
          if (account.lastSyncAt != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 10, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Sincronizado',
                    style: AppTypography.badge(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
