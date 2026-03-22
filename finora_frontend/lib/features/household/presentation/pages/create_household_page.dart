import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';

class CreateHouseholdPage extends StatefulWidget {
  const CreateHouseholdPage({super.key});

  @override
  State<CreateHouseholdPage> createState() => _CreateHouseholdPageState();
}

class _CreateHouseholdPageState extends State<CreateHouseholdPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
    final appBar = AppBar(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      title: Text(s.createHousehold, style: AppTypography.titleMedium()),
      leading: const BackButton(),
    );
    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Icon(Icons.home_rounded, color: AppColors.primary, size: 64),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: s.householdName,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, _nameCtrl.text.trim());
                  }
                },
                child: Text(s.createHousehold),
              ),
            ),
          ],
        ),
      ),
    );
    if (responsive.isTablet) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: appBar,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
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