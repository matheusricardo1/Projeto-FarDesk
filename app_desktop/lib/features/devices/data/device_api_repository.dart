import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/http/access_token_provider.dart';
import '../../../core/http/api_exception.dart';
import '../../../core/result.dart';
import '../domain/device.dart';
import '../domain/device_repository.dart';

/// Implementação real: fala com `backend/src/modules/devices` de verdade.
///
/// `DeviceResponseDto` do backend não diz qual device é "este PC" — isso
/// exigiria o host se auto-identificar pro backend, peça que ainda não
/// existe. Por enquanto nenhum device volta com `isCurrentDevice: true`.
class DeviceApiRepository implements DeviceRepository {
  DeviceApiRepository({
    required this.backendBaseUrl,
    required this.accessToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String backendBaseUrl;
  final AccessTokenProvider accessToken;
  final http.Client _http;

  Map<String, String> get _headers {
    final token = accessToken();
    if (token == null) throw ApiException('Nenhuma conta logada.');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  @override
  Future<Result<List<Device>>> fetchDevices() async {
    try {
      final response = await _http.get(Uri.parse('$backendBaseUrl/devices'), headers: _headers);
      if (response.statusCode != 200) return Failure(_errorFor(response));
      final list = jsonDecode(response.body) as List<dynamic>;
      return Ok(list.map((json) => _deviceFromJson(json as Map<String, dynamic>)).toList(growable: false));
    } catch (error) {
      return Failure(error);
    }
  }

  @override
  Future<Result<void>> connect(String deviceId) async {
    try {
      final response = await _http.post(Uri.parse('$backendBaseUrl/devices/$deviceId/connect'), headers: _headers);
      if (response.statusCode != 200) return Failure(_errorFor(response));
      return const Ok(null);
    } catch (error) {
      return Failure(error);
    }
  }

  @override
  Future<Result<Device>> wake(String deviceId) async {
    try {
      final response = await _http.post(Uri.parse('$backendBaseUrl/devices/$deviceId/wake'), headers: _headers);
      if (response.statusCode != 200) return Failure(_errorFor(response));
      return Ok(_deviceFromJson(jsonDecode(response.body) as Map<String, dynamic>));
    } catch (error) {
      return Failure(error);
    }
  }

  Device _deviceFromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        name: json['name'] as String,
        platform: DevicePlatform.values.byName(json['platform'] as String),
        status: DeviceStatus.values.byName(json['status'] as String),
      );

  ApiException _errorFor(http.Response response) {
    final body = _tryDecode(response.body);
    final message = body?['message'];
    return ApiException(
      message is String ? message : 'Falha ao falar com o backend (HTTP ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
