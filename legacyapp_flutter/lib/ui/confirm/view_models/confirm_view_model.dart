import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/confirm_repository.dart';
import '../../../domain/models/form_data.dart';

/// 確認画面が表示する入力内容。
///
/// 読み込み中・失敗・完了の3状態は [AsyncValue] が持つため、状態を表す enum を
/// 自前で用意しない。
///
/// **このProviderの寿命はFlutterエンジンの寿命と同じ。** ネイティブから
/// Flutter画面を開き直すと新しいエンジンが作られ、ここも作り直される
/// （手順5.1節）。画面をまたいで持ち越したい状態はここに置かない。
final FutureProvider<FormDataModel> formDataProvider =
    FutureProvider<FormDataModel>((Ref ref) {
      return ref.watch(confirmRepositoryProvider).load();
    });

/// 送信の実行と、その最中かどうか。
///
/// 状態として持つのは「送信中か」だけ。成否は [submit] の戻り値で返し、
/// 通知の表示と画面遷移はView側が決める。
class SubmitController extends Notifier<bool> {
  @override
  bool build() => false;

  /// 入力内容を送信する。成功したらtrue。
  ///
  /// 二重送信を防ぐため、実行中の呼び出しは無視する。
  Future<bool> submit() async {
    final FormDataModel? data = ref.read(formDataProvider).value;
    if (state || data == null) {
      return false;
    }
    state = true;

    bool success;
    try {
      success = await ref.read(confirmRepositoryProvider).submit(data);
    } catch (error, stackTrace) {
      debugPrint('submit failed: $error\n$stackTrace');
      success = false;
    }

    state = false;
    return success;
  }
}

final NotifierProvider<SubmitController, bool> submitControllerProvider =
    NotifierProvider<SubmitController, bool>(SubmitController.new);
