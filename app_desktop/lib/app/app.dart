import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_system/design_system.dart';
import '../features/account/presentation/login_screen.dart';
import '../features/account/presentation/session_view_model.dart';
import '../shell/app_shell.dart';
import '../shell/title_bar.dart';
import 'dependencies.dart';

class FarDeskApp extends StatelessWidget {
  const FarDeskApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: dependencies.providers,
      child: MaterialApp(
        title: 'FarDesk',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _AppRoot(),
      ),
    );
  }
}

/// Moldura da janela (barra de título própria, já que não há moldura nativa)
/// + alternância entre login e área logada a partir do estado de sessão.
/// Sem navegação imperativa: sair da conta no futuro volta pro login sozinho.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<SessionViewModel, bool>((session) => session.isSignedIn);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const TitleBar(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: FadeSwitcher(
              duration: Motion.slow,
              child: signedIn ? const AppShell(key: ValueKey('shell')) : const LoginScreen(key: ValueKey('login')),
            ),
          ),
        ],
      ),
    );
  }
}
