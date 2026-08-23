# Flutter側のデバッグ手順

ホストアプリに組み込んだFlutterのコードを、ブレークポイントを張って追う手順。

導入手順そのものは `MIGRATION_GUIDE.md`、作業の記録は `WORK_LOG.md` にある。

---

## 0. 前提

| 項目 | 状態 |
|---|---|
| Android | 追加設定なしで `flutter attach` できる |
| iOS | Info.plist にローカルネットワーク権限が必要（設定済み） |

```xml
<key>NSBonjourServices</key>
<array>
  <string>_dartVmService._tcp</string>
</array>
<key>NSLocalNetworkUsageDescription</key>
<string>Allows Flutter debugging and hot reload</string>
```

無い場合は `flutter attach` が `Waiting for a connection` から進まない。

---

## 1. 方法を選ぶ

| 方法 | ブレークポイント | ネイティブ連携 | 主な用途 |
|---|---|---|---|
| **モジュール単体で `flutter run`** | 使える | **不可** | UI・ロジックの作り込み |
| **ホストアプリに `flutter attach`** | 使える | 可 | ネイティブ連携の確認 |
| **DevTools のデバッガ** | 使える | 可 | IDEを使わない場合 |

作り込みの大半は**モジュール単体**で足りる。ネイティブから値を受け取る箇所を
追うときだけ `flutter attach` を使う。

---

## 2. モジュール単体で動かす

```bash
cd legacyapp_flutter
flutter run -d <device-id>      # flutter devices で確認
```

モジュール付属のラッパーアプリ（`com.example.legacyapp_flutter.host`）が
起動する。ホストアプリとは別のアプリで、起動が速くデバッガも最初から繋がる。

**制約**: ネイティブ側のチャネルハンドラが存在しないため、チャネルを呼ぶと
例外になる。

```
MissingPluginException(No implementation found for method ... on channel ...)
```

チャネル越しの依存はインターフェース化し、単体実行時はfakeを差し込む。

**制約**: 初期ルートがネイティブから渡らないため `/`（ルート未指定）になる。

---

## 3. ホストアプリにアタッチする

ホストアプリを起動し、**Flutter画面を表示した状態で**アタッチする。

### Android

```bash
cd legacyapp_flutter
flutter attach -d emulator-5554
```

自動探索で接続できる。

### iOS

**自動探索が働かない。** 権限を入れていても
`Waiting for a connection from Flutter on ...` から進まない
（Xcode 26.6 / iOSシミュレータ / Flutter 3.47.1 で確認）。

VMサービスのURLをデバイスログから取得して直接渡す。

```bash
# 1. URLを調べる
xcrun simctl spawn <udid> log show --last 3m \
  --predicate 'processImagePath CONTAINS "LegacyApp"' --style compact \
  | grep "Dart VM service"
# flutter: The Dart VM service is listening on http://127.0.0.1:64556/A-PAwEJH-H0=/

# 2. そのURLを渡す
cd legacyapp_flutter
flutter attach -d <udid> --debug-url "http://127.0.0.1:64556/A-PAwEJH-H0=/"
```

URLはアプリを起動するたびに変わる。

### 接続できたときの出力

```
r Hot reload. 🔥🔥🔥
R Hot restart.
A Dart VM Service on ... is available at: http://127.0.0.1:60868/xKkFgCUHMhQ=/
The Flutter DevTools debugger and profiler ... http://127.0.0.1:60868/.../devtools/?uri=...
```

---

## 4. ブレークポイントを張る

### VS Code

1. **`legacyapp_flutter` をプロジェクトルートとして開く**
   （リポジトリ全体を開くとFlutterプロジェクトとして認識されない）
2. ホストアプリを起動し、Flutter画面を表示しておく
3. コマンドパレット → **Flutter: Attach to Flutter on Device**
4. ソースにブレークポイントを置く

### Android Studio / IntelliJ

1. `legacyapp_flutter` を開く
2. **Run ▸ Flutter Attach**

### DevTools（IDEを使わない場合）

`flutter attach` が出力するDevToolsのURLをブラウザで開き、**Debugger** タブで
ソースを開いてブレークポイントを張る。

### 止まらない場合

**その画面が既に構築済みだと `build` を通らない。** 一度戻ってから開き直す。

本構成はFlutter画面を開くたびに新しいエンジンを生成するため、開き直せば必ず
`build` が走る。

---

## 5. ホットリロード

接続後、`flutter attach` のコンソールで `r`（リロード）/ `R`（リスタート）。

対話操作なしで反映させる場合は `--pid-file` を使う。

```bash
flutter attach -d <device-id> --pid-file=/tmp/flutter.pid
kill -SIGUSR1 $(cat /tmp/flutter.pid)   # ホットリロード
kill -SIGUSR2 $(cat /tmp/flutter.pid)   # ホットリスタート
```

### 反映されない場合

**ルートの画面をインラインのクロージャで組んでいると、成功と表示されても画面が
更新されない。**

```dart
// 反映されない
builder: (_) => Scaffold(appBar: AppBar(...), body: ...)
// 反映される
builder: (_) => MyScreen()
```

画面はWidgetクラスとして切り出す。切り出せない場合はホットリスタートで確認する。

---

## 6. どの層の問題かを切り分ける

| 対象 | 使うもの |
|---|---|
| Dartのコード | `flutter attach` + IDE / DevTools |
| ネイティブのコード | Android Studio / Xcode のデバッガ |
| 境界（チャネル） | 両側にログ。チャネル名・メソッド名・引数の型のいずれかが食い違うと**無言で失敗する** |

チャネルの疎通が怪しいときは、Flutter側の画面に受け取った値をそのまま表示する
のが早い。UIを作り込む前でも検証できる。

```dart
FutureBuilder<Draft>(
  future: repository.load(),
  builder: (_, snap) => Text('${snap.data}'),
)
```

---

## 7. ビルドが端末に反映されているか怪しいとき

画面に出る一意な文字列を一時的に仕込んで確認する。バイナリ内のシンボルを
`strings` で探す方法は、Flutterフレームワーク側に同名のものがあると判定に
ならない。

**Android**: DebugビルドのAPKが大きく、上書きインストールが失敗することがある。

```
adb: failed to install ...: Failure [INSTALL_FAILED_INSUFFICIENT_STORAGE]
```

`adb uninstall` してから `adb install` する。`-r` を付けていると見落としやすい。

**iOS**: 同名アプリのDerivedDataが複数あると、古いビルドを掴むことがある。
更新時刻でソートして特定する。

```bash
ls -dt ~/Library/Developer/Xcode/DerivedData/LegacyApp-*/Build/Products/Debug-iphonesimulator/LegacyApp.app
```
