// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OxiCloud';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Register';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get email => 'Email';

  @override
  String get logout => 'Log out';

  @override
  String get files => 'Files';

  @override
  String get photos => 'Photos';

  @override
  String get favorites => 'Favorites';

  @override
  String get recent => 'Recent';

  @override
  String get trash => 'Trash';

  @override
  String get shares => 'Shares';

  @override
  String get settings => 'Settings';

  @override
  String get search => 'Search';

  @override
  String get upload => 'Upload';

  @override
  String get download => 'Download';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get move => 'Move';

  @override
  String get copy => 'Copy';

  @override
  String get createFolder => 'Create folder';

  @override
  String get emptyTrash => 'Empty trash';

  @override
  String get restore => 'Restore';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get offline => 'Offline';

  @override
  String get syncing => 'Syncing…';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get noFiles => 'No files here';

  @override
  String storageUsed(String used, String total) {
    return '$used of $total used';
  }

  @override
  String uploadProgress(String name, int percent) {
    return 'Uploading $name… $percent%';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get serverUrl => 'Server URL';

  @override
  String get connectToServer => 'Connect to server';

  @override
  String get welcomeTitle => 'Welcome to OxiCloud';

  @override
  String get welcomeSubtitle => 'Your self-hosted cloud';
}
