import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/domain/entities/item.dart';
import 'package:oxicloud_desktop/domain/services/mime_type_service.dart';
import 'package:oxicloud_desktop/presentation/providers/file_list_provider.dart';
import 'package:intl/intl.dart';

/// Widget for displaying a file or folder in a list
class FileListItem extends ConsumerWidget {
  /// The storage item to display
  final StorageItem item;
  
  /// Callback when the item is tapped
  final VoidCallback onTap;
  
  /// Callback when the item is long-pressed
  final VoidCallback? onLongPress;
  
  /// Size of the item's icon or thumbnail
  final double iconSize;
  
  /// Whether to show item details
  final bool showDetails;
  
  /// Create a FileListItem
  const FileListItem({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.iconSize = 40.0,
    this.showDetails = true,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: _buildLeadingIcon(ref),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: showDetails ? _buildSubtitle() : null,
      trailing: _buildTrailingIcons(),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
  
  /// Build the leading icon or thumbnail
  Widget _buildLeadingIcon(WidgetRef ref) {
    if (item.isFolder) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: Icon(
          Icons.folder,
          size: iconSize * 0.8,
          color: Colors.amber,
        ),
      );
    }
    
    // For files, try to show thumbnails for images
    if (item.mimeType != null && item.mimeType!.startsWith('image/')) {
      return _buildImageThumbnail(ref);
    }
    
    // Otherwise show an icon based on mime type
    final iconData = item.mimeType != null
        ? MimeTypeService.getFileIcon(item.mimeType!)
        : Icons.insert_drive_file;
    
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Icon(
        iconData,
        size: iconSize * 0.8,
      ),
    );
  }
  
  /// Build an image thumbnail
  Widget _buildImageThumbnail(WidgetRef ref) {
    final thumbnailAsync = ref.watch(fileThumbnailProvider(item.id));
    
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: thumbnailAsync.when(
        data: (thumbnail) {
          if (thumbnail != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                thumbnail,
                fit: BoxFit.cover,
                width: iconSize,
                height: iconSize,
                cacheWidth: iconSize.toInt() * 2, // For high DPI screens
                filterQuality: FilterQuality.low,
              ),
            );
          } else {
            return Icon(
              Icons.image,
              size: iconSize * 0.8,
            );
          }
        },
        loading: () => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, __) => Icon(
          Icons.image,
          size: iconSize * 0.8,
        ),
      ),
    );
  }
  
  /// Build the subtitle with item details
  Widget _buildSubtitle() {
    final formattedDate = _formatDate(item.modifiedAt);
    
    if (item.isFolder) {
      return Text(formattedDate);
    } else {
      final formattedSize = _formatSize(item.size);
      return Text('$formattedSize • $formattedDate');
    }
  }
  
  /// Build trailing icons for item status
  Widget _buildTrailingIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.isShared)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.share,
              size: 16,
              color: Colors.blueGrey,
            ),
          ),
        if (item.isFavorite)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.star,
              size: 16,
              color: Colors.amber,
            ),
          ),
        const Icon(
          Icons.more_vert,
          size: 20,
        ),
      ],
    );
  }
  
  /// Format file size for display
  String _formatSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    num size = bytes;
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return i == 0
        ? '$size ${suffixes[i]}'
        : '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final fileDate = DateTime(
      date.year,
      date.month,
      date.day,
    );
    
    if (fileDate == today) {
      return 'Today ${DateFormat.Hm().format(date)}';
    } else if (fileDate == yesterday) {
      return 'Yesterday ${DateFormat.Hm().format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat.E().format(date) + ' ' + DateFormat.Hm().format(date);
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}