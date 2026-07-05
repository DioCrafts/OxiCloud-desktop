// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'OxiCloud';

  @override
  String get login => 'Accedi';

  @override
  String get register => 'Registrati';

  @override
  String get username => 'Nome utente';

  @override
  String get password => 'Password';

  @override
  String get email => 'Email';

  @override
  String get logout => 'Disconnetti';

  @override
  String get files => 'File';

  @override
  String get photos => 'Foto';

  @override
  String get favorites => 'Preferiti';

  @override
  String get recent => 'Recenti';

  @override
  String get trash => 'Cestino';

  @override
  String get shares => 'Condivisioni';

  @override
  String get settings => 'Impostazioni';

  @override
  String get search => 'Cerca';

  @override
  String get upload => 'Carica';

  @override
  String get download => 'Scarica';

  @override
  String get delete => 'Elimina';

  @override
  String get rename => 'Rinomina';

  @override
  String get move => 'Sposta';

  @override
  String get copy => 'Copia';

  @override
  String get createFolder => 'Crea cartella';

  @override
  String get emptyTrash => 'Svuota cestino';

  @override
  String get restore => 'Ripristina';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get error => 'Errore';

  @override
  String get retry => 'Riprova';

  @override
  String get offline => 'Offline';

  @override
  String get syncing => 'Sincronizzazione in corso…';

  @override
  String get syncComplete => 'Sincronizzazione completata';

  @override
  String get noFiles => 'Nessun file qui';

  @override
  String storageUsed(String used, String total) {
    return '$used di $total utilizzati';
  }

  @override
  String uploadProgress(String name, int percent) {
    return 'Caricamento di $name in corso… $percent%';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi',
      one: '1 elemento',
      zero: 'Nessun elemento',
    );
    return '$_temp0';
  }

  @override
  String get serverUrl => 'URL del server';

  @override
  String get connectToServer => 'Connetti al server';

  @override
  String get welcomeTitle => 'Benvenuto su OxiCloud';

  @override
  String get welcomeSubtitle => 'Il tuo cloud self-hosted';
}
