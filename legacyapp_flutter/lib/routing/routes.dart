/// Flutter側が担当する画面のルート名。
///
/// ネイティブはFlutterを起動するときにこの文字列を初期ルートとして渡す。
/// 画面をFlutter化するたびにここへ1行足す。
class AppRoutes {
  const AppRoutes._();

  static const String root = '/';

  /// Todo（メモ）の確認画面。
  static const String confirm = '/confirm';
}
