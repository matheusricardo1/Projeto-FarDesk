import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/update/app_update_service.dart';

enum UpdateCheckStatus { idle, checking, upToDate, available, downloading, readyToInstall, error }

/// Estado da tela "Atualizações" — separado do dialog automático de
/// `_AppRootState` (que dispara ao abrir o app). Aqui é a verificação sob
/// demanda, com progresso de download visível.
class UpdateViewModel extends ChangeNotifier {
  UpdateViewModel(this._service);

  final AppUpdateService _service;

  UpdateCheckStatus _status = UpdateCheckStatus.idle;
  AppUpdateInfo? _available;
  double? _progress;
  Object? _error;
  DateTime? _lastCheckedAt;

  String get currentVersion => _service.currentVersion;
  UpdateCheckStatus get status => _status;
  AppUpdateInfo? get available => _available;

  /// `null` = baixando sem saber o total (sem `Content-Length`).
  double? get progress => _progress;
  Object? get error => _error;
  DateTime? get lastCheckedAt => _lastCheckedAt;

  Future<void> checkNow() async {
    if (_status == UpdateCheckStatus.checking || _status == UpdateCheckStatus.downloading) return;
    _status = UpdateCheckStatus.checking;
    _error = null;
    notifyListeners();

    try {
      final update = await _service.checkForUpdate();
      _lastCheckedAt = DateTime.now();
      _available = update;
      _status = update == null ? UpdateCheckStatus.upToDate : UpdateCheckStatus.available;
    } catch (error) {
      _error = error;
      _status = UpdateCheckStatus.error;
    }
    notifyListeners();
  }

  Future<void> downloadAndInstall() async {
    final update = _available;
    if (update == null) return;

    _status = UpdateCheckStatus.downloading;
    _progress = 0;
    _error = null;
    notifyListeners();

    try {
      final installer = await _service.downloadInstaller(
        update,
        onProgress: (received, total) {
          _progress = total > 0 ? received / total : null;
          notifyListeners();
        },
      );
      _status = UpdateCheckStatus.readyToInstall;
      notifyListeners();

      await Process.start(installer.path, const [], mode: ProcessStartMode.detached);
      await windowManager.close();
    } on SocketException catch (error) {
      _fail(error);
    } on HttpException catch (error) {
      _fail(error);
    } on FileSystemException catch (error) {
      _fail(error);
    } on ProcessException catch (error) {
      _fail(error);
    }
  }

  void _fail(Object error) {
    _error = error;
    _status = UpdateCheckStatus.error;
    notifyListeners();
  }
}
