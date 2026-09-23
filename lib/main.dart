import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'features/widget/widget_data_service.dart';

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
