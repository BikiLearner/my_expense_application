import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/analytics_provider.dart';
import 'all_detail_screens.dart';

class DailyHeatmapCard extends StatelessWidget {
  const DailyHeatmapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AnalyticsProvider, Map<String, double>>(
      selector: (_, p) => p.dailyTotals,
      builder: (context, dailyTotals, _) {
        if (dailyTotals.isEmpty) return const SizedBox();

        final provider = context.read<AnalyticsProvider>();
        final year = int.tryParse(provider.year) ?? DateTime.now().year;
        final maxVal = dailyTotals.values.isEmpty
            ? 1.0
            : dailyTotals.values.reduce((a, b) => a > b ? a : b);

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const HeatmapDetailScreen(),
            ),
          )),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141420),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daily Heatmap',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${dailyTotals.values.where((v) => v > 0).length} days active',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Tap a cell to see that day\'s expenses',
                    style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                const SizedBox(height: 16),

                // Month labels + grid
                _buildHeatmap(context, year, dailyTotals, maxVal),

                const SizedBox(height: 12),
                // Legend
                Row(
                  children: [
                    Text('Less', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    const SizedBox(width: 8),
                    ..._intensityColors.map((c) => Container(
                      width: 12, height: 12,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                    const SizedBox(width: 4),
                    Text('More', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const _intensityColors = [
    Color(0xFF1A1A2E),
    Color(0xFF0D3D3D),
    Color(0xFF0A6060),
    Color(0xFF0A9090),
    Color(0xFF64FFDA),
  ];

  Widget _buildHeatmap(
      BuildContext context, int year, Map<String, double> dailyTotals, double maxVal) {
    final months = List.generate(12, (i) => i + 1);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: months.map((month) {
          final daysInMonth = DateUtils.getDaysInMonth(year, month);
          final monthKey = DateFormat('MMM').format(DateTime(year, month));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthKey,
                  style: TextStyle(color: Colors.grey[600], fontSize: 9)),
              const SizedBox(height: 4),
              Row(
                children: _buildWeekColumns(year, month, daysInMonth, dailyTotals, maxVal, context),
              ),
              const SizedBox(width: 4),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildWeekColumns(
      int year, int month, int daysInMonth,
      Map<String, double> dailyTotals, double maxVal, BuildContext context) {
    final days = <Widget>[];
    int firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon

    // Build all day cells for this month
    final cells = <Widget>[];

    // Empty cells for offset
    for (int offset = 1; offset < firstWeekday; offset++) {
      cells.add(const SizedBox(width: 11, height: 11));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final dateId = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final amount = dailyTotals[dateId] ?? 0.0;
      final intensity = maxVal > 0 ? (amount / maxVal).clamp(0.0, 1.0) : 0.0;
      final color = _getColor(intensity);

      cells.add(
        GestureDetector(
          onTap: amount > 0
              ? () => _showDayTooltip(context, dateId, amount)
              : null,
          child: Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    // Group into weeks of 7
    final weeks = <Column>[];
    for (int i = 0; i < cells.length; i += 7) {
      final weekCells = cells.sublist(i, (i + 7).clamp(0, cells.length));
      weeks.add(Column(
        children: weekCells,
      ));
    }
    return weeks;
  }

  Color _getColor(double intensity) {
    if (intensity == 0) return _intensityColors[0];
    if (intensity < 0.25) return _intensityColors[1];
    if (intensity < 0.5) return _intensityColors[2];
    if (intensity < 0.75) return _intensityColors[3];
    return _intensityColors[4];
  }

  void _showDayTooltip(BuildContext context, String dateId, double amount) {
    String dateStr = dateId;
    try {
      dateStr = DateFormat('EEE, MMM dd').format(DateTime.parse(dateId));
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(dateStr,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(color: Color(0xFF64FFDA), fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('spent on this day', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}