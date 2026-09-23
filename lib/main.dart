import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'features/sms_import/sms_gateway.dart';
import 'features/sms_import/sms_import_runner.dart';
import 'features/widget/home_widget_sync.dart';
import 'features/widget/widget_data_service.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await WidgetDataService.initialize();

  runApp(
    ProviderScope(
      overrides: await bootstrapOverrides(),
      child: const SpendSplitApp(),
    ),
  );
}

/// Entrypoint for SmsReceiver's headless engine when the app isn't running.
@pragma('vm:entry-point')
Future<void> smsBackgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetDataService.initialize();
  final container = ProviderContainer(overrides: await bootstrapOverrides());
  try {
    final inserted = await container
        .read(smsImportRunnerProvider)
        .run(waitForNew: true);
    if (inserted > 0) {
      await container.read(transactionsProvider.future);
      await syncHomeWidget(container.read);
    }
  } finally {
    container.dispose();
    await const SmsGateway().backgroundDone();
  }
}
