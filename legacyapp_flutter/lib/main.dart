import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'routing/router.dart';
import 'ui/core/l10n/generated/app_localizations.dart';
import 'ui/core/themes/app_theme.dart';

/// アプリ唯一のDartエントリポイント。
///
/// 画面ごとにエントリポイントを増やすと、画面を追加するたびにネイティブ側の
/// 起動コードも増える。全画面のFlutter化を前提にするため、エントリポイントは
/// ひとつに固定し、**表示する画面はネイティブから渡される初期ルートで決める**。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MainApp(
      initialRoute: PlatformDispatcher.instance.defaultRouteName,
      router: AppRouter(registeredScreens()),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({
    super.key,
    required this.initialRoute,
    required this.router,
  });

  /// ネイティブから渡された初期ルート。
  final String initialRoute;

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // 表示言語はホストアプリと同じくOSの設定に従う。ネイティブの
      // strings.xml / Localizable.strings はFlutterからは参照できないため、
      // 文言はFlutter側のARBに持ち直している。
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: initialRoute,
      // ガイド5.4節: 初期スタックを1画面に固定する
      onGenerateInitialRoutes: router.onGenerateInitialRoutes,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
