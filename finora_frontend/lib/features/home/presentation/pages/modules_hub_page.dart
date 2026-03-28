import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';
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

  /// Columnas del grid adaptadas al tamaño de pantalla
  int _gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.tabletLarge) return 4;
    if (width >= Breakpoints.tabletSmall) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surfaceLight,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(s.modules, style: AppTypography.titleLarge()),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.surfaceLight,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _AccountsCard(s: s, onNavigate: onNavigateToAccounts),
            ),
          ),
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // Tablet: 3 columnas en portrait, 4 en landscape / iPad Pro
                crossAxisCount: _gridColumns(context),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: _gridColumns(context) >= 3 ? 1.2 : 1.1,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
    return GestureDetector(
      onTap: () {
        if (onNavigate != null) {
          onNavigate!();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccountsPage(onViewAccountTransactions: null),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.accounts,
                    style: AppTypography.titleMedium(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.accountsSubtitle,
                    style: AppTypography.bodySmall(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              label,
              style: AppTypography.titleSmall(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.labelSmall(color: AppColors.gray500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
