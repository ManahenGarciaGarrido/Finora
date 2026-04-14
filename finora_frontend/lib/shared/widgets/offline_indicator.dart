import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Indicador visual de modo offline (RNF-15)
///
/// Muestra un banner animado en la parte superior cuando
/// no hay conexión a internet. Se oculta automáticamente
/// al recuperar la conexión.
class OfflineIndicator extends StatefulWidget {
  final ConnectivityService connectivityService;
  final Widget child;

  const OfflineIndicator({
    super.key,
    required this.connectivityService,
    required this.child,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOffline = false;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _isOffline = !widget.connectivityService.isOnline;
    _subscription = widget.connectivityService.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() => _isOffline = !isOnline);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOffline ? null : 0,
          curve: Curves.easeInOut,
          child: _isOffline
              ? Material(
                  color: AppColors.warning,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sin conexión — Los datos se guardan localmente',
                              style: AppTypography.labelSmall(
                                color: AppColors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
