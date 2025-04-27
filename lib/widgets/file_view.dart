import 'package:flutter/material.dart';
import '../models/file_model.dart';
import '../theme/app_theme.dart';

enum ViewMode { grid, list }

class FileView extends StatefulWidget {
  final List<FileModel> files;
  final Function(FileModel) onFileTap;
  final Function(FileModel) onFileLongPress;
  final Function(FileModel) onFavoriteToggle;
  final Function(FileModel) onShare;
  final Function(FileModel) onDelete;
  final Function(FileModel) onRename;
  final Function(FileModel) onDownload;
  final Function(FileModel) onMove;
  final Function(FileModel) onCopy;
  final Function(FileModel) onKeepOffline;
  final Function(FileModel) onFreeSpace;

  const FileView({
    Key? key,
    required this.files,
    required this.onFileTap,
    required this.onFileLongPress,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.onDelete,
    required this.onRename,
    required this.onDownload,
    required this.onMove,
    required this.onCopy,
    required this.onKeepOffline,
    required this.onFreeSpace,
  }) : super(key: key);

  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView> {
  ViewMode _viewMode = ViewMode.grid;
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final sortedFiles = _sortFiles(widget.files);

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: _viewMode == ViewMode.grid
              ? _buildGridView(sortedFiles)
              : _buildListView(sortedFiles),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildViewToggle(),
          SizedBox(width: 20),
          _buildSortDropdown(),
          Spacer(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildToggleButton(
            icon: Icons.grid_view,
            isActive: _viewMode == ViewMode.grid,
            onTap: () => setState(() => _viewMode = ViewMode.grid),
          ),
          _buildToggleButton(
            icon: Icons.view_list,
            isActive: _viewMode == ViewMode.list,
            onTap: () => setState(() => _viewMode = ViewMode.list),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.accentColor : Color(0xFF64748B),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            'Ordenar por:',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
            ),
          ),
          SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            items: [
              DropdownMenuItem(value: 'name', child: Text('Nombre')),
              DropdownMenuItem(value: 'date', child: Text('Fecha')),
              DropdownMenuItem(value: 'size', child: Text('Tamaño')),
              DropdownMenuItem(value: 'type', child: Text('Tipo')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
              }
            },
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: AppTheme.textColor),
          ),
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: AppTheme.textColor,
              size: 20,
            ),
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.create_new_folder, size: 20),
          label: Text('Nueva carpeta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.upload_file, size: 20),
          label: Text('Subir archivo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGridView(List<FileModel> files) {
    return GridView.builder(
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildFileCard(file);
      },
    );
  }

  Widget _buildListView(List<FileModel> files) {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildFileListItem(file);
      },
    );
  }

  Widget _buildFileCard(FileModel file) {
    return Card(
      child: InkWell(
        onTap: () => widget.onFileTap(file),
        onLongPress: () => widget.onFileLongPress(file),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  file.icon,
                  size: 48,
                  color: file.color,
                ),
                if (file.isFavorite)
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(
                    file.syncStatusIcon,
                    color: file.syncStatusColor,
                    size: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              file.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              file.formattedSize,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            if (file.syncStatus == SyncStatus.syncing)
              LinearProgressIndicator(
                value: file.downloadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListItem(FileModel file) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(file.icon, color: file.color, size: 32),
          Positioned(
            bottom: 0,
            right: 0,
            child: Icon(
              file.syncStatusIcon,
              color: file.syncStatusColor,
              size: 16,
            ),
          ),
        ],
      ),
      title: Text(file.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${file.formattedSize} • ${file.formattedDate}'),
          if (file.syncStatus == SyncStatus.syncing)
            LinearProgressIndicator(
              value: file.downloadProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (file.isFavorite)
            IconButton(
              icon: Icon(Icons.star, color: Colors.amber),
              onPressed: () => widget.onFavoriteToggle(file),
            ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showFileOptions(file),
          ),
        ],
      ),
      onTap: () => widget.onFileTap(file),
      onLongPress: () => widget.onFileLongPress(file),
    );
  }

  void _showFileOptions(FileModel file) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Descargar'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDownload(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Compartir'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onShare(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.star),
                title: Text(file.isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onFavoriteToggle(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.drive_file_move),
                title: Text('Mover'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onMove(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.content_copy),
                title: Text('Copiar'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onCopy(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Renombrar'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onRename(file);
                },
              ),
              if (file.syncStatus == SyncStatus.synced)
                ListTile(
                  leading: Icon(Icons.cloud_off),
                  title: Text('Liberar espacio'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onFreeSpace(file);
                  },
                ),
              if (file.syncStatus == SyncStatus.onlineOnly)
                ListTile(
                  leading: Icon(Icons.cloud_download),
                  title: Text('Mantener disponible sin conexión'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onKeepOffline(file);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete(file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<FileModel> _sortFiles(List<FileModel> files) {
    List<FileModel> sorted = List.from(files);
    sorted.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'date':
          result = a.modifiedDate.compareTo(b.modifiedDate);
          break;
        case 'size':
          result = a.size.compareTo(b.size);
          break;
        case 'type':
          result = a.type.index.compareTo(b.type.index);
          break;
        default:
          result = 0;
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }
} 