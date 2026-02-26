import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

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

class _Psd2ConsentManagementPageState extends State<Psd2ConsentManagementPage> {
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
      setState(() {
        _error =
            'No se pudieron cargar los consentimientos. Inténtalo de nuevo.';
        _loading = false;
      });
    }
  }

  Future<void> _renewConsent(String connectionId, String bankName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renovar consentimiento'),
        content: Text(
          'Se renovará el acceso de Finora a $bankName por 90 días más (PSD2).\n\n'
          'No se modificarán tus datos ni transacciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Renovar'),
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
          content: Text('Consentimiento de $bankName renovado por 90 días'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadConsents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al renovar: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _revokeConsent(String connectionId, String bankName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revocar consentimiento'),
        content: Text(
          '¿Seguro que quieres revocar el acceso de Finora a $bankName?\n\n'
          'Esto desconectará el banco y dejará de sincronizarse. '
          'Tus transacciones existentes se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revocar acceso'),
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
          content: Text('Acceso a $bankName revocado. Banco desconectado.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadConsents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al revocar: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'Consentimientos bancarios',
          style: AppTypography.titleMedium(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _loadConsents)
          : _consents.isEmpty
          ? _EmptyView()
          : _ConsentList(
              consents: _consents,
              onRenew: _renewConsent,
              onRevoke: _revokeConsent,
            ),
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
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            Text(
              'Sin consentimientos activos',
              style: AppTypography.titleSmall(),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando conectes un banco, aquí aparecerá el consentimiento PSD2 '
              'con su estado y fecha de expiración.',
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
                    'PSD2 (Directiva de Servicios de Pago) exige renovar el '
                    'consentimiento bancario cada 90 días. Finora te avisará '
                    'con 14 días de antelación.',
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
    final status = consent['status'] as String? ?? 'active';
    final bankName = consent['institutionName'] as String? ?? 'Banco';
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
        statusLabel = 'Expirado';
        statusIcon = Icons.warning_amber_rounded;
      case 'revoked':
        statusColor = AppColors.gray400;
        statusLabel = 'Revocado';
        statusIcon = Icons.block_rounded;
      default:
        if (renewalReq) {
          statusColor = AppColors.warning;
          statusLabel = 'Renovación requerida';
          statusIcon = Icons.update_rounded;
        } else {
          statusColor = AppColors.success;
          statusLabel = 'Activo';
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
                            style: AppTypography.labelSmall(color: statusColor),
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
                label: 'Expira en',
                value: '$daysRemaining días',
                valueColor: renewalReq
                    ? AppColors.warning
                    : AppColors.textPrimaryLight,
              ),
              const SizedBox(height: 6),
            ],
            if (expiresAt != null) ...[
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Fecha de expiración',
                value: _formatDate(expiresAt),
              ),
              const SizedBox(height: 6),
            ],
            _DetailRow(
              icon: Icons.lock_outline_rounded,
              label: 'Permisos concedidos',
              value: 'Solo lectura (cuentas + transacciones)',
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
                        'El consentimiento expira en $daysRemaining días. '
                        'Renuévalo para seguir sincronizando.',
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
                        'El consentimiento ha expirado. Renuévalo para reactivar la sincronización.',
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
                        label: const Text('Renovar 90 días'),
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
                    label: const Text(
                      'Revocar',
                      style: TextStyle(color: AppColors.error),
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
