import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/http/access_token_provider.dart';
import '../../../core/http/api_exception.dart';
import '../../../core/result.dart';
import '../domain/integration.dart';
import '../domain/integration_repository.dart';

/// Implementação real: fala com `backend/src/modules/integrations`.
///
/// O backend só sabe de plataformas de verdade (hoje só Tailscale, via
/// `IntegrationPlatform`) e só devolve uma entrada em `GET /integrations`
/// pra quem já foi conectado alguma vez — nunca uma lista fixa de "cards".
/// Por isso o catálogo (nome, ícone, categoria, obrigatoriedade) é mantido
/// aqui no cliente e só tem o status sobreposto pelo que vem do backend.
/// Steam e Hydra aparecem no catálogo mas ainda não têm backend: tentar
/// conectá-los devolve uma falha clara em vez de fingir sucesso.
class IntegrationApiRepository implements IntegrationRepository {
  IntegrationApiRepository({
    required this.backendBaseUrl,
    required this.accessToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String backendBaseUrl;
  final AccessTokenProvider accessToken;
  final http.Client _http;

  static const _catalog = [
    Integration(
      id: 'tailscale',
      name: 'Tailscale',
      description: 'Rede privada que conecta seus dispositivos sem configurar porta ou IP manualmente. '
          'Entra com um API access token gerado no painel do Tailscale.',
      icon: Icons.hub_rounded,
      category: IntegrationCategory.network,
      status: IntegrationStatus.disconnected,
      required: true,
      authMethod: IntegrationAuthMethod.apiKey,
    ),
    Integration(
      id: 'steam',
      name: 'Steam',
      description: 'Cruza sua biblioteca Steam com o que está instalado em cada PC.',
      icon: Icons.videogame_asset_rounded,
      category: IntegrationCategory.library,
      status: IntegrationStatus.disconnected,
    ),
    Integration(
      id: 'hydra',
      name: 'Hydra Launcher',
      description: 'Cruza sua biblioteca do Hydra Launcher com o que está instalado em cada PC.',
      icon: Icons.bolt_rounded,
      category: IntegrationCategory.library,
      status: IntegrationStatus.disconnected,
    ),
  ];

  Map<String, String> get _headers {
    final token = accessToken();
    if (token == null) throw ApiException('Nenhuma conta logada.');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  @override
  Future<Result<List<Integration>>> fetchIntegrations() async {
    try {
      final response = await _http.get(Uri.parse('$backendBaseUrl/integrations'), headers: _headers);
      if (response.statusCode != 200) return Failure(_errorFor(response));
      final connected = (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
      return Ok(_catalog.map((integration) => _overlay(integration, connected)).toList(growable: false));
    } catch (error) {
      return Failure(error);
    }
  }

  Integration _overlay(Integration catalogEntry, List<Map<String, dynamic>> connected) {
    final match = connected.firstWhere(
      (json) => json['platform'] == catalogEntry.id,
      orElse: () => const {},
    );
    if (match.isEmpty || match['status'] != 'connected') return catalogEntry;
    return catalogEntry.connectedWith('sua conta Tailscale');
  }

  @override
  Future<Result<Integration>> connect(String integrationId) async =>
      Failure(ApiException('"$integrationId" ainda não tem integração real — só o Tailscale está disponível por enquanto.'));

  @override
  Future<Result<Integration>> connectTailscale({required String apiAccessToken}) async {
    try {
      final response = await _http.post(
        Uri.parse('$backendBaseUrl/integrations/tailscale/connect'),
        headers: _headers,
        body: jsonEncode({'apiAccessToken': apiAccessToken}),
      );
      if (response.statusCode != 200) return Failure(_errorFor(response));
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'connected') {
        return Failure(ApiException('Tailscale recusou essas credenciais.'));
      }
      return Ok(_catalog.first.connectedWith('sua conta Tailscale'));
    } catch (error) {
      return Failure(error);
    }
  }

  @override
  Future<Result<Integration>> disconnect(String integrationId) async {
    try {
      final response = await _http.delete(Uri.parse('$backendBaseUrl/integrations/$integrationId'), headers: _headers);
      if (response.statusCode != 200) return Failure(_errorFor(response));
      final entry = _catalog.firstWhere((i) => i.id == integrationId, orElse: () => _catalog.first);
      return Ok(entry.disconnected());
    } catch (error) {
      return Failure(error);
    }
  }

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
