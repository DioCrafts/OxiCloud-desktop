// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'OxiCloud';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get username => 'Usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get email => 'Correo electrónico';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get files => 'Archivos';

  @override
  String get photos => 'Fotos';

  @override
  String get favorites => 'Favoritos';

  @override
  String get recent => 'Recientes';

  @override
  String get trash => 'Papelera';

  @override
  String get shares => 'Compartidos';

  @override
  String get settings => 'Ajustes';

  @override
  String get search => 'Buscar';

  @override
  String get upload => 'Subir';

  @override
  String get download => 'Descargar';

  @override
  String get delete => 'Eliminar';

  @override
  String get rename => 'Renombrar';

  @override
  String get move => 'Mover';

  @override
  String get copy => 'Copiar';

  @override
  String get createFolder => 'Crear carpeta';

  @override
  String get emptyTrash => 'Vaciar papelera';

  @override
  String get restore => 'Restaurar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Reintentar';

  @override
  String get offline => 'Sin conexión';

  @override
  String get syncing => 'Sincronizando…';

  @override
  String get syncComplete => 'Sincronización completa';

  @override
  String get noFiles => 'No hay archivos aquí';

  @override
  String storageUsed(String used, String total) {
    return '$used de $total usado';
  }

  @override
  String uploadProgress(String name, int percent) {
    return 'Subiendo $name… $percent%';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
      zero: 'Sin elementos',
    );
    return '$_temp0';
  }

  @override
  String get serverUrl => 'URL del servidor';

  @override
  String get connectToServer => 'Conectar al servidor';

  @override
  String get welcomeTitle => 'Bienvenido a OxiCloud';

  @override
  String get welcomeSubtitle => 'Tu nube privada';
}
