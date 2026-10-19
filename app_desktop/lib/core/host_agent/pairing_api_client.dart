import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/pairing_request_summary.dart';

/// Lado do agente na conversa com o backend do FarDesk — ver
/// `backend/src/modules/pairing`. O agente só lê (`pending`) e confirma
/// (`ack`/`fail`); quem cria a `PairingRequest` é sempre o cliente que quer
/// se conectar (`CreatePairingRequestUseCase`), nunca o agente.
class PairingApiClient {
  PairingApiClient({required this.backendBaseUrl, required this.accessToken, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final String backendBaseUrl;
  final String accessToken;
  final http.Client _http;

  Map<String, String> get _headers => {'Authorization': 'Bearer $accessToken'};

  /// `null` quando não há nenhum pareamento esperando esse dispositivo agora.
  Future<PairingRequestSummary?> fetchPending(String deviceId) async {
    final response = await _http.get(
      Uri.parse('$backendBaseUrl/devices/$deviceId/pairing-requests/pending'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw PairingApiException('Falha ao consultar pareamento pendente (HTTP ${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final request = body['request'] as Map<String, dynamic>?;
    return request == null ? null : PairingRequestSummary.fromJson(request);
  }

  Future<void> ack(String deviceId, String requestId) async {
    final response = await _http.post(
      Uri.parse('$backendBaseUrl/devices/$deviceId/pairing-requests/$requestId/ack'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw PairingApiException('Falha ao confirmar entrega do PIN (HTTP ${response.statusCode}).');
    }
  }

  Future<void> fail(String deviceId, String requestId, String reason) async {
    final response = await _http.post(
      Uri.parse('$backendBaseUrl/devices/$deviceId/pairing-requests/$requestId/fail'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode != 200) {
      throw PairingApiException('Falha ao registrar falha de pareamento (HTTP ${response.statusCode}).');
    }
  }
}

class PairingApiException implements Exception {
  const PairingApiException(this.message);

  final String message;

  @override
  String toString() => 'PairingApiException: $message';
}
