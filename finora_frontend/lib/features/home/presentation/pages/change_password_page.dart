import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final apiClient = di.sl<ApiClient>();
      await apiClient.put(
        '/user/change-password',
        data: {
          'currentPassword': _currentCtrl.text,
          'newPassword': _newCtrl.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        final msg = e.toString().contains('401')
            ? 'Contraseña actual incorrecta'
            : 'Error al cambiar contraseña';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Seguridad', style: AppTypography.titleMedium()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cambiar contraseña', style: AppTypography.headlineSmall()),
              const SizedBox(height: 8),
              Text(
                'Tu nueva contraseña debe tener al menos 8 caracteres e incluir números o símbolos.',
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _currentCtrl,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Introduce tu contraseña actual'
                    : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) =>
                    (v != null && v.length < 8) ? 'Mínimo 8 caracteres' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
                validator: (v) => (v != _newCtrl.text)
                    ? 'Las contraseñas no coinciden'
                    : null,
              ),

              const SizedBox(height: 40),

              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Actualizar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
