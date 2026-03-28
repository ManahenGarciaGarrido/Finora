import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/profile_photo_service.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../../core/responsive/breakpoints.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  bool _isSaving = false;
  String? _photoPath;
  String? _remotePhotoBase64; // loaded from backend on init

  // Language and currency state
  String _selectedLocale = 'es';
  late CurrencyConfig _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String initialName = '';
    if (authState is Authenticated) {
      initialName = authState.user.name;
    }
    _nameController = TextEditingController(text: initialName);
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _selectedLocale = AppSettingsService().currentLocaleCode;
    _selectedCurrency = AppSettingsService().currentCurrency;
    _loadRemotePhoto();
  }

  Future<void> _loadRemotePhoto() async {
    try {
      final apiClient = di.sl<ApiClient>();
      final resp = await apiClient.get('/user/profile');
      final data = resp.data as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final photo = user['photoBase64'] as String?;
      if (photo != null && photo.isNotEmpty && mounted) {
        setState(() => _remotePhotoBase64 = photo);
        ProfilePhotoService().update(photo);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final s = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final apiClient = di.sl<ApiClient>();
      await apiClient.put(
        '/user/profile',
        data: {'name': _nameController.text.trim()},
      );

      // Upload photo if a new one was picked
      if (_photoPath != null) {
        final bytes = await File(_photoPath!).readAsBytes();
        final base64Str = base64Encode(bytes);
        await apiClient.post(
          '/user/profile/photo',
          data: {'photo_base64': base64Str},
        );
        ProfilePhotoService().update(base64Str);
      }

      if (mounted) {
        context.read<AuthBloc>().add(
          UpdateProfileName(name: _nameController.text.trim()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileUpdatedMsg),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileUpdateErrorMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _photoPath = picked.path);
    }
  }

  void _showPhotoPicker() {
    final s = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(s.ticketPhoto, style: AppTypography.titleMedium()),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(s.camera, style: AppTypography.bodyMedium()),
                subtitle: Text(
                  s.takePictureNow,
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(s.gallery, style: AppTypography.bodyMedium()),
                subtitle: Text(
                  s.selectFromGallery,
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_photoPath != null)
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  title: Text(
                    s.deletePhoto,
                    style: AppTypography.bodyMedium(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photoPath = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageLabel() {
    final s = AppLocalizations.of(context);
    return _selectedLocale == 'es' ? s.spanish : s.english;
  }

  Future<void> _showLanguageDialog() async {
    final s = AppLocalizations.of(context);
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(s.language),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'es'),
            child: Row(
              children: [
                const Text('🇪🇸  '),
                Text(
                  s.spanish,
                  style: _selectedLocale == 'es'
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
                if (_selectedLocale == 'es')
                  const Spacer()
                else
                  const SizedBox(),
                if (_selectedLocale == 'es')
                  const Icon(Icons.check_rounded, size: 16),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'en'),
            child: Row(
              children: [
                const Text('🇬🇧  '),
                Text(
                  s.english,
                  style: _selectedLocale == 'en'
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
                if (_selectedLocale == 'en')
                  const Spacer()
                else
                  const SizedBox(),
                if (_selectedLocale == 'en')
                  const Icon(Icons.check_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null && selected != _selectedLocale) {
      setState(() => _selectedLocale = selected);
      await AppSettingsService().setLocale(selected);
    }
  }

  Future<void> _showCurrencyDialog() async {
    final selected = await showDialog<CurrencyConfig>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context).settingsCurrency,
          style: AppTypography.titleMedium(),
        ),
        children: AppSettingsService.availableCurrencies.map((cfg) {
          final isSelected = cfg.code == _selectedCurrency.code;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, cfg),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primarySoft
                          : AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cfg.symbol,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cfg.code, style: AppTypography.titleSmall()),
                        Text(
                          cfg.name,
                          style: AppTypography.bodySmall(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null && selected.code != _selectedCurrency.code) {
      await AppSettingsService().setCurrency(selected);
      setState(() => _selectedCurrency = selected);
    }
  }

  Widget _buildBodyContent(AppLocalizations s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile picture section ───────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _showPhotoPicker,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage: _photoPath != null
                          ? FileImage(File(_photoPath!)) as ImageProvider
                          : (_remotePhotoBase64 != null
                                ? MemoryImage(base64Decode(_remotePhotoBase64!))
                                : null),
                      child: (_photoPath == null && _remotePhotoBase64 == null)
                          ? Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : 'U',
                              style: AppTypography.headlineLarge(
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.backgroundLight,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Información personal section ──────────────────────────────
            Text(
              s.publicInfoHeading,
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),

            // Full name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                fillColor: AppColors.cardLight,
                labelText: s.fullNameLabel,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.nameRequiredError : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Phone number field (optional)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                fillColor: AppColors.cardLight,
                labelText: '${s.phoneNumber} (${s.optional})',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bio field (optional, max 150 chars)
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                fillColor: AppColors.cardLight,
                labelText: '${s.profileBio} (${s.optional})',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.notes_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // ── Idioma y moneda section ───────────────────────────────────
            Text(
              s.languageAndCurrency,
              style: AppTypography.labelMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),

            // Language selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray100),
              ),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    size: 20,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                title: Text(s.language, style: AppTypography.titleSmall()),
                subtitle: Text(
                  _getLanguageLabel(),
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.gray400,
                ),
                onTap: _showLanguageDialog,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Currency selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray100),
              ),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.currency_exchange_rounded,
                    size: 20,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                title: Text(
                  s.settingsCurrency,
                  style: AppTypography.titleSmall(),
                ),
                subtitle: Text(
                  '${_selectedCurrency.code} - ${_selectedCurrency.name}',
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.gray400,
                ),
                onTap: _showCurrencyDialog,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
    final appBar = AppBar(
      title: Text(s.editProfileTitle, style: AppTypography.titleMedium()),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isSaving)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              s.save,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
    if (responsive.isTablet) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: appBar,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _buildBodyContent(s),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: appBar,
      body: _buildBodyContent(s),
    );
  }
}
