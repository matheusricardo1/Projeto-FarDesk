/// Espelha o `PairingRequestResponseDto` do backend — só os campos que o
/// agente precisa pra agir.
class PairingRequestSummary {
  const PairingRequestSummary({required this.id, required this.deviceId, required this.pin, required this.status});

  final String id;
  final String deviceId;
  final String pin;
  final String status;

  factory PairingRequestSummary.fromJson(Map<String, dynamic> json) => PairingRequestSummary(
        id: json['id'] as String,
        deviceId: json['deviceId'] as String,
        pin: json['pin'] as String,
        status: json['status'] as String,
      );
}
