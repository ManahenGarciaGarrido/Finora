import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/bank_institution_entity.dart';
import '../bloc/bank_bloc.dart';
import '../bloc/bank_event.dart';
import '../bloc/bank_state.dart';
import 'bank_connection_tutorial.dart';
import 'psd2_consent_dialog.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

/// Bottom sheet that lists available banking institutions (RF-10).
/// Opened from AccountsPage when the user taps "Conectar banco".
///
/// HU-05: Muestra el tutorial en la primera conexión y el dialog
///        de consentimiento PSD2 antes de iniciar el flujo OAuth.
class InstitutionSelectorSheet extends StatefulWidget {
  const InstitutionSelectorSheet({super.key});

  /// HU-05: Abre el tutorial si es la primera vez, luego el selector de bancos.
  static Future<void> show(BuildContext context) async {
    // Tutorial de primera conexión (HU-05 AC: "tutorial opcional")
    final proceed = await BankConnectionTutorial.showIfNeeded(context);
    if (!proceed || !context.mounted) return;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BankBloc>(),
        child: const InstitutionSelectorSheet(),
      ),
    );
  }

  @override
  State<InstitutionSelectorSheet> createState() =>
      _InstitutionSelectorSheetState();
}

class _InstitutionSelectorSheetState extends State<InstitutionSelectorSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<BankBloc>().add(const LoadInstitutions());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      snap: true,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
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
                          Text(
                            AppLocalizations.of(context).chooseBankTitle,
                            style: AppTypography.titleLarge(),
                          ),
                          Text(
                            AppLocalizations.of(context).securePsd2Connection,
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).searchBankHint,
                    hintStyle: AppTypography.bodyMedium(
                      color: AppColors.textTertiaryLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.gray400,
                      size: 20,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.gray400,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.gray200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.gray200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Institution list
              Expanded(
                child: BlocConsumer<BankBloc, BankState>(
                  listener: (context, state) {
                    // Real OAuth mode: close sheet when URL is ready
                    if (state is BankConnectAuthUrlReady) {
                      Navigator.pop(context);
                    }
                  },
                  builder: (context, state) {
                    if (state is InstitutionsLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SkeletonListLoader(count: 6, cardHeight: 64),
                      );
                    }

                    if (state is InstitutionsError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 40,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context).errorLoadingBanks,
                              style: AppTypography.titleSmall(),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.read<BankBloc>().add(
                                const LoadInstitutions(),
                              ),
                              child: Text(AppLocalizations.of(context).retry),
                            ),
                          ],
                        ),
                      );
                    }

                    List<BankInstitutionEntity> institutions = [];
                    if (state is InstitutionsLoaded) {
                      institutions = state.institutions.where((inst) {
                        return _query.isEmpty ||
                            inst.name.toLowerCase().contains(_query);
                      }).toList();
                    }

                    if (institutions.isEmpty && state is InstitutionsLoaded) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context).noBanksFound,
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: institutions.length,
                      itemBuilder: (context, i) {
                        final inst = institutions[i];
                        return _InstitutionTile(institution: inst);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InstitutionTile extends StatelessWidget {
  final BankInstitutionEntity institution;

  const _InstitutionTile({required this.institution});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // HU-05: Mostrar dialog de consentimiento PSD2 antes de conectar.
        // El dialog explica claramente los permisos solicitados.
        final accepted = await Psd2ConsentDialog.show(
          context,
          institution.name,
        );
        if (!accepted || !context.mounted) return;

        // Close the sheet immediately, then dispatch the event.
        Navigator.pop(context);
        context.read<BankBloc>().add(ConnectBankRequested(institution.id));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: [
            // Logo / fallback icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: institution.logo != null
                  ? Image.network(
                      institution.logo!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance_rounded,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.primary,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(institution.name, style: AppTypography.titleSmall()),
                  if (institution.bic != null)
                    Text(
                      institution.bic!,
                      style: AppTypography.bodySmall(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.gray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
