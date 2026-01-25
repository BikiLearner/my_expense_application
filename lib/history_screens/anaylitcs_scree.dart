import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseAnalyticsScreen extends StatelessWidget {
  final String year;

  const ExpenseAnalyticsScreen({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "$year Analytics",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('expenses')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No data available",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Filter for selected year
          final yearDocs = snapshot.data!.docs
              .where((doc) => doc.id.startsWith(year))
              .toList();

          if (yearDocs.isEmpty) {
            return Center(
              child: Text(
                "No expenses for $year",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          // Calculate monthly totals
          final Map<String, double> monthlyTotals = {};
          double totalExpense = 0;
          double highestMonth = 0;
          double lowestMonth = double.infinity;
          String highestMonthName = '';
          String lowestMonthName = '';

          for (var doc in yearDocs) {
            final dateId = doc.id;
            final month = dateId.substring(0, 7); // yyyy-MM
            final total = (doc.data() as Map)['total']?.toDouble() ?? 0;

            monthlyTotals[month] = (monthlyTotals[month] ?? 0) + total;
            totalExpense += total;
          }

          // Find highest and lowest months
          monthlyTotals.forEach((month, total) {
            if (total > highestMonth) {
              highestMonth = total;
              highestMonthName = _formatMonth(month);
            }
            if (total < lowestMonth && total > 0) {
              lowestMonth = total;
              lowestMonthName = _formatMonth(month);
            }
          });

          final avgMonthly = monthlyTotals.isNotEmpty
              ? totalExpense / monthlyTotals.length
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _buildSummaryCard(
                  "Total Spent",
                  "₹${totalExpense.toStringAsFixed(0)}",
                  Icons.account_balance_wallet,
                  Colors.redAccent,
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  "Monthly Average",
                  "₹${avgMonthly.toStringAsFixed(0)}",
                  Icons.trending_up,
                  Colors.blueAccent,
                ),
                const SizedBox(height: 24),

                // Highest & Lowest
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Highest Month",
                        highestMonthName,
                        "₹${highestMonth.toStringAsFixed(0)}",
                        Colors.orangeAccent,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        "Lowest Month",
                        lowestMonthName,
                        "₹${lowestMonth != double.infinity ? lowestMonth.toStringAsFixed(0) : '0'}",
                        Colors.greenAccent,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Monthly Breakdown Chart
                const Text(
                  "Monthly Breakdown",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMonthlyChart(monthlyTotals, highestMonth),

                const SizedBox(height: 24),

                // Spending Trend
                _buildTrendAnalysis(monthlyTotals),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String month,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            month,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(Map<String, double> monthlyTotals, double max) {
    final sortedMonths = monthlyTotals.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: sortedMonths.map((month) {
          final total = monthlyTotals[month] ?? 0;
          final percentage = max > 0 ? total / max : 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatMonth(month),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      "₹${total.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage.toDouble(),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF64FFDA), Colors.blueAccent],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendAnalysis(Map<String, double> monthlyTotals) {
    if (monthlyTotals.length < 2) {
      return const SizedBox();
    }

    final sortedMonths = monthlyTotals.keys.toList()..sort();
    final firstMonth = monthlyTotals[sortedMonths.first] ?? 0;
    final lastMonth = monthlyTotals[sortedMonths.last] ?? 0;
    final difference = lastMonth - firstMonth;
    final percentChange = firstMonth > 0 ? (difference / firstMonth) * 100 : 0;
    final isIncreasing = difference > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spending Trend",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                isIncreasing ? Icons.trending_up : Icons.trending_down,
                color: isIncreasing ? Colors.redAccent : Colors.greenAccent,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIncreasing
                          ? "Spending Increased"
                          : "Spending Decreased",
                      style: TextStyle(
                        color: isIncreasing
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${percentChange.abs().toStringAsFixed(1)}% compared to ${_formatMonth(sortedMonths.first)}",
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMonth(String monthId) {
    try {
      final date = DateTime.parse("$monthId-01");
      return DateFormat('MMM yyyy').format(date);
    } catch (e) {
      return monthId;
    }
  }
}
