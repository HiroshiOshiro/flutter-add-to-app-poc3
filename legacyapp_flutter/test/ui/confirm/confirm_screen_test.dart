import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacyapp_flutter/data/repositories/confirm_repository.dart';
import 'package:legacyapp_flutter/domain/models/form_data.dart';
import 'package:legacyapp_flutter/ui/confirm/widgets/confirm_screen.dart';
import 'package:legacyapp_flutter/ui/core/l10n/generated/app_localizations.dart';
import 'package:legacyapp_flutter/ui/core/l10n/generated/app_localizations_en.dart';
import 'package:legacyapp_flutter/ui/core/l10n/generated/app_localizations_ja.dart';

Widget _host(ConfirmRepository repository, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ConfirmScreen(repository: repository),
  );
}

/// テストから期待値を引くための参照。画面と同じARBを見る。
final AppLocalizations _en = AppLocalizationsEn();
final AppLocalizations _ja = AppLocalizationsJa();

void main() {
  testWidgets('shows the values fetched from the repository', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FakeConfirmRepository(
          data: const FormDataModel(
            name: '山田太郎',
            email: 'yamada@example.com',
            message: 'よろしくお願いします',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('山田太郎'), findsOneWidget);
    expect(find.text('yamada@example.com'), findsOneWidget);
    expect(find.text('よろしくお願いします'), findsOneWidget);
    expect(find.text(_en.confirmTitle), findsOneWidget);
  });

  testWidgets('follows the locale, as the native screens do', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(FakeConfirmRepository(), locale: const Locale('ja')),
    );
    await tester.pumpAndSettle();

    expect(find.text(_ja.confirmTitle), findsOneWidget);
    expect(find.text(_ja.actionConfirm), findsOneWidget);
    expect(find.text(_en.confirmTitle), findsNothing);
  });

  testWidgets('shows a spinner until the data arrives', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(FakeConfirmRepository()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the confirm button submits the data', (
    WidgetTester tester,
  ) async {
    final FakeConfirmRepository repository = FakeConfirmRepository();
    await tester.pumpWidget(_host(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.actionConfirm));
    await tester.pumpAndSettle();

    expect(repository.submitted, hasLength(1));
  });

  testWidgets('a failed submission shows a message and keeps the screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(FakeConfirmRepository(submitResult: false)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.actionConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.submitFailed), findsOneWidget);
    expect(find.text(_en.confirmTitle), findsOneWidget);
  });
}
