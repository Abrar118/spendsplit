import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendsplit/data/repositories/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('monthly budget persists and zero disables it', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SettingsRepository(
      await SharedPreferences.getInstance(),
    );
    expect(repository.loadSettings().monthlyExpenseBudget, 0);
    await repository.setMonthlyExpenseBudget(25000);
    expect(repository.loadSettings().monthlyExpenseBudget, 25000);
    await repository.setMonthlyExpenseBudget(0);
    expect(repository.loadSettings().monthlyExpenseBudget, 0);
    await expectLater(
      repository.setMonthlyExpenseBudget(-1),
      throwsArgumentError,
    );
    await expectLater(
      repository.setMonthlyExpenseBudget(double.nan),
      throwsArgumentError,
    );
  });
}
