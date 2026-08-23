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

PR: https://github.com/HiroshiOshiro/flutter-add-to-app-poc3/pull/4

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

当初「7節で対応する」として先送りしたが、**これは誤った判断だった**。
ガイドは4.4節、つまりiOS組み込みの一部として置いている。先送りした結果、
Androidはデバッグできるのに iOS だけできない状態を作ってしまった。
後から別PRで対応した（[PR #8](https://github.com/HiroshiOshiro/flutter-add-to-app-poc3/pull/8)、下記「補足: 4.4節の実施」）。

### ガイドへのフィードバック

なし。XcodeGen対応表はそのまま適用でき、修正は不要だった。

---

## 5節: Flutter画面を表示する

PR: https://github.com/HiroshiOshiro/flutter-add-to-app-poc3/pull/5

ガイド0.5節の方針により、この節で作るのは**プレースホルダ**。ルート名を表示
するだけで、UIの作り込みは7節の後に行う。

### エンジンの持ち方（5.1節）

**FlutterEngineGroup** を選択。全画面のFlutter化を前提とするため、画面数が
増えても成立する方式が必要。

### Dart側

```
lib/
  main.dart                             唯一のエントリポイント
  routing/routes.dart                   ルート名の定義
  routing/router.dart                   登録表とルート解決
  ui/placeholder/placeholder_screen.dart  プレースホルダ
```

表示する画面は `PlatformDispatcher.instance.defaultRouteName` で受け取る。
画面をFlutter化するときに触るのは `AppRoutes` と登録表の2箇所だけ。

**初期スタックの固定（5.4節）** は条件に該当するため、最初から
`onGenerateInitialRoutes` を入れた。入れないと `/confirm` が `['/', '/confirm']`
の2画面になり、戻る操作でネイティブに抜けられない。

**画面はWidgetクラスとして切り出した（7.2節）。** インラインのクロージャで
組むとホットリロードが効かないため。

### Android（5.2節）

```java
FlutterEngineGroup group = new FlutterEngineGroup(appContext);
FlutterEngine engine = group.createAndRunEngine(
        appContext, DartExecutor.DartEntrypoint.createDefault(), route);
FlutterEngineCache.getInstance().put(engineId, engine);
return FlutterActivity.withCachedEngine(engineId).build(context);
```

**テーマの条件（5.2節）**: `@style/LaunchTheme` は既存アプリに存在しないため、
ホストアプリ既存の `@style/AppTheme` を指定した。ガイドに条件として書いてあった
ため、`AAPT: error: resource style/LaunchTheme not found` は発生しなかった。

`MemoFragment` は `new Intent(context, ConfirmActivity.class)` をやめ、
`FlutterHost.intentFor(context, "/confirm")` を呼ぶだけになった。

### iOS（5.3節）

```swift
let engine = engineGroup.makeEngine(
    withEntrypoint: nil, libraryURI: nil, initialRoute: route)
GeneratedPluginRegistrant.register(with: engine)
return FlutterViewController(engine: engine, nibName: nil, bundle: nil)
```

**Objective-C相互運用（0.3節）**: Bridging Header と
`SWIFT_INSTALL_OBJC_HEADER` / `SWIFT_OBJC_INTERFACE_HEADER_NAME` を
**先に設定した**。ガイドに条件として書いてあったため、
`use of undeclared identifier FlutterHost` は発生しなかった。

`import Flutter` と `import FlutterPluginRegistrant` の2つが必要
（`import FlutterNativeIntegration` では `FlutterEngineGroup` が見つからない）。

### 確認

| OS | Flutter画面 | 戻る操作 |
|---|---|---|
| Android | `route: /confirm` を表示 | `MainActivity` に復帰 |
| iOS | `route: /confirm` を表示 | ナビゲーションバーの戻るで復帰 |

AppBarに余分な戻る矢印は出ていない（初期スタックが1画面である証拠）。

### 途中で起きたこと

`find ... -name "LegacyApp.app" | head -1` で古いDerivedDataのビルドを
インストールしようとして `Invalid parameter not satisfying: installURL` に
なった。同名アプリのDerivedDataが複数あるため、更新時刻でソートして特定した。

```
$ ls -dlt ~/Library/Developer/Xcode/DerivedData/LegacyApp-*/Build/Products/Debug-iphonesimulator/LegacyApp.app
```

### ガイドへのフィードバック

なし。5.2節のテーマ、5.4節の初期ルート、0.3節のBridging Header はいずれも
条件として明記されていたため、**エラーを踏む前に対処できた**。

---

## 補足: IDEからのビルド

PR: https://github.com/HiroshiOshiro/flutter-add-to-app-poc3/pull/6

CLIでのビルドしか確認していなかったため、Xcode / Android Studio から開いた
場合の前提を確認してREADMEに追加した。

**両OSともIDEからビルドできる。** ただしそれぞれ、バージョン管理対象外で
チェックアウト直後に存在しないものが1つずつある。

| IDE | 必要なもの | 無い場合 |
|---|---|---|
| Android Studio | `legacy_android/local.properties` | `SDK location not found` |
| Xcode | `legacyapp_flutter/build/ios/SwiftPackages/` | パッケージを解決できない |

`local.properties` はAndroid Studioがプロジェクトを開いたときに自動生成する
ため、IDEから始める場合は不要。CLIで作業していたため `ANDROID_HOME` 環境変数で
代用しており、この不足に気づいていなかった。

Xcode側は `flutter build swift-package --platform ios` の実行が必要。
Androidの `.android/` が `flutter pub get` で生成されるのとは異なり、
**明示的なコマンドが要る**（ガイド4.2-A節に条件として記載済み）。

開くのは `LegacyApp.xcodeproj`。SPM方式では `.xcworkspace` は生成されない。

---

## 補足: Xcodeだけ `Missing package product` になる

PR: https://github.com/HiroshiOshiro/flutter-add-to-app-poc3/pull/7

`flutter build swift-package --platform ios` を実行した後、Xcodeでビルドすると
次のエラーになった。

```
/Users/.../legacy_ios/LegacyApp.xcodeproj
Missing package product 'FlutterNativeIntegration'
```

### 切り分け

コマンドラインでは成功していた。パッケージ解決だけを単体で実行しても成功する。

```
$ xcodebuild -project LegacyApp.xcodeproj -scheme LegacyApp -resolvePackageDependencies
resolved source packages: FlutterFramework, FlutterNativeTools,
                          FlutterPluginRegistrant, FlutterNativeIntegration
```

**プロジェクト定義とパッケージの実体は正しく、Xcode側の状態が古いだけ**と
判断できた。`project.xcworkspace/xcuserdata/.../UserInterfaceState.xcuserstate`
が残っており、Xcodeでプロジェクトを開いたまま `xcodegen generate` で
`.pbxproj` を差し替えたことが原因。

### 対処

Xcodeを終了し、Xcode側の状態とDerivedDataを消してから開き直して解消した。

### ガイドへのフィードバック

**4.3節に不足があった。** 「プロジェクト再生成 → `pod install` → ビルド」の
順序は書いてあったが、**「再生成時にXcodeを閉じる」が書かれていなかった**。

SPM方式では `pod install` の工程が無いため、順序の記述だけでは今回の症状を
防げない。4.3節に条件2として追記し、症状一覧にも追加した。切り分けに使える
`-resolvePackageDependencies` も載せた。

---

## 補足: 4.4節の実施（先送りの訂正）

PR: https://github.com/HiroshiOshiro/flutter-add-to-app-poc3/pull/8

4節の作業時に「7節で対応する」として先送りしていたローカルネットワーク権限を
実施した。

### 先送りが誤りだった理由

- ガイドは4.4節、つまり**iOS組み込みの一部**として置いている
- 先送りした結果、5節・6節を進める間 **iOS だけデバッグできない**状態になる
- `project.yml` を触る作業なので、4節で他の設定と一緒に入れる方が
  `xcodegen generate` のやり直しが減る

「デバッグ関連だから7節」という表面的な分類で判断していた。

### XcodeGen では構成別に分けられなかった

ガイドは「Debug構成にだけ入れる。Release構成には `_dartVmService._tcp` を
含めない」としている。XcodeGenで2通り試した。

**試行1: `INFOPLIST_KEY_*` を構成別に指定** → 失敗。

```yaml
configs:
  Debug:
    INFOPLIST_KEY_NSBonjourServices: _dartVmService._tcp
    INFOPLIST_KEY_NSLocalNetworkUsageDescription: ...
```

ビルドは通るが、**どちらのキーも生成されたInfo.plistに入らなかった**。
`info: path: Generated-Info.plist` で明示的な `INFOPLIST_FILE` を使っている
ため、`INFOPLIST_KEY_*` による注入が効かない。配列型のキーが扱えない問題
以前に、文字列キーも反映されなかった。

**試行2: `info.properties` に追加** → 成功。ただし**全構成に入る**。

```
$ plutil -extract NSBonjourServices xml1 -o - .../LegacyApp.app/Info.plist
<array>
	<string>_dartVmService._tcp</string>
</array>
```

構成別に分けるには、XcodeGenによるInfo.plist生成をやめて構成ごとのplistを
手で管理する必要がある。PoCの範囲では全構成に入れる方を選んだ。

### iOSでの `flutter attach`

権限を追加しても**自動探索は成功しなかった**。

```
$ flutter attach -d <udid>
Waiting for a connection from Flutter on iPhone 16e...   （進まない）
```

ガイド7.1節の回避策で接続できた。

```
$ xcrun simctl spawn <udid> log show --last 3m \
    --predicate 'processImagePath CONTAINS "LegacyApp"' --style compact \
    | grep "Dart VM service"
flutter: The Dart VM service is listening on http://127.0.0.1:64556/A-PAwEJH-H0=/

$ flutter attach -d <udid> --debug-url "http://127.0.0.1:64556/A-PAwEJH-H0=/"
r Hot reload. 🔥🔥🔥
A Dart VM Service on iPhone 16e is available at: ...
```

Androidは自動探索で接続できる（追加設定なし）。

### ガイドへのフィードバック

**4.4節に不足あり。** 「Debug構成にだけ入れる」という指示は、Info.plistを
手で管理している前提になっている。**プロジェクト生成ツールがInfo.plistを
生成する構成では、構成別に分ける方法が自明でない。** 4.2-A節にXcodeGen対応表を
足したのと同じ扱いで、この制約を書き添えるべき。

### デバッグ手順を別資料に分離

`DEBUGGING.md` を作成した。ガイドは導入手順、こちらは日常的に参照する
デバッグ手順、という分担にした。
