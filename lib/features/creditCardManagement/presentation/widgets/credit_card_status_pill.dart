// 🟢 Active / Inactive pill
import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_color.dart';

class CreditCardStatusPill extends StatelessWidget {
  final bool isActive;

  const CreditCardStatusPill({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColor.creditSoft : AppColor.creditDue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}