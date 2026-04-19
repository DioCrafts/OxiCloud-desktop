import 'package:flutter/material.dart';

import 'mobile_bottom_nav.dart';
import 'mobile_drawer.dart';

class MobileShell extends StatelessWidget {
  final String currentPath;
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const MobileShell({
    super.key,
    required this.currentPath,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: const MobileDrawer(),
      body: child,
      bottomNavigationBar: MobileBottomNav(currentPath: currentPath),
      floatingActionButton: floatingActionButton,
    );
  }
}
