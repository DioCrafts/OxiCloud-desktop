import 'package:flutter/material.dart';

import '../../core/entities/file_item.dart';
import '../theme/oxicloud_colors.dart';

/// Breadcrumb navigation bar for the file browser.
///
/// Displays the current path as clickable segments. Tapping a segment
/// navigates back to that folder level.
class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final ValueChanged<int> onTap;

  const BreadcrumbBar({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: OxiColors.toolbarBg,
        border: Border(bottom: BorderSide(color: OxiColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, size: 18, color: OxiColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: OxiColors.textPlaceholder,
                ),
              ),
              itemBuilder: (context, index) {
                final isLast = index == items.length - 1;
                return InkWell(
                  onTap: isLast ? null : () => onTap(index),
                  borderRadius: BorderRadius.circular(4),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Text(
                        items[index].name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                          color: isLast
                              ? OxiColors.textHeading
                              : OxiColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
