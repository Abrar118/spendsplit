import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/financial_summaries.dart';

class DollarHeaderCard extends StatelessWidget {
  const DollarHeaderCard({required this.summary, super.key});

  final DollarTrackerSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final utilized = summary.annualLimit <= 0
        ? 0.0
        : (summary.spentYtd / summary.annualLimit).clamp(0.0, 1.0);

    return GlassCard(
      glowColor: AppColors.amber,
      radius: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF25175A), const Color(0xFF0E223E)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REMAINING BALANCE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedAmountText(
                      value: summary.remaining,
                      formatter: (value) =>
                          formatUsdAmount(value, fractionDigits: 0),
                      textStyle: theme.textTheme.displaySmall?.copyWith(
                        color: summary.remaining < 0
                            ? AppColors.coral
                            : Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricColumn(
                            label: 'ANNUAL LIMIT',
                            value: formatUsdAmount(
                              summary.annualLimit,
                              fractionDigits: 0,
                            ),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _MetricColumn(
                            label: 'SPENT YTD',
                            value: formatUsdAmount(
                              summary.spentYtd,
                              fractionDigits: 0,
                            ),
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 128,
                height: 128,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: utilized),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return CustomPaint(
                      painter: _UtilizationRingPainter(progress: animatedValue),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(utilized * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.amber,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'UTILIZED',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _UtilizationRingPainter extends CustomPainter {
  const _UtilizationRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 15.0;
    final radius = (size.width - strokeWidth) / 2;
    final center = size.center(Offset.zero);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) {
      return;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.amber.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      (math.pi * 2) * progress,
      false,
      glowPaint,
    );

    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: (math.pi * 2) - (math.pi / 2),
        colors: [Color(0xFFFFC72C), Color(0xFFFFD54F)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      (math.pi * 2) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _UtilizationRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
