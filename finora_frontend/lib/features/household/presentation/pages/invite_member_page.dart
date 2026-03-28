import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';

/// Full-page form to invite a member to the household by email.
/// Returns the entered email string when the invite is sent.
class InviteMemberPage extends StatefulWidget {
  const InviteMemberPage({super.key});

  @override
  State<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends State<InviteMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _invite() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
    final appBar = AppBar(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      leading: const BackButton(),
      title: Text(s.inviteMember, style: AppTypography.titleMedium()),
    );
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF039BE5).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF039BE5).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Color(0xFF039BE5),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.inviteMember,
                  style: AppTypography.titleMedium(
                    color: const Color(0xFF039BE5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.householdInviteInfo,
                    style: AppTypography.bodySmall(color: AppColors.gray700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Email field
          Text(
            s.email,
            style: AppTypography.labelSmall(color: AppColors.gray600),
          ),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                fillColor: AppColors.cardLight,
                prefixIcon: const Icon(Icons.email_outlined),
                hintText: 'correo@ejemplo.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return s.enterAccountNameError;
                }
                if (!v.contains('@') || !v.contains('.')) {
                  return s.invalidEmail;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _invite,
              icon: const Icon(Icons.send_rounded),
              label: Text(s.inviteMember),
            ),
          ),
        ],
      ),
    );
    if (responsive.isTablet) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: appBar,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: body,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: appBar,
      body: body,
    );
  }
}
