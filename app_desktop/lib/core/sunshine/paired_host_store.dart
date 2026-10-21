import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:path_provider/path_provider.dart';

/// Pareamento GameStream já concluído com um host — o certificado precisa
/// ficar fixado (pinned) pra sempre depois do primeiro pareamento, nunca
/// validado contra uma CA.
class PairedHostRecord {
  const PairedHostRecord({required this.host, required this.httpsPort, required this.serverCertDer});

  final String host;
  final int httpsPort;
  final Uint8List serverCertDer;

  Map<String, dynamic> _toJson() => {
        'host': host,
        'httpsPort': httpsPort,
        'serverCertDerHex': hex.encode(serverCertDer),
      };

  static PairedHostRecord _fromJson(Map<String, dynamic> json) => PairedHostRecord(
        host: json['host'] as String,
        httpsPort: json['httpsPort'] as int,
        serverCertDer: Uint8List.fromList(hex.decode(json['serverCertDerHex'] as String)),
      );
}

/// Persiste, por `deviceId`, o host e o certificado já pareados — pra não
/// precisar repetir o handshake de pareamento GameStream a cada sessão de
/// stream. Mesmo padrão de armazenamento do `SunshineIdentityStore` (um JSON
/// no diretório de dados do app).
class PairedHostStore {
  PairedHostStore({Directory? directory}) : _directoryOverride = directory;

  final Directory? _directoryOverride;
  Map<String, dynamic>? _cached;

  Future<PairedHostRecord?> load(String deviceId) async {
    final all = await _loadAll();
    final json = all[deviceId] as Map<String, dynamic>?;
    return json == null ? null : PairedHostRecord._fromJson(json);
  }

  Future<void> save(String deviceId, PairedHostRecord record) async {
    final all = await _loadAll();
    all[deviceId] = record._toJson();
    final file = await _storeFile();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(all));
  }

  Future<Map<String, dynamic>> _loadAll() async {
    final cached = _cached;
    if (cached != null) return cached;

    final file = await _storeFile();
    if (!await file.exists()) {
      return _cached = <String, dynamic>{};
    }
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return _cached = json;
  }

  Future<File> _storeFile() async {
    final directory = _directoryOverride ?? await getApplicationSupportDirectory();
    return File('${directory.path}/paired_hosts.json');
  }
}
