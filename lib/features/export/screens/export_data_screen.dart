import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_selector/file_selector.dart' as fs;
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

import '../../../core/constants/enums.dart';
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
  bool _importing = false;

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
              'Export your local transaction history for safekeeping or import a previous SpendSplit CSV backup.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 36),

            Text(
              'IMPORT CSV',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import a CSV created by SpendSplit export. Duplicate rows are skipped automatically.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Missing expense categories will be recreated as custom categories.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _exporting || _importing
                        ? null
                        : _handleImportCsv,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: BorderSide(
                        color: AppColors.teal.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: _importing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.teal,
                            ),
                          )
                        : const Icon(LucideIcons.upload, size: 18),
                    label: Text(_importing ? 'IMPORTING...' : 'IMPORT CSV'),
                  ),
                ],
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
    File? exportedFile;

    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      if (_selectedFormat == _ExportFormat.csv) {
        exportedFile = await _generateCsv(filtered, catMap, dir, timestamp);
      } else {
        exportedFile = await _generatePdf(filtered, catMap, dir, timestamp);
      }

      await Share.shareXFiles([
        XFile(exportedFile.path),
      ], subject: 'SpendSplit Export — $timestamp');
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted && _exporting) {
        setState(() => _exporting = false);
      }

      final file = exportedFile;
      if (file != null) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } on Exception {
          // Best-effort cleanup for exported temp files.
        }
      }
    }
  }

  Future<void> _handleImportCsv() async {
    final pickedFile = await fs.openFile(
      acceptedTypeGroups: const [
        fs.XTypeGroup(
          label: 'CSV',
          extensions: ['csv'],
          mimeTypes: ['text/csv', 'text/plain', 'application/csv'],
        ),
      ],
      confirmButtonText: 'Import',
    );

    if (pickedFile == null || !mounted) return;

    setState(() => _importing = true);

    try {
      final content = await pickedFile.readAsString();
      final result = await _importCsvContent(content);
      if (!mounted) return;

      final summary = switch (result.imported) {
        0 when result.invalidRows > 0 =>
          'No rows were imported. ${result.invalidRows} invalid row${result.invalidRows == 1 ? '' : 's'} skipped.',
        0 =>
          'No new transactions were imported. ${result.duplicateRows} duplicate row${result.duplicateRows == 1 ? '' : 's'} skipped.',
        _ =>
          'Imported ${result.imported} transaction${result.imported == 1 ? '' : 's'}'
              '${result.duplicateRows > 0 ? ', skipped ${result.duplicateRows} duplicate${result.duplicateRows == 1 ? '' : 's'}' : ''}'
              '${result.invalidRows > 0 ? ', skipped ${result.invalidRows} invalid row${result.invalidRows == 1 ? '' : 's'}' : ''}'
              '${result.createdCategories > 0 ? ', created ${result.createdCategories} categor${result.createdCategories == 1 ? 'y' : 'ies'}' : ''}.',
      };

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(summary)));
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: ${e.message}')));
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted && _importing) {
        setState(() => _importing = false);
      }
    }
  }

  Future<_CsvImportResult> _importCsvContent(String content) async {
    final rows = _parseCsvRows(content);
    if (rows.isEmpty) {
      throw const FormatException('The selected file is empty.');
    }

    final header = rows.first.map((cell) => cell.trim().toLowerCase()).toList();
    final headerIndex = {for (var i = 0; i < header.length; i++) header[i]: i};
    const requiredHeaders = [
      'date',
      'type',
      'amount',
      'category',
      'source',
      'note',
    ];
    for (final column in requiredHeaders) {
      if (!headerIndex.containsKey(column)) {
        throw FormatException('Missing required "$column" column.');
      }
    }

    final transactionRepository = ref.read(transactionRepositoryProvider);
    final categoryRepository = ref.read(categoryRepositoryProvider);
    final database = ref.read(appDatabaseProvider);

    final categories = await categoryRepository.getMainCategories();
    final existingTransactions = await transactionRepository.getTransactions();

    final categoryIdByName = {
      for (final category in categories)
        _normalizeKey(category.name): category.id,
    };
    final categoryNameById = {
      for (final category in categories)
        category.id: _normalizeKey(category.name),
    };
    final existingSignatures = {
      for (final transaction in existingTransactions)
        _transactionSignature(
          type: transaction.type,
          amount: transaction.amount,
          date: transaction.date,
          categoryName: transaction.categoryId == null
              ? null
              : categoryNameById[transaction.categoryId],
          source: transaction.source,
          note: transaction.note,
        ),
    };

    final parsedRows = <_ParsedCsvTransaction>[];
    var invalidRows = 0;
    var duplicateRows = 0;

    for (final row in rows.skip(1)) {
      if (row.every((cell) => cell.trim().isEmpty)) continue;

      final parsed = _tryParseImportRow(row, headerIndex);
      if (parsed == null) {
        invalidRows += 1;
        continue;
      }

      final signature = _transactionSignature(
        type: parsed.type,
        amount: parsed.amount,
        date: parsed.date,
        categoryName: parsed.categoryName,
        source: parsed.source,
        note: parsed.note,
      );
      if (existingSignatures.contains(signature)) {
        duplicateRows += 1;
        continue;
      }

      existingSignatures.add(signature);
      parsedRows.add(parsed);
    }

    if (parsedRows.isEmpty) {
      return _CsvImportResult(
        imported: 0,
        duplicateRows: duplicateRows,
        invalidRows: invalidRows,
        createdCategories: 0,
      );
    }

    var createdCategories = 0;
    await database.transaction(() async {
      for (final row in parsedRows) {
        int? categoryId;
        if (row.type == TransactionType.expense.dbValue &&
            row.categoryName != null &&
            row.displayCategoryName != null) {
          final normalized = row.categoryName!;
          categoryId = categoryIdByName[normalized];
          if (categoryId == null) {
            categoryId = await categoryRepository.createCategory(
              CategoriesTableCompanion.insert(
                name: row.displayCategoryName!,
                icon: 'more_horiz',
                color: 0xFF8892A7,
                isPredefined: const Value(false),
                isDollarCategory: const Value(false),
              ),
            );
            categoryIdByName[normalized] = categoryId;
            createdCategories += 1;
          }
        }

        await transactionRepository.createTransaction(
          TransactionsTableCompanion.insert(
            type: row.type,
            amount: row.amount,
            categoryId: Value(categoryId),
            source: Value(row.source),
            note: Value(row.note),
            date: row.date,
            savingsGoalId: const Value(null),
          ),
        );
      }
    });

    return _CsvImportResult(
      imported: parsedRows.length,
      duplicateRows: duplicateRows,
      invalidRows: invalidRows,
      createdCategories: createdCategories,
    );
  }

  _ParsedCsvTransaction? _tryParseImportRow(
    List<String> row,
    Map<String, int> headerIndex,
  ) {
    String cell(String name) {
      final index = headerIndex[name];
      if (index == null || index >= row.length) return '';
      return row[index].trim();
    }

    final type = _parseImportedType(cell('type'));
    if (type == null) return null;

    final amount = double.tryParse(cell('amount').replaceAll(',', ''));
    if (amount == null || amount <= 0) return null;

    final dateText = cell('date');
    DateTime? date;
    try {
      date = DateFormat('yyyy-MM-dd HH:mm').parseStrict(dateText);
    } on FormatException {
      date = DateTime.tryParse(dateText);
    }
    if (date == null) return null;

    final categoryCell = cell('category');
    final sourceCell = cell('source');
    final noteCell = cell('note');

    return _ParsedCsvTransaction(
      type: type,
      amount: amount,
      date: date,
      categoryName: categoryCell.isEmpty ? null : _normalizeKey(categoryCell),
      displayCategoryName: categoryCell.isEmpty ? null : categoryCell,
      source: sourceCell.isEmpty ? null : sourceCell,
      note: noteCell.isEmpty ? null : noteCell,
    );
  }

  List<List<String>> _parseCsvRows(String raw) {
    final input = raw.replaceFirst('\ufeff', '');
    final rows = <List<String>>[];
    final currentRow = <String>[];
    var currentField = StringBuffer();
    var inQuotes = false;

    void pushField() {
      currentRow.add(currentField.toString());
      currentField = StringBuffer();
    }

    void pushRow() {
      pushField();
      rows.add(List<String>.from(currentRow));
      currentRow.clear();
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          final hasEscapedQuote = i + 1 < input.length && input[i + 1] == '"';
          if (hasEscapedQuote) {
            currentField.write('"');
            i += 1;
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
        continue;
      }

      if (char == '"') {
        inQuotes = true;
        continue;
      }

      if (char == ',') {
        pushField();
        continue;
      }

      if (char == '\n') {
        pushRow();
        continue;
      }

      if (char == '\r') {
        final nextIsLf = i + 1 < input.length && input[i + 1] == '\n';
        if (!nextIsLf) {
          pushRow();
        }
        continue;
      }

      currentField.write(char);
    }

    if (inQuotes) {
      throw const FormatException('CSV contains an unterminated quoted field.');
    }

    final hasTrailingData =
        currentField.length > 0 || currentRow.any((field) => field.isNotEmpty);
    if (hasTrailingData) {
      pushRow();
    }

    return rows
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList();
  }

  String? _parseImportedType(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'income' => TransactionType.income.dbValue,
      'expense' => TransactionType.expense.dbValue,
      'savings_deposit' ||
      'savings deposit' => TransactionType.savingsDeposit.dbValue,
      'savings_withdrawal' ||
      'savings withdrawal' => TransactionType.savingsWithdrawal.dbValue,
      _ => null,
    };
  }

  String _transactionSignature({
    required String type,
    required double amount,
    required DateTime date,
    required String? categoryName,
    required String? source,
    required String? note,
  }) {
    return [
      type,
      amount.toStringAsFixed(2),
      date.toIso8601String(),
      _normalizeKey(categoryName),
      _normalizeKey(source),
      _normalizeKey(note),
    ].join('|');
  }

  String _normalizeKey(String? value) => value?.trim().toLowerCase() ?? '';

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

class _CsvImportResult {
  const _CsvImportResult({
    required this.imported,
    required this.duplicateRows,
    required this.invalidRows,
    required this.createdCategories,
  });

  final int imported;
  final int duplicateRows;
  final int invalidRows;
  final int createdCategories;
}

class _ParsedCsvTransaction {
  const _ParsedCsvTransaction({
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryName,
    required this.displayCategoryName,
    required this.source,
    required this.note,
  });

  final String type;
  final double amount;
  final DateTime date;
  final String? categoryName;
  final String? displayCategoryName;
  final String? source;
  final String? note;
}
