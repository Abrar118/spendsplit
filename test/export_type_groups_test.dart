import 'package:flutter_test/flutter_test.dart';
import 'package:spendsplit/features/export/screens/export_data_screen.dart';

void main() {
  // file_selector_ios throws (silently, from a tap handler) when a type group
  // has no uniformTypeIdentifiers.
  test('import/restore pickers declare iOS UTIs', () {
    for (final group in [csvTypeGroup, jsonTypeGroup]) {
      expect(group.uniformTypeIdentifiers, isNotEmpty, reason: group.label);
    }
  });
}
