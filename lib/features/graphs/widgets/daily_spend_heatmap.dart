import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/panel.dart';
import '../../../data/database/app_database.dart';
import '../graph_series.dart';

/// Thirteen weeks of daily spending as a calendar grid, one square per day,
/// shaded by how much went out. Tap a day to read its total.
class DailySpendHeatmap extends StatefulWidget {
  const DailySpendHeatmap({required this.transactions, super.key});

  final List<TransactionsTableData> transactions;

  @override
  State<DailySpendHeatmap> createState() => _DailySpendHeatmapState();
}

class _DailySpendHeatmapState extends State<DailySpendHeatmap> {
  static const _weeks = 13;
  static const _gap = 3.0;
  static const _labelWidth = 18.0;

  /// Shades for levels 1–4: one hue, faint to full.
  static final _shades = [
    for (final a in const [0.28, 0.5, 0.75, 1.0])
      AppColors.spend.withValues(alpha: a),
  ];

  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grid = buildDailySpend(
      widget.transactions,
      DateTime.now(),
      weeks: _weeks,
    );
    final cuts = grid.thresholds;
    final selected = _selected != null && _selected! < grid.days.length
        ? _selected
        : null;

    var busiest = -1;
    for (var i = 0; i < grid.days.length; i++) {
      if (grid.days[i] > 0 &&
          (busiest < 0 || grid.days[i] > grid.days[busiest])) {
        busiest = i;
      }
    }
    final activeDays = grid.days.where((v) => v > 0).length;

    String describe(int i) {
      final date = DateFormat('EEE d MMM').format(grid.dateAt(i));
      final amount = grid.days[i];
      return amount > 0
          ? '$date: ${formatBdtAmount(amount)}'
          : '$date: no spending';
    }

    final footer = selected != null
        ? describe(selected)
        : busiest >= 0
        ? 'Biggest day: ${describe(busiest).replaceFirst(':', ',')}'
        : 'No spending in the last $_weeks weeks.';

    return Panel(
      color: AppColors.surfaceRaised,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily spending', style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            'Last $_weeks weeks, spending on $activeDays days. '
            'Tap a day for its total.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Semantics(
            label:
                'Daily spending for the last $_weeks weeks. '
                'Spending on $activeDays days. $footer',
            child: ExcludeSemantics(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cell =
                      ((constraints.maxWidth - _labelWidth - _gap * _weeks) /
                              _weeks)
                          .clamp(8.0, 28.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _monthLabels(theme, grid, cell),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _weekdayLabels(theme, cell),
                          for (var week = 0; week < _weeks; week++)
                            Padding(
                              padding: const EdgeInsets.only(left: _gap),
                              child: Column(
                                children: [
                                  for (var day = 0; day < 7; day++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: day == 0 ? 0 : _gap,
                                      ),
                                      child: _cell(
                                        grid,
                                        week * 7 + day,
                                        cell,
                                        cuts,
                                        selected,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: theme.textTheme.labelSmall),
              const SizedBox(width: 4),
              for (final color in [AppColors.background, ..._shades])
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Container(width: 10, height: 10, color: color),
                ),
              const SizedBox(width: 4),
              Text('More', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            footer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    DailySpend grid,
    int index,
    double size,
    List<double> cuts,
    int? selected,
  ) {
    if (index >= grid.days.length) return SizedBox.square(dimension: size);
    final level = grid.level(grid.days[index], cuts);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          setState(() => _selected = _selected == index ? null : index),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: level == 0 ? AppColors.background : _shades[level - 1],
          border: index == selected
              ? Border.all(color: AppColors.textPrimary, width: 2)
              : null,
        ),
      ),
    );
  }

  Widget _weekdayLabels(ThemeData theme, double cell) {
    const labels = ['M', '', 'W', '', 'F', '', 'S'];
    return SizedBox(
      width: _labelWidth - _gap,
      child: Column(
        children: [
          for (var i = 0; i < 7; i++)
            Container(
              height: cell,
              margin: EdgeInsets.only(top: i == 0 ? 0 : _gap),
              alignment: Alignment.centerLeft,
              child: Text(
                labels[i],
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  /// A month name over the week column where that month begins.
  Widget _monthLabels(ThemeData theme, DailySpend grid, double cell) {
    return SizedBox(
      height: 14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var week = 0; week < _weeks; week++)
            if (_monthStartsIn(grid, week) case final month?)
              Positioned(
                left: _labelWidth + week * (cell + _gap),
                child: Text(
                  DateFormat('MMM').format(month),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
              ),
        ],
      ),
    );
  }

  /// The month whose first day falls in [week], or the first week's month.
  static DateTime? _monthStartsIn(DailySpend grid, int week) {
    for (var day = 0; day < 7; day++) {
      final date = grid.dateAt(week * 7 + day);
      if (date.day == 1 || (week == 0 && day == 0 && date.day <= 21)) {
        return date;
      }
    }
    return null;
  }
}
