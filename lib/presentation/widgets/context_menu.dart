import 'package:flutter/material.dart';

class ContextMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
}

class AppContextMenu {
  AppContextMenu._();

  static void show({
    required BuildContext context,
    required Offset position,
    required List<ContextMenuItem> items,
  }) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: items.map((item) {
        return PopupMenuItem<void>(
          onTap: item.onTap,
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: item.isDanger
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: item.isDanger
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
