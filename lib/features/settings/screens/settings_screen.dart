import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

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
                      await HapticFeedback.mediumImpact();
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
    final textController = TextEditingController(
      text: initialValue == 0
          ? ''
          : initialValue.toStringAsFixed(initialValue % 1 == 0 ? 0 : 2),
    );

    double? value;
    try {
      value = await showMaterialModalBottomSheet<double>(
        context: context,
        backgroundColor: Colors.transparent,
        bounce: true,
        builder: (context) {
          final theme = Theme.of(context);
          String? errorText;

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
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
                      Text(title, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(helperText, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: textController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          DecimalTextInputFormatter(maxDecimalPlaces: 2),
                        ],
                        style: theme.textTheme.headlineMedium,
                        decoration: InputDecoration(
                          prefixText: '$symbol ',
                          hintText: '0',
                          errorText: errorText,
                        ),
                        onChanged: (_) {
                          if (errorText != null) {
                            setModalState(() {
                              errorText = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                final parsed = double.tryParse(
                                  textController.text.trim(),
                                );
                                if (parsed == null || parsed < 0) {
                                  setModalState(() {
                                    errorText = 'Enter a valid number';
                                  });
                                  return;
                                }
                                Navigator.of(context).pop(parsed);
                              },
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      textController.dispose();
    }

    if (value == null) {
      return;
    }

    await onSave(value);
    HapticFeedback.mediumImpact();

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
