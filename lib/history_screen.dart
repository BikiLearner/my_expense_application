import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'detail_screen.dart';
import 'expence_provider.dart';
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.history, color: Color(0xFF64FFDA)),
            SizedBox(width: 12),
            Text(
              "Expense History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: provider.getAllExpenseDates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF64FFDA),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading history',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dates = snapshot.data!;
          if (dates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No history found',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start adding expenses to see history',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          dates.sort((a, b) => b.compareTo(a)); // latest first
          final grouped = provider.groupDatesByMonth(dates);

          // Calculate grand total
          return FutureBuilder<double>(
            future: _calculateGrandTotal(provider, dates),
            builder: (context, totalSnapshot) {
              final grandTotal = totalSnapshot.data ?? 0.0;

              return Column(
                children: [
                  // Grand Total Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A5F), Color(0xFF2A5298)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total All Time',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${dates.length} days',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Month-wise Breakdown
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: grouped.entries.map((entry) {
                        final monthKey = entry.key; // yyyy-MM
                        final monthDates = entry.value;

                        final monthLabel = DateFormat('MMMM yyyy')
                            .format(DateTime.parse("$monthKey-01"));

                        return _buildMonthSection(
                          context,
                          provider,
                          monthLabel,
                          monthDates,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Build Month Section
  Widget _buildMonthSection(
      BuildContext context,
      ExpenseProvider provider,
      String monthLabel,
      List<String> monthDates,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2C2C2C),
          width: 1,
        ),
      ),
      child: FutureBuilder<double>(
        future: _calculateMonthTotal(provider, monthDates),
        builder: (context, monthTotalSnap) {
          final monthTotal = monthTotalSnap.data ?? 0.0;

          return ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Color(0xFF64FFDA),
                size: 24,
              ),
            ),
            title: Text(
              monthLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${monthDates.length} days',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${monthTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF64FFDA),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            children: monthDates.map((dateId) {
              return _buildDateItem(context, provider, dateId);
            }).toList(),
          );
        },
      ),
    );
  }

  // Build Date Item
  Widget _buildDateItem(
      BuildContext context,
      ExpenseProvider provider,
      String dateId,
      ) {
    return FutureBuilder<double>(
      future: provider.getTotalForDate(dateId),
      builder: (context, totalSnap) {
        if (!totalSnap.hasData) {
          return const SizedBox();
        }

        final total = totalSnap.data!;
        final date = DateTime.parse(dateId);
        final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateId;

        return InkWell(
          onTap: () {
            // Navigate to date detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DateDetailScreen(
                  dateId: dateId,
                  date: date,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday
                    ? const Color(0xFF64FFDA)
                    : const Color(0xFF3C3C3C),
                width: isToday ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Date Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF64FFDA).withOpacity(0.2)
                        : const Color(0xFF3C3C3C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
                          color: isToday
                              ? const Color(0xFF64FFDA)
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isToday
                              ? const Color(0xFF64FFDA)
                              : Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Date Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMMM yyyy').format(date),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount & Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Calculate grand total
  Future<double> _calculateGrandTotal(
      ExpenseProvider provider,
      List<String> dates,
      ) async {
    double total = 0;
    for (final dateId in dates) {
      total += await provider.getTotalForDate(dateId);
    }
    return total;
  }

  // Calculate month total
  Future<double> _calculateMonthTotal(
      ExpenseProvider provider,
      List<String> monthDates,
      ) async {
    double total = 0;
    for (final dateId in monthDates) {
      total += await provider.getTotalForDate(dateId);
    }
    return total;
  }
}