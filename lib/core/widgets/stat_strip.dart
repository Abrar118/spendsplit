import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One cell of a [StatStrip].
class StatCell {
  const StatCell({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;
}

/// Figures side by side in one row, divided by vertical hairlines: label
/// above, value below. The grid-specimen way to show a few related numbers
/// without a card each.
class StatStrip extends StatelessWidget {
  const StatStrip({required this.cells, super.key});

  final List<StatCell> cells;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              Container(
                width: 0.5,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.hairline,
              ),
            Expanded(
              child: Semantics(
                label: '${cells[i].label} ${cells[i].value}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cells[i].label, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        cells[i].value,
                        maxLines: 1,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cells[i].color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
