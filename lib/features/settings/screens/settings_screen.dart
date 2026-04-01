import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            32,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.chevronLeft),
                ),
                const SizedBox(width: 4),
                Text('Settings', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GlassCard(
              glowColor: AppColors.teal,
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURITY',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SwitchRow(
                    icon: LucideIcons.lock,
                    title: 'Biometric Lock',
                    subtitle: settings.biometricEnabled
                        ? 'Unlock required when the app opens'
                        : 'Keep the app open without biometric gate',
                    value: settings.biometricEnabled,
                    onChanged: (value) async {
                      if (value) {
                        final isAvailable = await ref
                            .read(authRepositoryProvider)
                            .isAvailable();
                        if (!isAvailable) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Local authentication is unavailable on this device.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                      }

                      await controller.setBiometricEnabled(value);
                      if (value) {
                        ref.read(appSessionUnlockedProvider.notifier).unlock();
                      } else {
                        ref.read(appSessionUnlockedProvider.notifier).lock();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Biometric lock enabled'
                                  : 'Biometric lock disabled',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            GlassCard(
              glowColor: AppColors.purple,
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINANCIAL DEFAULTS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionRow(
                    icon: LucideIcons.wallet,
                    title: 'Initial Balance',
                    subtitle: 'Starting BDT balance used for totals',
                    value: formatBdtAmount(
                      settings.initialBalance,
                      fractionDigits: 0,
                    ),
                    onTap: () => _showAmountEditor(
                      context: context,
                      title: 'Initial Balance',
                      symbol: '৳',
                      initialValue: settings.initialBalance,
                      helperText: 'Used in total balance calculations.',
                      onSave: controller.setInitialBalance,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionRow(
                    icon: LucideIcons.badgeDollarSign,
                    title: 'Dollar Annual Limit',
                    subtitle: 'USD allowance for ${settings.dollarLimitYear}',
                    value: formatUsdAmount(
                      settings.dollarAnnualLimit,
                      fractionDigits: 0,
                    ),
                    accentColor: settings.needsDollarLimitRefresh
                        ? AppColors.amber
                        : AppColors.teal,
                    onTap: () => _showAmountEditor(
                      context: context,
                      title: 'Dollar Annual Limit',
                      symbol: '\$',
                      initialValue: settings.dollarAnnualLimit,
                      helperText:
                          'Tracked against ${settings.dollarLimitYear} spending.',
                      onSave: controller.setDollarAnnualLimit,
                    ),
                  ),
                  if (settings.needsDollarLimitRefresh) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ActionRow(
                      icon: LucideIcons.calendarDays,
                      title: 'Allowance Year',
                      subtitle:
                          'Your limit is still assigned to ${settings.dollarLimitYear}',
                      value: DateTime.now().year.toString(),
                      accentColor: AppColors.amber,
                      onTap: () =>
                          controller.setDollarLimitYear(DateTime.now().year),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            GlassCard(
              glowColor: AppColors.teal,
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATA',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionRow(
                    icon: LucideIcons.layoutGrid,
                    title: 'Manage Categories',
                    subtitle: 'View and delete custom categories',
                    value: '',
                    onTap: () => context.push(AppRoute.manageCategories.path),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionRow(
                    icon: LucideIcons.bookmark,
                    title: 'Manage Templates',
                    subtitle: 'View and delete transaction templates',
                    value: '',
                    onTap: () => context.push(AppRoute.manageTemplates.path),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionRow(
                    icon: LucideIcons.download,
                    title: 'Export Data',
                    subtitle: 'CSV or PDF of your transactions',
                    value: '',
                    onTap: () => context.push(AppRoute.exportData.path),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAmountEditor({
    required BuildContext context,
    required String title,
    required String symbol,
    required double initialValue,
    required String helperText,
    required Future<void> Function(double value) onSave,
  }) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (_) => _AmountEditorSheet(
        title: title,
        symbol: symbol,
        initialValue: initialValue,
        helperText: helperText,
        onSave: onSave,
      ),
    );

    if (didSave != true) {
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title updated')));
    }
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _LeadingIcon(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.teal,
            activeTrackColor: AppColors.teal.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AmountEditorSheet extends StatefulWidget {
  const _AmountEditorSheet({
    required this.title,
    required this.symbol,
    required this.initialValue,
    required this.helperText,
    required this.onSave,
  });

  final String title;
  final String symbol;
  final double initialValue;
  final String helperText;
  final Future<void> Function(double value) onSave;

  @override
  State<_AmountEditorSheet> createState() => _AmountEditorSheetState();
}

class _AmountEditorSheetState extends State<_AmountEditorSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue == 0
          ? ''
          : widget.initialValue.toStringAsFixed(
              widget.initialValue % 1 == 0 ? 0 : 2,
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: GlassCard(
        glowColor: AppColors.teal,
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(widget.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.helperText, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [DecimalTextInputFormatter(maxDecimalPlaces: 2)],
              style: theme.textTheme.headlineMedium,
              decoration: InputDecoration(
                prefixText: '${widget.symbol} ',
                hintText: '0',
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0) {
      setState(() {
        _errorText = 'Enter a valid number';
      });
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(parsed);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _errorText = 'Failed to save changes';
      });
    }
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
    this.accentColor = AppColors.teal,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            _LeadingIcon(icon: icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.teal, size: 20),
    );
  }
}
