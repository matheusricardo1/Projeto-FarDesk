import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../core/design_system/design_system.dart';
import '../core/update/app_update_service.dart';
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
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final shellKey = GlobalKey<AppShellState>();
  bool _checkingForUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_checkingForUpdate) return;
    _checkingForUpdate = true;
    final update = await context.read<AppUpdateService>().checkForUpdate();
    if (!mounted || update == null) return;
    await _showUpdateDialog(update);
  }

  Future<void> _showUpdateDialog(AppUpdateInfo update) async {
    final shouldUpdate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Nova versão disponível'),
        content: Text(
          'A versão ${update.version} do FarDesk está disponível. '
          'Deseja atualizar agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Depois'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Atualizar agora'),
          ),
        ],
      ),
    );
    if (shouldUpdate != true || !mounted) return;

    try {
      final installer = await context
          .read<AppUpdateService>()
          .downloadInstaller(update);
      await Process.start(
        installer.path,
        const [],
        mode: ProcessStartMode.detached,
      );
      await windowManager.close();
    } on SocketException catch (error, stackTrace) {
      await _showUpdateError(error, stackTrace);
    } on HttpException catch (error, stackTrace) {
      await _showUpdateError(error, stackTrace);
    } on FileSystemException catch (error, stackTrace) {
      await _showUpdateError(error, stackTrace);
    } on ProcessException catch (error, stackTrace) {
      await _showUpdateError(error, stackTrace);
    }
  }

  Future<void> _showUpdateError(Object error, StackTrace stackTrace) async {
    debugPrint('[FarDeskApp] falha ao instalar atualização: $error');
    debugPrint('$stackTrace');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Não foi possível atualizar'),
        content: const Text(
          'Tente novamente mais tarde ou baixe a versão mais recente pelo site do FarDesk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<SessionViewModel, bool>(
      (session) => session.isSignedIn,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          TitleBar(
            onBeforeClose: () async {
              await shellKey.currentState?.shutdown();
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: FadeSwitcher(
              duration: Motion.slow,
              child: signedIn
                  ? AppShell(key: shellKey)
                  : const LoginScreen(key: ValueKey('login')),
            ),
          ),
        ],
      ),
    );
  }
}
