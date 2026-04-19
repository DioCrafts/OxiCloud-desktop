import 'package:flutter/material.dart';

import 'desktop_sidebar.dart';
import 'desktop_status_bar.dart';

class DesktopShell extends StatelessWidget {
  final String currentPath;
  final Widget child;
  final int? itemCount;
  final int? selectedCount;

  const DesktopShell({
    super.key,
    required this.currentPath,
    required this.child,
    this.itemCount,
    this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                DesktopSidebar(currentPath: currentPath),
                Expanded(child: child),
              ],
            ),
          ),
          DesktopStatusBar(itemCount: itemCount, selectedCount: selectedCount),
        ],
      ),
    );
  }
}
