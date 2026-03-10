/// Página de Configuración 2FA — RNF-03
///
/// RNF-03: Autenticación de dos factores (2FA) TOTP
///  - Muestra código QR para escanear con Google Authenticator / Authy
///  - Campo para verificar el primer código y activar 2FA
///  - Muestra códigos de recuperación de emergencia (solo al activar)
///  - Opción para desactivar 2FA (requiere contraseña)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/l10n/app_localizations.dart';

/// RNF-03: Flujo completo de configuración y gestión de 2FA TOTP.
class TwoFaSetupPage extends StatefulWidget {
  const TwoFaSetupPage({super.key});

  @override
  State<TwoFaSetupPage> createState() => _TwoFaSetupPageState();
}

class _TwoFaSetupPageState extends State<TwoFaSetupPage> {
  final _apiClient = di.sl<ApiClient>();

  bool _loading = true;
  bool _is2faEnabled = false;
  String? _otpauthUri;
  String? _secret;
  List<String>? _recoveryCodes;

  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _verifying = false;
  bool _disabling = false;
  bool _obscurePassword = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await _apiClient.get('/auth/2fa/status');
      setState(() {
        _is2faEnabled = res.data['is_2fa_enabled'] as bool;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setup() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await _apiClient.post('/auth/2fa/setup');
      setState(() {
        _secret = res.data['secret'] as String;
        _otpauthUri = res.data['otpauth_uri'] as String;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _verify() async {
    final s = AppLocalizations.of(context);
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMsg = s.code2faHint);
      return;
    }
    setState(() {
      _verifying = true;
      _errorMsg = null;
    });
    try {
      final res = await _apiClient.post(
        '/auth/2fa/verify',
        data: {'code': code},
      );
      setState(() {
        _is2faEnabled = true;
        _recoveryCodes = List<String>.from(res.data['recovery_codes'] ?? []);
        _otpauthUri = null;
        _secret = null;
        _codeController.clear();
        _verifying = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg =
            'Código incorrecto. Verifica que la hora de tu dispositivo sea correcta.'; // TODO: add localization key
        _verifying = false;
      });
    }
  }

  Future<void> _disable() async {
    final s = AppLocalizations.of(context);
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(
        () => _errorMsg =
            'Introduce tu contraseña para desactivar el 2FA', // TODO: add localization key
      );
      return;
    }
    setState(() {
      _disabling = true;
      _errorMsg = null;
    });
    try {
      await _apiClient.post('/auth/2fa/disable', data: {'password': password});
      setState(() {
        _is2faEnabled = false;
        _passwordController.clear();
        _disabling = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.twoFaDisabled),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Contraseña incorrecta'; // TODO: add localization key
        _disabling = false;
      });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(s.twoFactorAuth, style: AppTypography.titleMedium()),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusHeader(s),
                  const SizedBox(height: 20),
                  if (_errorMsg != null) _buildError(),
                  if (!_is2faEnabled && _otpauthUri == null)
                    _buildSetupPrompt(s),
                  if (_otpauthUri != null) _buildQrSection(s),
                  if (_is2faEnabled && _recoveryCodes == null)
                    _buildEnabledView(s),
                  if (_recoveryCodes != null) _buildRecoveryCodes(s),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusHeader(AppLocalizations s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _is2faEnabled ? AppColors.successSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _is2faEnabled
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _is2faEnabled
                ? Icons.verified_user_rounded
                : Icons.security_rounded,
            color: _is2faEnabled ? AppColors.success : AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _is2faEnabled ? s.twoFaEnabled : s.twoFaDisabled,
                  style: AppTypography.titleSmall(
                    color: _is2faEnabled
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
                Text(
                  _is2faEnabled
                      ? 'Tu cuenta está protegida con autenticación en dos pasos' // TODO: add localization key
                      : 'Activa el 2FA para mayor seguridad en tu cuenta', // TODO: add localization key
                  style: AppTypography.bodySmall(color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMsg!,
              style: AppTypography.bodySmall(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPrompt(AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo funciona?',
          style: AppTypography.titleSmall(),
        ), // TODO: add localization key
        const SizedBox(height: 12),
        _infoRow(
          Icons.phone_android_rounded,
          'Instala una app autenticadora como Google Authenticator o Authy', // TODO: add localization key
        ),
        _infoRow(Icons.qr_code_scanner_rounded, s.scan2faQr),
        _infoRow(Icons.pin_rounded, s.enter2faCode),
        _infoRow(
          Icons.lock_rounded,
          'En cada inicio de sesión se pedirá el código temporal', // TODO: add localization key
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _setup,
            icon: const Icon(Icons.security_rounded),
            label: Text(s.setup2fa),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall(color: AppColors.gray600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection(AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.scan2faQr, style: AppTypography.titleSmall()),
        const SizedBox(height: 8),
        Text(
          'Abre Google Authenticator o Authy y escanea este código:', // TODO: add localization key
          style: AppTypography.bodySmall(color: AppColors.gray600),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: QrImageView(
              data: _otpauthUri!,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Clave manual por si falla el QR
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿No puedes escanear el QR? Introduce la clave manual:', // TODO: add localization key
                style: AppTypography.labelSmall(color: AppColors.gray600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _secret ?? '',
                      style: AppTypography.titleSmall(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _secret ?? ''));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(s.codeCopied)));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(s.verifyCode, style: AppTypography.titleSmall()),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge(),
          decoration: InputDecoration(
            hintText: s.code2faHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _verifying ? null : _verify,
            icon: _verifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(_verifying ? s.loading : s.enable2fa),
          ),
        ),
      ],
    );
  }

  Widget _buildEnabledView(AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '2FA activo. Se pedirá código al iniciar sesión.', // TODO: add localization key
                style: AppTypography.bodySmall(color: AppColors.successDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          s.disable2fa,
          style: AppTypography.titleSmall(color: AppColors.error),
        ),
        const SizedBox(height: 8),
        Text(
          'Introduce tu contraseña para desactivar la autenticación en dos pasos:', // TODO: add localization key
          style: AppTypography.bodySmall(color: AppColors.gray600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Contraseña actual', // TODO: add localization key
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _disabling ? null : _disable,
            icon: _disabling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open_rounded),
            label: Text(_disabling ? s.loading : s.disable2fa),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryCodes(AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Guarda estos códigos ahora! Solo se muestran una vez. Úsalos si pierdes acceso a tu autenticador.', // TODO: add localization key
                  style: AppTypography.bodySmall(color: AppColors.warningDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(s.recoveryCodes, style: AppTypography.titleSmall()),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            children: [
              ...?_recoveryCodes?.map(
                (code) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.key_rounded,
                        size: 14,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 8),
                      Text(code, style: AppTypography.titleSmall()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final codesText = _recoveryCodes!.join('\n');
                  Clipboard.setData(ClipboardData(text: codesText));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s.codeCopied)));
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(s.copyCode),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => _recoveryCodes = null),
            child: Text(s.done),
          ),
        ),
      ],
    );
  }
}
