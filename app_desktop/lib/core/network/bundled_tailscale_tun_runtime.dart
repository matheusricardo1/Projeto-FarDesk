import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'network_runtime.dart';

class BundledTailscaleTunRuntime implements NetworkRuntime {
  BundledTailscaleTunRuntime({required this.executableDirectory})
    : _status = ValueNotifier(
        const NetworkRuntimeStatus(state: NetworkRuntimeState.stopped),
      );

  final Directory executableDirectory;
  final ValueNotifier<NetworkRuntimeStatus> _status;
  Process? _daemon;
  Process? _cli;

  @override
  bool get supportsSystemSockets => true;

  @override
  ValueListenable<NetworkRuntimeStatus> get status => _status;

  @override
  Future<NetworkRuntimeStatus> start({
    required String authKey,
    required String stateDirectory,
    required String hostname,
  }) async {
    if (_status.value.state == NetworkRuntimeState.running) {
      return _status.value;
    }
    if (!Platform.isWindows) {
      throw const NetworkRuntimeException(
        'A rede TUN embutida está disponível apenas no Windows.',
      );
    }

    _status.value = const NetworkRuntimeStatus(
      state: NetworkRuntimeState.starting,
    );
    final state = Directory(stateDirectory);
    await state.create(recursive: true);
    final daemonPath = '${executableDirectory.path}\\tailscaled.exe';
    final cliPath = '${executableDirectory.path}\\tailscale.exe';
    if (!File(daemonPath).existsSync() || !File(cliPath).existsSync()) {
      throw NetworkRuntimeException(
        'O runtime TUN do FarDesk não foi distribuído. Esperados tailscaled.exe e tailscale.exe em ${executableDirectory.path}.',
      );
    }

    _daemon = await Process.start(daemonPath, [
      '--state=${state.path}\\tailscaled.state',
      '--socket=${state.path}\\tailscaled.sock',
      '--tun=wintun',
    ], runInShell: false);
    try {
      final socket = '${state.path}\\tailscaled.sock';
      await _runCliWithRetry(cliPath, [
        '--socket=$socket',
        'up',
        '--auth-key=$authKey',
        '--hostname=$hostname',
        '--accept-routes=false',
      ]);
      final json = await _runCli(cliPath, [
        '--socket=$socket',
        'status',
        '--json',
      ]);
      final addresses = _addressesFromStatus(json);
      if (addresses.isEmpty) {
        throw const NetworkRuntimeException(
          'O runtime TUN subiu, mas ainda não recebeu um endereço Tailscale.',
        );
      }
      final next = NetworkRuntimeStatus(
        state: NetworkRuntimeState.running,
        addresses: addresses,
      );
      _status.value = next;
      return next;
    } catch (error) {
      await stop();
      _status.value = NetworkRuntimeStatus(
        state: NetworkRuntimeState.failed,
        error: error,
      );
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    final cli = _cli;
    final daemon = _daemon;
    _cli = null;
    _daemon = null;
    if (cli != null) cli.kill();
    if (daemon != null) daemon.kill();
    _status.value = const NetworkRuntimeStatus(
      state: NetworkRuntimeState.stopped,
    );
  }

  @override
  void dispose() {
    stop();
    _status.dispose();
  }

  Future<String> _runCli(String executable, List<String> arguments) async {
    final process = await Process.start(
      executable,
      arguments,
      runInShell: false,
    );
    _cli = process;
    final stdout = await process.stdout.transform(utf8.decoder).join();
    final stderr = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw NetworkRuntimeException(
        stderr.trim().isEmpty
            ? 'tailscale.exe falhou (código $exitCode).'
            : stderr.trim(),
      );
    }
    return stdout;
  }

  Future<String> _runCliWithRetry(
    String executable,
    List<String> arguments, {
    int attempts = 20,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        return await _runCli(executable, arguments);
      } catch (error) {
        lastError = error;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    throw NetworkRuntimeException('O daemon TUN não ficou pronto: $lastError');
  }

  List<String> _addressesFromStatus(String raw) {
    final status = jsonDecode(raw) as Map<String, dynamic>;
    final self = status['Self'] as Map<String, dynamic>?;
    final addresses = self?['TailscaleIPs'] as List<dynamic>?;
    return addresses
            ?.whereType<String>()
            .where((address) => address.contains('.'))
            .toList(growable: false) ??
        const [];
  }
}
