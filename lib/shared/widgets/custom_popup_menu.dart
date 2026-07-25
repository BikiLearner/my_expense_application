import 'package:flutter/material.dart';

/// A model to define each item in the reusable popup menu
class PopupActionItem {
  final String value;
  final String title;
  final IconData icon;
  final Color color;

  const PopupActionItem({
    required this.value,
    required this.title,
    required this.icon,
    required this.color,
  });
}

/// The reusable popup menu widget
class CustomActionPopupMenu extends StatelessWidget {
  final List<PopupActionItem> items;
  final Function(String) onSelected;

  const CustomActionPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white),
      ),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 50),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<String>(
            value: item.value,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.title,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}