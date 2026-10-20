import 'package:app_desktop/core/host_agent/host_agent_pairing_service.dart';
import 'package:app_desktop/core/http/access_token_provider.dart';
import 'package:app_desktop/core/host_agent/models/pairing_request_summary.dart';
import 'package:app_desktop/core/host_agent/models/pending_sunshine_pairing.dart';
import 'package:app_desktop/core/host_agent/pairing_api_client.dart';
import 'package:app_desktop/core/host_agent/sunshine_admin_client.dart';
import 'package:app_desktop/core/sunshine/sunshine_pairing_client.dart' show sunshineClientDeviceName;
import 'package:flutter_test/flutter_test.dart';

/// Fakes — nada aqui chama rede de verdade. `PairingApiClient` e
/// `SunshineAdminClient` são classes concretas (não interfaces) no código
/// real, então os fakes estendem e sobrescrevem os métodos usados pelo
/// serviço, igual o resto do app faz pra testar sem o Nest/backend em pé.
class FakePairingApiClient implements PairingApiClient {
  FakePairingApiClient({this.pending});

  PairingRequestSummary? pending;
  String? ackedRequestId;
  String? failedRequestId;
  String? failureReason;

  @override
  String get backendBaseUrl => 'http://fake';

  @override
  AccessTokenProvider get accessToken => () => 'fake-token';

  @override
  Future<PairingRequestSummary?> fetchPending(String deviceId) async => pending;

  @override
  Future<void> ack(String deviceId, String requestId) async => ackedRequestId = requestId;

  @override
  Future<void> fail(String deviceId, String requestId, String reason) async {
    failedRequestId = requestId;
    failureReason = reason;
  }
}

class FakeSunshineAdminClient implements SunshineAdminClient {
  FakeSunshineAdminClient({this.localPairings = const [], this.acceptPin = true});

  List<PendingSunshinePairing> localPairings;
  bool acceptPin;
  String? submittedPairingId;
  String? submittedPin;

  @override
  String get username => 'fake';

  @override
  String get password => 'fake';

  @override
  String get host => 'localhost';

  @override
  int get port => 47990;

  @override
  Future<List<PendingSunshinePairing>> listPendingPairings() async => localPairings;

  @override
  Future<bool> submitPin({required String pairingId, required String pin, required String clientName}) async {
    submittedPairingId = pairingId;
    submittedPin = pin;
    return acceptPin;
  }

  @override
  Future<bool> bootstrapCredentials() async => true;

  @override
  Future<List<Map<String, dynamic>>> listApps() async => const [];

  @override
  Future<bool> addApp(Map<String, dynamic> app) async => true;

  @override
  Future<bool> closeApp() async => true;

  @override
  Future<List<Map<String, dynamic>>> listClients() async => const [];

  @override
  Future<bool> unpairClient(String uuid) async => true;

  @override
  Future<bool> unpairAllClients() async => true;
}

void main() {
  group('HostAgentPairingService', () {
    test('não faz nada quando não há pareamento pendente no backend', () async {
      final pairingApi = FakePairingApiClient();
      final sunshineAdmin = FakeSunshineAdminClient();
      final service = HostAgentPairingService(deviceId: 'device-1', pairingApi: pairingApi, sunshineAdmin: sunshineAdmin);

      await service.runPairingCycle();

      expect(pairingApi.ackedRequestId, isNull);
    });

    test('não liga o Sunshine (ensureHostRunning) sem pareamento pendente', () async {
      var calls = 0;
      final pairingApi = FakePairingApiClient();
      final service = HostAgentPairingService(
        deviceId: 'device-1',
        pairingApi: pairingApi,
        sunshineAdmin: FakeSunshineAdminClient(),
        ensureHostRunning: () async => calls++,
      );

      await service.runPairingCycle();

      expect(calls, 0);
    });

    test('liga o Sunshine (ensureHostRunning) só quando aparece um pareamento pendente de verdade', () async {
      var calls = 0;
      final pairingApi = FakePairingApiClient(
        pending: const PairingRequestSummary(id: 'req-1', deviceId: 'device-1', pin: '4242', status: 'pending'),
      );
      final sunshineAdmin = FakeSunshineAdminClient(
        localPairings: const [PendingSunshinePairing(pairingId: 'p', deviceName: sunshineClientDeviceName, address: 'x')],
      );
      final service = HostAgentPairingService(
        deviceId: 'device-1',
        pairingApi: pairingApi,
        sunshineAdmin: sunshineAdmin,
        ensureHostRunning: () async => calls++,
      );

      await service.runPairingCycle();

      expect(calls, 1);
    });

    test('não faz nada enquanto o cliente ainda não chegou no Sunshine local', () async {
      final pairingApi = FakePairingApiClient(
        pending: const PairingRequestSummary(id: 'req-1', deviceId: 'device-1', pin: '1234', status: 'pending'),
      );
      final sunshineAdmin = FakeSunshineAdminClient(localPairings: const []);
      final service = HostAgentPairingService(deviceId: 'device-1', pairingApi: pairingApi, sunshineAdmin: sunshineAdmin);

      await service.runPairingCycle();

      expect(pairingApi.ackedRequestId, isNull);
      expect(pairingApi.failedRequestId, isNull);
    });

    test('submete o PIN certo e confirma (ack) quando o Sunshine aceita', () async {
      final pairingApi = FakePairingApiClient(
        pending: const PairingRequestSummary(id: 'req-1', deviceId: 'device-1', pin: '4242', status: 'pending'),
      );
      final sunshineAdmin = FakeSunshineAdminClient(
        localPairings: const [
          PendingSunshinePairing(pairingId: 'outro-nome', deviceName: 'Outro App', address: '10.0.0.5'),
          PendingSunshinePairing(pairingId: 'pairing-abc', deviceName: sunshineClientDeviceName, address: '10.0.0.9'),
        ],
      );
      final service = HostAgentPairingService(deviceId: 'device-1', pairingApi: pairingApi, sunshineAdmin: sunshineAdmin);

      await service.runPairingCycle();

      expect(sunshineAdmin.submittedPairingId, 'pairing-abc');
      expect(sunshineAdmin.submittedPin, '4242');
      expect(pairingApi.ackedRequestId, 'req-1');
      expect(pairingApi.failedRequestId, isNull);
    });

    test('reporta falha pro backend quando o Sunshine recusa o PIN', () async {
      final pairingApi = FakePairingApiClient(
        pending: const PairingRequestSummary(id: 'req-1', deviceId: 'device-1', pin: '0000', status: 'pending'),
      );
      final sunshineAdmin = FakeSunshineAdminClient(
        localPairings: const [PendingSunshinePairing(pairingId: 'pairing-xyz', deviceName: sunshineClientDeviceName, address: '10.0.0.9')],
        acceptPin: false,
      );
      final service = HostAgentPairingService(deviceId: 'device-1', pairingApi: pairingApi, sunshineAdmin: sunshineAdmin);

      await service.runPairingCycle();

      expect(pairingApi.ackedRequestId, isNull);
      expect(pairingApi.failedRequestId, 'req-1');
      expect(pairingApi.failureReason, isNotEmpty);
    });

    test('ignora uma solicitação que não está mais pending (já foi completada/falhou)', () async {
      final pairingApi = FakePairingApiClient(
        pending: const PairingRequestSummary(id: 'req-1', deviceId: 'device-1', pin: '1234', status: 'completed'),
      );
      final sunshineAdmin = FakeSunshineAdminClient(
        localPairings: const [PendingSunshinePairing(pairingId: 'p', deviceName: sunshineClientDeviceName, address: 'x')],
      );
      final service = HostAgentPairingService(deviceId: 'device-1', pairingApi: pairingApi, sunshineAdmin: sunshineAdmin);

      await service.runPairingCycle();

      expect(sunshineAdmin.submittedPairingId, isNull);
    });

    test('start/stop controlam o timer', () async {
      final service = HostAgentPairingService(
        deviceId: 'device-1',
        pairingApi: FakePairingApiClient(),
        sunshineAdmin: FakeSunshineAdminClient(),
        pollInterval: const Duration(milliseconds: 10),
      );

      expect(service.isRunning, isFalse);
      service.start();
      expect(service.isRunning, isTrue);
      service.stop();
      expect(service.isRunning, isFalse);
    });

    test('erro num ciclo não derruba o serviço — só é reportado via onError', () async {
      final pairingApi = _ThrowingPairingApiClient();
      Object? reportedError;
      final service = HostAgentPairingService(
        deviceId: 'device-1',
        pairingApi: pairingApi,
        sunshineAdmin: FakeSunshineAdminClient(),
        onError: (error) => reportedError = error,
      );

      await service.runPairingCycle();

      expect(reportedError, isNotNull);
    });
  });
}

class _ThrowingPairingApiClient extends FakePairingApiClient {
  @override
  Future<PairingRequestSummary?> fetchPending(String deviceId) async {
    throw StateError('rede fora do ar');
  }
}
