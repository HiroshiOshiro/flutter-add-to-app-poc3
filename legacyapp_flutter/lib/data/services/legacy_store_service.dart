import 'package:flutter/services.dart';

import '../../domain/models/form_data.dart';

/// 移行前のネイティブコードが保持しているデータを読むためのService。
///
/// ガイド6.1節に従い、画面単位ではなく**機能単位**でチャネルを切っている。
/// 画面が増えてもチャネルは増えず、データの所有がFlutterへ移るたびに減る。
///
/// ガイド6.2節の通り、このデータの**所有者はネイティブのまま**。Flutterは
/// 読むだけで、書き戻しはしない。
class LegacyStoreService {
  const LegacyStoreService([
    this._channel = const MethodChannel(channelName),
  ]);

  static const String channelName = 'com.example.legacyapp/legacy_store';

  final MethodChannel _channel;

  /// 入力内容をまとめて取得する。
  ///
  /// 項目ごとにメソッドを分けず**まとめて返す**形にしている。項目が増える
  /// たびにネイティブ側の変更が必要になるのを避けるため（ガイド0.5節）。
  Future<FormDataModel> readFormData() async {
    final Map<Object?, Object?>? raw =
        await _channel.invokeMethod<Map<Object?, Object?>>('readFormData');
    if (raw == null) {
      return const FormDataModel(name: '', email: '', message: '');
    }
    return FormDataModel.fromMap(
      raw.map((Object? k, Object? v) =>
          MapEntry<String, String>(k! as String, (v ?? '') as String)),
    );
  }
}
