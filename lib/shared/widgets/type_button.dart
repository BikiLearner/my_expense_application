import 'package:flutter/material.dart';

import '../enums/expense_type.dart';

class TypeButton extends StatelessWidget {
  final ExpenseType type;
  final bool selected;
  final VoidCallback onTap;

  const TypeButton({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? type.color.withValues(alpha: 0.2)
              : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? type.color : const Color(0xFF3C3C3C),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              color: selected ? type.color : Colors.grey[500],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              style: TextStyle(
                color: selected ? type.color : Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}