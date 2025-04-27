import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'widgets/file_view.dart';
import 'models/file_model.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OxiCloud Desktop',
      theme: AppTheme.lightTheme,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<FileModel> _files = [];
  String _currentPath = '/';
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await _apiService.getFiles(_currentPath);
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar archivos: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  title: _getTitle(),
                  onSearch: _handleSearch,
                  onLogout: _handleLogout,
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _getContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Mis archivos';
      case 1:
        return 'Compartidos';
      case 2:
        return 'Favoritos';
      case 3:
        return 'Recientes';
      case 4:
        return 'Papelera';
      default:
        return 'OxiCloud';
    }
  }

  Widget _getContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildFilesContent();
      case 1:
        return _buildSharedContent();
      case 2:
        return _buildFavoritesContent();
      case 3:
        return _buildRecentContent();
      case 4:
        return _buildTrashContent();
      default:
        return Center(child: Text('Contenido no disponible'));
    }
  }

  Widget _buildFilesContent() {
    return FileView(
      files: _files,
      onFileTap: _handleFileTap,
      onFileLongPress: _handleFileLongPress,
      onFavoriteToggle: _handleFavoriteToggle,
      onShare: _handleShare,
      onDelete: _handleDelete,
      onRename: _handleRename,
      onDownload: _handleDownload,
      onMove: _handleMove,
      onCopy: _handleCopy,
      onKeepOffline: _handleKeepOffline,
      onFreeSpace: _handleFreeSpace,
    );
  }

  Widget _buildSharedContent() {
    return Center(
      child: Text('Contenido de Compartidos'),
    );
  }

  Widget _buildFavoritesContent() {
    return Center(
      child: Text('Contenido de Favoritos'),
    );
  }

  Widget _buildRecentContent() {
    return Center(
      child: Text('Contenido de Recientes'),
    );
  }

  Widget _buildTrashContent() {
    return Center(
      child: Text('Contenido de Papelera'),
    );
  }

  void _handleSearch(String query) {
    // TODO: Implementar búsqueda
  }

  void _handleLogout() {
    // TODO: Implementar logout
  }

  Future<void> _handleKeepOffline(FileModel file) async {
    try {
      setState(() {
        _files = _files.map((f) {
          if (f.id == file.id) {
            return f.copyWith(syncStatus: SyncStatus.syncing);
          }
          return f;
        }).toList();
      });

      await _apiService.downloadFile(file);
      await _apiService.setSyncStatus(file.id, SyncStatus.synced);

      final localPath = await _apiService.getLocalPath(file.id);
      setState(() {
        _files = _files.map((f) {
          if (f.id == file.id) {
            return f.copyWith(
              syncStatus: SyncStatus.synced,
              localPath: localPath,
            );
          }
          return f;
        }).toList();
      });
    } catch (e) {
      setState(() {
        _files = _files.map((f) {
          if (f.id == file.id) {
            return f.copyWith(syncStatus: SyncStatus.error);
          }
          return f;
        }).toList();
      });
      _showError('Error al mantener archivo disponible sin conexión: $e');
    }
  }

  Future<void> _handleFreeSpace(FileModel file) async {
    try {
      await _apiService.removeLocalFile(file.id);
      await _apiService.setSyncStatus(file.id, SyncStatus.onlineOnly);

      setState(() {
        _files = _files.map((f) {
          if (f.id == file.id) {
            return f.copyWith(
              syncStatus: SyncStatus.onlineOnly,
              localPath: null,
            );
          }
          return f;
        }).toList();
      });
    } catch (e) {
      _showError('Error al liberar espacio: $e');
    }
  }

  Future<void> _handleFileTap(FileModel file) async {
    if (file.type == FileType.folder) {
      setState(() {
        _currentPath = file.path;
      });
      await _loadFiles();
    } else {
      if (file.syncStatus == SyncStatus.synced && file.localPath != null) {
        // TODO: Abrir archivo local
      } else if (file.syncStatus == SyncStatus.onlineOnly) {
        // Preguntar si desea descargar el archivo
        final shouldDownload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Archivo no disponible sin conexión'),
            content: Text('¿Desea descargar el archivo para verlo sin conexión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sí'),
              ),
            ],
          ),
        );

        if (shouldDownload == true) {
          await _handleKeepOffline(file);
        }
      }
    }
  }

  void _handleFileLongPress(FileModel file) {
    // TODO: Implementar selección múltiple
  }

  void _handleFavoriteToggle(FileModel file) async {
    try {
      await _apiService.toggleFavorite(file.id, !file.isFavorite);
      setState(() {
        _files = _files.map((f) {
          if (f.id == file.id) {
            return f.copyWith(isFavorite: !f.isFavorite);
          }
          return f;
        }).toList();
      });
    } catch (e) {
      _showError('Error al actualizar favorito: $e');
    }
  }

  void _handleShare(FileModel file) {
    // TODO: Implementar compartir
  }

  void _handleDelete(FileModel file) async {
    try {
      await _apiService.deleteFile(file.id);
      setState(() {
        _files.removeWhere((f) => f.id == file.id);
      });
    } catch (e) {
      _showError('Error al eliminar archivo: $e');
    }
  }

  void _handleRename(FileModel file) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: file.name);
        return AlertDialog(
          title: Text('Renombrar archivo'),
          content: TextField(
            controller: controller,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text('Renombrar'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        await _apiService.renameFile(file.id, newName);
        setState(() {
          _files = _files.map((f) {
            if (f.id == file.id) {
              return f.copyWith(name: newName);
            }
            return f;
          }).toList();
        });
      } catch (e) {
        _showError('Error al renombrar archivo: $e');
      }
    }
  }

  void _handleDownload(FileModel file) {
    // TODO: Implementar descarga
  }

  void _handleMove(FileModel file) async {
    // TODO: Implementar diálogo para seleccionar nueva ubicación
  }

  void _handleCopy(FileModel file) async {
    // TODO: Implementar diálogo para seleccionar ubicación de copia
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 