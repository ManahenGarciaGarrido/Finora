import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/pending_bank_account_entity.dart';
import '../bloc/bank_bloc.dart';
import '../bloc/bank_event.dart';
import '../bloc/bank_state.dart';

/// Pantalla de selección de cuentas bancarias tras conectar con Plaid (RF-10).
/// Muestra la lista de cuentas disponibles con saldo original y equivalente EUR.
class BankAccountSelectionPage extends StatefulWidget {
  final String connectionId;
  final String institutionName;
  final List<PendingBankAccountEntity> pendingAccounts;

  const BankAccountSelectionPage({
    super.key,
    required this.connectionId,
    required this.institutionName,
    required this.pendingAccounts,
  });

  @override
  State<BankAccountSelectionPage> createState() =>
      _BankAccountSelectionPageState();
}

class _BankAccountSelectionPageState extends State<BankAccountSelectionPage> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    // Preseleccionar todas
    _selected = widget.pendingAccounts.map((a) => a.externalAccountId).toSet();
  }

  void _toggleAll(bool select) {
    setState(() {
      if (select) {
        _selected.addAll(widget.pendingAccounts.map((a) => a.externalAccountId));
      } else {
        _selected.clear();
      }
    });
  }

  void _confirm(BuildContext context) {
    if (_selected.isEmpty) return;
    context.read<BankBloc>().add(ConfirmBankAccountSelection(
      connectionId: widget.connectionId,
      selectedAccountIds: _selected.toList(),
    ));
  }

  String _formatCurrency(double amount, String currency) {
    final symbol = currency == 'EUR'
        ? '€'
        : currency == 'USD'
            ? '\$'
            : currency == 'GBP'
                ? '£'
                : currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BankBloc, BankState>(
      listener: (context, state) {
        if (state is BankConnectSuccess || state is BankConnectFailure) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimaryLight),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Seleccionar cuentas', style: AppTypography.titleMedium()),
        ),
        body: BlocBuilder<BankBloc, BankState>(
          builder: (context, state) {
            final isImporting =
                state is BankPendingAccountsReady && state.isImporting;

            return Column(
              children: [
                // ── Cabecera ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuentas de ${widget.institutionName}',
                        style: AppTypography.bodyMedium(
                            color: AppColors.gray500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige qué cuentas quieres vincular a Finora. '
                        'Los saldos se muestran convertidos a EUR.',
                        style: AppTypography.bodyMedium(
                            color: AppColors.gray400),
                      ),
                      const SizedBox(height: 12),
                      // Seleccionar / deseleccionar todas
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleAll(true),
                            child: Text('Seleccionar todas',
                                style: AppTypography.labelSmall(
                                    color: AppColors.primary)),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _toggleAll(false),
                            child: Text('Deseleccionar',
                                style: AppTypography.labelSmall(
                                    color: AppColors.gray400)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.gray200),

                // ── Lista de cuentas ──────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.pendingAccounts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.gray100, indent: 72),
                    itemBuilder: (context, index) {
                      final account = widget.pendingAccounts[index];
                      final isChecked =
                          _selected.contains(account.externalAccountId);

                      return InkWell(
                        onTap: isImporting
                            ? null
                            : () {
                                setState(() {
                                  if (isChecked) {
                                    _selected.remove(account.externalAccountId);
                                  } else {
                                    _selected.add(account.externalAccountId);
                                  }
                                });
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              // Checkbox
                              Checkbox(
                                value: isChecked,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                onChanged: isImporting
                                    ? null
                                    : (v) {
                                        setState(() {
                                          if (v == true) {
                                            _selected.add(
                                                account.externalAccountId);
                                          } else {
                                            _selected.remove(
                                                account.externalAccountId);
                                          }
                                        });
                                      },
                              ),
                              const SizedBox(width: 8),

                              // Icono de cuenta
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Nombre y divisa original
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.name,
                                      style: AppTypography.bodyLarge(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (account.originalCurrency != 'EUR')
                                      Text(
                                        '${_formatCurrency(account.originalBalance, account.originalCurrency)} '
                                        '· ${account.originalCurrency}',
                                        style: AppTypography.labelSmall(
                                            color: AppColors.gray400),
                                      ),
                                  ],
                                ),
                              ),

                              // Saldo en EUR
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${account.balanceEur.toStringAsFixed(2)} €',
                                    style: AppTypography.bodyLarge(),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.successSoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'EUR',
                                      style: AppTypography.labelSmall(
                                          color: AppColors.success),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Botón de confirmación ─────────────────────────────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: (isImporting || _selected.isEmpty)
                            ? null
                            : () => _confirm(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.gray300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isImporting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _selected.isEmpty
                                    ? 'Selecciona al menos una cuenta'
                                    : 'Vincular ${_selected.length} '
                                      'cuenta${_selected.length == 1 ? '' : 's'}',
                                style: AppTypography.labelLarge(
                                    color: AppColors.white),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
