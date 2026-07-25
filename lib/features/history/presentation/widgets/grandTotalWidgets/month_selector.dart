import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelector extends StatelessWidget {
  final int selectedMonth;
  final ValueChanged<int> onMonthSelected;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Format the currently selected month for the button (e.g., "Jan")
    final label = DateFormat.MMM().format(DateTime(0, selectedMonth));

    return GestureDetector(
      onTap: () => _openMonthPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Keeps the button wrapped to its content
          children: [
            const Icon(
              Icons.calendar_month,
              color: Color(0xFF64FFDA),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _openMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: 12,
          itemBuilder: (_, i) {
            final month = i + 1;
            final label = DateFormat.MMMM().format(DateTime(0, month));
            final isSelected = selectedMonth == month;

            return ListTile(
              leading: Icon(
                Icons.calendar_month,
                color: isSelected ? const Color(0xFF64FFDA) : Colors.grey,
              ),
              title: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF64FFDA) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF64FFDA))
                  : null,
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                if (!isSelected) {
                  onMonthSelected(month); // Pass the new month back to the parent
                }
              },
            );
          },
        );
      },
    );
  }
}