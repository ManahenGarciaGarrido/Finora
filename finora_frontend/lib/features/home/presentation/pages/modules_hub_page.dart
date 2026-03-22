import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../debts/presentation/pages/debts_page.dart';
import '../../../investments/presentation/pages/investments_page.dart';
import '../../../household/presentation/pages/household_page.dart';
import '../../../gamification/presentation/pages/gamification_page.dart';
import '../../../fiscal/presentation/pages/fiscal_page.dart';
import '../../../ocr/presentation/pages/ocr_page.dart';
import '../../../widget/presentation/pages/widget_page.dart';
import 'accounts_page.dart';
import 'budget_page.dart';

class ModulesHubPage extends StatelessWidget {
  /// Callback para navegar a AccountsPage dentro del IndexedStack de HomePage.
  final VoidCallback? onNavigateToAccounts;

  const ModulesHubPage({super.key, this.onNavigateToAccounts});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(), // Animación de rebote más suave
        slivers: [
          SliverAppBar(
            expandedHeight: 110, // Altura ajustada
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surfaceLight, // Fondo plano y limpio
            elevation: 0,
            automaticallyImplyLeading: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20), // Borde redondeado suave
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 18),
              title: Text(
                s.modules,
                style: AppTypography.titleLarge().copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors
                      .primaryDark, // Texto claro sin el efecto de fondo
                ),
              ),
            ),
          ),

          // Tarjeta principal (Cuentas)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: _AccountsCard(s: s, onNavigate: onNavigateToAccounts),
            ),
          ),

          // Grid de Módulos
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _ModuleCard(
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF6C63FF),
                  label: s.budgetTitle,
                  subtitle: s.budgetSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetPage()),
                  ),
                ),
                _ModuleCard(
                  icon: Icons.credit_card_off_rounded,
                  color: const Color(0xFFE53935),
                  label: s.debtsTitle,
                  subtitle: s.debtsSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebtsPage()),
                  ),
                ),
                _ModuleCard(
                  icon: Icons.show_chart_rounded,
                  color: const Color(0xFF00897B),
                  label: s.investmentsTitle,
                  subtitle: s.investmentsSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InvestmentsPage()),
                  ),
                ),
                _ModuleCard(
                  icon: Icons.people_rounded,
                  color: const Color(0xFF039BE5),
                  label: s.householdTitle,
                  subtitle: s.householdSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HouseholdPage()),
                  ),
                ),
                _ModuleCard(
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFFF8F00),
                  label: s.gamificationTitle,
                  subtitle: s.gamificationSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GamificationPage()),
                  ),
                ),
                _ModuleCard(
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF5E35B1),
                  label: s.fiscalTitle,
                  subtitle: s.fiscalSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FiscalPage()),
                  ),
                ),
                _ModuleCard(
                  icon: Icons.document_scanner_rounded,
                  color: const Color(0xFF00ACC1),
                  label: s.ocrTitle,
                  subtitle: s.ocrSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OcrPage()),
                  ),
                ),
                _ModuleCard(
                  icon: Icons.widgets_rounded,
                  color: const Color(0xFF43A047),
                  label: s.widgetTitle,
                  subtitle: s.widgetSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WidgetPage()),
                  ),
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.95, // Ajustado para un mejor diseño
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ), // Espaciado final
        ],
      ),
    );
  }
}

class _AccountsCard extends StatelessWidget {
  final dynamic s;
  final VoidCallback? onNavigate;
  const _AccountsCard({required this.s, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (onNavigate != null) {
              onNavigate!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AccountsPage(onViewAccountTransactions: null),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.accounts,
                        style: AppTypography.titleMedium(
                          color: Colors.white,
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        s.accountsSubtitle,
                        style: AppTypography.bodySmall(
                          color: Colors.white.withValues(alpha: 0.8),
                        ).copyWith(height: 1.2),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const Spacer(),
                Text(
                  label,
                  style: AppTypography.titleSmall().copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall(
                    color: AppColors.gray500,
                  ).copyWith(height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
