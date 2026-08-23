// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get greeting => 'こんにちは!';

  @override
  String get confirmTitle => '入力内容の確認';

  @override
  String get labelName => '名前';

  @override
  String get labelEmail => 'メールアドレス';

  @override
  String get labelMessage => 'メッセージ';

  @override
  String get actionConfirm => '確定';

  @override
  String get submitFailed => '送信に失敗しました';

  @override
  String get loadFailed => '入力内容の取得に失敗しました';
}
