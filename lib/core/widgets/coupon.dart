import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

/// How an entry's state is drawn: as form, not only colour.
enum CouponState {
  /// Posted: a solid coupon.
  posted,

  /// Future-dated: a dashed outline with no fill.
  upcoming,

  /// Imported from SMS and not yet checked: solid, stamped.
  review,
}

/// One entry drawn as a coupon: a [stub] (date or time), a perforation with
/// notches cut from the top and bottom edge, then the [child] body.
class Coupon extends StatelessWidget {
  const Coupon({
    required this.stub,
    required this.child,
    this.state = CouponState.posted,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    super.key,
  });

  static const stubWidth = 64.0;

  final Widget stub;
  final Widget child;
  final CouponState state;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final upcoming = state == CouponState.upcoming;
    final body = CustomPaint(
      painter: _CouponPainter(upcoming: upcoming),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppDecorations.radius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Row(
              children: [
                SizedBox(
                  width: stubWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    child: DefaultTextStyle.merge(
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: upcoming
                            ? AppColors.textTertiary
                            : AppColors.textSecondary,
                      ),
                      child: Center(child: stub),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: state == CouponState.review
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                body,
                const Positioned(right: 10, top: -7, child: _Stamp()),
              ],
            )
          : body,
    );
  }
}

/// The red rubber stamp on an unchecked SMS entry.
class _Stamp extends StatelessWidget {
  const _Stamp();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.07,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.spend, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Text(
            'UNCHECKED',
            style: TextStyle(
              color: AppColors.spend,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponPainter extends CustomPainter {
  _CouponPainter({required this.upcoming});

  final bool upcoming;

  static const _notch = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    const x = Coupon.stubWidth;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppDecorations.radius),
        ),
      );
    final notches = Path()
      ..addOval(Rect.fromCircle(center: const Offset(x, 0), radius: _notch))
      ..addOval(
        Rect.fromCircle(center: Offset(x, size.height), radius: _notch),
      );
    final shape = Path.combine(PathOperation.difference, outline, notches);

    if (upcoming) {
      _dashPath(
        canvas,
        shape,
        Paint()
          ..color = AppColors.textTertiary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else {
      // A step above the panels so entries read as objects on the ground.
      canvas.drawPath(shape, Paint()..color = AppColors.surfaceRaised);
    }

    // The perforation between stub and body.
    final perf = Paint()
      ..color = upcoming ? AppColors.textTertiary : AppColors.outlineVariant
      ..strokeWidth = 1.5;
    for (var y = _notch + 4; y < size.height - _notch - 4; y += 7) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 3), perf);
    }
  }

  void _dashPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CouponPainter old) => old.upcoming != upcoming;
}
