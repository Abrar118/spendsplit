import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/providers.dart';

enum _ExportFormat { csv, pdf }

enum _DateRange { allTime, thisMonth, custom }

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  _ExportFormat _selectedFormat = _ExportFormat.csv;
  _DateRange _selectedRange = _DateRange.allTime;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionCount =
        ref.watch(transactionsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            120,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.chevronLeft),
                ),
                const SizedBox(width: 4),
                Text('Export', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'SYSTEM EXPORT',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.teal,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export Data',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0x33FFFFFF), blurRadius: 12),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export your local transaction history for safekeeping or external analysis.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 36),

            // --- Format ---
            Text(
              'SELECT FORMAT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FormatCard(
                    icon: LucideIcons.fileSpreadsheet,
                    title: 'CSV',
                    description: 'Best for Excel, Sheets, or scripts.',
                    accentColor: AppColors.teal,
                    selected: _selectedFormat == _ExportFormat.csv,
                    onTap: () =>
                        setState(() => _selectedFormat = _ExportFormat.csv),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _FormatCard(
                    icon: LucideIcons.fileText,
                    title: 'PDF',
                    description: 'Best for printing or sharing.',
                    accentColor: AppColors.purple,
                    selected: _selectedFormat == _ExportFormat.pdf,
                    onTap: () =>
                        setState(() => _selectedFormat = _ExportFormat.pdf),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // --- Date Range ---
            Text(
              'DATE RANGE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _RangeChip(
                  label: 'All Time',
                  selected: _selectedRange == _DateRange.allTime,
                  onTap: () =>
                      setState(() => _selectedRange = _DateRange.allTime),
                ),
                _RangeChip(
                  label: 'This Month',
                  selected: _selectedRange == _DateRange.thisMonth,
                  onTap: () =>
                      setState(() => _selectedRange = _DateRange.thisMonth),
                ),
                _RangeChip(
                  label: 'Custom',
                  icon: LucideIcons.calendar,
                  selected: _selectedRange == _DateRange.custom,
                  onTap: _pickCustomRange,
                ),
              ],
            ),
            if (_selectedRange == _DateRange.custom &&
                _customStart != null &&
                _customEnd != null) ...[
              const SizedBox(height: 12),
              Text(
                '${DateFormat('MMM d, yyyy').format(_customStart!)} — ${DateFormat('MMM d, yyyy').format(_customEnd!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.teal,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // --- Info ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 18,
                    color: AppColors.teal.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your data is processed locally. ~$transactionCount transactions available.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- Export Button ---
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.2),
                      blurRadius: 50,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: _exporting ? null : _handleExport,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Icon(LucideIcons.download, size: 20),
                  label: Text(_exporting ? 'EXPORTING...' : 'EXPORT NOW'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _selectedRange = _DateRange.custom;
      _customStart = picked.start;
      _customEnd = picked.end;
    });
  }

  List<TransactionsTableData> _filterByRange(List<TransactionsTableData> all) {
    switch (_selectedRange) {
      case _DateRange.allTime:
        return all;
      case _DateRange.thisMonth:
        final now = DateTime.now();
        return all
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
      case _DateRange.custom:
        if (_customStart == null || _customEnd == null) return const [];
        final endInclusive = DateTime(
          _customEnd!.year,
          _customEnd!.month,
          _customEnd!.day,
          23,
          59,
          59,
        );
        return all
            .where(
              (t) =>
                  !t.date.isBefore(_customStart!) &&
                  !t.date.isAfter(endInclusive),
            )
            .toList();
    }
  }

  Future<void> _handleExport() async {
    final allTransactions = ref.read(transactionsProvider).valueOrNull;
    if (allTransactions == null || allTransactions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export.')),
        );
      }
      return;
    }

    if (_selectedRange == _DateRange.custom &&
        (_customStart == null || _customEnd == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a custom date range first.')),
        );
      }
      return;
    }

    final filtered = _filterByRange(allTransactions);
    if (filtered.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No transactions in the selected range.'),
          ),
        );
      }
      return;
    }

    // Resolve category names
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    final catMap = {for (final c in categories) c.id: c.name};

    setState(() => _exporting = true);

    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      File file;
      if (_selectedFormat == _ExportFormat.csv) {
        file = await _generateCsv(filtered, catMap, dir, timestamp);
      } else {
        file = await _generatePdf(filtered, catMap, dir, timestamp);
      }

      if (!mounted) return;
      setState(() => _exporting = false);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'SpendSplit Export — $timestamp');
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<File> _generateCsv(
    List<TransactionsTableData> transactions,
    Map<int, String> catMap,
    Directory dir,
    String timestamp,
  ) async {
    final buf = StringBuffer();
    buf.writeln('Date,Type,Amount,Category,Source,Note');

    for (final t in transactions) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(t.date);
      final type = t.type;
      final amount = t.amount.toStringAsFixed(2);
      final category = _csvEscape(catMap[t.categoryId] ?? '');
      final source = _csvEscape(t.source ?? '');
      final note = _csvEscape(t.note ?? '');
      buf.writeln('$date,$type,$amount,$category,$source,$note');
    }

    final file = File(p.join(dir.path, 'spendsplit_$timestamp.csv'));
    await file.writeAsString(buf.toString());
    return file;
  }

  String _csvEscape(String value) {
    final sanitized = RegExp(r'^[\t\r ]*[=+@-]').hasMatch(value)
        ? "'$value"
        : value;

    if (sanitized.contains(',') ||
        sanitized.contains('"') ||
        sanitized.contains('\n') ||
        sanitized.contains('\r')) {
      return '"${sanitized.replaceAll('"', '""')}"';
    }
    return sanitized;
  }

  Future<File> _generatePdf(
    List<TransactionsTableData> transactions,
    Map<int, String> catMap,
    Directory dir,
    String timestamp,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    // Split into chunks of 30 rows per page
    const rowsPerPage = 30;
    for (var page = 0; page < transactions.length; page += rowsPerPage) {
      final chunk = transactions.skip(page).take(rowsPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (page == 0) ...[
                  pw.Text(
                    'SpendSplit — Transaction Export',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated ${DateFormat('MMMM d, yyyy – h:mm a').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    '${transactions.length} transactions',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                ],
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  headers: ['Date', 'Type', 'Amount', 'Category', 'Note'],
                  data: chunk.map((t) {
                    return [
                      dateFormat.format(t.date),
                      _readableType(t.type),
                      '৳ ${t.amount.toStringAsFixed(2)}',
                      catMap[t.categoryId] ?? t.source ?? '—',
                      t.note ?? '',
                    ];
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );
    }

    final file = File(p.join(dir.path, 'spendsplit_$timestamp.pdf'));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  String _readableType(String type) {
    return switch (type) {
      'income' => 'Income',
      'expense' => 'Expense',
      'savings_deposit' => 'Savings Deposit',
      'savings_withdrawal' => 'Savings Withdrawal',
      _ => type,
    };
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(20),
        glowColor: selected ? accentColor : null,
        child: Stack(
          children: [
            if (selected)
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.08),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? accentColor.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(height: 12),
                  Icon(LucideIcons.checkCircle, color: accentColor, size: 20),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceContainerHighest
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.teal : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.teal : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
