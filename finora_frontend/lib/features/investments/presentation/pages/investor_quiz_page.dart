import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../bloc/investment_bloc.dart';
import '../bloc/investment_event.dart';
import '../bloc/investment_state.dart';
import 'investment_allocation_animation_page.dart';

class InvestorQuizPage extends StatefulWidget {
  const InvestorQuizPage({super.key});

  @override
  State<InvestorQuizPage> createState() => _InvestorQuizPageState();
}

class _InvestorQuizPageState extends State<InvestorQuizPage> {
  String _risk = 'moderate';
  String _horizon = 'medium';
  final _capacityCtrl = TextEditingController();

  @override
  void dispose() {
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
    return BlocListener<InvestmentBloc, InvestmentState>(
      listener: (ctx, state) {
        if (state is ProfileSaved) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: ctx.read<InvestmentBloc>(),
                child: const InvestmentAllocationAnimationPage(),
              ),
            ),
          );
        } else if (state is InvestmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
          title: Text(s.quizTitle, style: AppTypography.titleMedium()),
          leading: const BackButton(),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.isTablet ? 640 : double.infinity),
            child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(s.recommendedStrategy,
                style: AppTypography.labelSmall(color: AppColors.gray500)),
            const SizedBox(height: 16),
            // Risk tolerance
            Text(s.healthScore, style: AppTypography.titleSmall()),
            const SizedBox(height: 8),
            _riskOption(s, 'conservative', s.profileConservative,
                s.profileConservativeDesc, Icons.shield_outlined),
            const SizedBox(height: 8),
            _riskOption(s, 'moderate', s.profileModerate,
                s.profileModerateDesc, Icons.balance_rounded),
            const SizedBox(height: 8),
            _riskOption(s, 'aggressive', s.profileAggressive,
                s.profileAggressiveDesc, Icons.trending_up_rounded),
            const SizedBox(height: 24),
            // Investment horizon
            Text(s.investmentHorizon, style: AppTypography.titleSmall()),
            const SizedBox(height: 8),
            _horizonOption(s, 'short', s.shortTerm),
            const SizedBox(height: 8),
            _horizonOption(s, 'medium', s.mediumTerm),
            const SizedBox(height: 8),
            _horizonOption(s, 'long', s.longTerm),
            const SizedBox(height: 24),
            // Monthly capacity
            TextFormField(
              controller: _capacityCtrl,
              decoration: InputDecoration(
                  labelText: s.monthlyCapacity,
                  prefixText: '€ ',
                  border: const OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(s.saveProfile),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _riskOption(
      dynamic s, String value, String label, String desc, IconData icon) {
    final selected = _risk == value;
    return GestureDetector(
      onTap: () => setState(() => _risk = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.gray200,
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.gray400,
                size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.titleSmall(
                          color: selected
                              ? AppColors.primary
                              : null)),
                  Text(desc,
                      style: AppTypography.bodySmall(
                          color: AppColors.gray500)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _horizonOption(dynamic s, String value, String label) {
    final selected = _horizon == value;
    return GestureDetector(
      onTap: () => setState(() => _horizon = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.gray200,
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTypography.bodyMedium(
                      color: selected ? AppColors.primary : null)),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _save() {
    context.read<InvestmentBloc>().add(SaveProfile({
          'risk_tolerance': _risk,
          'investment_horizon': _horizon,
          'monthly_capacity':
              _capacityCtrl.text.isEmpty
                  ? null
                  : double.tryParse(
                      _capacityCtrl.text.replaceAll(',', '.')),
        }));
  }
}