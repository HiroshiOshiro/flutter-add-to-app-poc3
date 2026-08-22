import 'package:flutter/material.dart';

/// 組み込みの配線を確認するためのプレースホルダ。
///
/// ガイド0.5節の方針により、0〜7節はこの画面で進める。UIの作り込みは
/// ネイティブ側の作業が完了してから行う。
///
/// **ルート名をそのまま表示する**のが要点。ネイティブから初期ルートが正しく
/// 渡っているかを目視で確認できる。
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter (placeholder)')),
      body: Center(child: Text('route: $routeName')),
    );
  }
}
