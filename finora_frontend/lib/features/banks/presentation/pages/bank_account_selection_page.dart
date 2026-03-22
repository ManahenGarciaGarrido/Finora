import 'dart:async';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/pending_bank_account_entity.dart';
import '../bloc/bank_bloc.dart';
import '../bloc/bank_event.dart';
import '../bloc/bank_state.dart';
import '../../../../core/services/currency_service.dart';

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
    // Preseleccionar todas por defecto (escenario común UX)
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

  void _confirm() {
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
    final s = AppLocalizations.of(context);

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
          title: Text(s.selectAccounts, style: AppTypography.titleMedium()),
        ),
        body: Builder(builder: (ctx) {
          final responsive = ResponsiveUtils(ctx);
          final bodyContent = BlocBuilder<BankBloc, BankState>(
            builder: (context, state) {
              final isImporting =
                  state is BankPendingAccountsReady && state.isImporting;

              if (isImporting) {
                return _BankImportingOverlay(
                  accountCount: _selected.length,
                  institutionName: widget.institutionName,
                  s: s,
                );
              }

              return Column(
                children: [
                  _buildHeader(s),
                  const Divider(height: 1, color: AppColors.gray200),
                  _buildAccountsList(s, isImporting),
                  _buildBottomAction(s, isImporting),
                ],
              );
            },
          );
          if (responsive.isTablet) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: bodyContent,
              ),
            );
          }
          return bodyContent;
        }),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.accountsFromInstitution(widget.institutionName),
            style: AppTypography.bodyMedium(color: AppColors.gray500),
          ),
          const SizedBox(height: 4),
          Text(
            s.selectAccountsSubtitle,
            style: AppTypography.bodyMedium(color: AppColors.gray400),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleAll(true),
                child: Text(
                  s.selectAllAccounts,
                  style: AppTypography.labelSmall(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _toggleAll(false),
                child: Text(
                  s.deselectAccounts,
                  style: AppTypography.labelSmall(color: AppColors.gray400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(AppLocalizations s, bool isImporting) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.pendingAccounts.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.gray100, indent: 72),
        itemBuilder: (context, index) {
          final account = widget.pendingAccounts[index];
          final isChecked = _selected.contains(account.externalAccountId);

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
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
                                _selected.add(account.externalAccountId);
                              } else {
                                _selected.remove(account.externalAccountId);
                              }
                            });
                          },
                  ),
                  const SizedBox(width: 8),
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
                            '${_formatCurrency(account.originalBalance, account.originalCurrency)} · ${account.originalCurrency}',
                            style: AppTypography.labelSmall(
                              color: AppColors.gray400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyService().format(account.balanceEur),
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
    );
  }

  Widget _buildBottomAction(AppLocalizations s, bool isImporting) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: (isImporting || _selected.isEmpty) ? null : _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.gray300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _selected.isEmpty
                  ? s.selectAtLeastOneAccount
                  : s.confirmLinkAccounts(_selected.length),
              style: AppTypography.labelLarge(color: AppColors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Overlay de Carga Localizado ─────────────────────────────────────────────

class _BankImportingOverlay extends StatefulWidget {
  final int accountCount;
  final String institutionName;
  final AppLocalizations s;

  const _BankImportingOverlay({
    required this.accountCount,
    required this.institutionName,
    required this.s,
  });

  @override
  State<_BankImportingOverlay> createState() => _BankImportingOverlayState();
}

class _BankImportingOverlayState extends State<_BankImportingOverlay>
    with SingleTickerProviderStateMixin {
  late List<String> _messages;
  int _messageIndex = 0;
  double _progress = 0.0;
  Timer? _messageTimer;
  Timer? _progressTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _messages = [
      widget.s.linkingStep1,
      widget.s.linkingStep2,
      widget.s.linkingStep3,
      widget.s.linkingStep4,
      widget.s.linkingStep5,
      widget.s.linkingStep6,
      widget.s.linkingStep7,
      widget.s.linkingStep8,
      widget.s.linkingStep9,
    ];

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _messageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
      }
    });

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              widget.s.linkingAccounts(
                widget.s.accountCountLabel(widget.accountCount),
              ),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SecureChip(
                  icon: Icons.lock_outline_rounded,
                  label: widget.s.encryptedConnectionLabel,
                  color: AppColors.success,
                ),
                _SecureChip(
                  icon: Icons.psychology_outlined,
                  label: widget.s.aiAnalysisLabel,
                  color: AppColors.primary,
                ),
                _SecureChip(
                  icon: Icons.verified_user_outlined,
                  label: widget.s.psd2CertifiedLabel,
                  color: AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              widget.s.dontCloseAppMsg,
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