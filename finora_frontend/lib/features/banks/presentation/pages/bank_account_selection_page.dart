import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
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
        _selected.addAll(
          widget.pendingAccounts.map((a) => a.externalAccountId),
        );
      } else {
        _selected.clear();
      }
    });
  }

  void _confirm(BuildContext context) {
    if (_selected.isEmpty) return;
    context.read<BankBloc>().add(
      ConfirmBankAccountSelection(
        connectionId: widget.connectionId,
        selectedAccountIds: _selected.toList(),
      ),
    );
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
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimaryLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context).selectAccounts,
            style: AppTypography.titleMedium(),
          ),
        ),
        body: BlocBuilder<BankBloc, BankState>(
          builder: (context, state) {
            final isImporting =
                state is BankPendingAccountsReady && state.isImporting;

            // Cuando está importando, mostrar overlay de carga a pantalla completa
            if (isImporting) {
              return _BankImportingOverlay(
                accountCount: _selected.length,
                institutionName: widget.institutionName,
              );
            }

            return Column(
              children: [
                // ── Cabecera ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuentas de ${widget.institutionName}', // TODO: add localization key
                        style: AppTypography.bodyMedium(
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige qué cuentas quieres vincular a Finora. '
                        'Los saldos se muestran convertidos a EUR.', // TODO: add localization key
                        style: AppTypography.bodyMedium(
                          color: AppColors.gray400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Seleccionar / deseleccionar todas
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleAll(true),
                            child: Text(
                              AppLocalizations.of(context).selectAllAccounts,
                              style: AppTypography.labelSmall(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _toggleAll(false),
                            child: Text(
                              AppLocalizations.of(context).deselectAccounts,
                              style: AppTypography.labelSmall(
                                color: AppColors.gray400,
                              ),
                            ),
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
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.gray100,
                      indent: 72,
                    ),
                    itemBuilder: (context, index) {
                      final account = widget.pendingAccounts[index];
                      final isChecked = _selected.contains(
                        account.externalAccountId,
                      );

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
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              // Checkbox
                              Checkbox(
                                value: isChecked,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: isImporting
                                    ? null
                                    : (v) {
                                        setState(() {
                                          if (v == true) {
                                            _selected.add(
                                              account.externalAccountId,
                                            );
                                          } else {
                                            _selected.remove(
                                              account.externalAccountId,
                                            );
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
                                          color: AppColors.gray400,
                                        ),
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
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.successSoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'EUR',
                                      style: AppTypography.labelSmall(
                                        color: AppColors.success,
                                      ),
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
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _selected.isEmpty
                              ? AppLocalizations.of(
                                  context,
                                ).selectAtLeastOneAccount
                              : '${AppLocalizations.of(context).linkVerb} ${_selected.length} '
                                    'cuenta${_selected.length == 1 ? '' : 's'}', // TODO: add localization key
                          style: AppTypography.labelLarge(
                            color: AppColors.white,
                          ),
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

// ─── Overlay de carga durante la importación ─────────────────────────────────

class _BankImportingOverlay extends StatefulWidget {
  final int accountCount;
  final String institutionName;

  const _BankImportingOverlay({
    required this.accountCount,
    required this.institutionName,
  });

  @override
  State<_BankImportingOverlay> createState() => _BankImportingOverlayState();
}

class _BankImportingOverlayState extends State<_BankImportingOverlay>
    with SingleTickerProviderStateMixin {
  static const _messages = [
    'Conectando con tu banco...',
    'Obteniendo información de tus cuentas...',
    'Generando historial de transacciones...',
    'Analizando tus movimientos con IA...',
    'Categorizando transacciones automáticamente...',
    'Calculando tus patrones de gasto...',
    'Detectando suscripciones recurrentes...',
    'Preparando tu perfil financiero...',
    'Casi listo, un momento más...', // TODO: add localization key
  ];

  int _messageIndex = 0;
  double _progress = 0.0;
  Timer? _messageTimer;
  Timer? _progressTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotar mensajes cada 4 segundos
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });

    // Progreso simulado: avanza rápido al principio, se ralentiza al final
    _progressTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted && _progress < 0.92) {
        setState(() {
          final remaining = 0.92 - _progress;
          _progress += remaining * 0.12;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _progressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountLabel = widget.accountCount == 1
        ? '1 cuenta' // TODO: add localization key
        : '${widget.accountCount} cuentas'; // TODO: add localization key

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono animado
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
            ),

            const SizedBox(height: 36),

            Text(
              'Vinculando $accountLabel', // TODO: add localization key
              style: AppTypography.titleLarge(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.institutionName,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.gray200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 20),

            // Mensaje rotativo con fade
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _messages[_messageIndex],
                key: ValueKey(_messageIndex),
                style: AppTypography.bodyMedium(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            // Chips de seguridad
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SecureChip(
                  icon: Icons.lock_outline_rounded,
                  label: AppLocalizations.of(context).encryptedConnectionLabel,
                  color: AppColors.success,
                ),
                _SecureChip(
                  icon: Icons.psychology_outlined,
                  label: AppLocalizations.of(context).aiAnalysisLabel,
                  color: AppColors.primary,
                ),
                _SecureChip(
                  icon: Icons.verified_user_outlined,
                  label: AppLocalizations.of(context).psd2CertifiedLabel,
                  color: AppColors.accent,
                ),
              ],
            ),

            const SizedBox(height: 32),

            Text(
              AppLocalizations.of(context).dontCloseAppMsg,
              style: AppTypography.labelSmall(
                color: AppColors.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SecureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SecureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppTypography.labelSmall(color: color)),
        ],
      ),
    );
  }
}
