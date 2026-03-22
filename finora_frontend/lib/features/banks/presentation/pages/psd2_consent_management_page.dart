import 'package:flutter/material.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:finora_frontend/shared/widgets/skeleton_loader.dart';

/// Pantalla de gestión de consentimientos PSD2 (RNF-05).
///
/// Muestra todos los consentimientos bancarios activos del usuario con:
///  - Estado (activo / expirado / revocado)
///  - Días restantes hasta la expiración
///  - Aviso de renovación cuando quedan ≤14 días (PSD2 SCA)
///  - Opción de renovar o revocar cada consentimiento
///
/// PSD2 requiere que el usuario reconfirme el consentimiento bancario
/// cada 90 días (Strong Customer Authentication).
class Psd2ConsentManagementPage extends StatefulWidget {
  final ApiClient apiClient;

  const Psd2ConsentManagementPage({super.key, required this.apiClient});

  @override
  State<Psd2ConsentManagementPage> createState() =>
      _Psd2ConsentManagementPageState();
}

class _Psd2ConsentManagementPageState
    extends State<Psd2ConsentManagementPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _consents = [];

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.apiClient.get(ApiEndpoints.bankConsents);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _consents = (data['consents'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).bankConsentsLoadError;
        _loading = false;
      });
    }
  }

  Future<void> _renewConsent(String connectionId, String bankName) async {
    final s = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.renewConsent),
        content: Text(s.renewConsentContent(bankName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.renew),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await widget.apiClient.post(ApiEndpoints.renewBankConsent(connectionId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).consentRenewedMsg(bankName)),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadConsents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).errorRenewing}: ${e.toString()}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _revokeConsent(String connectionId, String bankName) async {
    final s = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.revokeConsentTitle),
        content: Text(s.revokeConsentContent(bankName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.revokeAccess),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await widget.apiClient.delete(
        ApiEndpoints.revokeBankConsent(connectionId),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).consentRevokedMsg(bankName),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadConsents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).errorRevoking}: ${e.toString()}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
    final bodyContent = _loading
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SkeletonListLoader(count: 4, cardHeight: 88),
          )
        : _error != null
        ? _ErrorView(error: _error!, onRetry: _loadConsents)
        : _consents.isEmpty
        ? const _EmptyView()
        : _ConsentList(
            consents: _consents,
            onRenew: _renewConsent,
            onRevoke: _revokeConsent,
          );
    return Scaffold(
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
        title: Text(s.bankConsentsTitle, style: AppTypography.titleMedium()),
      ),
      body: responsive.isTablet
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: bodyContent,
              ),
            )
          : bodyContent,
    );
  }
}

// ─── Subwidgets ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 56,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(s.noActiveConsents, style: AppTypography.titleSmall()),
            const SizedBox(height: 8),
            Text(
              s.noActiveConsentsDesc,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentList extends StatelessWidget {
  final List<Map<String, dynamic>> consents;
  final void Function(String id, String name) onRenew;
  final void Function(String id, String name) onRevoke;

  const _ConsentList({
    required this.consents,
    required this.onRenew,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Información PSD2
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).psd2RenewalInfoMsg,
                    style: AppTypography.bodySmall(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...consents.map(
            (c) =>
                _ConsentCard(consent: c, onRenew: onRenew, onRevoke: onRevoke),
          ),
        ],
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final Map<String, dynamic> consent;
  final void Function(String id, String name) onRenew;
  final void Function(String id, String name) onRevoke;

  const _ConsentCard({
    required this.consent,
    required this.onRenew,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final status = consent['status'] as String? ?? 'active';
    final bankName =
        consent['institutionName'] as String? ?? s.bankFallbackName;
    final connectionId = consent['connectionId'] as String? ?? '';
    final daysRemaining = (consent['daysRemaining'] as num?)?.toInt() ?? 0;
    final renewalReq = consent['renewalRequired'] as bool? ?? false;
    final expiresAt = consent['expiresAt'] as String?;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'expired':
        statusColor = AppColors.error;
        statusLabel = s.statusExpired;
        statusIcon = Icons.warning_amber_rounded;
      case 'revoked':
        statusColor = AppColors.gray400;
        statusLabel = s.statusRevoked;
        statusIcon = Icons.block_rounded;
      default:
        if (renewalReq) {
          statusColor = AppColors.warning;
          statusLabel = s.renewalRequired;
          statusIcon = Icons.update_rounded;
        } else {
          statusColor = AppColors.success;
          statusLabel = s.statusActive;
          statusIcon = Icons.check_circle_outline_rounded;
        }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: renewalReq ? AppColors.warning : AppColors.gray200,
          width: renewalReq ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: banco + estado
            Row(
              children: [
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
                      Text(bankName, style: AppTypography.bodyLarge()),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: AppTypography.labelSmall(
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: 12),

            // Detalles
            if (status == 'active') ...[
              _DetailRow(
                icon: Icons.timer_outlined,
                label: s.expiresInLabel,
                value: s.daysCount(daysRemaining),
                valueColor: renewalReq
                    ? AppColors.warning
                    : AppColors.textPrimaryLight,
              ),
              const SizedBox(height: 6),
            ],
            if (expiresAt != null) ...[
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: s.expiresAtLabel,
                value: _formatDate(expiresAt),
              ),
              const SizedBox(height: 6),
            ],
            _DetailRow(
              icon: Icons.lock_outline_rounded,
              label: s.grantedPermissionsLabel,
              value: s.readOnlyAccountsLabel,
            ),

            // Aviso de renovación
            if (renewalReq && status == 'active') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.update_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.consentExpiresWarning(daysRemaining),
                        style: AppTypography.bodySmall(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (status == 'expired') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.consentExpiredWarning,
                        style: AppTypography.bodySmall(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Acciones
            if (status != 'revoked')
              Row(
                children: [
                  if (status == 'active' || status == 'expired')
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => onRenew(connectionId, bankName),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(s.renew90Days),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => onRevoke(connectionId, bankName),
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    label: Text(
                      s.revokeLabel,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.gray400),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTypography.bodySmall(color: AppColors.gray400),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall(
              color: valueColor ?? AppColors.textPrimaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}