import 'package:flutter/material.dart';

import '../ui/placeholder/placeholder_screen.dart';
import 'routes.dart';

/// Flutter化済みの画面の登録表。
///
/// 画面をFlutter化するときに触るのは、[AppRoutes] へのルート名追加とこの表への
/// 1行追加だけ。ネイティブ側には画面ごとの起動コードを足さない。
Map<String, WidgetBuilder> registeredScreens() {
  return <String, WidgetBuilder>{
    // 5節の時点ではプレースホルダ。作り込みで実画面に差し替える。
    AppRoutes.confirm: (_) =>
        const PlaceholderScreen(routeName: AppRoutes.confirm),
  };
}

/// ルート名から画面を解決する。
class AppRouter {
  const AppRouter(this.screens);

  final Map<String, WidgetBuilder> screens;

  /// 初期ルートを「1画面だけのスタック」として構成する（ガイド5.4節）。
  ///
  /// [MaterialApp] の既定実装は `initialRoute` を `/` で分割して複数の画面を
  /// 積むため、`/confirm` を渡すと2画面になる。add-to-appでは画面スタックの底で
  /// 戻ったらネイティブ側のコンテナに抜けるのが正しい。
  List<Route<Object?>> onGenerateInitialRoutes(String initialRoute) {
    return <Route<Object?>>[
      onGenerateRoute(RouteSettings(name: initialRoute)),
    ];
  }

  Route<Object?> onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder? builder = screens[settings.name];
    if (builder != null) {
      return MaterialPageRoute<Object?>(builder: builder, settings: settings);
    }
    // ネイティブ側のルート名とAppRoutesの定義がずれたときに白画面にならないよう
    // 明示的に表示する。
    return MaterialPageRoute<Object?>(
      settings: settings,
      builder: (_) =>
          PlaceholderScreen(routeName: settings.name ?? AppRoutes.root),
    );
  }
}
