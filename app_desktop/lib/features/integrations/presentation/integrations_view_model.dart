import 'package:flutter/foundation.dart';

import '../../../core/result.dart';
import '../domain/integration.dart';
import '../domain/integration_repository.dart';

class IntegrationsViewModel extends ChangeNotifier {
  IntegrationsViewModel(this._repository);

  final IntegrationRepository _repository;

  List<Integration> _integrations = const [];
  bool _loading = false;
  Object? _loadError;
  Object? _actionError;
  final Set<String> _pending = {};

  bool get isLoading => _loading;
  bool get hasIntegrations => _integrations.isNotEmpty;
  Object? get loadError => _loadError;
  Object? get actionError => _actionError;

  List<Integration> get all => _integrations;
  List<Integration> byCategory(IntegrationCategory category) =>
      _integrations.where((i) => i.category == category).toList(growable: false);

  /// Integrações obrigatórias ainda não conectadas — hoje só o Tailscale,
  /// sem ele não dá pra conectar em outro PC nem acessar este pelo celular.
  List<Integration> get missingRequired => _integrations.where((i) => i.required && !i.isConnected).toList(growable: false);

  bool isPending(String integrationId) => _pending.contains(integrationId);

  /// Se a integração com esse id está conectada — usada pelo fluxo de
  /// conexão em dispositivos pra saber se Steam/Hydra entram como opção de
  /// destino do stream.
  bool isIntegrationConnected(String id) => _integrations.any((i) => i.id == id && i.isConnected);

  Future<void> load() async {
    _loading = true;
    _loadError = null;
    notifyListeners();

    switch (await _repository.fetchIntegrations()) {
      case Ok(:final value):
        _integrations = value;
      case Failure(:final error):
        _loadError = error;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> connect(Integration integration) => _runAction(integration.id, () => _repository.connect(integration.id));

  Future<void> connectTailscale(Integration integration, {required String clientId, required String clientSecret}) =>
      _runAction(integration.id, () => _repository.connectTailscale(clientId: clientId, clientSecret: clientSecret));

  Future<void> disconnect(Integration integration) =>
      _runAction(integration.id, () => _repository.disconnect(integration.id));

  Future<void> _runAction(String id, Future<Result<Integration>> Function() action) async {
    if (_pending.contains(id)) return;
    _pending.add(id);
    _actionError = null;
    notifyListeners();

    switch (await action()) {
      case Ok(:final value):
        _integrations = [for (final i in _integrations) i.id == value.id ? value : i];
      case Failure(:final error):
        _actionError = error;
    }

    _pending.remove(id);
    notifyListeners();
  }
}
