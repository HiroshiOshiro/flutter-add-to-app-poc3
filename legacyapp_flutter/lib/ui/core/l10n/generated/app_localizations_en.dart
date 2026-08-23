// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get greeting => 'Hello!';

  @override
  String get confirmTitle => 'Confirm your details';

  @override
  String get labelName => 'Name';

  @override
  String get labelEmail => 'Email';

  @override
  String get labelMessage => 'Message';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get submitFailed => 'Failed to submit';

  @override
  String get loadFailed => 'Failed to load your details';
}
