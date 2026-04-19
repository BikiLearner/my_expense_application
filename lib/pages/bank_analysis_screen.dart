import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../enums/expense_type.dart';
import '../models/bank_model.dart';
import '../expense_home/models/expense_items.dart';
import '../providers/bank_expense_analysis_provider.dart';

class BankAnalysisScreen extends StatefulWidget {
  final BankModel bank;

  const BankAnalysisScreen({
    super.key,
    required this.bank,
  });

  @override
  State<BankAnalysisScreen> createState() => _BankAnalysisScreenState();
}

class _BankAnalysisScreenState extends State<BankAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late BankAnalysisProvider _provider;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _provider = BankAnalysisProvider();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize with bank data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.initialize(widget.bank);
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: _buildAppBar(),
        body: Selector<BankAnalysisProvider, bool>(
          selector: (_, provider) => provider.isLoading,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return _buildLoadingState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<BankAnalysisProvider>().fetchAnalysis(widget.bank);
                _animationController.reset();
                _animationController.forward();
              },
              color: const Color(0xFF64FFDA),
              backgroundColor: const Color(0xFF1C1F33),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildMonthYearSelector(),
                          const SizedBox(height: 20),
                          _buildSummaryCard(),
                          const SizedBox(height: 20),
                          _buildBankSection(),
                          const SizedBox(height: 16),
                          _buildCashSection(),
                          const SizedBox(height: 16),
                          _buildUnknownSection(),
                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1F33),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64FFDA).withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(Color(0xFF64FFDA)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing expenses...',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1C1F33),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.bank.bankName,
            style: const TextStyle(
              color: Color(0xFF64FFDA),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Selector<BankAnalysisProvider, bool>(
          selector: (_, provider) => provider.isLoading,
          builder: (context, isLoading, _) {
            return IconButton(
              icon: AnimatedRotation(
                turns: isLoading ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: const Icon(Icons.refresh_rounded, color: Color(0xFF64FFDA)),
              ),
              onPressed: isLoading
                  ? null
                  : () => context.read<BankAnalysisProvider>().fetchAnalysis(widget.bank),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthYearSelector() {
    return Selector<BankAnalysisProvider, DateTime>(
      selector: (_, provider) => provider.selectedDate,
      builder: (context, selectedDate, _) {
        final provider = context.read<BankAnalysisProvider>();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1C1F33),
                const Color(0xFF1C1F33).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF64FFDA).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64FFDA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF64FFDA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Period',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      provider.resetToCurrentMonth();
                      provider.fetchAnalysis(widget.bank);
                    },
                    icon: const Icon(
                      Icons.today_rounded,
                      color: Color(0xFF64FFDA),
                      size: 16,
                    ),
                    label: const Text(
                      'Today',
                      style: TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: const Color(0xFF64FFDA).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Year & Month Dropdowns
              Row(
                children: [
                  // Year Dropdown
                  Expanded(
                    child: _buildStyledDropdown<int>(
                      value: selectedDate.year,
                      icon: Icons.event_rounded,
                      items: List.generate(10, (i) => DateTime.now().year - 5 + i)
                          .map((year) => DropdownMenuItem(
                        value: year,
                        child: Text(
                          year.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (year) {
                        if (year != null) {
                          provider.setYear(year);
                          provider.fetchAnalysis(widget.bank);
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Month Dropdown
                  Expanded(
                    flex: 2,
                    child: _buildStyledDropdown<int>(
                      value: selectedDate.month,
                      icon: Icons.calendar_month_rounded,
                      items: List.generate(12, (i) => i + 1)
                          .map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(
                          provider.getMonthName(month),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (month) {
                        if (month != null) {
                          provider.setMonth(month);
                          provider.fetchAnalysis(widget.bank);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Month Navigation Arrows
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNavigationButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () {
                      provider.previousMonth();
                      provider.fetchAnalysis(widget.bank);
                    },
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64FFDA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF64FFDA).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      DateFormat('MMM yyyy').format(selectedDate),
                      style: const TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildNavigationButton(
                    icon: Icons.chevron_right_rounded,
                    onPressed: () {
                      provider.nextMonth();
                      provider.fetchAnalysis(widget.bank);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyledDropdown<T>({
    required T value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF64FFDA).withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF64FFDA).withOpacity(0.7),
          ),
          dropdownColor: const Color(0xFF1C1F33),
          borderRadius: BorderRadius.circular(14),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: const Color(0xFF64FFDA).withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: const Color(0xFF64FFDA),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Selector<BankAnalysisProvider, (double, int)>(
      selector: (_, provider) => (provider.totalMonthExpense, provider.totalTransactions),
      builder: (context, data, _) {
        final (totalExpense, totalTransactions) = data;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expenses',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'This Month',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '₹${totalExpense.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$totalTransactions transactions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankSection() {
    return Selector<BankAnalysisProvider, BankExpenseAnalysis?>(
      selector: (_, provider) => provider.bankAnalysis[widget.bank.id],
      builder: (context, analysis, _) {
        if (analysis == null) {
          return _buildEmptyCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'No ${widget.bank.bankName} Expenses',
            subtitle: 'No transactions found for this month',
            gradient: const LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
            ),
          );
        }

        return _buildAnalysisCard(
          analysis: analysis,
          icon: Icons.account_balance_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          ),
        );
      },
    );
  }

  Widget _buildCashSection() {
    return Selector<BankAnalysisProvider, BankExpenseAnalysis?>(
      selector: (_, provider) => provider.cashAnalysis,
      builder: (context, analysis, _) {
        if (analysis == null) return const SizedBox.shrink();

        return _buildAnalysisCard(
          analysis: analysis,
          icon: Icons.payments_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
          ),
        );
      },
    );
  }

  Widget _buildUnknownSection() {
    return Selector<BankAnalysisProvider, BankExpenseAnalysis?>(
      selector: (_, provider) => provider.unknownAnalysis,
      builder: (context, analysis, _) {
        if (analysis == null) return const SizedBox.shrink();

        return _buildAnalysisCard(
          analysis: analysis,
          icon: Icons.help_outline_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          ),
          showWarning: true,
        );
      },
    );
  }

  Widget _buildAnalysisCard({
    required BankExpenseAnalysis analysis,
    required IconData icon,
    required Gradient gradient,
    bool showWarning = false,
  }) {
    return Selector<BankAnalysisProvider, double>(
      selector: (_, provider) => provider.getPercentage(analysis.totalExpense),
      builder: (context, percentage, _) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1F33),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: showWarning
                  ? Colors.orangeAccent.withOpacity(0.4)
                  : const Color(0xFF64FFDA).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: gradient.scale(0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            analysis.bankName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (showWarning)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '⚠️ Missing type',
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => gradient.createShader(bounds),
                          child: Text(
                            '₹${analysis.totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white60,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${analysis.transactionCount} transactions',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0E21),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Expenses List
              if (analysis.expenses.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Color(0xFF2C3E50), height: 1),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: analysis.expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildExpenseItem(analysis.expenses[index]);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseItem(ExpenseItem expense) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _getTypeColor(expense.type).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTypeColor(expense.type).withOpacity(0.3),
                  _getTypeColor(expense.type).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTypeIcon(expense.type),
              color: _getTypeColor(expense.type),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (expense.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    expense.description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white38,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(expense.createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF64FFDA), Color(0xFF00BCD4)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '₹${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF0A0E21),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF64FFDA).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient.scale(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white70, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(ExpenseType type) {
    switch (type) {
      case ExpenseType.luxury:
        return Icons.diamond_rounded;
      case ExpenseType.needed:
        return Icons.shopping_bag_rounded;
      case ExpenseType.saving:
        return Icons.trending_up_rounded;
    }
  }

  Color _getTypeColor(ExpenseType type) {
    switch (type) {
      case ExpenseType.luxury:
        return const Color(0xFFB794F6);
      case ExpenseType.needed:
        return const Color(0xFF63B3ED);
      case ExpenseType.saving:
        return const Color(0xFF68D391);
    }
  }
}

// Extension to scale gradient opacity
extension GradientScale on Gradient {
  Gradient scale(double factor) {
    if (this is LinearGradient) {
      final lg = this as LinearGradient;
      return LinearGradient(
        colors: lg.colors.map((c) => c.withOpacity(factor)).toList(),
        begin: lg.begin,
        end: lg.end,
      );
    }
    return this;
  }
}