import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Action for platform adaptive alert
class PlatformAdaptiveAlertAction {
  /// Label for the action button
  final String label;
  
  /// Whether this is the default action
  final bool isDefaultAction;
  
  /// Whether this is a destructive action
  final bool isDestructiveAction;
  
  /// Callback when the action is pressed
  final VoidCallback? onPressed;
  
  /// Create a platform adaptive alert action
  const PlatformAdaptiveAlertAction({
    required this.label,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.onPressed,
  });
}

/// Show a platform adaptive alert dialog
Future<void> showPlatformAdaptiveAlert({
  required BuildContext context,
  required String title,
  required String content,
  required List<PlatformAdaptiveAlertAction> actions,
}) async {
  final theme = Theme.of(context);
  final isCupertino = theme.platform == TargetPlatform.iOS || 
                     theme.platform == TargetPlatform.macOS;
  
  if (isCupertino) {
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions.map((action) => CupertinoDialogAction(
          isDefaultAction: action.isDefaultAction,
          isDestructiveAction: action.isDestructiveAction,
          onPressed: () {
            Navigator.of(context).pop();
            action.onPressed?.call();
          },
          child: Text(action.label),
        )).toList(),
      ),
    );
  } else {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions.map((action) {
          final buttonStyle = action.isDestructiveAction
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null;
              
          return TextButton(
            style: buttonStyle,
            onPressed: () {
              Navigator.of(context).pop();
              action.onPressed?.call();
            },
            child: Text(action.label),
          );
        }).toList(),
      ),
    );
  }
}