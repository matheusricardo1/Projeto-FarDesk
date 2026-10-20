import 'package:flutter/foundation.dart';

import '../../../core/result.dart';
import '../domain/account.dart';
import '../domain/auth_repository.dart';

/// Estado global de sessão — vive no topo da árvore porque login, sidebar
/// (avatar) e tela de conta dependem dele.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._repository) {
    _restoreSession();
  }

  final AuthRepository _repository;

  AccountSession? _session;
  AuthProvider? _pendingSignIn;
  bool _addingAccount = false;
  String? _pendingSwitchId;
  Object? _error;

  Future<void> _restoreSession() async {
    final result = await _repository.restoreSession();
    if (result case Ok(:final value)) {
      _session = value;
    } else if (result case Failure(:final error)) {
      _error = error;
    }
    notifyListeners();
  }

  bool get isSignedIn => _session != null;
  AccountSession? get session => _session;
  List<Account> get accounts => _session?.accounts ?? const [];
  Account? get activeAccount => _session?.activeAccount;
  int get activeIndex => _session?.activeIndex ?? 0;

  AuthProvider? get pendingSignIn => _pendingSignIn;
  bool get isAddingAccount => _addingAccount;
  String? get pendingSwitchId => _pendingSwitchId;
  Object? get error => _error;

  Future<void> signIn(AuthProvider provider) async {
    if (_pendingSignIn != null) return;
    _pendingSignIn = provider;
    _error = null;
    notifyListeners();

    _apply(await _repository.signIn(provider));
    _pendingSignIn = null;
    notifyListeners();
  }

  Future<void> addAccount() async {
    if (_addingAccount) return;
    _addingAccount = true;
    _error = null;
    notifyListeners();

    _apply(await _repository.addAccount(AuthProvider.google));
    _addingAccount = false;
    notifyListeners();
  }

  Future<void> switchAccount(String accountId) async {
    if (_pendingSwitchId != null || accountId == _session?.activeAccountId) return;
    _pendingSwitchId = accountId;
    _error = null;
    notifyListeners();

    _apply(await _repository.switchAccount(accountId));
    _pendingSwitchId = null;
    notifyListeners();
  }

  void _apply(Result<AccountSession> result) {
    switch (result) {
      case Ok(:final value):
        _session = value;
      case Failure(:final error):
        _error = error;
    }
  }
}
