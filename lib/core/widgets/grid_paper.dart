import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The faint square construction grid behind hero figures.
class GridPaperPainter extends CustomPainter {
  const GridPaperPainter({this.cell = 12});

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPaperPainter old) => old.cell != cell;
}
