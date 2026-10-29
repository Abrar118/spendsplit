import 'package:flutter/material.dart';

import '../../../core/widgets/dot_figure.dart';
import '../../../core/widgets/stat_strip.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/financial_summaries.dart';

/// Home's hero: Available as one monumental dot-grid figure over the
/// construction grid, then the split bar showing how the balance divides
/// between Available and Savings.
class AvailableHero extends StatelessWidget {
  const AvailableHero({required this.summary, super.key});

  final BalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final available = summary.availableBalance;
    final overdrawn = available < 0;
    final figureColor = overdrawn ? AppColors.spend : AppColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DotFigure(
          label: overdrawn ? 'Available · overdrawn' : 'Available',
          value: available.abs(),
          prefix: '৳',
          color: figureColor,
          semanticLabel:
              'Available ${formatBdtAmount(available)}'
              '${overdrawn ? ', overdrawn' : ''}',
        ),
        SplitBar(available: available, savings: summary.savingsBalance),
        const SizedBox(height: 8),
        _SplitLegend(available: available, savings: summary.savingsBalance),
        const SizedBox(height: 16),
        StatStrip(
          cells: [
            StatCell(
              label: 'Savings',
              value: formatBdtAmount(summary.savingsBalance),
              color: AppColors.savings,
            ),
            StatCell(
              label: 'Total balance',
              value: formatBdtAmount(summary.totalBalance),
            ),
          ],
        ),
      ],
    );
  }
}

/// Available (orange) meeting Savings (bone) at their true proportion, the
/// boundary cut on one diagonal.
class SplitBar extends StatelessWidget {
  const SplitBar({
    required this.available,
    required this.savings,
    this.height = 44,
    super.key,
  });

  final double available;
  final double savings;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _availableShare(available, savings) ?? -1),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 700),
          curve: Curves.easeOutExpo,
          builder: (context, share, _) =>
              CustomPaint(painter: _SplitPainter(share: share)),
        ),
      ),
    );
  }
}

/// Available's share of the balance, or null when there is nothing to split.
double? _availableShare(double available, double savings) {
  final a = available < 0 ? 0.0 : available;
  final s = savings < 0 ? 0.0 : savings;
  final total = a + s;
  if (total <= 0) return null;
  return a / total;
}

class _SplitPainter extends CustomPainter {
  _SplitPainter({required this.share});

  /// Available's share; negative means empty.
  final double share;

  static const _slant = 10.0;
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (share < 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = AppColors.hairline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }
    final orange = Paint()..color = AppColors.accent;
    final bone = Paint()..color = AppColors.savings;
    if (share >= 0.999) {
      canvas.drawRect(Offset.zero & size, orange);
      return;
    }
    if (share <= 0.001) {
      canvas.drawRect(Offset.zero & size, bone);
      return;
    }
    // Keep the cut inside the bar even for tiny shares.
    final x = (share * w).clamp(_slant, w - _slant);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(x + _slant / 2, 0)
        ..lineTo(x - _slant / 2, h)
        ..lineTo(0, h)
        ..close(),
      orange,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x + _slant / 2 + _gap, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h)
        ..lineTo(x - _slant / 2 + _gap, h)
        ..close(),
      bone,
    );
  }

  @override
  bool shouldRepaint(_SplitPainter old) => old.share != share;
}

class _SplitLegend extends StatelessWidget {
  const _SplitLegend({required this.available, required this.savings});

  final double available;
  final double savings;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    final share = _availableShare(available, savings);
    if (share == null) {
      return Text('Nothing to split yet', style: style);
    }
    final pct = (share * 100).round();
    return Row(
      children: [
        Text('Available $pct%', style: style),
        const Spacer(),
        Text('Savings ${100 - pct}%', style: style),
      ],
    );
  }
}
