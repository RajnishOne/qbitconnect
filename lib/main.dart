import 'package:flutter/material.dart';
import 'src/core/core.dart';

void main() async {
  // Initialize all app services and dependencies
  await AppInitializer.initialize();

  // Run the app
  runApp(const AppWidget());
}
