import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    title: 'FarDesk',
    size: Size(1280, 800),
    minimumSize: Size(960, 600),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // URL do backend — override com `flutter run --dart-define=BACKEND_BASE_URL=https://...`
  // quando o backend não estiver em localhost:3000.
  const backendBaseUrl = String.fromEnvironment('BACKEND_BASE_URL', defaultValue: 'http://localhost:3000');

  runApp(FarDeskApp(dependencies: AppDependencies.real(backendBaseUrl: backendBaseUrl)));
}
