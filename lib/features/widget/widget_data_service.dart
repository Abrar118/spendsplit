import 'package:home_widget/home_widget.dart';

/// Pushes the latest balance data to the native home screen widget.
class WidgetDataService {
  static const _appGroupId = 'group.com.example.spendsplit';
  static const _androidWidgetName = 'SpendSplitWidgetProvider';

  static Future<void> initialize() async {
    HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateBalance({
    required double availableBalance,
    required double savingsPercent,
  }) async {
    await HomeWidget.saveWidgetData<String>(
      'available_balance',
      _formatAmount(availableBalance),
    );
    await HomeWidget.saveWidgetData<String>(
      'savings_percent',
      '${savingsPercent >= 0 ? '+' : ''}${savingsPercent.toStringAsFixed(1)}%',
    );
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: 'SpendSplitWidget',
    );
  }

  static String _formatAmount(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount.abs() >= 1000) {
      final whole = amount.truncate();
      return _addCommas(whole);
    }
    return amount.toStringAsFixed(0);
  }

  static String _addCommas(int value) {
    final str = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return value < 0 ? '-${buf.toString()}' : buf.toString();
  }
}
