import 'package:flutter/material.dart';

class YearSelector extends StatelessWidget {
  final int selectedYear;
  final ValueChanged<int> onYearSelected;

  const YearSelector({
    super.key,
    required this.selectedYear,
    required this.onYearSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openYearPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF64FFDA),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              selectedYear.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _openYearPicker(BuildContext context) {
    final currentYear = DateTime.now().year;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Hugs content so it doesn't take full screen
            children: [
              // Bottom sheet drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Select Year",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Generate last 6 years
              ...List.generate(6, (i) {
                final year = currentYear - i;
                final isSelected = year == selectedYear;

                return ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: isSelected
                        ? const Color(0xFF64FFDA)
                        : Colors.grey[600],
                  ),
                  title: Text(
                    year.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF64FFDA)
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF64FFDA))
                      : null,
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    if (!isSelected) {
                      onYearSelected(year); // Pass the new year back to the parent
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}