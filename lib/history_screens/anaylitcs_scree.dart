import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseAnalyticsScreen extends StatelessWidget {
  final String year;

  const ExpenseAnalyticsScreen({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$year Deep Dive",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              "Composition & Trends",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<QuerySnapshot>>(
        // 🚀 Fetch Daily Expenses AND Year Stats in parallel
        future: Future.wait([
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('expenses')
              .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$year-01-01')
              .where(FieldPath.documentId, isLessThanOrEqualTo: '$year-12-31')
              .get(),
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('year_stats')
              .doc(year)
              .collection('months')
              .get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF64FFDA)));
          }

          if (!snapshot.hasData || snapshot.data![0].docs.isEmpty) {
            return _buildEmptyState();
          }

          // 1. Process Data
          final dailyDocs = snapshot.data![0].docs;
          final statDocs = snapshot.data![1].docs;

          final analytics = _processAdvancedData(dailyDocs, statDocs);

          // 2. Responsive Layout
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOP SUMMARY CARDS ---
                    _buildTopStatsGrid(analytics, isDesktop),

                    const SizedBox(height: 24),

                    // --- SPENDING HABITS (Needs vs Wants) ---
                    //  - Triggering relevant chart tag
                    _buildCompositionCard(analytics),

                    const SizedBox(height: 24),

                    // --- TREND CHART ---
                    //  - Triggering relevant chart tag
                    _buildTrendSection(analytics),

                    const SizedBox(height: 24),

                    // --- DETAILED BREAKDOWN ---
                    Text(
                      "Monthly Performance",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    isDesktop
                        ? _buildDesktopTable(analytics)
                        : _buildMobileList(analytics),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🧠 ADVANCED DATA PROCESSING
  // ---------------------------------------------------------------------------

  _AdvancedAnalyticsData _processAdvancedData(
      List<QueryDocumentSnapshot> dailyDocs,
      List<QueryDocumentSnapshot> statDocs
      ) {
    // 1. Aggregates from Daily Docs (Time based)
    final Map<String, double> monthlyTotals = {};
    double totalSpent = 0;

    // Find Peak Day
    String peakDate = "";
    double peakDayAmount = 0;

    for (var doc in dailyDocs) {
      final total = (doc.data() as Map)['total']?.toDouble() ?? 0;
      final dateId = doc.id; // yyyy-MM-dd
      final monthKey = dateId.substring(0, 7); // yyyy-MM

      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + total;
      totalSpent += total;

      if (total > peakDayAmount) {
        peakDayAmount = total;
        peakDate = dateId;
      }
    }

    // 2. Aggregates from Year Stats (Type based)
    double totalLuxury = 0;
    double totalNeeded = 0;
    double totalSaving = 0;

    for (var doc in statDocs) {
      final data = doc.data() as Map<String, dynamic>;
      totalLuxury += (data['luxury'] ?? 0).toDouble();
      totalNeeded += (data['needed'] ?? 0).toDouble();
      totalSaving += (data['saving'] ?? 0).toDouble();
    }

    // Fallback if statDocs are empty (calculate totals from existing daily sum, assume 'needed' for safety)
    if (totalLuxury + totalNeeded + totalSaving == 0) {
      totalNeeded = totalSpent;
    }

    final highestMonthTotal = monthlyTotals.values.isEmpty
        ? 0.0
        : monthlyTotals.values.reduce((a, b) => a > b ? a : b);

    return _AdvancedAnalyticsData(
      totalSpent: totalSpent,
      monthlyTotals: monthlyTotals,
      highestMonthTotal: highestMonthTotal,
      peakDate: peakDate,
      peakDayAmount: peakDayAmount,
      totalLuxury: totalLuxury,
      totalNeeded: totalNeeded,
      totalSaving: totalSaving,
    );
  }

  // ---------------------------------------------------------------------------
  // 🧱 WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildTopStatsGrid(_AdvancedAnalyticsData data, bool isDesktop) {
    // Format Peak Date
    String peakDateStr = "N/A";
    if (data.peakDate.isNotEmpty) {
      final dt = DateTime.parse(data.peakDate);
      peakDateStr = DateFormat("MMM dd").format(dt);
    }

    final children = [
      _StatCard(
        label: "Total Spent",
        value: "₹${_formatCompact(data.totalSpent)}",
        icon: Icons.account_balance_wallet,
        color: const Color(0xFF64FFDA),
      ),
      _StatCard(
        label: "Peak Day ($peakDateStr)",
        value: "₹${_formatCompact(data.peakDayAmount)}",
        icon: Icons.priority_high_rounded,
        color: Colors.redAccent,
      ),
      _StatCard(
        label: "Savings",
        value: "₹${_formatCompact(data.totalSaving)}",
        icon: Icons.savings,
        color: Colors.greenAccent,
      ),
      _StatCard(
        label: "Daily Avg",
        value: "₹${_formatCompact(data.totalSpent / 365)}", // Simplified avg
        icon: Icons.calendar_today,
        color: Colors.blueAccent,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: children.map((e) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: e,
        ))).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: children,
    );
  }

  Widget _buildCompositionCard(_AdvancedAnalyticsData data) {
    final total = data.totalLuxury + data.totalNeeded + data.totalSaving;
    if (total == 0) return const SizedBox();

    final luxuryPct = data.totalLuxury / total;
    final neededPct = data.totalNeeded / total;
    final savingPct = data.totalSaving / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spending Habits",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Based on expenses tagged as Needed, Luxury, or Saving",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Custom Stacked Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 30,
              child: Row(
                children: [
                  if (neededPct > 0) Expanded(flex: (neededPct * 100).toInt(), child: Container(color: Colors.orangeAccent)),
                  if (luxuryPct > 0) Expanded(flex: (luxuryPct * 100).toInt(), child: Container(color: Colors.redAccent)),
                  if (savingPct > 0) Expanded(flex: (savingPct * 100).toInt(), child: Container(color: Colors.greenAccent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem("Needed", data.totalNeeded, Colors.orangeAccent, neededPct),
              _buildLegendItem("Luxury", data.totalLuxury, Colors.redAccent, luxuryPct),
              _buildLegendItem("Saved", data.totalSaving, Colors.greenAccent, savingPct),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double amount, Color color, double pct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
            "${(pct * 100).toStringAsFixed(1)}%",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
        ),
        Text(
          "₹${_formatCompact(amount)}",
          style: TextStyle(color: color, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildTrendSection(_AdvancedAnalyticsData data) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Monthly Trend", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text("High: ₹${_formatCompact(data.highestMonthTotal)}", style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _SimpleBarChart(monthlyTotals: data.monthlyTotals, maxVal: data.highestMonthTotal),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(_AdvancedAnalyticsData data) {
    final sortedKeys = data.monthlyTotals.keys.toList()..sort();
    return Column(
      children: sortedKeys.reversed.map((key) {
        final amount = data.monthlyTotals[key]!;
        final max = data.highestMonthTotal;
        final date = DateTime.tryParse("$key-01") ?? DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MM').format(date),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(date),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : amount / max,
                        backgroundColor: Colors.black,
                        color: const Color(0xFF64FFDA),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "₹${_formatCompact(amount)}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopTable(_AdvancedAnalyticsData data) {
    // Desktop layout using Wrap for cards
    final sortedKeys = data.monthlyTotals.keys.toList()..sort();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: sortedKeys.map((key) {
        final amount = data.monthlyTotals[key]!;
        final date = DateTime.tryParse("$key-01") ?? DateTime.now();

        return Container(
          width: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('MMM yyyy').format(date), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 8),
              Text("₹${_formatCompact(amount)}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text("No analytics available yet", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 100000) return "${(value / 100000).toStringAsFixed(1)}L";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}k";
    return value.toStringAsFixed(0);
  }
}

// -----------------------------------------------------------------------------
// 🧠 HELPER CLASSES & WIDGETS
// -----------------------------------------------------------------------------

class _AdvancedAnalyticsData {
  final double totalSpent;
  final Map<String, double> monthlyTotals;
  final double highestMonthTotal;
  final String peakDate;
  final double peakDayAmount;
  final double totalLuxury;
  final double totalNeeded;
  final double totalSaving;

  _AdvancedAnalyticsData({
    required this.totalSpent,
    required this.monthlyTotals,
    required this.highestMonthTotal,
    required this.peakDate,
    required this.peakDayAmount,
    required this.totalLuxury,
    required this.totalNeeded,
    required this.totalSaving,
  });
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11), maxLines: 1)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final Map<String, double> monthlyTotals;
  final double maxVal;

  const _SimpleBarChart({required this.monthlyTotals, required this.maxVal});

  @override
  Widget build(BuildContext context) {
    final yearKeys = List.generate(12, (i) => "${i + 1}".padLeft(2, '0'));

    return LayoutBuilder(builder: (context, constraints) {
      final barWidth = (constraints.maxWidth / 12) - 6;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: yearKeys.map((monthNum) {
          final key = monthlyTotals.keys.firstWhere((k) => k.endsWith("-$monthNum"), orElse: () => "");
          final amount = key.isEmpty ? 0.0 : monthlyTotals[key]!;
          final pct = maxVal == 0 ? 0.0 : amount / maxVal;
          final isZero = amount == 0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: barWidth,
                height: constraints.maxHeight * (isZero ? 0.01 : pct * 0.85),
                decoration: BoxDecoration(
                  color: isZero ? Colors.white.withOpacity(0.05) : const Color(0xFF64FFDA),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('MMM').format(DateTime(2024, int.parse(monthNum))),
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ],
          );
        }).toList(),
      );
    });
  }
}