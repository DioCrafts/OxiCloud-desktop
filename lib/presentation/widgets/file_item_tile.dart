import 'package:flutter/material.dart';

import '../../core/entities/file_item.dart';
import '../theme/oxicloud_colors.dart';

// =============================================================================
// Folder tile (used in both list and grid mode)
// =============================================================================

class FolderTile extends StatelessWidget {
  final FolderItem folder;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const FolderTile({
    super.key,
    required this.folder,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: OxiColors.navFilesInactive.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.folder_rounded,
          color: OxiColors.navFilesInactive,
          size: 24,
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
      ),
      onTap: onTap,
    );
  }
}

// =============================================================================
// File tile (used in list mode)
// =============================================================================

class FileTile extends StatelessWidget {
  final FileItem file;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;

  const FileTile({
    super.key,
    required this.file,
    this.onTap,
    this.onRename,
    this.onDelete,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final fileType = file.fileType;
    final color = FileTypeHelper.color(fileType);
    final icon = FileTypeHelper.icon(fileType);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
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
      ),
      onTap: onTap,
    );
  }
}

// =============================================================================
// Grid card for folders
// =============================================================================

class FolderGridCard extends StatelessWidget {
  final FolderItem folder;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const FolderGridCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: OxiColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder_rounded,
                color: OxiColors.navFilesInactive,
                size: 40,
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
  final FileItem file;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;

  const FileGridCard({
    super.key,
    required this.file,
    this.onTap,
    this.onRename,
    this.onDelete,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final fileType = file.fileType;
    final color = FileTypeHelper.color(fileType);
    final icon = FileTypeHelper.icon(fileType);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: OxiColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
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
}

// =============================================================================
// Shared three-dot context menu button
// =============================================================================

class _ContextMenuButton extends StatelessWidget {
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;

  const _ContextMenuButton({
    this.onRename,
    this.onDelete,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: OxiColors.textSecondary),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (_) => [
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
          case 'download':
            onDownload?.call();
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
