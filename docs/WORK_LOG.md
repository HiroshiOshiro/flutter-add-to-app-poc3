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

PR: (作成中)

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
