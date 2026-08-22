# 作業ログ

`MIGRATION_GUIDE.md` の手順に沿ってFlutterを導入した記録。

- 作業の塊ごとにブランチを切り、PRとしてマージする
- 各節の記録に対応するPRのリンクを載せる
- 手順に誤り・不足が見つかった場合はガイド本体を更新し、その内容もここに残す

## 方針

| 項目 | 選択 |
|---|---|
| Android の組み込み方式 | source module |
| iOS の組み込み方式 | Swift Package Manager |
| 最初にFlutter化する画面 | Todo（メモ）の確認画面 |
| API呼び出し | Flutter側で実装 |
| ローカルデータ操作 | MethodChannel（ネイティブが所有） |

作業順序はガイド0.5節に従い、**組み込みを先に終わらせ、画面の作り込みは最後**に
行う。

---

## 0節: 事前確認

PR: https://github.com/HiroshiOshiro/flutter-add-to-app-poc3/pull/1

### 設計上の制約の確認（0.1節）

| 制約 | 本プロジェクトの状況 |
|---|---|
| Flutterモジュールは1アプリに1つ | 問題なし。全画面を1モジュールに置く方針 |
| モバイルはマルチエンジンのみ | 問題なし |
| AndroidXが必須 | `android.useAndroidX=true` を確認 |
| 対応ABI | 独自ABI指定なし |
| プラグインの互換性 | 現時点でプラグイン未使用 |

### バージョン要件の確認（0.2節）

| 対象 | 要件 | 確認結果 | 判定 |
|---|---|---|---|
| Flutter SDK | 3.44 以上（SPM方式） | 3.47.1、`swift-package` あり | OK |
| Gradle | 8.14 以上 | **8.9** | **NG** |
| Android Gradle Plugin | 8.11.1 以上 | **8.7.0** | **NG** |
| Gradleを動かすJDK | 17 以上 | 21.0.10 | OK |
| AndroidX | 必須 | `true` | OK |
| Xcode | 15.0 以上 | 26.6 | OK |

```
$ flutter --version
Flutter 3.47.1 • channel [user-branch]

$ ./gradlew -version
Gradle 8.9
Launcher JVM:  21.0.10 (JetBrains s.r.o.)

$ grep "tools.build:gradle" build.gradle
        classpath 'com.android.tools.build:gradle:8.7.0'

$ xcodebuild -version
Xcode 26.6
```

### 要件を満たすための更新

Gradle と AGP が下限を下回っていたため更新した。

| 対象 | 変更前 | 変更後 |
|---|---|---|
| Gradle | 8.9 | 8.14.3 |
| Android Gradle Plugin | 8.7.0 | 8.11.1 |

**`compileOptions` は `VERSION_1_8` のまま変更していない。** ガイド0.2節の通り、
Java 17 の要件はGradleを動かすJDK（21.0.10）に対するもので、ホストアプリの
`compileOptions` とは別物。

### ベースラインの確認

Flutter組み込み前の状態で、両OSともビルドできることを確認した。組み込み後に
失敗したとき、原因が組み込みにあるのか元からなのかを切り分けるため。

```
$ (legacy_android) ./gradlew assembleDebug
BUILD SUCCESSFUL in 11s

$ (legacy_ios) xcodegen generate && xcodebuild ... build
** BUILD SUCCEEDED **
```

### ガイドへのフィードバック

なし。0.2節の表のとおりに確認でき、満たさない項目も表から特定できた。

---

## 2節: Flutterモジュールを作る

PR: https://github.com/HiroshiOshiro/flutter-add-to-app-poc3/pull/2

### 作成

```
$ flutter create -t module --org com.example legacyapp_flutter
All done!
Your module code is in legacyapp_flutter/lib/main.dart.
```

### モジュール名（2.2節）

ホストアプリ `legacyapp` に紐づけて `legacyapp_flutter` とした。

Todo（メモ）の確認画面が最初のFlutter化対象だが、**将来Flutter化するすべての
画面がこのモジュールに入る**ため、機能名を付けない。1アプリに1モジュールしか
組み込めないという制約から、機能名を付けると2画面目で実態と合わなくなる。

### androidPackage の確認（2.3節）

```
$ grep -A3 "^  module:" legacyapp_flutter/pubspec.yaml
  module:
    androidX: true
    androidPackage: com.example.legacyapp_flutter
    iosBundleIdentifier: com.example.legacyappFlutter

$ grep "applicationId" legacy_android/app/build.gradle
        applicationId "com.example.legacyapp"
```

`com.example.legacyapp_flutter` と `com.example.legacyapp` で異なるため
問題なし。ガイドの記述どおり、モジュール名から自動生成されるので作業は不要
だった。

### 生成物の除外（2.1節）

`.android/` と `.ios/` が生成された。`flutter pub get` のたびに再生成される
ため、gitignoreに追加した。

```gitignore
legacyapp_flutter/.android/
legacyapp_flutter/.ios/
legacyapp_flutter/build/
legacyapp_flutter/.dart_tool/
legacyapp_flutter/.flutter-plugins-dependencies
```

### 確認

```
$ (legacyapp_flutter) flutter analyze
No issues found!

$ (legacyapp_flutter) flutter test
All tests passed!
```

この時点ではテンプレートのカウンターアプリがそのまま入っている。5節で
プレースホルダに置き換える。

### ガイドへのフィードバック

なし。手順どおりに完了した。

---

## 3節: Androidへ組み込む（source module）

PR: https://github.com/HiroshiOshiro/flutter-add-to-app-poc3/pull/3

### 組み込み方式（3.2節）

**source module** を選択。Flutterを触る開発者が限られる段階ではなく、
このプロジェクトでは全員がFlutterを扱う前提のため。

### リポジトリ設定（3.1節）

**条件の確認**: `repositoriesMode` が `FAIL_ON_PROJECT_REPOS` だった。

```
$ grep -n "repositoriesMode" legacy_android/settings.gradle
9:    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
```

ガイドの条件に該当したため、**組み込む前に**対処した。

```groovy
dependencyResolutionManagement {
    repositoriesMode = RepositoriesMode.PREFER_SETTINGS
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}
```

ルートの `buildscript { repositories { ... } }` は残した。依存解決用の
リポジトリとは別物で、削除するとビルドツール自体が解決できなくなる。

### source module の取り込み（3.3-A節）

```groovy
// settings.gradle
include(":app")
setBinding(new Binding([gradle: this]))
def filePath = settingsDir.parentFile.toString() + "/legacyapp_flutter/.android/include_flutter.groovy"
apply from: filePath
```

```groovy
// app/build.gradle
implementation(project(":flutter"))
```

### 確認（3.5節）

```
$ ./gradlew assembleDebug
BUILD SUCCESSFUL

$ ./gradlew projects
+--- Project ':app'
\--- Project ':flutter'
```

`:flutter` サブプロジェクトが追加されたことを確認した。名前は固定で、
これが「1アプリに1モジュール」制約の実体になる。

### ABIを絞る（3.4節）

未設定のまま。ホストアプリに独自のABI指定が無く、必須ではないため。

### ガイドへのフィードバック

なし。0節でバージョン要件を先に満たしていたため、ビルド失敗は一度も
起きなかった。3.1節の条件も事前に検出でき、組み込む前に対処できた。

---

## 4節: iOSへ組み込む（Swift Package Manager）

PR: (作成中)

### 方式（4.1節）

**Swift Package Manager** を選択。CocoaPodsはメンテナンスモードで、
レジストリが2026年12月2日に読み取り専用になるため、新規導入で選ぶ理由がない。

前提の Flutter 3.44 以上は0節で確認済み（3.47.1）。

### パッケージの生成（4.2-A節）

```
$ cd legacyapp_flutter
$ flutter build swift-package --platform ios
Building for Debug/Profile/Release...
   ├─Copying Flutter.xcframework...
   ├─Building App.xcframework and native assets...
   ├─Generating swift packages...

$ ls build/ios/SwiftPackages/
FlutterNativeIntegration  Scripts

$ ls build/ios/SwiftPackages/Scripts/
FlutterAssembleInputs.xcfilelist  flutter_integration.sh
flutter_lldb_helper.py           flutter_lldbinit
```

**条件の確認**: 出力先が `build/` 配下でバージョン管理対象外。
チェックアウト直後とCIでは、Xcodeプロジェクトを開く前にこのコマンドを実行する
必要がある。READMEに記載する。

### XcodeGen への反映（4.2-A節）

**条件の確認**: 本プロジェクトはXcodeGenで `project.yml` からプロジェクトを
生成しているため、GUI操作は再生成のたびに失われる。ガイドの対応表に従って
定義ファイル側に書いた。

| 手順 | project.yml での記述 |
|---|---|
| 1. パッケージを追加 | `packages.FlutterNativeIntegration.path` |
| 2. Frameworks に追加 | `dependencies: - package: FlutterNativeIntegration` |
| 3. Build Settings | `settings.base` に `FLUTTER_SWIFT_PACKAGE_OUTPUT` ほか |
| 4. Scheme の Pre-action | `schemes.LegacyApp.build.preActions` |
| 5. Run Script + 入力リスト | `postCompileScripts`（`basedOnDependencyAnalysis: false`） |

**5手順すべてを表現できた。**

### 確認（4.5節）

```
$ xcodegen generate
Created project at .../LegacyApp.xcodeproj

$ xcodebuild -project LegacyApp.xcodeproj -scheme LegacyApp \
    -sdk iphonesimulator -configuration Debug \
    -destination "generic/platform=iOS Simulator" build
** BUILD SUCCEEDED **
```

SPM方式では `.xcworkspace` は生成されないため、`-project` でビルドする
（CocoaPods方式との違い）。

### ローカルネットワーク権限（4.4節）

7節（デバッグ）で `flutter attach` を試す段階で対応する。

### ガイドへのフィードバック

なし。XcodeGen対応表はそのまま適用でき、修正は不要だった。
