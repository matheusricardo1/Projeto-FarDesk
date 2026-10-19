/// Um pareamento esperando PIN, do jeito que o próprio Sunshine local vê —
/// `GET https://localhost:47990/api/pin`. `id` aqui é o `pairing_id` do
/// Sunshine (32 hex), nada a ver com o id da `PairingRequest` do backend do
/// FarDesk — são dois sistemas diferentes que o agente precisa correlacionar.
class PendingSunshinePairing {
  const PendingSunshinePairing({required this.pairingId, required this.deviceName, required this.address});

  final String pairingId;
  final String deviceName;
  final String address;
}
