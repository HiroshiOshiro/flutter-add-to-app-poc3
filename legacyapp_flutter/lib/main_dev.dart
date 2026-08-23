import 'package:flutter/material.dart';

import 'data/repositories/confirm_repository.dart';
import 'ui/confirm/widgets/confirm_screen.dart';
import 'ui/core/l10n/generated/app_localizations.dart';
import 'ui/core/themes/app_theme.dart';

/// モジュール単体で画面を作り込むためのエントリポイント。
///
/// ```bash
/// flutter run -t lib/main_dev.dart
/// ```
///
/// ネイティブに組み込まずに動かすため、チャネルを呼ぶ依存はfakeへ差し替える。
/// これが無いと `MissingPluginException` で画面が出ない（`DEBUGGING.md` 2節）。
///
/// **ネイティブ側の起動コードはこのファイルを参照しない。** ネイティブが呼ぶ
/// エントリポイントは `main.dart` の `main()` ひとつのままで、
/// `-t` は開発時のコマンドラインからのみ使う。
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: AppBar(title: const Text('confirm (dev)')),
        body: ConfirmScreen(repository: FakeConfirmRepository()),
      ),
    ),
  );
}
