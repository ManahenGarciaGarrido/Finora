import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/bank_bloc.dart';
import '../bloc/bank_event.dart';
import '../bloc/bank_state.dart';
import 'plaid_link_screen.dart';

/// Full-screen page shown while waiting for OAuth callback (RF-10).
/// Polls /banks/:id/sync-status via BankBloc until status == 'linked'.
///
/// HU-05: Si la conexión falla, muestra UI de solución de problemas
///        específica para el tipo de error, en lugar de cerrar silenciosamente.
class BankConnectingPage extends StatefulWidget {
  final String connectionId;
  final String institutionName;

  /// URL de autenticación Plaid Link. Si no está vacía, abre PlaidLinkScreen.
  final String authUrl;

  const BankConnectingPage({
    super.key,
    required this.connectionId,
    required this.institutionName,
    this.authUrl = '',
  });

  @override
  State<BankConnectingPage> createState() => _BankConnectingPageState();
}

class _BankConnectingPageState extends State<BankConnectingPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Abrir el WebView de Plaid Link justo después del primer frame.
    if (widget.authUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaidLinkScreen(authUrl: widget.authUrl),
          ),
        ).then((result) {
          if (!mounted) return;
          final tokenData = result as Map<String, String>?;
          if (tokenData != null && tokenData['public_token'] != null) {
            context.read<BankBloc>().add(
              ExchangePublicToken(
                connectionId: widget.connectionId,
                publicToken: tokenData['public_token']!,
                institutionName: tokenData['institution_name'] ?? 'Banco',
              ),
            );
          } else if (tokenData != null && tokenData['cancelled'] == 'true') {
            // CU-02 FA2: Usuario canceló explícitamente → mostrar mensaje informativo
            context.read<BankBloc>().add(const CancelledByUser());
          } else {
            context.read<BankBloc>().add(
              PollSyncStatus(widget.connectionId, 0),
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<BankBloc>().add(PollSyncStatus(widget.connectionId, 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        context.read<BankBloc>().add(const CancelBankPolling());
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
            onPressed: () {
              context.read<BankBloc>().add(const CancelBankPolling());
              Navigator.pop(context);
            },
          ),
          title: Text(
            AppLocalizations.of(context).connectingBankTitle,
            style: AppTypography.titleMedium(),
          ),
        ),
        body: Builder(
          builder: (ctx) {
            final responsive = ResponsiveUtils(ctx);
            final blocBody = BlocConsumer<BankBloc, BankState>(
              listener: (context, state) {
                if (state is BankConnectSuccess) {
                  Navigator.pop(context, true);
                }
                // HU-05: No cerrar automáticamente en caso de error;
                // se muestra la UI de troubleshooting en el builder.
              },
              builder: (context, state) {
                // HU-05: Si hay un fallo, mostrar pantalla de troubleshooting
                if (state is BankConnectFailure) {
                  return _TroubleshootingView(
                    message: state.message,
                    errorType: state.errorType,
                    connectionId: widget.connectionId,
                    institutionName: widget.institutionName,
                  );
                }

                final attempt = state is BankConnectPolling ? state.attempt : 0;
                final progress = (attempt / 60.0).clamp(0.0, 1.0);

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _AnimatedBankIcon(state: state),

                        const SizedBox(height: 32),

                        Text(
                          _titleFor(context, state),
                          style: AppTypography.titleLarge(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _subtitleFor(context, state, widget.institutionName),
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        if (state is BankConnectPolling) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.gray200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${AppLocalizations.of(context).bankWaitingAuthTitle}... ($attempt/60)',
                            style: AppTypography.labelSmall(
                              color: AppColors.textTertiaryLight,
                            ),
                          ),
                        ],

                        if (state is BankConnectAuthUrlReady) ...[
                          CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context).openingBrowserMsg,
                            style: AppTypography.labelSmall(
                              color: AppColors.textTertiaryLight,
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _InfoChip(
                              icon: Icons.lock_outline_rounded,
                              label: AppLocalizations.of(
                                context,
                              ).encryptedConnectionLabel,
                              color: AppColors.success,
                            ),
                            _InfoChip(
                              icon: Icons.visibility_off_outlined,
                              label: AppLocalizations.of(context).readOnlyLabel,
                              color: AppColors.info,
                            ),
                            _InfoChip(
                              icon: Icons.verified_user_outlined,
                              label: AppLocalizations.of(
                                context,
                              ).psd2CertifiedLabel,
                              color: AppColors.accent,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        TextButton(
                          onPressed: () {
                            context.read<BankBloc>().add(
                              const CancelBankPolling(),
                            );
                            Navigator.pop(context);
                          },
                          child: Text(
                            AppLocalizations.of(context).cancel,
                            style: AppTypography.labelLarge(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
            if (responsive.isTablet) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: blocBody,
                ),
              );
            }
            return blocBody;
          },
        ),
      ),
    );
  }

  String _titleFor(BuildContext ctx, BankState state) {
    final s = AppLocalizations.of(ctx);
    if (state is BankConnectAuthUrlReady) return s.bankOpeningTitle;
    if (state is BankConnectPolling) return s.bankWaitingAuthTitle;
    return s.connectingBankTitle;
  }

  String _subtitleFor(BuildContext ctx, BankState state, String name) {
    if (state is BankConnectAuthUrlReady) {
      return AppLocalizations.of(ctx).bankAuthCompleteInBrowserMsg;
    }
    if (state is BankConnectPolling) {
      return AppLocalizations.of(ctx).bankAuthReturnMsg;
    }
    return '${AppLocalizations.of(ctx).bankInitiatingConnectionMsg} $name...';
  }
}

// ─── HU-05: Troubleshooting UI ──────────────────────────────────────────────

/// Pantalla de solución de problemas mostrada cuando la conexión bancaria falla.
/// Proporciona pasos específicos según el tipo de error (HU-05 AC).
class _TroubleshootingView extends StatelessWidget {
  final String message;
  final BankConnectErrorType errorType;
  final String connectionId;
  final String institutionName;

  const _TroubleshootingView({
    required this.message,
    required this.errorType,
    required this.connectionId,
    required this.institutionName,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configFor(context, errorType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Error icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: config.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(config.icon, color: config.iconColor, size: 40),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            config.title,
            style: AppTypography.titleLarge(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTypography.bodyMedium(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Troubleshooting steps card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).bankWhatYouCanDo,
                      style: AppTypography.labelMedium(color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...config.steps.asMap().entries.map((entry) {
                  return _StepRow(number: entry.key + 1, text: entry.value);
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Retry button (if applicable)
          if (config.showRetry)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<BankBloc>().add(PollSyncStatus(connectionId, 0));
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(AppLocalizations.of(context).bankRetryConnection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          if (config.showRetry) const SizedBox(height: 12),

          // Back button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<BankBloc>().add(const CancelBankPolling());
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                config.showRetry
                    ? AppLocalizations.of(context).bankChooseOtherBank
                    : AppLocalizations.of(context).back,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondaryLight,
                side: const BorderSide(color: AppColors.gray200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Support link
          GestureDetector(
            onTap: () => _showSupportInfo(context),
            child: Text(
              AppLocalizations.of(context).bankContactSupport,
              style: AppTypography.labelSmall(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showSupportInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.support_agent_rounded,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).technicalSupport,
              style: AppTypography.titleMedium(),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).bankSupportContactMsg,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const _SupportRow(
              icon: Icons.email_outlined,
              label: 'soporte@finora.app',
            ),
            _SupportRow(
              icon: Icons.chat_bubble_outline_rounded,
              label: AppLocalizations.of(context).chatOnFinoraLabel,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  _TroubleshootingConfig _configFor(
    BuildContext context,
    BankConnectErrorType type,
  ) {
    final s = AppLocalizations.of(context);
    switch (type) {
      case BankConnectErrorType.timeout:
        return _TroubleshootingConfig(
          icon: Icons.timer_off_outlined,
          iconColor: AppColors.warning,
          title: s.bankTimeoutTitle,
          steps: s.bankTimeoutSteps,
          showRetry: true,
        );
      case BankConnectErrorType.permissionDenied:
        return _TroubleshootingConfig(
          icon: Icons.block_rounded,
          iconColor: AppColors.error,
          title: s.bankPermissionDeniedTitle,
          steps: s.bankPermissionDeniedSteps,
          showRetry: true,
        );
      case BankConnectErrorType.connectionError:
        return _TroubleshootingConfig(
          icon: Icons.wifi_off_rounded,
          iconColor: AppColors.error,
          title: s.bankNoInternetTitle,
          steps: s.bankNoInternetSteps,
          showRetry: true,
        );
      case BankConnectErrorType.sessionExpired:
        return _TroubleshootingConfig(
          icon: Icons.lock_clock_outlined,
          iconColor: AppColors.warning,
          title: s.bankSessionExpiredTitle,
          steps: s.bankSessionExpiredSteps,
          showRetry: false,
        );
      case BankConnectErrorType.serviceUnavailable:
        return _TroubleshootingConfig(
          icon: Icons.cloud_off_rounded,
          iconColor: AppColors.warning,
          title: s.bankServiceUnavailTitle,
          steps: s.bankServiceUnavailSteps,
          showRetry: true,
        );
      case BankConnectErrorType.syncFailed:
        return _TroubleshootingConfig(
          icon: Icons.sync_problem_rounded,
          iconColor: AppColors.info,
          title: s.bankSyncFailedTitle,
          steps: s.bankSyncFailedSteps,
          showRetry: false,
        );
      // CU-02 FA2: Cancelación explícita del usuario
      case BankConnectErrorType.cancelledByUser:
        return _TroubleshootingConfig(
          icon: Icons.cancel_outlined,
          iconColor: AppColors.gray500,
          title: s.bankCancelledTitle,
          steps: s.bankCancelledSteps,
          showRetry: true,
        );
      // CU-02 FA1: Límite de 3 intentos fallidos alcanzado
      case BankConnectErrorType.maxAttemptsReached:
        return _TroubleshootingConfig(
          icon: Icons.lock_clock_outlined,
          iconColor: AppColors.error,
          title: s.bankMaxAttemptsTitle,
          steps: s.bankMaxAttemptsSteps,
          showRetry: false,
        );
      case BankConnectErrorType.unknown:
        return _TroubleshootingConfig(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          title: s.bankUnknownErrorTitle,
          steps: s.bankUnknownErrorSteps,
          showRetry: true,
        );
    }
  }
}

class _TroubleshootingConfig {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> steps;
  final bool showRetry;

  const _TroubleshootingConfig({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.steps,
    required this.showRetry,
  });
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.labelSmall(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall(color: AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SupportRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
          ),
        ],
      ),
    );
  }
}

// ─── Existing helpers (unchanged) ───────────────────────────────────────────

class _AnimatedBankIcon extends StatefulWidget {
  final BankState state;

  const _AnimatedBankIcon({required this.state});

  @override
  State<_AnimatedBankIcon> createState() => _AnimatedBankIconState();
}

class _AnimatedBankIconState extends State<_AnimatedBankIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.shadowColor(AppColors.primaryDark),
        ),
        child: const Icon(
          Icons.account_balance_rounded,
          color: AppColors.white,
          size: 48,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelSmall(color: color)),
        ],
      ),
    );
  }
}
