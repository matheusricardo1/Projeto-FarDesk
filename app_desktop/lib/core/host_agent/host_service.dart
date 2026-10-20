import 'dart:io';

/// Ciclo de vida do Sunshine como **serviço do Windows** — nunca como
/// processo solto que o app segura aberto. É exatamente o padrão que
/// Docker Desktop usa com o `dockerd`, ou o VS Code com language servers:
/// um daemon em background, sem janela, que o app só liga/desliga/consulta.
///
/// `SunshineService` é o nome real do serviço que o próprio instalador do
/// Sunshine registra (`sunshinesvc.exe`, ver `scripts/install-service.bat`
/// do pacote oficial) — reaproveitamos o mesmo nome de propósito, pra não
/// duplicar o serviço se a pessoa também tiver o Sunshine "oficial" instalado
/// por fora.
///
/// O FarDesk em si **não** exige administrador (de propósito — senão
/// `flutter run`/abrir o app direto sempre pediria UAC). Então `sc create`
/// precisa de elevação explícita (`_runElevated`, 1 ou 2 prompts de UAC, só
/// na primeira vez que esta máquina é preparada como host). Depois disso,
/// `install()` também libera start/stop do serviço pra qualquer usuário
/// autenticado (`_grantStartStopToAuthenticatedUsers`) — é isso que faz
/// `start()`/`stop()` (chamados a cada cliente que conecta/desconecta)
/// nunca mais pedirem UAC.
///
/// Registrado com `start= demand` (manual), não `auto`: o serviço existe e
/// está configurado desde a primeira execução, mas só é efetivamente ligado
/// quando um cliente realmente tenta conectar (ver `HostActivation.ensureRunning`).
class HostService {
  HostService({required this.installDirectory, this.serviceName = 'SunshineService'});

  /// Pasta onde o pacote portátil do Sunshine foi extraído — precisa conter
  /// `tools/sunshinesvc.exe`. Quem baixa/extrai isso é outra peça
  /// (provisionamento dos arquivos), não responsabilidade desta classe.
  final Directory installDirectory;
  final String serviceName;

  String get _serviceBinaryPath => '${installDirectory.path}\\tools\\sunshinesvc.exe';

  /// `true` se o serviço já está registrado no SCM (independente de estar rodando).
  Future<bool> isInstalled() async {
    final result = await Process.run('sc', ['qc', serviceName]);
    return result.exitCode == 0;
  }

  /// Registra o serviço — início manual (`demand`) — e libera start/stop
  /// pra qualquer usuário autenticado, pra nunca mais precisar de UAC
  /// depois desta chamada. Pede elevação (UAC) só aqui.
  Future<void> install() async {
    if (await isInstalled()) return;

    await _runElevated('sc', [
      'create',
      serviceName,
      'binPath=',
      '"$_serviceBinaryPath"',
      'start=',
      'demand',
      'DisplayName=',
      '"Sunshine Service (FarDesk)"',
    ]);
    await _runElevated('sc', [
      'description',
      serviceName,
      '"Host de streaming do FarDesk — ligado só enquanto um cliente está conectado."',
    ]);
    await _grantStartStopToAuthenticatedUsers();
  }

  Future<void> uninstall() async {
    if (!await isInstalled()) return;
    await stop();
    await _runElevated('sc', ['delete', serviceName]);
  }

  /// Não precisa de UAC — `install()` já liberou start/stop pra qualquer
  /// usuário autenticado.
  Future<void> start() async {
    if (await isRunning()) return;
    await _run('sc', ['start', serviceName]);
  }

  Future<void> stop() async {
    if (!await isRunning()) return;
    await _run('sc', ['stop', serviceName]);
    await waitUntilStopped();
  }

  Future<void> waitUntilStopped({
    Duration timeout = const Duration(seconds: 15),
    Duration pollInterval = const Duration(milliseconds: 250),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (!await isRunning()) return;
      await Future<void>.delayed(pollInterval);
    }
    throw HostServiceException('Sunshine não encerrou em $timeout.');
  }

  Future<bool> isRunning() async {
    final result = await Process.run('sc', ['query', serviceName]);
    return result.exitCode == 0 && result.stdout.toString().contains('RUNNING');
  }

  /// Espera a API HTTP do Sunshine (porta 47990) responder — é o sinal real
  /// de "pronto pra uso", não só "o processo existe". `onReady` faz uma
  /// chamada leve (ex: `HostApi.isReachable()`) e deve devolver falso
  /// enquanto o serviço ainda está de pé mas a API não respondeu.
  Future<void> waitUntilReady({
    required Future<bool> Function() onReady,
    Duration timeout = const Duration(seconds: 20),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await onReady()) return;
      await Future<void>.delayed(pollInterval);
    }
    throw HostServiceException('Sunshine não respondeu em $timeout.');
  }

  /// `sc sdshow`/`sdset` são a forma documentada de mudar quem pode
  /// start/stop um serviço específico sem precisar ser admin — adiciona
  /// uma ACE concedendo `RP` (start) e `WP` (stop) pro grupo "Authenticated
  /// Users" (`AU`) na security descriptor do serviço. Best-effort: se
  /// falhar (ex: SDDL em formato inesperado), o serviço continua
  /// funcional — só vai exigir UAC em todo `start()`/`stop()` também.
  Future<void> _grantStartStopToAuthenticatedUsers() async {
    try {
      final current = await Process.run('sc', ['sdshow', serviceName]);
      // `sc sdshow` imprime linha(s) de cabeçalho antes da SDDL de
      // verdade — a linha certa é a primeira que começa com "D:" (toda
      // SDDL válida começa pela DACL). Usar a saída inteira aqui fazia o
      // `sc sdset` receber lixo e falhar silenciosamente (best-effort).
      final sddl = current.stdout
          .toString()
          .split('\n')
          .map((line) => line.trim())
          .firstWhere((line) => line.startsWith('D:'), orElse: () => '');
      if (sddl.isEmpty) return;

      const startStopForAuthenticatedUsers = '(A;;RPWP;;;AU)';
      if (sddl.contains('AU)')) return; // já concedido numa instalação anterior.

      final sIndex = sddl.indexOf('S:');
      final updated = sIndex == -1
          ? '$sddl$startStopForAuthenticatedUsers'
          : '${sddl.substring(0, sIndex)}$startStopForAuthenticatedUsers${sddl.substring(sIndex)}';

      await _runElevated('sc', ['sdset', serviceName, updated]);
    } catch (_) {
      // Best-effort — ver doc do método.
    }
  }

  Future<void> _run(String executable, List<String> args) async {
    final result = await Process.run(executable, args);
    if (result.exitCode != 0) {
      throw HostServiceException('Falha ao executar "$executable ${args.join(' ')}": ${result.stderr}'.trim());
    }
  }

  /// `sc create`/`delete`/`sdset` exigem admin — como o FarDesk não roda
  /// elevado, a única forma de pedir isso é abrir um processo elevado à
  /// parte (`Start-Process -Verb RunAs`), que dispara o UAC.
  Future<void> _runElevated(String executable, List<String> args) async {
    final argString = args.map((a) => a.contains(' ') ? "'$a'" : a).join(',');
    final command = "Start-Process -FilePath '$executable' -ArgumentList $argString -Verb RunAs -Wait "
        "-WindowStyle Hidden";
    final result = await Process.run('powershell', ['-NoProfile', '-Command', command]);
    if (result.exitCode != 0) {
      throw HostServiceException('Falha ao executar "$executable" elevado: ${result.stderr}'.trim());
    }
  }
}

class HostServiceException implements Exception {
  const HostServiceException(this.message);

  final String message;

  @override
  String toString() => 'HostServiceException: $message';
}
