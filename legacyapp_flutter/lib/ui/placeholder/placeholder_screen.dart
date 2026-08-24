import 'package:flutter/material.dart';

import '../../data/services/legacy_store_service.dart';
import '../../data/services/navigation_service.dart';
import '../../domain/models/form_data.dart';

/// 組み込みの配線を確認するための画面。
///
/// ガイド0.5節の方針により、0〜7節はこの画面で進めた。作り込み後は
/// **未登録のルートを開いたときの表示**として残している。ネイティブが渡す
/// ルート名と [AppRoutes] の定義がずれたときに、白画面ではなく原因が出る。
///
/// この画面が確認するのは3点。
///   1. ネイティブから初期ルートが渡っていること（ルート名の表示）
///   2. チャネル越しに値が渡ること（取得結果をそのまま表示）
///   3. ネイティブ画面へ抜けられること（ボタン）
class PlaceholderScreen extends StatefulWidget {
  PlaceholderScreen({
    super.key,
    required this.routeName,
    LegacyStoreService? legacyStore,
    this.navigation = const NavigationService(),
  }) : legacyStore = legacyStore ?? LegacyStoreService();

  final String routeName;
  final LegacyStoreService legacyStore;
  final NavigationService navigation;

  @override
  State<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends State<PlaceholderScreen> {
  late Future<FormDataModel> _formData;

  @override
  void initState() {
    super.initState();
    _formData = widget.legacyStore.readFormData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter (placeholder)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('route: ${widget.routeName}'),
            const SizedBox(height: 24),
            // 取得した値をそのまま表示する。UIを作り込む前に
            // チャネルの疎通を確認するため（ガイド0.5節）。
            FutureBuilder<FormDataModel>(
              future: _formData,
              builder: (_, AsyncSnapshot<FormDataModel> snapshot) {
                if (snapshot.hasError) {
                  return Text('legacy_store error: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Text('legacy_store: loading...');
                }
                return Text('legacy_store: ${snapshot.data}');
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => widget.navigation.openNative('complete'),
              child: const Text('openNative("complete")'),
            ),
          ],
        ),
      ),
    );
  }
}
