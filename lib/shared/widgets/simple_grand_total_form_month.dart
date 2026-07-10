import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../enums/expense_type.dart';
import '../../features/history/presentation/provider/month_expense_provider.dart';

class SimpleMonthSummaryBanner extends StatefulWidget {
  final String monthKey;

  const SimpleMonthSummaryBanner({super.key, required this.monthKey});

  @override
  State<SimpleMonthSummaryBanner> createState() =>
      _SimpleMonthSummaryBannerState();
}

class _SimpleMonthSummaryBannerState extends State<SimpleMonthSummaryBanner>
    with TickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MonthExpensesProvider>(
      builder: (context, provider, _) {
        final totalDays = provider.totalDays;
        if (totalDays == 0) return const SizedBox.shrink();

        final monthTotal = provider.monthTotal;
        final date = DateTime.parse('${widget.monthKey}-01');
        final monthLabel = DateFormat('MMMM yyyy').format(date);

        final isCompact = MediaQuery.of(context).size.width <= 420;

        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2A5298)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                /// 🔹 HEADER (always visible)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monthLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${monthTotal.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// 🔽 EXPAND BUTTON
                    IconButton(
                      icon: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          Icons.expand_more,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onPressed: _toggle,
                    ),
                  ],
                ),

                /// 🔥 EXPANDABLE CONTENT
                if (_expanded) ...[
                  const SizedBox(height: 20),

                  _ExpandedSummary(
                    provider: provider,
                    isCompact: isCompact,
                    monthKey: widget.monthKey,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool compact;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: compact
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300], fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${value.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${value.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ExpandedSummary extends StatelessWidget {
  final MonthExpensesProvider provider;
  final bool isCompact;
  final String monthKey;

  const _ExpandedSummary({
    required this.provider,
    required this.isCompact,
    required this.monthKey,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = provider.totalDays;

    final savingTotal = provider.getMonthTotalForType(ExpenseType.saving);
    final luxuryTotal = provider.getMonthTotalForType(ExpenseType.luxury);
    final neededTotal = provider.getMonthTotalForType(ExpenseType.needed);
    final avgPerDay = provider.avgPerDay;
    final highestDay = provider.highestDay;
    final monthTotal = provider.monthTotal;
    final date = DateTime.parse('$monthKey-01');
    final monthLabel = DateFormat('MMMM yyyy').format(date);

    // Calculate averages per day
    final savingPerDay = totalDays > 0 ? savingTotal / totalDays : 0.0;
    final luxuryPerDay = totalDays > 0 ? luxuryTotal / totalDays : 0.0;
    final neededPerDay = totalDays > 0 ? neededTotal / totalDays : 0.0;

    return Column(
      children: [
        Row(
          children: [
            _MiniStat(
              label: "Avg / Day",
              value: avgPerDay,
              color: Colors.blueAccent,
              icon: Icons.trending_up,
            ),
            const SizedBox(width: 12),
            _MiniStat(
              label: "Highest Day",
              value: highestDay,
              color: Colors.orangeAccent,
              icon: Icons.arrow_upward,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Luxury & Saving per day
        Row(
          children: [
            _MiniStat(
              label: "Luxury / Day",
              value: luxuryPerDay,
              color: Colors.pinkAccent,
              icon: Icons.auto_awesome,
              compact: isCompact,
            ),
            const SizedBox(width: 8),
            _MiniStat(
              label: "Saving / Day",
              value: savingPerDay,
              color: Colors.greenAccent,
              icon: Icons.savings,
              compact: isCompact,
            ),
            const SizedBox(width: 8),
            _MiniStat(
              label: "Needed / Day",
              value: neededPerDay,
              color: Colors.orangeAccent,
              icon: Icons.shopping_cart,
              compact: isCompact,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Expense split
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TypeStat(
                icon: Icons.savings_outlined,
                label: "Saving",
                value: savingTotal,
                color: Colors.greenAccent,
              ),
              _TypeStat(
                icon: Icons.auto_awesome_outlined,
                label: "Luxury",
                value: luxuryTotal,
                color: Colors.pinkAccent,
              ),
              _TypeStat(
                icon: Icons.shopping_cart_outlined,
                label: "Needed",
                value: neededTotal,
                color: Colors.orangeAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _TypeStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          "₹${value.toStringAsFixed(0)}",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
