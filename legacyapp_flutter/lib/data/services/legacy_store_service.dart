import '../../domain/models/form_data.dart';
import 'generated/legacy_store.g.dart';

/// 移行前のネイティブコードが保持しているデータを読むためのService。
///
/// チャネルの実体は `pigeons/legacy_store.dart` から生成する（手順6.5節）。
/// メソッド名の文字列と手書きのキャストが両側から消え、食い違いはコンパイル
/// エラーになる。
///
/// **生成クラスを直接使わず、この薄いServiceで包んでいる。** 移行完了時に
/// 消えるのはチャネルであってRepositoryではないため、生成された型が上層へ
/// 漏れないようにしている。ここが[FormDataDto]から[FormDataModel]への
/// 変換点になる。
///
/// ガイド6.2節の通り、このデータの**所有者はネイティブのまま**。Flutterは
/// 読むだけで、書き戻しはしない。
class LegacyStoreService {
  LegacyStoreService([LegacyStoreApi? api]) : _api = api ?? LegacyStoreApi();

  final LegacyStoreApi _api;

  /// 入力内容をまとめて取得する。
  Future<FormDataModel> readFormData() async {
    final FormDataDto dto = await _api.readFormData();
    return FormDataModel(
      name: dto.name,
      email: dto.email,
      message: dto.message,
    );
  }
}
