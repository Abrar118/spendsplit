import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/providers.dart';

class MonthlyBudgetCard extends ConsumerWidget {
  const MonthlyBudgetCard({required this.spent, super.key});
  final double spent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(appSettingsProvider).monthlyExpenseBudget;
    final remaining = budget - spent;
    final enabled = budget > 0;
    final color = remaining < 0 ? AppColors.coral : AppColors.blue;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly budget',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _BudgetDialog(initialBudget: budget),
                ),
                child: Text(enabled ? 'Edit' : 'Set budget'),
              ),
            ],
          ),
          Text(
            enabled
                ? '${formatBdtAmount(remaining.abs())} ${remaining < 0 ? 'over budget' : 'remaining'}'
                : 'Give your spending a monthly limit.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: enabled ? color : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (enabled) ...[
            LinearProgressIndicator(
              value: (spent / budget).clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: color,
              backgroundColor: AppColors.surfaceContainerHighest,
              semanticsLabel: 'Monthly budget used',
            ),
            const SizedBox(height: 10),
            Text(
              '${formatBdtAmount(spent)} spent of ${formatBdtAmount(budget)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'The same limit applies to every month. Dollar spending is separate.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BudgetDialog extends ConsumerStatefulWidget {
  const _BudgetDialog({required this.initialBudget});
  final double initialBudget;
  @override
  ConsumerState<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends ConsumerState<_BudgetDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialBudget == 0
        ? ''
        : widget.initialBudget.toStringAsFixed(2),
  );
  String? _error;
  bool _saving = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final value = double.tryParse(_controller.text.replaceAll(',', '').trim());
    if (value == null || !value.isFinite || value < 0) {
      setState(() => _error = 'Enter zero or a positive amount.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(appSettingsProvider.notifier)
          .setMonthlyExpenseBudget(value);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Monthly expense budget'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        enabled: !_saving,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: 'Amount (৳)',
          errorText: _error,
          helperText: 'Enter 0 to turn off the budget.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}
