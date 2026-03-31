import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/categories.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.category,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final TransactionsTableData transaction;
  final CategoriesTableData? category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = _presentationFor(transaction, category);
    const borderRadius = BorderRadius.all(Radius.circular(20));

    return ClipRRect(
      borderRadius: borderRadius,
      child: Slidable(
        key: ValueKey(transaction.id),
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.82,
          children: [
            _GlassSlidableAction(
              presentation: presentation,
              direction: AxisDirection.right,
              color: AppColors.blue,
              icon: LucideIcons.pencil,
              label: 'Edit',
              onPressed: onTap,
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.82,
          children: [
            _GlassSlidableAction(
              presentation: presentation,
              direction: AxisDirection.left,
              color: AppColors.coral,
              icon: LucideIcons.trash2,
              label: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
        child: Builder(
          builder: (slidableContext) {
            final controller = Slidable.of(slidableContext);
            if (controller == null) {
              return const SizedBox.shrink();
            }

            return AnimatedBuilder(
              animation: controller.animation,
              builder: (context, _) {
                final swipeProgress = controller.animation.value.clamp(
                  0.0,
                  1.0,
                );
                final backgroundOpacity = lerpDouble(
                  0.82,
                  0.03,
                  swipeProgress,
                )!;
                final borderOpacity = lerpDouble(0.06, 0.1, swipeProgress)!;
                final blurAmount = lerpDouble(14, 24, swipeProgress)!;

                return ClipRRect(
                  borderRadius: borderRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurAmount,
                      sigmaY: blurAmount,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(
                          alpha: backgroundOpacity,
                        ),
                        borderRadius: borderRadius,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: borderOpacity),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: onTap,
                          child: Ink(
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  // 3dp accent bar — stretches to match tile height
                                  Container(
                                    width: 3,
                                    decoration: BoxDecoration(
                                      color: presentation.amountColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        14,
                                        16,
                                        14,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: presentation.amountColor,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: presentation
                                                      .amountColor
                                                      .withValues(alpha: 0.28),
                                                  blurRadius: 18,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              presentation.icon,
                                              color: Colors.white,
                                              size: 19,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  presentation.title,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  presentation.subtitle,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            presentation.amountText,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color:
                                                      presentation.amountColor,
                                                ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GlassSlidableAction extends StatelessWidget {
  const _GlassSlidableAction({
    required this.presentation,
    required this.direction,
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final _TransactionPresentation presentation;
  final AxisDirection direction;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  bool get _isTrailingAction => direction == AxisDirection.left;

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (_) => onPressed(),
      backgroundColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: _isTrailingAction
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  end: _isTrailingAction
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.14),
                    color.withValues(alpha: 0.08),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Positioned(
              left: _isTrailingAction ? 0 : null,
              right: _isTrailingAction ? null : 0,
              top: 0,
              bottom: 0,
              width: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: _isTrailingAction
                        ? const Alignment(-0.95, 0)
                        : const Alignment(0.95, 0),
                    radius: 1,
                    colors: [
                      color.withValues(alpha: 0.95),
                      color.withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Row(
                children: _isTrailingAction
                    ? [
                        Expanded(
                          child: _ActionBody(
                            presentation: presentation,
                            amountColor: color,
                            alignTrailing: false,
                          ),
                        ),
                        _ActionDivider(color: color),
                        _ActionDock(icon: icon),
                      ]
                    : [
                        _ActionDock(icon: icon),
                        _ActionDivider(color: color),
                        Expanded(
                          child: _ActionBody(
                            presentation: presentation,
                            amountColor: color,
                            alignTrailing: true,
                          ),
                        ),
                      ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: _isTrailingAction
                          ? const Alignment(0.55, 0)
                          : const Alignment(-0.55, 0),
                      radius: 0.42,
                      colors: [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBody extends StatelessWidget {
  const _ActionBody({
    required this.presentation,
    required this.amountColor,
    required this.alignTrailing,
  });

  final _TransactionPresentation presentation;
  final Color amountColor;
  final bool alignTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: alignTrailing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (alignTrailing)
              Expanded(
                child: Text(
                  presentation.amountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            if (alignTrailing) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                presentation.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
                textAlign: alignTrailing ? TextAlign.right : TextAlign.left,
              ),
            ),
            if (!alignTrailing) const SizedBox(width: 12),
            if (!alignTrailing)
              Expanded(
                child: Text(
                  presentation.amountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          presentation.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.0,
          ),
          textAlign: alignTrailing ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.02),
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 10),
        ],
      ),
    );
  }
}

class _ActionDock extends StatelessWidget {
  const _ActionDock({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Center(child: Icon(icon, color: Colors.white, size: 22)),
    );
  }
}

class _TransactionPresentation {
  const _TransactionPresentation({
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.amountColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String amountText;
  final Color amountColor;
  final IconData icon;
}

_TransactionPresentation _presentationFor(
  TransactionsTableData transaction,
  CategoriesTableData? category,
) {
  final type = TransactionType.fromDbValue(transaction.type);
  final dateText = DateFormat('MMM d • h:mm a').format(transaction.date);

  switch (type) {
    case TransactionType.expense:
      return _TransactionPresentation(
        title: transaction.note?.trim().isNotEmpty == true
            ? transaction.note!.trim()
            : (category?.name ?? 'Expense'),
        subtitle: '${category?.name ?? 'Expense'} • $dateText',
        amountText: '- ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.coral,
        icon: iconForCategoryKey(category?.icon ?? 'category'),
      );
    case TransactionType.income:
      final sourceLabel = switch (transaction.source) {
        'salary' => 'Salary',
        'freelance' => 'Freelance',
        _ => 'Income',
      };
      return _TransactionPresentation(
        title: transaction.note?.trim().isNotEmpty == true
            ? transaction.note!.trim()
            : sourceLabel,
        subtitle: '$sourceLabel • $dateText',
        amountText: '+ ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.green,
        icon: LucideIcons.trendingUp,
      );
    case TransactionType.savingsDeposit:
      return _TransactionPresentation(
        title: transaction.note?.trim().isNotEmpty == true
            ? transaction.note!.trim()
            : 'Savings Deposit',
        subtitle: 'Savings • $dateText',
        amountText: '↓ ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.purple,
        icon: LucideIcons.arrowDownToLine,
      );
    case TransactionType.savingsWithdrawal:
      return _TransactionPresentation(
        title: transaction.note?.trim().isNotEmpty == true
            ? transaction.note!.trim()
            : 'Savings Withdrawal',
        subtitle: 'Savings • $dateText',
        amountText: '↑ ৳${transaction.amount.toStringAsFixed(2)}',
        amountColor: AppColors.amber,
        icon: LucideIcons.arrowUpFromLine,
      );
  }
}
