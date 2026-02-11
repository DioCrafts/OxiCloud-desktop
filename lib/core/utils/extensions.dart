/// Utility extensions used across the application.

/// Readable byte formatting (reusable across entities and UI).
extension ByteFormatting on int {
  /// Converts bytes to a human-readable string (e.g. 1.5 GB).
  String toReadableBytes() {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// DateTime helpers for sync timestamps.
extension DateTimeFormatting on DateTime {
  /// Returns a relative "time ago" string.
  String toTimeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${day.toString().padLeft(2, '0')}/'
        '${month.toString().padLeft(2, '0')}/'
        '$year';
  }
}

/// Nullable string helpers.
extension StringNullableX on String? {
  /// Returns true if the string is null or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if the string is not null and not empty.
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
