import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/form_data.dart';
import '../services/api_client.dart';
import '../services/legacy_store_service.dart';

/// 確認画面が必要とするデータの単一の情報源。
///
/// ViewModelはこのインターフェースにだけ依存する。モジュール単体で動かすときは
/// [FakeConfirmRepository] に差し替える（ガイド0.5節）。
abstract class ConfirmRepository {
  /// 確認対象の入力内容を取得する。
  Future<FormDataModel> load();

  /// 入力内容を送信する。成功したらtrue。
  Future<bool> submit(FormDataModel data);
}

/// 本番の実装。
///
/// 取得はネイティブから（所有者がネイティブのため）、送信はFlutterから直接
/// 行う、という方針の分かれ目がここに現れる。
class DefaultConfirmRepository implements ConfirmRepository {
  DefaultConfirmRepository({
    LegacyStoreService? legacyStore,
    ApiClient? apiClient,
  })  : _legacyStore = legacyStore ?? LegacyStoreService(),
        _apiClient = apiClient ?? ApiClient();

  static final Uri _submitUri =
      Uri.parse('https://jsonplaceholder.typicode.com/posts');

  final LegacyStoreService _legacyStore;
  final ApiClient _apiClient;

  @override
  Future<FormDataModel> load() => _legacyStore.readFormData();

  @override
  Future<bool> submit(FormDataModel data) =>
      _apiClient.postJson(_submitUri, data.toMap());
}

/// モジュール単体での実行とテスト用。
///
/// チャネルを呼ばないため、ネイティブ側のハンドラが無い環境でも動く。
class FakeConfirmRepository implements ConfirmRepository {
  FakeConfirmRepository({
    this.data = const FormDataModel(
      name: 'Taro',
      email: 'taro@example.com',
      message: 'Hello',
    ),
    this.submitResult = true,
  });

  final FormDataModel data;
  final bool submitResult;
  final List<FormDataModel> submitted = <FormDataModel>[];

  @override
  Future<FormDataModel> load() async => data;

  @override
  Future<bool> submit(FormDataModel value) async {
    submitted.add(value);
    return submitResult;
  }
}

/// 確認画面が使うRepository。
///
/// **差し替え点はここ一箇所。** モジュール単体での実行（`main_dev.dart`）と
/// テストは `overrides` で [FakeConfirmRepository] に置き換える。
final confirmRepositoryProvider = Provider<ConfirmRepository>(
  (Ref ref) => DefaultConfirmRepository(),
);
