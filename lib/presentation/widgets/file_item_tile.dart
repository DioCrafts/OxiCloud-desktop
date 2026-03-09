import 'package:flutter/material.dart';

import '../../core/entities/file_item.dart';
import '../theme/oxicloud_colors.dart';

// =============================================================================
// Folder tile (used in list mode)
// =============================================================================

class FolderTile extends StatelessWidget {
  const FolderTile({
    super.key,
    required this.folder,
    required this.onTap,
    this.onRename,
    this.onDelete,
    this.onFavoriteToggle,
    this.onDownloadZip,
    this.isFavorite = false,
    this.isSelected = false,
    this.onLongPress,
  });

  final FolderItem folder;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDownloadZip;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: OxiColors.primary.withValues(alpha: 0.08),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: OxiColors.navFilesInactive.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.folder_rounded,
              color: OxiColors.navFilesInactive,
              size: 24,
            ),
            if (isFavorite)
              const Positioned(
                right: 2,
                top: 2,
                child: Icon(Icons.star, color: Colors.amber, size: 12),
              ),
          ],
        ),
      ),
      title: Text(
        folder.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        _formatDate(folder.modifiedAt),
        style: const TextStyle(fontSize: 12, color: OxiColors.textSecondary),
      ),
      trailing: _ContextMenuButton(
        onRename: onRename,
        onDelete: onDelete,
        onFavoriteToggle: onFavoriteToggle,
        onDownloadZip: onDownloadZip,
        isFavorite: isFavorite,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

// =============================================================================
// File tile (used in list mode)
// =============================================================================

class FileTile extends StatelessWidget {
  const FileTile({
    super.key,
    required this.file,
    this.onTap,
    this.onRename,
    this.onDelete,
    this.onDownload,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.isSelected = false,
    this.onLongPress,
    this.thumbnailUrl,
  });

  final FileItem file;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final fileType = file.fileType;
    final color = FileTypeHelper.color(fileType);
    final icon = FileTypeHelper.icon(fileType);

    return ListTile(
      selected: isSelected,
      selectedTileColor: OxiColors.primary.withValues(alpha: 0.08),
      leading: _buildLeading(fileType, color, icon),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
      ),
      subtitle: Text(
        '${file.formattedSize} · ${_formatDate(file.modifiedAt)}',
        style: const TextStyle(fontSize: 12, color: OxiColors.textSecondary),
      ),
      trailing: _ContextMenuButton(
        onRename: onRename,
        onDelete: onDelete,
        onDownload: onDownload,
        onFavoriteToggle: onFavoriteToggle,
        isFavorite: isFavorite,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildLeading(FileType fileType, Color color, IconData icon) {
    // Show thumbnail for images if URL is available
    if (thumbnailUrl != null && fileType == FileType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          thumbnailUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildIconContainer(color, icon),
        ),
      );
    }
    return _buildIconContainer(color, icon);
  }

  Widget _buildIconContainer(Color color, IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          if (isFavorite)
            const Positioned(
              right: 2,
              top: 2,
              child: Icon(Icons.star, color: Colors.amber, size: 12),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Grid card for folders
// =============================================================================

class FolderGridCard extends StatelessWidget {
  const FolderGridCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onRename,
    this.onDelete,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.isSelected = false,
    this.onLongPress,
  });

  final FolderItem folder;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? OxiColors.primary : OxiColors.border,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      color: isSelected ? OxiColors.primary.withValues(alpha: 0.05) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  const Icon(
                    Icons.folder_rounded,
                    color: OxiColors.navFilesInactive,
                    size: 40,
                  ),
                  if (isFavorite)
                    const Positioned(
                      right: -4,
                      top: -4,
                      child: Icon(Icons.star, color: Colors.amber, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                folder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(folder.modifiedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: OxiColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Grid card for files
// =============================================================================

class FileGridCard extends StatelessWidget {
  const FileGridCard({
    super.key,
    required this.file,
    this.onTap,
    this.onRename,
    this.onDelete,
    this.onDownload,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.isSelected = false,
    this.onLongPress,
    this.thumbnailUrl,
  });

  final FileItem file;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final fileType = file.fileType;
    final color = FileTypeHelper.color(fileType);
    final icon = FileTypeHelper.icon(fileType);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? OxiColors.primary : OxiColors.border,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      color: isSelected ? OxiColors.primary.withValues(alpha: 0.05) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(fileType, color, icon),
              const SizedBox(height: 8),
              Text(
                file.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                file.formattedSize,
                style: const TextStyle(
                  fontSize: 11,
                  color: OxiColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(FileType fileType, Color color, IconData icon) {
    if (thumbnailUrl != null && fileType == FileType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          thumbnailUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(icon, color: color, size: 36),
        ),
      );
    }

    return Stack(
      children: [
        Icon(icon, color: color, size: 36),
        if (isFavorite)
          const Positioned(
            right: -4,
            top: -4,
            child: Icon(Icons.star, color: Colors.amber, size: 14),
          ),
      ],
    );
  }
}

// =============================================================================
// Upload progress overlay widget
// =============================================================================

class UploadProgressOverlay extends StatelessWidget {
  const UploadProgressOverlay({
    super.key,
    required this.fileName,
    required this.progress,
    required this.percent,
  });

  final String fileName;
  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: OxiColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uploading $fileName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: OxiColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: OxiColors.border,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Multi-select action bar
// =============================================================================

class MultiSelectActionBar extends StatelessWidget {
  const MultiSelectActionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onMove,
    required this.onCopy,
    required this.onClearSelection,
  });

  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onCopy;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: OxiColors.border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClearSelection,
            tooltip: 'Clear selection',
          ),
          Text(
            '$selectedCount selected',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.drive_file_move_outlined),
            onPressed: onMove,
            tooltip: 'Move',
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: onCopy,
            tooltip: 'Copy',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: OxiColors.error),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared three-dot context menu button
// =============================================================================

class _ContextMenuButton extends StatelessWidget {
  const _ContextMenuButton({
    this.onRename,
    this.onDelete,
    this.onDownload,
    this.onFavoriteToggle,
    this.onDownloadZip,
    this.isFavorite = false,
  });

  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDownloadZip;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: OxiColors.textSecondary),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (_) => [
        if (onFavoriteToggle != null)
          PopupMenuItem(
            value: 'favorite',
            child: Row(
              children: [
                Icon(
                  isFavorite ? Icons.star : Icons.star_outline,
                  size: 18,
                  color: isFavorite ? Colors.amber : null,
                ),
                const SizedBox(width: 8),
                Text(isFavorite ? 'Remove Favorite' : 'Add to Favorites'),
              ],
            ),
          ),
        if (onDownload != null)
          const PopupMenuItem(
            value: 'download',
            child: Row(
              children: [
                Icon(Icons.download, size: 18),
                SizedBox(width: 8),
                Text('Download'),
              ],
            ),
          ),
        if (onDownloadZip != null)
          const PopupMenuItem(
            value: 'download_zip',
            child: Row(
              children: [
                Icon(Icons.archive_outlined, size: 18),
                SizedBox(width: 8),
                Text('Download as ZIP'),
              ],
            ),
          ),
        if (onRename != null)
          const PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: OxiColors.error),
                const SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: OxiColors.error)),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'favorite':
            onFavoriteToggle?.call();
          case 'download':
            onDownload?.call();
          case 'download_zip':
            onDownloadZip?.call();
          case 'rename':
            onRename?.call();
          case 'delete':
            onDelete?.call();
        }
      },
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
