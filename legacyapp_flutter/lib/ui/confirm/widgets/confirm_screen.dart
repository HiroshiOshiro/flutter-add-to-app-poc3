import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/navigation_service.dart';
import '../../../domain/models/form_data.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../view_models/confirm_view_model.dart';

/// Todo（メモ）の確認画面。
///
/// 移行前は `ConfirmActivity` / `ConfirmViewController` が担当していた画面。
/// 表示内容と操作は同じで、実装だけがFlutterへ移っている。
///
/// 依存はすべてProvider越しに受け取る。ネイティブに組み込まず単体で動かすときは
/// `overrides` でfakeに差し替える（`lib/main_dev.dart`）。
class ConfirmScreen extends ConsumerWidget {
  const ConfirmScreen({super.key});

  Future<void> _onConfirm(BuildContext context, WidgetRef ref) async {
    final bool success = await ref
        .read(submitControllerProvider.notifier)
        .submit();
    if (!context.mounted) {
      return;
    }
    if (success) {
      // 完了画面はまだネイティブのため、Flutterの領域から出る依頼をする。
      await ref.read(navigationServiceProvider).openNative('complete');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.submitFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FormDataModel> formData = ref.watch(formDataProvider);

    return Scaffold(
      // AppBarは置かない。ネイティブ側のコンテナ（ActionBar / NavigationBar）が
      // 既にタイトルと戻るを持っているため、置くと二重になる（手順8.3節）。
      body: SafeArea(
        child: formData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) {
            // ネイティブ側のチャネルハンドラが無い／メソッド名がずれている場合に
            // ここへ来る。握り潰すと白画面になるため明示する。
            debugPrint('formData failed: $error\n$stackTrace');
            return Center(
              child: Text(AppLocalizations.of(context)!.loadFailed),
            );
          },
          data: (FormDataModel data) => _content(context, ref, data),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, FormDataModel data) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isSubmitting = ref.watch(submitControllerProvider);

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
            onPressed: isSubmitting ? null : () => _onConfirm(context, ref),
            child: isSubmitting
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
