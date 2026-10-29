import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendsplit/core/icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/widgets/panel.dart';
import 'card_number_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../providers/providers.dart';
import '../../sms_import/providers/sms_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    return Scaffold(
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
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.chevronLeft),
                ),
                const SizedBox(width: 4),
                Text('Settings', style: theme.textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Group(
              title: 'Security',
              children: [
                _SwitchRow(
                  icon: LucideIcons.lock,
                  title: 'Biometric lock',
                  subtitle: settings.biometricEnabled
                      ? 'Unlock required when the app opens'
                      : 'Off: the app opens without Face ID or a fingerprint',
                  value: settings.biometricEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final isSupported = await ref
                          .read(authRepositoryProvider)
                          .isDeviceSupported();
                      if (!isSupported) {
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
            // SMS reading is Android-only (iOS has no SMS API).
            if (defaultTargetPlatform == TargetPlatform.android) ...[
              const SizedBox(height: AppSpacing.section),
              _Group(
                title: 'Bank SMS',
                children: [
                  const _SmsImportRow(),
                  if (settings.smsUnparsedCount > 0) const _SmsUnparsedRow(),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.section),
            _Group(
              title: 'Money',
              children: [
                _ActionRow(
                  icon: LucideIcons.wallet,
                  title: 'Starting balance',
                  subtitle: 'What the account held before your first entry',
                  value: formatBdtAmount(
                    settings.initialBalance,
                    fractionDigits: 0,
                  ),
                  onTap: () => _showAmountEditor(
                    context: context,
                    title: 'Starting balance',
                    symbol: '৳',
                    initialValue: settings.initialBalance,
                    helperText: 'Used in total balance calculations.',
                    onSave: controller.setInitialBalance,
                  ),
                ),
                _ActionRow(
                  icon: LucideIcons.badgeDollarSign,
                  title: 'USD yearly allowance',
                  subtitle: 'USD allowance for ${settings.dollarLimitYear}',
                  value: formatUsdAmount(
                    settings.dollarAnnualLimit,
                    fractionDigits: 0,
                  ),
                  valueColor: settings.needsDollarLimitRefresh
                      ? AppColors.warning
                      : AppColors.usd,
                  onTap: () => _showAmountEditor(
                    context: context,
                    title: 'USD yearly allowance',
                    symbol: '\$',
                    initialValue: settings.dollarAnnualLimit,
                    helperText:
                        'Tracked against ${settings.dollarLimitYear} spending.',
                    onSave: controller.setDollarAnnualLimit,
                  ),
                ),
                _ActionRow(
                  icon: LucideIcons.creditCard,
                  title: 'Card number',
                  subtitle: 'Shown masked; only the first and last four digits',
                  value: _maskCardNumber(settings.cardNumber),
                  onTap: () => _showCardNumberEditor(context, ref),
                ),
                if (settings.needsDollarLimitRefresh) ...[
                  _ActionRow(
                    icon: LucideIcons.calendarDays,
                    title: 'Allowance year',
                    subtitle:
                        'Your limit is still assigned to ${settings.dollarLimitYear}',
                    value: DateTime.now().year.toString(),
                    valueColor: AppColors.warning,
                    onTap: () =>
                        controller.setDollarLimitYear(DateTime.now().year),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            _Group(
              title: 'Data',
              children: [
                _ActionRow(
                  icon: LucideIcons.layoutGrid,
                  title: 'Categories',
                  subtitle: 'Rename, recolour or remove your own',
                  value: '',
                  onTap: () => context.push(AppRoute.manageCategories.path),
                ),
                _ActionRow(
                  icon: LucideIcons.bookmark,
                  title: 'Templates',
                  subtitle: 'Quick entries and expected monthly bills',
                  value: '',
                  onTap: () => context.push(AppRoute.manageTemplates.path),
                ),
                _ActionRow(
                  icon: LucideIcons.download,
                  title: 'Export and backup',
                  subtitle: 'CSV or PDF, or a full backup to restore from',
                  value: '',
                  onTap: () => context.push(AppRoute.exportData.path),
                ),
              ],
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

/// A titled settings group: a sentence-case header above one flush module,
/// rows separated by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = children.where((w) => w is! SizedBox).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.only(left: 52),
                    color: AppColors.hairline,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
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
    this.valueColor = AppColors.textSecondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(color: valueColor),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

String _maskCardNumber(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 12) return raw;
  return '${digits.substring(0, 4)} ···· ${digits.substring(digits.length - 4)}';
}

Future<void> _showCardNumberEditor(BuildContext context, WidgetRef ref) async {
  final current = ref.read(appSettingsProvider).cardNumber;
  final didSave = await showDialog<bool>(
    context: context,
    builder: (_) => CardNumberEditorDialog(
      initialDigits: current.replaceAll(RegExp(r'\D'), ''),
      onSave: (value) =>
          ref.read(appSettingsProvider.notifier).setCardNumber(value),
    ),
  );
  if (didSave == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Card number updated')));
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
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(widget.helperText, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  DecimalTextInputFormatter(maxDecimalPlaces: 2),
                ],
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
                                color: AppColors.onPrimary,
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

/// Shown only after bank SMS failed to parse: a format change would
/// otherwise skip messages silently and for good.
class _SmsUnparsedRow extends ConsumerWidget {
  const _SmsUnparsedRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      appSettingsProvider.select((s) => s.smsUnparsedCount),
    );
    if (count == 0) return const SizedBox.shrink();

    return _ActionRow(
      icon: LucideIcons.info,
      title: "Couldn't read $count bank SMS",
      subtitle: 'They mention a debit or credit but no transaction was made',
      value: 'View',
      valueColor: AppColors.warning,
      onTap: () => _show(context, ref),
    );
  }

  Future<void> _show(BuildContext context, WidgetRef ref) async {
    final latest = ref.read(appSettingsProvider).smsUnparsedLatest ?? '';
    final clear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Latest unread SMS'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(latest),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Add these by hand. If this keeps happening, the bank changed '
                'its format and the parser needs an update.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear == true) {
      await ref.read(appSettingsProvider.notifier).clearSmsUnparsed();
    }
  }
}

class _SmsImportRow extends ConsumerWidget {
  const _SmsImportRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.smsImportEnabled),
    );
    final perms = ref.watch(smsPermissionsProvider).valueOrNull;
    final missingRead = enabled && perms != null && !perms.read;
    final missingReceive = enabled && perms != null && !perms.receive;

    return _SwitchRow(
      icon: LucideIcons.messageSquare,
      title: 'Import Trust Bank SMS',
      subtitle: !enabled
          ? 'Log card debits and credits from bank SMS automatically'
          : missingRead
          ? 'SMS permission is off — tap to allow'
          : missingReceive
          ? 'Background capture off — tap to allow'
          : 'Imported automatically, even in the background',
      value: enabled,
      onTap: missingRead || missingReceive
          ? () => _request(context, ref)
          : null,
      onChanged: (value) async {
        final controller = ref.read(appSettingsProvider.notifier);
        if (!value) {
          await controller.disableSmsImport();
          return;
        }
        if (await _request(context, ref)) {
          // Start from now: SMS already on the phone were entered by hand.
          await controller.enableSmsImport(
            DateTime.now().millisecondsSinceEpoch,
          );
        }
      },
    );
  }

  Future<bool> _request(BuildContext context, WidgetRef ref) async {
    final perms = await ref.read(smsGatewayProvider).requestPermission();
    ref.invalidate(smsPermissionsProvider);
    if (!perms.read && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Allow SMS access to import bank messages. If Android stopped '
            'asking, enable it in App info → Permissions.',
          ),
        ),
      );
    }
    return perms.read;
  }
}
