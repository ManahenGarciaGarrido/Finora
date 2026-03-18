import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/market_index_entity.dart';

class MarketIndexCard extends StatelessWidget {
  final MarketIndexEntity index;

  const MarketIndexCard({super.key, required this.index});

  static const _categoryIcons = {
    'equity': Icons.bar_chart_rounded,
    'commodity': Icons.diamond_rounded,
    'forex': Icons.currency_exchange_rounded,
    'crypto': Icons.currency_bitcoin_rounded,
  };

  static const _categoryColors = {
    'equity': Color(0xFF059669),
    'commodity': Color(0xFFD97706),
    'forex': Color(0xFF0284C7),
    'crypto': Color(0xFF7C3AED),
  };

  @override
  Widget build(BuildContext context) {
    final changeColor = index.isPositive ? AppColors.success : AppColors.error;
    final catColor = _categoryColors[index.category] ?? AppColors.primary;
    final catIcon = _categoryIcons[index.category] ?? Icons.show_chart_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(catIcon, color: catColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Name + ticker
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(index.name, style: AppTypography.titleSmall()),
                Text(
                  index.ticker,
                  style: AppTypography.labelSmall(color: AppColors.gray500),
                ),
              ],
            ),
          ),

          // Sparkline
          if (index.spark.length >= 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _SparkLine(
                points: index.spark,
                color: changeColor,
                width: 56,
                height: 28,
              ),
            ),

          // Value + change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatValue(index.value, index.ticker),
                style: AppTypography.titleSmall(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      index.isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: changeColor,
                      size: 10,
                    ),
                    Text(
                      '${index.change.abs().toStringAsFixed(2)}%',
                      style: AppTypography.labelSmall(color: changeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(double value, String ticker) {
    if (ticker == 'EURUSD') return value.toStringAsFixed(4);
    if (value >= 10000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    if (value >= 1000) return value.toStringAsFixed(2);
    return value.toStringAsFixed(2);
  }
}

class _SparkLine extends StatelessWidget {
  final List<double> points;
  final Color color;
  final double width;
  final double height;

  const _SparkLine({
    required this.points,
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparkLinePainter(points: points, color: color),
      ),
    );
  }
}

class _SparkLinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  const _SparkLinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    if (range == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final y = size.height - (points[i] - minVal) / range * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Fill area under line
    final fillPath = Path()..addPath(path, Offset.zero);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_SparkLinePainter old) => old.points != points;
}
