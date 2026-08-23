import 'package:flutter/material.dart';

import '../../../data/repositories/confirm_repository.dart';
import '../../../data/services/navigation_service.dart';
import '../../../domain/models/form_data.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../view_models/confirm_view_model.dart';

/// Todo（メモ）の確認画面。
///
/// 移行前は `ConfirmActivity` / `ConfirmViewController` が担当していた画面。
/// 表示内容と操作は同じで、実装だけがFlutterへ移っている。
///
/// 依存は外から差し込める。ネイティブに組み込まずモジュール単体で動かすときは
/// [FakeConfirmRepository] を渡す（`lib/main_dev.dart`）。
class ConfirmScreen extends StatefulWidget {
  ConfirmScreen({
    super.key,
    ConfirmRepository? repository,
    this.navigation = const NavigationService(),
  }) : repository = repository ?? DefaultConfirmRepository();

  final ConfirmRepository repository;

  /// まだFlutter化されていない完了画面へ抜けるために使う。完了画面も
  /// Flutter化した時点で、この依存は `Navigator` の呼び出しに置き換わる。
  final NavigationService navigation;

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  late final ConfirmViewModel _viewModel = ConfirmViewModel(widget.repository);

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    final bool success = await _viewModel.submit();
    if (!mounted) {
      return;
    }
    if (success) {
      await widget.navigation.openNative('complete');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.submitFailed)),
      );
      _viewModel.clearSubmitFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBarは置かない。ネイティブ側のコンテナ（ActionBar / NavigationBar）が
      // 既にタイトルと戻るを持っているため、置くと二重になる（ガイド5.3節）。
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (BuildContext context, _) => _body(context),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (_viewModel.status) {
      case ConfirmStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ConfirmStatus.loadFailed:
        return Center(child: Text(AppLocalizations.of(context)!.loadFailed));
      case ConfirmStatus.ready:
        return _content(context, _viewModel.formData!);
    }
  }

  Widget _content(BuildContext context, FormDataModel data) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.greeting,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: Image.asset(
              'assets/images/profile_banner.png',
              width: 96,
              height: 96,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.confirmTitle,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          _Field(label: l10n.labelName, valueKey: 'name'),
          Text(data.name, style: textTheme.bodyMedium),
          _Field(label: l10n.labelEmail, valueKey: 'email'),
          Text(data.email, style: textTheme.bodyMedium),
          _Field(label: l10n.labelMessage, valueKey: 'message'),
          Text(data.message, style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          FilledButton(
            // 送信中は押せなくする（移行前のネイティブ実装と同じ）。
            onPressed: _viewModel.isSubmitting ? null : _onConfirm,
            child: _viewModel.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
  }
}

/// 項目のラベル。
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.valueKey});

  final String label;

  /// テストから項目を特定するためのキー。
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key('label_$valueKey'),
      padding: const EdgeInsets.only(top: 16, bottom: 2),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
