import 'package:flutter/material.dart';

import '../../core/theme/responsive.dart';
import 'desktop/desktop_shell.dart';
import 'mobile/mobile_shell.dart';

class AdaptiveShell extends StatelessWidget {
  final String currentPath;
  final String title;
  final Widget child;
  final int? itemCount;
  final int? selectedCount;
  final List<Widget>? mobileActions;
  final Widget? floatingActionButton;

  const AdaptiveShell({
    super.key,
    required this.currentPath,
    required this.title,
    required this.child,
    this.itemCount,
    this.selectedCount,
    this.mobileActions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return DesktopShell(
        currentPath: currentPath,
        itemCount: itemCount,
        selectedCount: selectedCount,
        child: child,
      );
    }

    return MobileShell(
      currentPath: currentPath,
      title: title,
      actions: mobileActions,
      floatingActionButton: floatingActionButton,
      child: child,
    );
  }
}
