import 'package:flutter/material.dart';

import '../../../core/result.dart';
import '../domain/integration.dart';
import '../domain/integration_repository.dart';

/// Implementação em memória pra desenvolver a UI sem backend. Começa com
/// tudo desconectado, pra demonstrar o estado "Tailscale obrigatório"
/// logo de cara.
class MockIntegrationRepository implements IntegrationRepository {
  MockIntegrationRepository({this.latency = const Duration(milliseconds: 900)});

  final Duration latency;

  final List<Integration> _integrations = [
    const Integration(
      id: 'tailscale',
      name: 'Tailscale',
      description: 'Rede privada que conecta seus dispositivos sem configurar porta ou IP manualmente. '
          'Entra com a mesma conta Google do FarDesk.',
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

  @override
  Future<Result<List<Integration>>> fetchIntegrations() async {
    await Future<void>.delayed(latency);
    return Ok(List.unmodifiable(_integrations));
  }

  @override
  Future<Result<Integration>> connect(String integrationId) async {
    await Future<void>.delayed(latency);
    return _update(integrationId, (i) => i.connectedWith(_mockAccountFor(integrationId)));
  }

  @override
  Future<Result<Integration>> connectTailscale({required String clientId, required String clientSecret}) async {
    await Future<void>.delayed(latency);
    return _update('tailscale', (i) => i.connectedWith(_mockAccountFor('tailscale')));
  }

  @override
  Future<Result<Integration>> disconnect(String integrationId) async {
    await Future<void>.delayed(latency ~/ 2);
    return _update(integrationId, (i) => i.disconnected());
  }

  Result<Integration> _update(String id, Integration Function(Integration) transform) {
    final index = _integrations.indexWhere((i) => i.id == id);
    if (index < 0) return Failure(StateError('Integração não encontrada: $id'));
    final updated = transform(_integrations[index]);
    _integrations[index] = updated;
    return Ok(updated);
  }

  String _mockAccountFor(String id) => switch (id) {
        'tailscale' => 'matheusricardo164@gmail.com',
        'steam' => 'matheus_player',
        'hydra' => 'matheus#hydra',
        _ => 'conectado',
      };
}
