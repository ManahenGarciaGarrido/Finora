import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../domain/entities/market_index_entity.dart';

class MarketDetailPage extends StatefulWidget {
  final MarketIndexEntity index;

  const MarketDetailPage({super.key, required this.index});

  @override
  State<MarketDetailPage> createState() => _MarketDetailPageState();
}

class _MarketDetailPageState extends State<MarketDetailPage> {
  String _period = '7d';
  List<Map<String, dynamic>> _points = [];
  bool _loading = true;
  String? _error;

  static const _periods = ['7d', '30d', '90d', '180d', '365d'];
  static const _periodLabels = {
    '7d': '1S',
    '30d': '1M',
    '90d': '3M',
    '180d': '6M',
    '365d': '1A',
  };

  @override
  void initState() {
    super.initState();
    _loadChart();
  }

  Future<void> _loadChart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await di.sl<ApiClient>().get(
        '/investments/chart/${widget.index.ticker}?period=$_period',
      );
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _points = List<Map<String, dynamic>>.from(data['points'] as List);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final index = widget.index;
    final changeColor = index.isPositive ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          '${index.name} (${index.ticker})',
          style: AppTypography.titleMedium(),
        ),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadChart,
            tooltip: s.refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Price header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _formatPrice(index.value, index.ticker),
                        style: AppTypography.titleLarge().copyWith(
                          fontSize: 32,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          index.isPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: changeColor,
                          size: 18,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${index.change.abs().toStringAsFixed(2)}%',
                          style: AppTypography.titleSmall(color: changeColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (index.high24h > 0 || index.low24h > 0)
                  Text(
                    '24h: H: ${_formatPrice(index.high24h, index.ticker)}  L: ${_formatPrice(index.low24h, index.ticker)}',
                    style: AppTypography.bodySmall(color: AppColors.gray500),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Period selector ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: _periods.map((p) {
                final selected = p == _period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_period != p) {
                        setState(() => _period = p);
                        _loadChart();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _periodLabels[p] ?? p,
                        style: AppTypography.labelSmall(
                          color: selected ? Colors.white : AppColors.gray600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── Chart ─────────────────────────────────────────────────────────
          Container(
            height: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      'Error cargando datos',
                      style: AppTypography.bodySmall(color: AppColors.error),
                    ),
                  )
                : _points.isEmpty
                ? Center(
                    child: Text(
                      'Sin datos disponibles',
                      style: AppTypography.bodySmall(color: AppColors.gray500),
                    ),
                  )
                : _AreaChart(points: _points, color: changeColor),
          ),

          const SizedBox(height: 16),

          // ── Stats grid ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.chartStatsTitle, style: AppTypography.titleSmall()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: s.volume24h,
                        value: _formatVolume(index.volume),
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: s.marketCap,
                        value: _formatVolume(index.marketCap),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: s.high24h,
                        value: index.high24h > 0
                            ? _formatPrice(index.high24h, index.ticker)
                            : '-',
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: s.low24h,
                        value: index.low24h > 0
                            ? _formatPrice(index.low24h, index.ticker)
                            : '-',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Category badge ────────────────────────────────────────────────
          _CategoryBadge(category: index.category),
        ],
      ),
    );
  }

  String _formatPrice(double value, String ticker) {
    if (ticker == 'EURUSD') return value.toStringAsFixed(4);
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(2)}k';
    if (value >= 1000) return value.toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }

  String _formatVolume(double value) {
    if (value <= 0) return '-';
    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)}T';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(2)}K';
    return value.toStringAsFixed(0);
  }
}

// ─── Stat Item ────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall(color: AppColors.gray500)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.titleSmall()),
      ],
    );
  }
}

// ─── Category Badge ───────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  static const _labels = {
    'equity': 'Renta Variable',
    'crypto': 'Criptomoneda',
    'commodity': 'Materia Prima',
    'forex': 'Divisas',
  };

  static const _colors = {
    'equity': Color(0xFF059669),
    'crypto': Color(0xFF7C3AED),
    'commodity': Color(0xFFD97706),
    'forex': Color(0xFF0284C7),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category] ?? AppColors.primary;
    final label = _labels[category] ?? category;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppTypography.labelSmall(color: color)),
    );
  }
}

// ─── Area Chart ───────────────────────────────────────────────────────────────

class _AreaChart extends StatelessWidget {
  final List<Map<String, dynamic>> points;
  final Color color;

  const _AreaChart({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AreaChartPainter(points: points, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;
  final Color color;

  const _AreaChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final closes = points
        .map((p) => (p['close'] as num?)?.toDouble() ?? 0.0)
        .toList();

    final minVal = closes.reduce(math.min);
    final maxVal = closes.reduce(math.max);
    final range = maxVal - minVal;

    if (range == 0) return;

    // X-axis labels area
    const labelAreaHeight = 20.0;
    final chartHeight = size.height - labelAreaHeight;

    double getX(int i) => i / (closes.length - 1) * size.width;
    double getY(double v) =>
        chartHeight -
        ((v - minVal) / range) * (chartHeight * 0.85) -
        chartHeight * 0.05;

    // Build line path
    final linePath = Path();
    linePath.moveTo(getX(0), getY(closes[0]));
    for (int i = 1; i < closes.length; i++) {
      // Smooth curve using cubic bezier
      final x0 = getX(i - 1);
      final y0 = getY(closes[i - 1]);
      final x1 = getX(i);
      final y1 = getY(closes[i]);
      final cpX = (x0 + x1) / 2;
      linePath.cubicTo(cpX, y0, cpX, y1, x1, y1);
    }

    // Fill area
    final fillPath = Path()..addPath(linePath, Offset.zero);
    fillPath.lineTo(size.width, chartHeight);
    fillPath.lineTo(0, chartHeight);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.03)],
    );

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, chartHeight),
        )
        ..style = PaintingStyle.fill,
    );

    // Draw line
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Draw last point dot
    final lastX = getX(closes.length - 1);
    final lastY = getY(closes.last);
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // X-axis date labels (first, middle, last)
    final labelPaint = TextPainter(textDirection: TextDirection.ltr);
    final indices = [0, closes.length ~/ 2, closes.length - 1];

    for (final i in indices) {
      final dateStr = _formatDate(points[i]['date'] as String? ?? '');
      labelPaint.text = TextSpan(
        text: dateStr,
        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
      );
      labelPaint.layout();
      final x = getX(i) - labelPaint.width / 2;
      final y = chartHeight + 4;
      labelPaint.paint(
        canvas,
        Offset(x.clamp(0, size.width - labelPaint.width), y),
      );
    }
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  bool shouldRepaint(_AreaChartPainter old) =>
      old.points != points || old.color != color;
}
