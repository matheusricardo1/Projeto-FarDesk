import 'dart:convert';

import 'package:http/http.dart' as http;

import '../http/access_token_provider.dart';
import '../http/api_exception.dart';

class TailscaleAuthKey {
  const TailscaleAuthKey({required this.value, required this.expiresAt});

  final String value;
  final DateTime expiresAt;

  factory TailscaleAuthKey.fromJson(Map<String, dynamic> json) => TailscaleAuthKey(
        value: json['authKey'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

class TailscaleNetworkDevice {
  const TailscaleNetworkDevice({
    required this.id,
    required this.name,
    required this.hostname,
    required this.addresses,
    required this.online,
  });

  final String id;
  final String name;
  final String hostname;
  final List<String> addresses;
  final bool online;

  factory TailscaleNetworkDevice.fromJson(Map<String, dynamic> json) => TailscaleNetworkDevice(
        id: json['id'] as String,
        name: json['name'] as String,
        hostname: json['hostname'] as String,
        addresses: (json['addresses'] as List<dynamic>).cast<String>(),
        online: json['online'] as bool,
      );
}

class TailscaleNetworkApi {
  TailscaleNetworkApi({
    required this.backendBaseUrl,
    required this.accessToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String backendBaseUrl;
  final AccessTokenProvider accessToken;
  final http.Client _http;

  Map<String, String> get _headers {
    final token = accessToken();
    if (token == null || token.isEmpty) throw ApiException('Nenhuma conta logada.');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Future<TailscaleAuthKey> issueAuthKey() async {
    final response = await _http.post(
      Uri.parse('$backendBaseUrl/integrations/tailscale/auth-key'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _errorFor(response);
    return TailscaleAuthKey.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<TailscaleNetworkDevice>> listDevices() async {
    final response = await _http.get(
      Uri.parse('$backendBaseUrl/integrations/tailscale/devices'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _errorFor(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((json) => TailscaleNetworkDevice.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  ApiException _errorFor(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body['message'];
      if (message is String) return ApiException(message, statusCode: response.statusCode);
    } catch (_) {
      // The status code remains useful when the server did not return JSON.
    }
    return ApiException(
      'Falha ao falar com a rede FarDesk (HTTP ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}
