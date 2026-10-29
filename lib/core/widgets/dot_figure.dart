import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'amount_text.dart';
import 'grid_paper.dart';

/// A hero figure built on its construction grid: label, optional currency
/// sign, and dot-grid numerals whose dots land exactly in the grid's cells.
///
/// Doto draws every dot inside a cell one tenth of the font size, advances
/// each glyph six cells, and (with [AppTypography.figure]'s even 0.9 line
/// height) sits its baseline eight cells down. So a grid with cell = size/10,
/// started at the figure's origin, lines up dot for dot. Everything above
/// the figure is sized in whole cells to keep that origin on a grid line.
class DotFigure extends StatelessWidget {
  const DotFigure({
    required this.label,
    required this.value,
    required this.color,
    required this.semanticLabel,
    this.prefix,
    this.suffix = '',
    this.maxSize = 88,
    super.key,
  });

  final String label;
  final double value;
  final Color color;
  final String semanticLabel;

  /// Currency sign set in the platform sans (Doto has no ৳), in a box four
  /// cells wide.
  final String? prefix;

  /// Appended to the digits in Doto, e.g. '%'.
  final String suffix;
  final double maxSize;

  static const _prefixCells = 4;
  static final _digits = NumberFormat('#,##0', 'en_US');

  String _format(double v) => _digits.format(v.round()) + suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        // Size from the final value so the grid holds still while counting.
        final cellsWide =
            (prefix == null ? 0 : _prefixCells) + _format(value).length * 6;
        final size = math
            .min(maxSize, box.maxWidth / (cellsWide * 0.1))
            .floorToDouble();
        final cell = size / 10;
        final labelCells = (24 / cell).ceil();

        return Semantics(
          label: semanticLabel,
          excludeSemantics: true,
          child: CustomPaint(
            painter: GridPaperPainter(cell: cell),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: cell),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: labelCells * cell,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: cell),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (prefix != null)
                        SizedBox(
                          width: _prefixCells * cell,
                          height: 9 * cell,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: EdgeInsets.only(top: cell),
                              child: Text(
                                prefix!,
                                style: TextStyle(
                                  color: color,
                                  fontSize: cell * 3.4,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      AnimatedAmountText(
                        value: value,
                        formatter: _format,
                        textStyle: AppTypography.figure(size, color: color),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
