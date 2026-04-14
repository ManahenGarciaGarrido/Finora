import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../domain/entities/consent.dart';
import '../../../home/presentation/pages/edit_profile_page.dart';
import '../../../../core/responsive/breakpoints.dart';

/// Página de Privacidad y GDPR
///
/// Conectada a la API real para gestionar consentimientos,
/// exportar datos y eliminar cuenta.
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _isLoading = true;
  final Map<ConsentType, bool> _consents = {};
  final ApiClient _apiClient = di.sl<ApiClient>();

  @override
  void initState() {
    super.initState();
    _loadConsentsFromApi();
  }

  Future<void> _loadConsentsFromApi() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.gdprUserConsents);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final consentsMap = data['consents'] as Map<String, dynamic>? ?? {};

        setState(() {
          for (final type in ConsentType.values) {
            final key = type.key;
            _consents[type] = consentsMap[key] == true;
          }
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading consents from API: $e');
    }

    // Fallback to defaults
    setState(() {
      for (final type in ConsentType.values) {
        _consents[type] = type.isRequired;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final appBar = AppBar(
      title: Text(AppLocalizations.of(context).privacyAndData),
      elevation: 0,
    );
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGDPRInfoCard(),
                const SizedBox(height: 24),
                _buildConsentsSection(),
                const SizedBox(height: 24),
                _buildUserRightsSection(),
                const SizedBox(height: 24),
                _buildDangerZoneSection(),
              ],
            ),
          );
    if (responsive.isTablet) {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: body,
          ),
        ),
      );
    }
    return Scaffold(appBar: appBar, body: body);
  }

  Widget _buildGDPRInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).gdprCompliance,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).gdprComplianceDesc,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showPrivacyPolicy,
              icon: const Icon(Icons.description),
              label: Text(AppLocalizations.of(context).viewPrivacyPolicy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).consentManagement,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).consentManagementSubtitle,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...ConsentType.values.map((type) => _buildConsentTile(type)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveConsents,
                child: Text(AppLocalizations.of(context).savePreferences),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentTile(ConsentType type) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(type.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.description, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                type.legalBasis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).primaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          value: _consents[type] ?? false,
          onChanged: type.isRequired
              ? null
              : (value) {
                  setState(() {
                    _consents[type] = value;
                  });
                },
          secondary: type.isRequired
              ? Chip(
                  label: Text(
                    AppLocalizations.of(context).required,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.orange,
                  labelStyle: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildUserRightsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).gdprRights,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRightTile(
              icon: Icons.download,
              title: AppLocalizations.of(context).rightOfAccess,
              subtitle: AppLocalizations.of(context).rightOfAccessDesc,
              onTap: _exportUserData,
            ),
            _buildRightTile(
              icon: Icons.edit,
              title: AppLocalizations.of(context).rightOfRectification,
              subtitle: AppLocalizations.of(context).rightOfRectificationDesc,
              onTap: _navigateToProfile,
            ),
            _buildRightTile(
              icon: Icons.history,
              title: AppLocalizations.of(context).consentHistoryTitle,
              subtitle: AppLocalizations.of(context).consentHistoryDesc,
              onTap: _showConsentHistory,
            ),
            _buildRightTile(
              icon: Icons.info_outline,
              title: AppLocalizations.of(context).dataProcessingInfoTitle,
              subtitle: AppLocalizations.of(context).dataProcessingInfoDesc,
              onTap: _showDataProcessingInfo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDangerZoneSection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).dangerZone,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).dangerZoneDesc,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(
                  AppLocalizations.of(context).deleteMyAccount,
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).privacyPolicyTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: const [_PrivacyPolicyContent()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConsents() async {
    try {
      final consentsMap = <String, bool>{};
      for (final entry in _consents.entries) {
        consentsMap[entry.key.key] = entry.value;
      }

      final response = await _apiClient.post(
        ApiEndpoints.gdprConsents,
        data: {'consents': consentsMap},
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).preferencesSavedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportUserData() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).exportMyData),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).exportDataDesc),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).exportDataIncludesLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).exportDataItem1),
            Text(AppLocalizations.of(context).exportDataItem2),
            Text(AppLocalizations.of(context).exportDataItem3),
            Text(AppLocalizations.of(context).exportDataItem4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performExport();
            },
            child: Text(AppLocalizations.of(context).exportData),
          ),
        ],
      ),
    );
  }

  Future<void> _performExport() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.gdprExport);

      if (response.statusCode == 200 && mounted) {
        final data = response.data as Map<String, dynamic>;
        final exportData = data['data'] as Map<String, dynamic>?;

        if (exportData != null) {
          _showExportResultDialog(exportData);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).errorExportingData}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportResultDialog(Map<String, dynamic> exportData) {
    final personalData = exportData['personalData'] as Map<String, dynamic>?;
    final financialData = exportData['financialData'] as Map<String, dynamic>?;
    final totalTransactions = financialData?['totalTransactions'] ?? 0;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).dataExportedTitle),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).dataSummary,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '${AppLocalizations.of(context).nameLabel}: ${personalData?['name'] ?? 'N/A'}',
              ),
              Text('Email: ${personalData?['email'] ?? 'N/A'}'),
              Text(
                '${AppLocalizations.of(context).transactionsLabel}: $totalTransactions',
              ),
              Text(
                '${AppLocalizations.of(context).registrationDateLabel}: ${_formatDate(personalData?['registrationDate'])}',
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).exportResultNote,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  void _showConsentHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ConsentHistorySheet(apiClient: _apiClient),
    );
  }

  void _showDataProcessingInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).dataProcessingInfoTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: const [_DataProcessingContent()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).deleteAccountConfirmTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).deleteAccountWarningTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).deleteAccountWarningItems,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).deleteAccountGdprNote,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showDeleteConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).next),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    final controller = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmDeletionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).deleteConfirmInstruction),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).deleteConfirmHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).deleteReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text == 'ELIMINAR') {
                Navigator.pop(dialogContext);
                await _performDeleteAccount(reasonController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).typeDeleteToConfirmError,
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).deleteDefinitely),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount(String reason) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.gdprDeleteAccount,
        data: {
          'confirmDeletion': 'DELETE_MY_ACCOUNT',
          'reason': reason.isNotEmpty
              ? reason
              : AppLocalizations.of(context).reasonOptionalHint,
        },
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).accountPermanentlyDeleted,
            ),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          context.read<AuthBloc>().add(const LogoutRequested());
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).errorDeletingAccount}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Sheet that loads and shows consent history from the API
class _ConsentHistorySheet extends StatefulWidget {
  final ApiClient apiClient;

  const _ConsentHistorySheet({required this.apiClient});

  @override
  State<_ConsentHistorySheet> createState() => _ConsentHistorySheetState();
}

class _ConsentHistorySheetState extends State<_ConsentHistorySheet> {
  bool _loading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await widget.apiClient.get(
        ApiEndpoints.gdprConsentHistory,
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _history = data['history'] as List<dynamic>? ?? [];
          _loading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading consent history: $e');
    }
    setState(() => _loading = false);
  }

  String _consentTypeName(BuildContext ctx, String type) {
    final s = AppLocalizations.of(ctx);
    switch (type) {
      case 'essential':
        return s.consentTypeEssential;
      case 'analytics':
        return s.consentTypeAnalytics;
      case 'marketing':
        return s.consentTypeMarketing;
      case 'third_party':
        return s.consentTypeThirdParty;
      case 'personalization':
        return s.consentTypePersonalization;
      case 'data_processing':
        return s.consentTypeDataProcessing;
      default:
        return type;
    }
  }

  String _actionName(BuildContext ctx, String action) {
    final s = AppLocalizations.of(ctx);
    switch (action) {
      case 'INITIAL_REGISTRATION':
        return s.actionInitialRegistration;
      case 'CONSENT_UPDATED':
        return s.actionConsentUpdated;
      case 'CONSENT_WITHDRAWN':
        return s.actionConsentWithdrawn;
      default:
        return action;
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = DateTime.parse(ts.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).consentHistoryTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_history.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  AppLocalizations.of(context).noConsentChanges,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final entry = _history[index] as Map<String, dynamic>;
                  final granted = entry['granted'] == true;
                  return ListTile(
                    leading: Icon(
                      granted ? Icons.check_circle : Icons.cancel,
                      color: granted ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      _consentTypeName(context, entry['consentType'] ?? ''),
                    ),
                    subtitle: Text(
                      '${_actionName(context, entry['action'] ?? '')} - ${_formatTimestamp(entry['timestamp'])}',
                    ),
                    trailing: Text(
                      granted
                          ? AppLocalizations.of(context).acceptedStatus
                          : AppLocalizations.of(context).rejectedStatus,
                      style: TextStyle(
                        color: granted ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget que muestra el contenido de la política de privacidad
class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          '1. Introducción',
          'Esta Política de Privacidad describe cómo Finora ("nosotros", "nuestro" o "la Aplicación") '
              'recopila, usa, almacena y protege su información personal de acuerdo con el Reglamento '
              'General de Protección de Datos (GDPR) de la Unión Europea.',
        ),
        _buildSection(
          '2. Datos que recopilamos',
          'Recopilamos los siguientes tipos de datos:\n'
              '- Datos de identificación: nombre, email, teléfono\n'
              '- Datos financieros: transacciones, saldos, categorías de gasto\n'
              '- Datos de uso: interacciones con la app, preferencias\n'
              '- Datos técnicos: dispositivo, sistema operativo, IP',
        ),
        _buildSection(
          '3. Base legal para el tratamiento',
          'Procesamos sus datos personales bajo las siguientes bases legales:\n'
              '- Ejecución de contrato: para proporcionar nuestros servicios\n'
              '- Consentimiento: para marketing y análisis\n'
              '- Interés legítimo: para seguridad y prevención de fraude\n'
              '- Obligación legal: para cumplir requisitos regulatorios',
        ),
        _buildSection(
          '4. Conservación de datos',
          'Conservamos sus datos personales durante el tiempo necesario:\n'
              '- Datos de cuenta: mientras la cuenta esté activa + 5 años\n'
              '- Datos financieros: 7 años por requisitos legales\n'
              '- Datos de marketing: hasta retirada del consentimiento\n'
              '- Logs de seguridad: 2 años',
        ),
        _buildSection(
          '5. Sus derechos',
          'Bajo el GDPR, usted tiene los siguientes derechos:\n'
              '- Derecho de acceso: obtener copia de sus datos\n'
              '- Derecho de rectificación: corregir datos inexactos\n'
              '- Derecho de supresión: eliminar sus datos ("derecho al olvido")\n'
              '- Derecho de portabilidad: recibir sus datos en formato estructurado\n'
              '- Derecho de oposición: oponerse al tratamiento\n'
              '- Derecho a retirar el consentimiento: en cualquier momento\n'
              '- Derecho a presentar reclamación: ante la autoridad de control',
        ),
        _buildSection(
          '6. Seguridad de los datos',
          'Implementamos medidas técnicas y organizativas apropiadas:\n'
              '- Cifrado AES-256 para datos en reposo\n'
              '- TLS 1.3 para datos en tránsito\n'
              '- Almacenamiento seguro con Keychain/KeyStore\n'
              '- Autenticación multifactor disponible\n'
              '- Auditorías de seguridad regulares',
        ),
        _buildSection(
          '7. Transferencias internacionales',
          'Sus datos se procesan dentro del Espacio Económico Europeo (EEE). '
              'En caso de transferencias fuera del EEE, garantizamos protección adecuada '
              'mediante cláusulas contractuales tipo o decisiones de adecuación de la Comisión Europea.',
        ),
        _buildSection(
          '8. Contacto',
          'Para ejercer sus derechos o realizar consultas sobre privacidad, '
              'contacte con nosotros en: privacy@finora.app',
        ),
        const SizedBox(height: 16),
        Text(
          'Última actualización: Febrero 2026',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}

/// Widget que muestra información sobre el tratamiento de datos
class _DataProcessingContent extends StatelessWidget {
  const _DataProcessingContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPurpose(
          'Gestión de cuenta',
          'Crear y mantener su cuenta de usuario',
          'Ejecución de contrato',
          ['Datos de identificación', 'Credenciales'],
          'Mientras la cuenta esté activa + 5 años',
        ),
        _buildPurpose(
          'Análisis financiero',
          'Proporcionar análisis de sus finanzas personales',
          'Ejecución de contrato',
          ['Transacciones', 'Saldos', 'Categorías'],
          '7 años (requisito legal)',
        ),
        _buildPurpose(
          'Mejora del servicio',
          'Analizar uso para mejorar la experiencia',
          'Interés legítimo / Consentimiento',
          ['Datos de uso', 'Preferencias'],
          '2 años',
        ),
        _buildPurpose(
          'Comunicaciones',
          'Enviar notificaciones y marketing',
          'Consentimiento',
          ['Email', 'Preferencias de comunicación'],
          'Hasta retirada de consentimiento',
        ),
        _buildPurpose(
          'Seguridad',
          'Prevenir fraude y proteger la plataforma',
          'Interés legítimo',
          ['Logs de acceso', 'IP', 'Dispositivo'],
          '2 años',
        ),
        const SizedBox(height: 24),
        const Text(
          'Minimización de datos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Solo recopilamos datos estrictamente necesarios:\n'
          '- Campos opcionales claramente identificados\n'
          '- No recopilamos datos sensibles innecesarios\n'
          '- Revisión periódica de necesidad de datos',
        ),
      ],
    );
  }

  Widget _buildPurpose(
    String purpose,
    String description,
    String legalBasis,
    List<String> categories,
    String retention,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              purpose,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: Colors.grey)),
            const Divider(),
            _buildInfoRow('Base legal', legalBasis),
            _buildInfoRow('Datos', categories.join(', ')),
            _buildInfoRow('Retención', retention),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
