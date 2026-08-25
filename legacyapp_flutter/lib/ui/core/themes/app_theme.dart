import 'package:flutter/material.dart';

/// アプリ全体のテーマ。
///
/// 画面ごとに色やサイズを書かず、最初からここに集約する。全画面をFlutter化した
/// 時点で、これがアプリの見た目の単一の定義になる。
class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
  );
}
