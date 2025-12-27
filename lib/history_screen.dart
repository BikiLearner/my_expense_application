import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'detail_screen.dart';
import 'expence_provider.dart';
import 'expense_model.dart';

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

      /// 🔴 ONLY THIS FutureBuilder CHANGED (DATA SOURCE)
      body: FutureBuilder<List<ExpenseDay>>(
        future: provider.getAllExpenseDays(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF64FFDA),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No history found',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final days = snapshot.data!;
          days.sort((a, b) => b.dateId.compareTo(a.dateId));

          /// 🔴 SAME GROUPING LOGIC, JUST DIFFERENT INPUT
          final Map<String, List<ExpenseDay>> grouped = {};
          for (final d in days) {
            final monthKey = d.dateId.substring(0, 7);
            grouped.putIfAbsent(monthKey, () => []).add(d);
          }

          /// 🔴 GRAND TOTAL – NO FIRESTORE CALL
          final grandTotal =
          days.fold(0.0, (sum, d) => sum + d.total);

          return Column(
            children: [
              /// ✅ GRAND TOTAL BANNER (UNCHANGED UI)
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
                        '${days.length} days',
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

              /// ✅ MONTH-WISE LIST (UNCHANGED UI)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    final monthKey = entry.key;
                    final monthDays = entry.value;

                    final monthLabel = DateFormat('MMMM yyyy')
                        .format(DateTime.parse("$monthKey-01"));

                    final monthTotal = monthDays.fold(
                      0.0,
                          (sum, d) => sum + d.total,
                    );

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
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFF64FFDA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Color(0xFF64FFDA),
                          ),
                        ),
                        title: Text(
                          monthLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${monthDays.length} days',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        trailing: Text(
                          '₹${monthTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF64FFDA),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: monthDays.map((day) {
                          final date = DateTime.parse(day.dateId);
                          final isToday =
                              DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
                                  day.dateId;

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DateDetailScreen(
                                    dateId: day.dateId,
                                    date: date,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
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
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? const Color(0xFF64FFDA)
                                          .withOpacity(0.2)
                                          : const Color(0xFF3C3C3C),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
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
                                          DateFormat('MMM')
                                              .format(date)
                                              .toUpperCase(),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEEE').format(date),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd MMMM yyyy')
                                              .format(date),
                                          style: TextStyle(
                                              color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${day.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF64FFDA),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
