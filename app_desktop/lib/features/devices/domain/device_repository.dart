import '../../../core/result.dart';
import 'device.dart';

/// Fonte dos dispositivos da conta. A implementação real conversa com o
/// backend orquestrador (status via heartbeat, Wake-on-LAN via agente).
abstract interface class DeviceRepository {
  Future<Result<List<Device>>> fetchDevices();

  /// Inicia a sessão de stream com o dispositivo.
  Future<Result<void>> connect(String deviceId);

  /// Acorda um dispositivo hibernando e retorna o estado atualizado.
  Future<Result<Device>> wake(String deviceId);
}
