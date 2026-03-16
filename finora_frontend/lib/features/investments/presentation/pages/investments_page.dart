import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../domain/entities/investor_profile_entity.dart';
import '../../domain/entities/portfolio_suggestion_entity.dart';
import '../../domain/entities/market_index_entity.dart';
import '../bloc/investment_bloc.dart';
import '../bloc/investment_event.dart';
import '../bloc/investment_state.dart';
import '../widgets/market_index_card.dart';
import '../widgets/portfolio_allocation_widget.dart';
import '../widgets/return_simulator_widget.dart';
import 'investor_quiz_page.dart';

class InvestmentsPage extends StatefulWidget {
  const InvestmentsPage({super.key});

  @override
  State<InvestmentsPage> createState() => _InvestmentsPageState();
}

class _InvestmentsPageState extends State<InvestmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  InvestorProfileEntity? _profile;
  PortfolioSuggestionEntity? _portfolio;
  List<MarketIndexEntity> _indices = [];
  List<Map<String, dynamic>> _glossary = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocProvider(
      create: (ctx) => di.sl<InvestmentBloc>()..add(const LoadProfile()),
      child: BlocConsumer<InvestmentBloc, InvestmentState>(
        listener: (ctx, state) {
          if (state is ProfileLoaded) {
            setState(() {
              _profile = state.profile;
              _loading = false;
            });
          } else if (state is ProfileSaved) {
            setState(() => _profile = state.profile);
            ctx.read<InvestmentBloc>().add(const LoadPortfolioSuggestion());
          } else if (state is PortfolioLoaded) {
            setState(() {
              _portfolio = state.suggestion;
              _loading = false;
            });
          } else if (state is IndicesLoaded) {
            setState(() {
              _indices = state.indices;
              _loading = false;
            });
          } else if (state is GlossaryLoaded) {
            setState(() {
              _glossary = state.terms;
              _loading = false;
            });
          } else if (state is InvestmentLoading) {
            setState(() => _loading = true);
          } else if (state is InvestmentError) {
            setState(() {
              _loading = false;
            });
          }
        },
        builder: (ctx, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceLight,
              elevation: 0,
              title: Text(
                s.investmentsTitle,
                style: AppTypography.titleMedium(),
              ),
              leading: const BackButton(),
              bottom: TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                isScrollable: true,
                tabs: [
                  Tab(text: s.investorProfileTab),
                  Tab(text: s.portfolioTab),
                  Tab(text: s.simulatorTab),
                  Tab(text: s.marketsTab),
                ],
                onTap: (i) {
                  if (i == 1 && _portfolio == null && _profile != null) {
                    ctx.read<InvestmentBloc>().add(
                      const LoadPortfolioSuggestion(),
                    );
                  }
                  if (i == 3 && _indices.isEmpty) {
                    ctx.read<InvestmentBloc>().add(const LoadIndices());
                  }
                },
              ),
            ),
            body: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonListLoader(count: 4, cardHeight: 80),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildProfileTab(ctx, s),
                      _buildPortfolioTab(ctx, s),
                      _buildSimulatorTab(ctx),
                      _buildMarketsTab(ctx, s),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildProfileTab(BuildContext ctx, dynamic s) {
    if (_profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: AppColors.gray400,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                s.noProfile,
                style: AppTypography.bodyMedium(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _openQuiz(ctx, s),
                icon: const Icon(Icons.quiz_rounded),
                label: Text(s.startQuizBtn),
              ),
            ],
          ),
        ),
      );
    }

    final riskLabel =
        {
          'conservative': s.profileConservative,
          'moderate': s.profileModerate,
          'aggressive': s.profileAggressive,
        }[_profile!.riskTolerance] ??
        _profile!.riskTolerance;

    final horizonLabel =
        {
          'short': s.shortTerm,
          'medium': s.mediumTerm,
          'long': s.longTerm,
        }[_profile!.investmentHorizon] ??
        _profile!.investmentHorizon;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            children: [
              _profileRow(s.recommendedStrategy, riskLabel),
              const Divider(height: 20),
              _profileRow(s.investmentHorizon, horizonLabel),
              if (_profile!.monthlyCapacity != null) ...[
                const Divider(height: 20),
                _profileRow(
                  s.monthlyCapacity,
                  '€ ${_profile!.monthlyCapacity!.toStringAsFixed(2)}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _openQuiz(ctx, s),
          icon: const Icon(Icons.edit_outlined),
          label: Text(s.edit),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(color: AppColors.gray600)),
        Text(value, style: AppTypography.titleSmall()),
      ],
    );
  }

  Widget _buildPortfolioTab(BuildContext ctx, dynamic s) {
    if (_profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                color: AppColors.gray400,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                s.profileRequired,
                style: AppTypography.bodyMedium(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_portfolio == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PortfolioAllocationWidget(suggestion: _portfolio!);
  }

  Widget _buildSimulatorTab(BuildContext ctx) {
    return ReturnSimulatorWidget(
      onSimulate: (data) async {
        ctx.read<InvestmentBloc>().add(SimulateReturns(data));
        // Direct API call for immediate result
        final bloc = ctx.read<InvestmentBloc>();
        await Future.delayed(const Duration(milliseconds: 100));
        final state = bloc.state;
        if (state is SimulationResult) return state.result;
        throw Exception('Simulation failed');
      },
    );
  }

  Widget _buildMarketsTab(BuildContext ctx, dynamic s) {
    if (_indices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              s.loading,
              style: AppTypography.bodySmall(color: AppColors.gray500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          ctx.read<InvestmentBloc>().add(const LoadIndices()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.marketIndices, style: AppTypography.titleSmall()),
          const SizedBox(height: 12),
          ..._indices.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MarketIndexCard(index: i),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.glossaryTitle, style: AppTypography.titleSmall()),
          const SizedBox(height: 8),
          if (_glossary.isEmpty)
            TextButton(
              onPressed: () =>
                  ctx.read<InvestmentBloc>().add(const LoadGlossary()),
              child: Text(s.glossaryTitle),
            )
          else
            ..._glossary.map(
              (term) => ExpansionTile(
                title: Text(
                  term['term'] as String,
                  style: AppTypography.bodyMedium(),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      term['definition_es'] as String,
                      style: AppTypography.bodySmall(color: AppColors.gray600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openQuiz(BuildContext ctx, dynamic s) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: ctx.read<InvestmentBloc>(),
          child: const InvestorQuizPage(),
        ),
      ),
    );
    if (result == true) {
      ctx.read<InvestmentBloc>().add(const LoadProfile());
    }
  }
}
