import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'src/core/core.dart';

void main() async {
  // Initialize all app services and dependencies
  await AppInitializer.initialize();

  // Initialize EasyLocalization
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Run the app
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: const AppWidget(),
    ),
  );
}
