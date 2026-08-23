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
- `docs/DEBUGGING.md` — Flutter側のデバッグ手順
- `docs/WORK_LOG.md` — 作業ログ（各節の記録とPRリンク）

## ビルドする

### 共通の準備

Flutterモジュールの依存を取得する。`legacyapp_flutter/.android/` と `.ios/` が
生成され、ホストアプリはそこを参照する。

```bash
cd legacyapp_flutter
flutter pub get
```

### Android Studio

`legacy_android` を開いてビルドする。

**`local.properties` にAndroid SDKの場所が必要。** 無いと
`SDK location not found` で失敗する。Android Studioでプロジェクトを開くと
自動生成されるが、コマンドラインだけで作業する場合は手で作る（絶対パスを含む
マシン固有の設定のため、リポジトリには含まれない）。

```bash
echo "sdk.dir=$HOME/Library/Android/sdk" > legacy_android/local.properties
```

コマンドラインの場合:

```bash
cd legacy_android
./gradlew assembleDebug
```

### Xcode

**先にSwiftパッケージを生成する。** 出力先 `legacyapp_flutter/build/` は
バージョン管理対象外のため、チェックアウト直後や `flutter clean` の後は
このコマンドが必要（ガイド4.2-A節）。Androidの `.android/` が
`flutter pub get` で生成されるのとは異なる。

```bash
cd legacyapp_flutter
flutter build swift-package --platform ios
```

そのうえで `LegacyApp.xcodeproj` を開く。**SPM方式では `.xcworkspace` は
生成されない**（CocoaPods方式との違い）。

```bash
open legacy_ios/LegacyApp.xcodeproj
```

`project.yml` や `LegacyApp/Sources` 配下を変更した場合は `xcodegen generate`
を実行してから開く。

コマンドラインの場合:

```bash
cd legacy_ios
xcodebuild -project LegacyApp.xcodeproj -scheme LegacyApp \
  -sdk iphonesimulator -configuration Debug \
  -destination "generic/platform=iOS Simulator" build
```

### Flutterモジュール単体

ホストアプリに組み込まずに画面を動かせる。チャネル越しの依存はfakeに
差し替わる。

```bash
cd legacyapp_flutter
flutter run -t lib/main_dev.dart -d <device-id>
```

```bash
cd legacyapp_flutter
flutter analyze && flutter test
```

## 進捗

| ステップ（MIGRATION_GUIDE の節） | 状態 |
|---|---|
| 0. 事前確認 | 完了 |
| 2. Flutterモジュールを作る | 完了 |
| 3. Androidへ組み込む（source module） | 完了 |
| 4. iOSへ組み込む（SPM） | 完了 |
| 5. Flutter画面を表示する | 完了（プレースホルダ） |
| 6. ネイティブとの通信 | 完了 |
| 7. デバッグ | 完了 |
| 8. 画面の作り込み | 完了（確認画面） |

確認画面のFlutter化が完了し、移行前と同じ動作になっている。次の画面（入力・完了）
へ進む場合、`AppRoutes` と `registeredScreens()` への追加が作業の起点になる。
