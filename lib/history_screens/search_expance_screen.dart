import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expence_provider.dart';

class SearchExpensesScreen extends StatefulWidget {
  const SearchExpensesScreen({super.key});

  @override
  State<SearchExpensesScreen> createState() => _SearchExpensesScreenState();
}

class _SearchExpensesScreenState extends State<SearchExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  String _searchQuery = '';
  double _minAmount = 0;
  double _maxAmount = 1000000;
  bool _showFilters = false;

  // 🔥 Cache for expenses - fetched only once
  List<Map<String, dynamic>>? _allExpenses;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllExpensesOnce(); // 🔥 Fetch once when screen opens
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  // 🔥 ONE-TIME FETCH - Called only once
  Future<void> _fetchAllExpensesOnce() async {
    final provider = context.read<ExpenseProvider>();

    try {
      // Fetch using provider method (you can add this to your provider)
      final expenses = await provider.getAllExpensesForSearch();

      setState(() {
        _allExpenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allExpenses = [];
        _isLoading = false;
      });
    }
  }

  // 🔥 LOCAL SEARCH - No Firebase calls
  List<Map<String, dynamic>> _getFilteredExpenses() {
    if (_allExpenses == null) return [];

    return _allExpenses!.where((expense) {
      final title = (expense['title'] as String).toLowerCase();
      final description = (expense['description'] as String).toLowerCase();
      final amount = expense['amount'] as double;

      // Search query filter
      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          description.contains(_searchQuery);

      // Amount filter
      final matchesAmount = amount >= _minAmount && amount <= _maxAmount;

      return matchesSearch && matchesAmount;
    }).toList();
  }

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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search expenses...",
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          // Clear search button
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters ? const Color(0xFF64FFDA) : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),

          // Search Results
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF64FFDA)),
                  SizedBox(height: 16),
                  Text(
                    "Loading expenses...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_allExpenses == null || _allExpenses!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              "No expenses found",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    final filteredExpenses = _getFilteredExpenses();

    if (filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? "No matches found"
                  : "No results for '$_searchQuery'",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try adjusting your filters",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results count and summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${filteredExpenses.length} result${filteredExpenses.length == 1 ? '' : 's'} found",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total: ₹${_calculateTotal(filteredExpenses).toStringAsFixed(0)}",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_searchQuery.isNotEmpty || _minAmount > 0 || _maxAmount < 1000000)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _minController.clear();
                      _maxController.clear();
                      _searchQuery = '';
                      _minAmount = 0;
                      _maxAmount = 1000000;
                      _showFilters = false;
                    });
                  },
                  icon: const Icon(
                    Icons.clear_all,
                    size: 16,
                    color: Color(0xFF64FFDA),
                  ),
                  label: const Text(
                    "Clear All",
                    style: TextStyle(color: Color(0xFF64FFDA)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredExpenses.length,
            itemBuilder: (context, index) {
              final expense = filteredExpenses[index];
              return _buildExpenseCard(expense);
            },
          ),
        ),
      ],
    );
  }

  double _calculateTotal(List<Map<String, dynamic>> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + (expense['amount'] as double));
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Amount Range",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_minAmount > 0 || _maxAmount < 1000000)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minController.clear();
                      _maxController.clear();
                      _minAmount = 0;
                      _maxAmount = 1000000;
                    });
                  },
                  child: const Text(
                    "Reset",
                    style: TextStyle(color: Color(0xFF64FFDA)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Min Amount",
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    prefixText: "₹",
                    prefixStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _minAmount = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Max Amount",
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    prefixText: "₹",
                    prefixStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _maxAmount = double.tryParse(value) ?? 1000000;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final title = expense['title'] as String;
    final amount = expense['amount'] as double;
    final description = expense['description'] as String;
    final dateId = expense['dateId'] as String;
    final timestamp = expense['createdAt'] as Timestamp?;

    String dateStr = '';
    if (timestamp != null) {
      dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    } else {
      try {
        final date = DateTime.parse(dateId);
        dateStr = DateFormat('dd MMM yyyy').format(date);
      } catch (e) {
        dateStr = dateId;
      }
    }

    // Highlight search matches
    final highlightedTitle = _highlightText(title, _searchQuery);
    final highlightedDesc = description.isNotEmpty
        ? _highlightText(description, _searchQuery)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: highlightedTitle,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF64FFDA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF64FFDA).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  "₹${amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Color(0xFF64FFDA),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (highlightedDesc != null) ...[
            const SizedBox(height: 8),
            highlightedDesc,
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔥 Highlight search matches
  Widget _highlightText(String text, String query) {
    final isDescription = text.length > 50; // Determine if it's description

    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isDescription ? Colors.grey[400] : Colors.white,
          fontSize: isDescription ? 14 : 16,
          fontWeight: isDescription ? FontWeight.normal : FontWeight.bold,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        style: TextStyle(
          color: isDescription ? Colors.grey[400] : Colors.white,
          fontSize: isDescription ? 14 : 16,
          fontWeight: isDescription ? FontWeight.normal : FontWeight.bold,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, index),
            style: TextStyle(
              color: isDescription ? Colors.grey[400] : Colors.white,
              fontSize: isDescription ? 14 : 16,
              fontWeight: isDescription ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              color: const Color(0xFF64FFDA),
              fontSize: isDescription ? 14 : 16,
              fontWeight: FontWeight.bold,
              backgroundColor: const Color(0xFF64FFDA).withOpacity(0.2),
            ),
          ),
          TextSpan(
            text: text.substring(index + query.length),
            style: TextStyle(
              color: isDescription ? Colors.grey[400] : Colors.white,
              fontSize: isDescription ? 14 : 16,
              fontWeight: isDescription ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}