import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Pantalla WebView que carga el flujo de autenticación de Plaid Link (RF-10).
///
/// Usa el WebView interno del sistema en lugar de Chrome Custom Tabs para:
/// - Permitir tráfico HTTP en redes locales de desarrollo (Android usesCleartextTraffic)
/// - Evitar ERR_SSL_PROTOCOL_ERROR causado por el modo HTTPS-first de Chrome
///
/// Cuando el WebView navega a '/callback-success' (señal de que Plaid completó
/// el intercambio de tokens), cierra la pantalla y vuelve a BankConnectingPage.
class PlaidLinkScreen extends StatefulWidget {
  final String authUrl;

  const PlaidLinkScreen({super.key, required this.authUrl});

  @override
  State<PlaidLinkScreen> createState() => _PlaidLinkScreenState();
}

class _PlaidLinkScreenState extends State<PlaidLinkScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _closed = false; // evitar doble Navigator.pop

  /// Cierra el WebView de forma segura con los datos opcionales del token.
  /// [tokenData] es un Map con {public_token, institution_name} si el flujo
  /// Plaid completó con éxito; null si el usuario canceló o hay error.
  void _closeScreen([Map<String, String>? tokenData]) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.pop(context, tokenData);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      // Canal JS: el HTML envía {public_token, institution_name} como JSON.
      // Flutter lo parsea y hace el intercambio con su propio HTTP client,
      // evitando las restricciones de red del WebView de Android.
      ..addJavaScriptChannel(
        'FlutterPlaid',
        onMessageReceived: (msg) {
          try {
            final data = jsonDecode(msg.message) as Map<String, dynamic>;
            final publicToken = data['public_token'] as String?;
            final instName = (data['institution_name'] as String?) ??
                (mounted ? AppLocalizations.of(context).bankFallbackName : 'Bank');
            if (publicToken != null && publicToken.isNotEmpty) {
              _closeScreen({
                'public_token': publicToken,
                'institution_name': instName,
              });
              return;
            }
          } catch (_) {}
          // Mensaje no parseable o sin token: cerrar sin datos
          _closeScreen();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
            // Fallback: en Android, onNavigationRequest no siempre se dispara
            // para navegación iniciada por JavaScript (window.location.href).
            // onPageFinished sí se dispara para todas las cargas de página.
            if (url.contains('callback-success')) _closeScreen();
          },
          onNavigationRequest: (request) {
            // Detección primaria para navegación iniciada por el usuario
            if (request.url.contains('callback-success')) {
              _closeScreen();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('[PlaidLink] resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.textPrimaryLight,
          ),
          tooltip: AppLocalizations.of(context).cancel,
          // CU-02 FA2: Devolver {'cancelled':'true'} para distinguir cancelación
          // explícita del usuario de otros tipos de cierre (error, timeout).
          onPressed: () => _closeScreen({'cancelled': 'true'}),
        ),
        title: Text(AppLocalizations.of(context).connectBank, style: AppTypography.titleMedium()),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.gray200,
                  color: AppColors.primary,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
