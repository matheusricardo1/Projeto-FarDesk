import 'dart:developer' as developer;

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

  // Builds locais podem sobrescrever a URL com
  // `--dart-define=BACKEND_BASE_URL=http://localhost:3000`.
  const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://fardesk-api.vercel.app',
  );
  const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.2',
  );
  developer.log(
    'FarDesk $appVersion usando backend $backendBaseUrl',
    name: 'FarDesk',
  );

  runApp(
    FarDeskApp(
      dependencies: AppDependencies.real(
        backendBaseUrl: backendBaseUrl,
        appVersion: appVersion,
      ),
    ),
  );
}
