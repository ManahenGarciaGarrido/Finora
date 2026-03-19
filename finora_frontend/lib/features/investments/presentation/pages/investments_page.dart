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
import 'market_detail_page.dart';

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title, style: AppTypography.titleSmall()),
    );
  }
}

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
  DateTime? _indicesLastUpdated;

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
              _indicesLastUpdated = DateTime.now();
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
                tabAlignment: TabAlignment.start,
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
    return const ReturnSimulatorWidget();
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

    final crypto = _indices.where((i) => i.category == 'crypto').toList();
    final equity = _indices.where((i) => i.category == 'equity').toList();
    final other = _indices
        .where((i) => i.category == 'commodity' || i.category == 'forex')
        .toList();

    return RefreshIndicator(
      onRefresh: () async =>
          ctx.read<InvestmentBloc>().add(const LoadIndices()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Last updated timestamp
          if (_indicesLastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${s.lastUpdated}: ${_formatTime(_indicesLastUpdated!)}',
                style: AppTypography.labelSmall(color: AppColors.gray400),
              ),
            ),

          // Crypto section
          if (crypto.isNotEmpty) ...[
            _SectionHeader(title: '${s.sectionCrypto} (${crypto.length})'),
            const SizedBox(height: 8),
            ...crypto.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarketDetailPage(index: i),
                    ),
                  ),
                  child: MarketIndexCard(index: i),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Equity section
          if (equity.isNotEmpty) ...[
            _SectionHeader(title: '${s.sectionEquity} (${equity.length})'),
            const SizedBox(height: 8),
            ...equity.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarketDetailPage(index: i),
                    ),
                  ),
                  child: MarketIndexCard(index: i),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Commodities & Forex section
          if (other.isNotEmpty) ...[
            _SectionHeader(
              title: '${s.sectionCommoditiesForex} (${other.length})',
            ),
            const SizedBox(height: 8),
            ...other.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarketDetailPage(index: i),
                    ),
                  ),
                  child: MarketIndexCard(index: i),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Glossary
          const SizedBox(height: 8),
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

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
