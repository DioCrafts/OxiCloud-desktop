/// Result of checking sync conditions
class SyncConditions {
  final bool canSync;
  final String reason;
  
  SyncConditions({
    required this.canSync,
    this.reason = '',
  });
}