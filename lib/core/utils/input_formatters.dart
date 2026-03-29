import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.maxDecimalPlaces = 2})
    : assert(maxDecimalPlaces >= 0);

  final int maxDecimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final pattern = RegExp('^\\d*\\.?\\d{0,$maxDecimalPlaces}\$');

    if (pattern.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}
