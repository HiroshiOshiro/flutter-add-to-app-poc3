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
