import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/portfolio_suggestion_entity.dart';
import '../bloc/investment_bloc.dart';
import '../bloc/investment_event.dart';
import '../bloc/investment_state.dart';

/// RF-28: Animated donut chart shown after saving/modifying investor profile.
/// Each ETF allocation segment fills in one by one.
class InvestmentAllocationAnimationPage extends StatefulWidget {
  const InvestmentAllocationAnimationPage({super.key});

  @override
  State<InvestmentAllocationAnimationPage> createState() =>
      _InvestmentAllocationAnimationPageState();
}

class _InvestmentAllocationAnimationPageState
    extends State<InvestmentAllocationAnimationPage>
    with TickerProviderStateMixin {
  PortfolioSuggestionEntity? _portfolio;
  bool _loading = true;

  // One controller per ETF segment
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];
  int _visibleCount = 0;

  static const List<Color> _palette = [
    Color(0xFF6C63FF),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF009688),
    Color(0xFFF44336),
  ];

  @override
  void initState() {
    super.initState();
    context.read<InvestmentBloc>().add(const LoadPortfolioSuggestion());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startAnimation(PortfolioSuggestionEntity portfolio) {
    setState(() {
      _portfolio = portfolio;
      _loading = false;
    });
    _buildAnimations(portfolio);
    _animateSequentially(0);
  }

  void _buildAnimations(PortfolioSuggestionEntity portfolio) {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    _animations.clear();

    for (var i = 0; i < portfolio.portfolio.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );
      final anim = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
      _controllers.add(ctrl);
      _animations.add(anim);
    }
    setState(() => _visibleCount = 0);
  }

  void _animateSequentially(int index) {
    if (index >= _controllers.length) return;
    setState(() => _visibleCount = index + 1);
    _controllers[index].forward().then((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _animateSequentially(index + 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocListener<InvestmentBloc, InvestmentState>(
      listener: (ctx, state) {
        if (state is PortfolioLoaded && _portfolio == null) {
          _startAnimation(state.suggestion);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
          title: Text(s.portfolioTab, style: AppTypography.titleMedium()),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(s),
      ),
    );
  }

  Widget _buildContent(dynamic s) {
    final portfolio = _portfolio!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Text(
              s.recommendedStrategy,
              style: AppTypography.titleMedium(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              portfolio.rationale,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Animated donut chart
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge(_animations),
              builder: (ctx, _) {
                return CustomPaint(
                  size: const Size(220, 220),
                  painter: _DonutPainter(
                    allocations: portfolio.portfolio,
                    animations: _animations,
                    visibleCount: _visibleCount,
                    colors: _palette,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // ETF list — reveal one by one as segments appear
          Text(
            s.portfolioTab,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_visibleCount.clamp(0, portfolio.portfolio.length), (
            i,
          ) {
            final etf = portfolio.portfolio[i];
            final color = _palette[i % _palette.length];
            return AnimatedOpacity(
              opacity: i < _visibleCount ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${etf.allocation}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  etf.etf,
                                  style: AppTypography.titleSmall(),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  etf.ticker,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            etf.category,
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          if (etf.reason.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              etf.reason,
                              style: AppTypography.bodySmall(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          if (_visibleCount >= portfolio.portfolio.length)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_rounded),
                label: Text(s.save),
              ),
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<PortfolioAllocationEntity> allocations;
  final List<Animation<double>> animations;
  final int visibleCount;
  final List<Color> colors;

  _DonutPainter({
    required this.allocations,
    required this.animations,
    required this.visibleCount,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 36.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = AppColors.gray200;
    canvas.drawCircle(
      center,
      radius - strokeWidth / 2,
      paint..style = PaintingStyle.stroke,
    );

    // Calculate total for angle computation
    final total = allocations.fold<int>(0, (sum, e) => sum + e.allocation);
    if (total == 0) return;

    double startAngle = -math.pi / 2; // start at top
    const gap = 0.03; // radians gap between segments

    for (var i = 0; i < allocations.length; i++) {
      if (i >= visibleCount) break;
      final etf = allocations[i];
      final targetSweep =
          (etf.allocation / total) * (math.pi * 2 - gap * allocations.length);
      final animValue = i < animations.length ? animations[i].value : 0.0;
      final sweepAngle = targetSweep * animValue;

      paint.color = colors[i % colors.length];
      paint.style = PaintingStyle.stroke;

      if (sweepAngle > 0) {
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      }

      startAngle += targetSweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}
