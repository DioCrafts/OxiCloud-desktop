import 'package:flutter/material.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.label, this.onTap});
}

class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right,
                    size: 18, color: theme.colorScheme.outline),
              ),
            _BreadcrumbChip(
              item: items[i],
              isLast: i == items.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  final BreadcrumbItem item;
  final bool isLast;

  const _BreadcrumbChip({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = isLast
        ? theme.textTheme.bodyMedium!
            .copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.bodyMedium!
            .copyWith(color: theme.colorScheme.primary);

    if (isLast || item.onTap == null) {
      return Text(item.label, style: style);
    }

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(item.label, style: style),
      ),
    );
  }
}
