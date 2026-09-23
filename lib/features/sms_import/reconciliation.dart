import '../../core/constants/enums.dart';
import '../../data/database/app_database.dart';

class BankReconciliation {
  const BankReconciliation({required this.bank, required this.app});

  final double bank;
  final double app;

  double get diff => bank - app;
}

/// App Total Balance (initial + income − expenses) counting only
/// transactions dated at or before [asOf]. Savings moves are ignored: they
/// stay in the same bank account.
double appTotalAsOf(
  Iterable<TransactionsTableData> transactions, {
  required double initialBalance,
  required DateTime asOf,
}) {
  var total = initialBalance;
  for (final t in transactions) {
    if (t.date.isAfter(asOf)) continue;
    if (t.type == TransactionType.income.dbValue) total += t.amount;
    if (t.type == TransactionType.expense.dbValue) total -= t.amount;
  }
  return total;
}
