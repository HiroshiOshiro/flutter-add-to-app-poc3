# flutter-add-to-app-poc3

既存のネイティブアプリ（iOS: Objective-C / Android: Java）に、
`docs/MIGRATION_GUIDE.md` の手順どおりにFlutterを導入する。

先行リポジトリ
[flutter-add-to-app-poc](https://github.com/HiroshiOshiro/flutter-add-to-app-poc)
の **Flutter導入直前のコミット `580a513`** から分岐している。

## 方針

| 項目 | 選択 |
|---|---|
| Android の組み込み方式 | **source module** |
| iOS の組み込み方式 | **Swift Package Manager** |
| 最初にFlutter化する画面 | Todo（メモ）の**確認画面** |
| 設計の前提 | **最終的に全画面をFlutter化する**ことを見越した構成にする |

最後の項目が構成に影響する。画面を1つだけ移す場合と、全画面を移す前提で
1つ目を移す場合とでは、選ぶ構成が変わる。

- Dartのエントリポイントは `main()` ひとつに固定し、表示する画面は
  ネイティブから渡す初期ルートで決める
- 画面遷移の所有権はFlutterの `Navigator` に置き、ネイティブへの依頼は
  Flutterの領域から出るときだけに限定する
- プラットフォームチャネルは画面単位ではなく機能単位で切る
- テーマ・ロギング・通信などの共通基盤は最初からDart側に置く

## 構成

- `legacy_android/` — 移行前のAndroidアプリ（Java）
- `legacy_ios/` — 移行前のiOSアプリ（Objective-C）
- `docs/MIGRATION_GUIDE.md` — add-to-app の導入手順
- `legacyapp_flutter/` — Flutterモジュール
- `docs/WORK_LOG.md` — 作業ログ（各節の記録とPRリンク）

## 進捗

| ステップ（MIGRATION_GUIDE の節） | 状態 |
|---|---|
| 0. 事前確認 | 完了 |
| 2. Flutterモジュールを作る | 完了 |
| 3. Androidへ組み込む（source module） | 完了 |
| 4. iOSへ組み込む（SPM） | 完了 |
| 5. Flutter画面を表示する | 未着手 |
| 6. ネイティブとの通信 | 未着手 |
| 7. デバッグ | 未着手 |
