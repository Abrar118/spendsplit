import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/goal_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';

Future<void> showCreateGoalSheet(
  BuildContext context, {
  SavingsGoalsTableData? existingGoal,
}) {
  return showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    bounce: true,
    builder: (context) => CreateGoalSheet(existingGoal: existingGoal),
  );
}

class CreateGoalSheet extends ConsumerStatefulWidget {
  const CreateGoalSheet({super.key, this.existingGoal});

  final SavingsGoalsTableData? existingGoal;

  @override
  ConsumerState<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<CreateGoalSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _currentAmountController;
  late final TextEditingController _targetAmountController;
  late String _selectedIcon;
  late bool _hasDeadline;
  DateTime? _deadline;
  bool _saving = false;

  bool get _editing => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    _nameController = TextEditingController(text: goal?.name ?? '');
    _currentAmountController = TextEditingController(
      text: goal == null ? '' : _formatInputAmount(goal.currentAmount),
    );
    _targetAmountController = TextEditingController(
      text: goal == null ? '' : _formatInputAmount(goal.targetAmount),
    );
    _selectedIcon = goal?.icon ?? GoalIcons.all.first.key;
    _hasDeadline = goal?.deadline != null;
    _deadline = goal?.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentAmountController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        _editing ? 'Edit Goal' : 'New Goal',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _FieldLabel(label: 'GOAL NAME'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'New Mac Pro'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _CurrencyField(
                          label: 'CURRENT SAVED',
                          controller: _currentAmountController,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _CurrencyField(
                          label: 'TARGET',
                          controller: _targetAmountController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(child: _FieldLabel(label: 'SET DEADLINE')),
                      Switch.adaptive(
                        value: _hasDeadline,
                        activeThumbColor: AppColors.teal,
                        activeTrackColor: AppColors.teal.withValues(alpha: 0.4),
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  _hasDeadline = value;
                                  if (!value) {
                                    _deadline = null;
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                  if (_hasDeadline) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _saving ? null : _pickDeadline,
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _deadline == null
                                  ? 'Choose date'
                                  : formatShortDate(_deadline!),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            const Icon(LucideIcons.calendarDays, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel(label: 'ICON'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final option in GoalIcons.all)
                        _GoalIconChip(
                          option: option,
                          selected: option.key == _selectedIcon,
                          onTap: _saving
                              ? null
                              : () => setState(() {
                                  _selectedIcon = option.key;
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _saveGoal,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_editing ? 'Update Goal' : 'Save Goal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    // For new goals, only allow future dates. For editing, allow past dates
    // so the user can see and adjust an already-set deadline.
    final firstDate = _editing
        ? now.subtract(const Duration(days: 365 * 5))
        : DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _deadline = picked;
    });
  }

  Future<void> _saveGoal() async {
    final name = _nameController.text.trim();
    final currentAmount =
        double.tryParse(_currentAmountController.text.trim()) ?? 0;
    final targetAmount = double.tryParse(_targetAmountController.text.trim());

    if (name.isEmpty || targetAmount == null || targetAmount <= 0) {
      _showSnackBar('Enter a goal name and valid target amount.');
      return;
    }

    if (currentAmount < 0) {
      _showSnackBar('Current saved amount cannot be negative.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final repository = ref.read(savingsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_editing) {
        final existing = widget.existingGoal!;
        await repository.updateGoal(
          existing.copyWith(
            name: name,
            currentAmount: currentAmount,
            targetAmount: targetAmount,
            icon: _selectedIcon,
            deadline: drift.Value(_hasDeadline ? _deadline : null),
          ),
        );
      } else {
        await repository.createGoal(
          SavingsGoalsTableCompanion.insert(
            name: name,
            currentAmount: drift.Value(currentAmount),
            targetAmount: targetAmount,
            icon: drift.Value(_selectedIcon),
            deadline: drift.Value(_hasDeadline ? _deadline : null),
          ),
        );
      }

      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 30);
      } else {
        HapticFeedback.mediumImpact();
      }

      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(_editing ? 'Goal updated' : 'Goal saved')),
      );
      Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatInputAmount(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(prefixText: '৳ ', hintText: '0'),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelMedium);
  }
}

class _GoalIconChip extends StatelessWidget {
  const _GoalIconChip({
    required this.option,
    required this.selected,
    this.onTap,
  });

  final GoalIconOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected
              ? option.color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? option.color
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(option.icon, color: option.color),
      ),
    );
  }
}
