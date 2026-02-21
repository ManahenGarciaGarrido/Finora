import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/bank_bloc.dart';
import '../bloc/bank_event.dart';
import '../bloc/bank_state.dart';

/// Full-screen page shown while waiting for OAuth callback (RF-10).
/// Polls /banks/:id/sync-status via BankBloc until status == 'linked'.
class BankConnectingPage extends StatefulWidget {
  final String connectionId;
  final String institutionName;

  const BankConnectingPage({
    super.key,
    required this.connectionId,
    required this.institutionName,
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// When the user closes the in-app browser and returns to the app,
  /// trigger an immediate poll so the result is detected without waiting
  /// for the next 3-second timer tick.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<BankBloc>().add(PollSyncStatus(widget.connectionId, 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_) {
        context.read<BankBloc>().add(const CancelBankPolling());
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryLight),
            onPressed: () {
              context.read<BankBloc>().add(const CancelBankPolling());
              Navigator.pop(context);
            },
          ),
          title: Text('Conectando banco', style: AppTypography.titleMedium()),
        ),
        body: BlocConsumer<BankBloc, BankState>(
          listener: (context, state) {
            if (state is BankConnectSuccess) {
              // Return to AccountsPage with success
              Navigator.pop(context, true);
            } else if (state is BankConnectFailure) {
              Navigator.pop(context, false);
            }
          },
          builder: (context, state) {
            final attempt = state is BankConnectPolling ? state.attempt : 0;
            final progress = (attempt / 60.0).clamp(0.0, 1.0);

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated bank icon
                    _AnimatedBankIcon(state: state),

                    const SizedBox(height: 32),

                    // Status text
                    Text(
                      _titleFor(state),
                      style: AppTypography.titleLarge(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _subtitleFor(state, widget.institutionName),
                      style: AppTypography.bodyMedium(
                          color: AppColors.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Progress bar
                    if (state is BankConnectPolling) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.gray200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Esperando autorización... ($attempt/60)',
                        style: AppTypography.labelSmall(
                            color: AppColors.textTertiaryLight),
                      ),
                    ],

                    if (state is BankConnectAuthUrlReady) ...[
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Abriendo el navegador...',
                        style: AppTypography.labelSmall(
                            color: AppColors.textTertiaryLight),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _InfoChip(
                          icon: Icons.lock_outline_rounded,
                          label: 'Conexión cifrada',
                          color: AppColors.success,
                        ),
                        _InfoChip(
                          icon: Icons.visibility_off_outlined,
                          label: 'Solo lectura',
                          color: AppColors.info,
                        ),
                        _InfoChip(
                          icon: Icons.verified_user_outlined,
                          label: 'PSD2 certificado',
                          color: AppColors.accent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Cancel button
                    TextButton(
                      onPressed: () {
                        context.read<BankBloc>().add(const CancelBankPolling());
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancelar',
                        style: AppTypography.labelLarge(
                            color: AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _titleFor(BankState state) {
    if (state is BankConnectAuthUrlReady) return 'Abriendo tu banco';
    if (state is BankConnectPolling) return 'Esperando autorización';
    return 'Conectando banco';
  }

  String _subtitleFor(BankState state, String name) {
    if (state is BankConnectAuthUrlReady) {
      return 'Completa la autorización en el navegador para continuar.';
    }
    if (state is BankConnectPolling) {
      return 'Una vez que autorices en el navegador, volverás automáticamente a Finora.';
    }
    return 'Iniciando la conexión segura con $name...';
  }
}

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
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
          Text(
            label,
            style: AppTypography.labelSmall(color: color),
          ),
        ],
      ),
    );
  }
}
