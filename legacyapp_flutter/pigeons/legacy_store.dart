import 'package:pigeon/pigeon.dart';

/// `legacy_store` チャネルの定義。
///
/// このファイルからDart / Java / Swiftのコードを生成する。手で書いたチャネルと
/// 違い、**メソッド名と型の食い違いがコンパイルエラーになる**（手順7.3節）。
///
/// 生成先をモジュールの `.android/` `.ios/` にしてはいけない。あれは
/// `flutter pub get` のたびに再生成される足場のため、ホストアプリの
/// ソースツリーへ出す。
///
/// 生成コマンド:
/// ```bash
/// cd legacyapp_flutter
/// dart run pigeon --input pigeons/legacy_store.dart
/// dart format lib/data/services/generated
/// ```
///
/// Pigeonの出力は `dart format` の結果と一致しないため、生成後に整形する。
/// しないとCIの整形チェックが落ちる。
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/data/services/generated/legacy_store.g.dart',
    javaOut: '../legacy_android/app/src/main/java/com/example/legacyapp/flutter/LegacyStorePigeon.java',
    javaOptions: JavaOptions(
      package: 'com.example.legacyapp.flutter',
      className: 'LegacyStorePigeon',
    ),
    swiftOut: '../legacy_ios/LegacyApp/Sources/LegacyStorePigeon.swift',
    dartPackageName: 'legacyapp_flutter',
  ),
)
/// 確認画面が表示する入力内容。
///
/// 項目ごとにメソッドを分けず**まとめて返す**（手順6.1節）。項目が増えるたびに
/// ネイティブ側の変更が必要になるのを避けるため。
class FormDataDto {
  FormDataDto({required this.name, required this.email, required this.message});

  final String name;
  final String email;
  final String message;
}

/// 移行前のネイティブコードが保持しているデータを読む。
///
/// このデータの所有者はネイティブのままで、Flutterからは読むだけ
/// （手順6.2節）。移行が完了した時点でこのAPIごと消える。
@HostApi()
abstract class LegacyStoreApi {
  FormDataDto readFormData();
}
