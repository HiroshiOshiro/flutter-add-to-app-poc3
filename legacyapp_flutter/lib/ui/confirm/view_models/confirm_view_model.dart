import 'package:flutter/foundation.dart';

import '../../../data/repositories/confirm_repository.dart';
import '../../../domain/models/form_data.dart';

/// 確認画面の状態。
enum ConfirmStatus {
  /// 入力内容を取得している。
  loading,

  /// 表示できる。
  ready,

  /// 取得に失敗した。
  loadFailed,
}

/// 確認画面のViewModel。
///
/// Viewが持つのは表示と入力だけで、状態と手続きはここに置く。Widgetを
/// 差し替えてもロジックが影響を受けないようにするため。
///
/// 画面遷移はここでは行わない。遷移はViewの責務とし、ViewModelは
/// **送信が成功したかどうか**だけを返す。
class ConfirmViewModel extends ChangeNotifier {
  ConfirmViewModel(this._repository);

  final ConfirmRepository _repository;

  ConfirmStatus _status = ConfirmStatus.loading;
  ConfirmStatus get status => _status;

  FormDataModel? _formData;
  FormDataModel? get formData => _formData;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// 送信に失敗した直後だけtrue。Viewが通知を出したら [clearSubmitFailure] で戻す。
  bool _submitFailed = false;
  bool get submitFailed => _submitFailed;

  /// 入力内容を取得する。
  Future<void> load() async {
    _status = ConfirmStatus.loading;
    notifyListeners();
    try {
      _formData = await _repository.load();
      _status = ConfirmStatus.ready;
    } catch (error, stackTrace) {
      // ネイティブ側のチャネルハンドラが無い／メソッド名がずれている場合に
      // ここへ来る。握り潰すと白画面になるため状態として持つ。
      debugPrint('ConfirmViewModel.load failed: $error\n$stackTrace');
      _status = ConfirmStatus.loadFailed;
    }
    notifyListeners();
  }

  /// 入力内容を送信する。成功したらtrue。
  ///
  /// 二重送信を防ぐため、実行中の呼び出しは無視する。
  Future<bool> submit() async {
    final FormDataModel? data = _formData;
    if (_isSubmitting || data == null) {
      return false;
    }
    _isSubmitting = true;
    _submitFailed = false;
    notifyListeners();

    bool success;
    try {
      success = await _repository.submit(data);
    } catch (error, stackTrace) {
      debugPrint('ConfirmViewModel.submit failed: $error\n$stackTrace');
      success = false;
    }

    _isSubmitting = false;
    _submitFailed = !success;
    notifyListeners();
    return success;
  }

  void clearSubmitFailure() {
    if (!_submitFailed) {
      return;
    }
    _submitFailed = false;
    notifyListeners();
  }
}
