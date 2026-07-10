import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../expense/data/model/expense_items.dart';
import '../provider/all_expense_provider.dart';
import '../../../../shared/widgets/day_expense.dart';
// 👆 Ensure this path matches your project structure

class SearchExpensesScreen extends StatefulWidget {
  const SearchExpensesScreen({super.key});

  @override
  State<SearchExpensesScreen> createState() => _SearchExpensesScreenState();
}

class _SearchExpensesScreenState extends State<SearchExpensesScreen> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  // Search State
  String _searchQuery = '';
  double _minAmount = 0;
  double _maxAmount = double.infinity;

  // Filter Toggle
  bool _showFilters = false;

  // 🗓 Date Selection State
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;

    // Load initial data
    _fetchData();
  }

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllExpensesProvider>().setMonth(
        year: _selectedYear.toString(),
        month: _selectedMonth,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  // ───────────────────────── LOGIC ─────────────────────────

  /// Groups expenses by 'yyyy-MM-dd'
  Map<String, List<ExpenseItem>> _groupExpensesByDate(List<ExpenseItem> items) {
    final Map<String, List<ExpenseItem>> grouped = {};
    for (var item in items) {
      final key = DateFormat('yyyy-MM-dd').format(item.createdAt);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }
    return grouped;
  }

  // ───────────────────────── UI: APP BAR ─────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F1115),
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      titleSpacing: 0,
      title: Container(
        height: 44,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF64FFDA), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: false,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search title, notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: const Icon(Icons.close, color: Colors.grey, size: 18),
              ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: _showFilters
                ? const Color(0xFF64FFDA).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_list,
              color: _showFilters ? const Color(0xFF64FFDA) : Colors.grey,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── UI: CONTROL PANEL ─────────────────────────

  Widget _buildControlPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _showFilters ? 150 : 0, // Expands when active
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Date Selectors
              Row(
                children: [
                  Expanded(child: _buildYearDropdown()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMonthDropdown()),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Price Range
              Row(
                children: [
                  Expanded(child: _buildPriceInput(_minController, 'Min ₹')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPriceInput(_maxController, 'Max ₹')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Dropdowns & Inputs Helpers ---

  Widget _buildYearDropdown() {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      10,
      (index) => currentYear - 5 + index,
    ); // 5 years back, 5 forward

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int>(
        value: _selectedYear,
        dropdownColor: const Color(0xFF1E1E1E),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFF64FFDA),
          size: 18,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: years.map((y) {
          return DropdownMenuItem(value: y, child: Text(y.toString()));
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedYear = val);
            _fetchData();
          }
        },
      ),
    );
  }

  Widget _buildMonthDropdown() {
    final months =
        DateFormat().dateSymbols.MONTHS; // ["January", "February"...]

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int>(
        value: _selectedMonth,
        dropdownColor: const Color(0xFF1E1E1E),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFF64FFDA),
          size: 18,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: List.generate(12, (index) {
          return DropdownMenuItem(value: index + 1, child: Text(months[index]));
        }),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedMonth = val);
            _fetchData();
          }
        },
      ),
    );
  }

  Widget _buildPriceInput(TextEditingController controller, String label) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
          filled: true,
          fillColor: const Color(0xFF0F1115),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) {
          setState(() {
            if (label.contains('Min')) {
              _minAmount = double.tryParse(v) ?? 0;
            } else {
              _maxAmount = double.tryParse(v) ?? double.infinity;
            }
          });
        },
      ),
    );
  }

  // ───────────────────────── MAIN BUILD ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filter Panel (Expandable)
          _buildControlPanel(),

          // Main Content
          Expanded(
            child: Consumer<AllExpensesProvider>(
              builder: (_, provider, __) {
                // 1. Loading State
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
                  );
                }

                // 2. Perform Search
                final results = provider.search(
                  query: _searchQuery,
                  min: _minAmount,
                  max: _maxAmount,
                );

                // 3. Group results
                final grouped = _groupExpensesByDate(results);
                final sortedDateKeys = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));
                final totalSum = results.fold(0.0, (s, e) => s + e.amount);

                // 4. Empty State
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.manage_search,
                          size: 60,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No expenses in ${DateFormat().dateSymbols.MONTHS[_selectedMonth - 1]} $_selectedYear'
                              : 'No matches found',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Summary Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1115),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${results.length} TRANSACTIONS',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'TOTAL: ₹${totalSum.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF64FFDA),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Results List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        itemCount: sortedDateKeys.length,
                        itemBuilder: (context, index) {
                          final dateKey = sortedDateKeys[index];
                          final dayExpenses = grouped[dateKey]!;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            // 🔥 Using your beautiful DayCard
                            child: DayCard(dateId: dateKey, items: dayExpenses),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
