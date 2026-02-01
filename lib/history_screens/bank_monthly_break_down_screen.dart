import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bank_model.dart';
import '../models/bank_month_entry_model.dart';
import '../models/bank_month_model.dart';
import '../providers/bank_provider.dart';

class BankMonthlyBreakdownScreen extends StatefulWidget {
  final String year;

  const BankMonthlyBreakdownScreen({super.key, required this.year});

  @override
  State<BankMonthlyBreakdownScreen> createState() =>
      _BankMonthlyBreakdownScreenState();
}

class _BankMonthlyBreakdownScreenState
    extends State<BankMonthlyBreakdownScreen> {
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<BankProvider>();
    provider.listenBanks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A0E27),
        iconTheme: const IconThemeData(color: Color(0xFFE8EAED)),
        title: Text(
          '${_getMonthName(DateTime.now().month)} ${widget.year}',
          style: const TextStyle(
            color: Color(0xFFE8EAED),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Selector<BankProvider, List<BankModel>>(
        selector: (_, p) => p.banks,
        builder: (_, banks, __) {
          if (banks.isEmpty) {
            return const Center(
              child: Text(
                'No banks found',
                style: TextStyle(color: Color(0xFF9AA0A6)),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Financial Overview Card
              _FinancialOverviewCard(year: widget.year),
              const SizedBox(height: 24),

              // Section Header
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Bank Accounts',
                  style: TextStyle(
                    color: Color(0xFFE8EAED),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Bank cards
              ...List.generate(
                banks.length,
                    (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BankAccountCard(
                    bank: banks[i],
                    year: widget.year,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FINANCIAL OVERVIEW CARD
// ═══════════════════════════════════════════════════════════════════════════

class _FinancialOverviewCard extends StatelessWidget {
  final String year;

  const _FinancialOverviewCard({required this.year});

  @override
  Widget build(BuildContext context) {
    return Consumer<BankProvider>(
      builder: (context, provider, _) {
        final thisMonthTotal = provider.getTotalMonthAmountOfThisMonth();
        final totalSurplus = provider.getTotalThisMonthSurplus();
        final currentAmount = provider.getTotalCurrentAmountMonthAmountOfThisMonth() ?? 0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2333),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2D3748),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Financial Overview',
                    style: TextStyle(
                      color: Color(0xFFE8EAED),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current Balance (Primary Metric)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        color: Color(0xFF9AA0A6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${currentAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'This Month Initial',
                      value: '₹${thisMonthTotal.toStringAsFixed(0)}',
                      valueColor: thisMonthTotal >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      icon: Icons.arrow_upward_rounded,
                      iconColor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Previous Surplus',
                      value: '₹${totalSurplus.toStringAsFixed(0)}',
                      valueColor: totalSurplus >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Additional Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3748).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF60A5FA),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Net Position: ₹${(currentAmount - totalSurplus).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF9AA0A6),
                          fontSize: 12,
                        ),
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
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF374151),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9AA0A6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BANK ACCOUNT CARD
// ═══════════════════════════════════════════════════════════════════════════

class _BankAccountCard extends StatefulWidget {
  final BankModel bank;
  final String year;

  const _BankAccountCard({
    required this.bank,
    required this.year,
  });

  @override
  State<_BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<_BankAccountCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    final monthId =
        '${widget.year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    context.read<BankProvider>().listenBankMonths(widget.bank.id);
    context.read<BankProvider>().listenMonthEntries(
      bankId: widget.bank.id,
      monthId: monthId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthId =
        '${widget.year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    return Selector<BankProvider, BankMonthModel?>(
      selector: (_, p) {
        final months = p.getBankMonths(widget.bank.id);
        try {
          return months.firstWhere((m) => m.id == monthId);
        } catch (_) {
          return null;
        }
      },
      builder: (_, month, __) {
        if (month == null) {
          return const SizedBox();
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C2333),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2D3748),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Bank Header
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Bank Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Bank Name & Balance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bank.bankName,
                              style: const TextStyle(
                                color: Color(0xFFE8EAED),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Amount: ₹${month.totalAdded.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stats
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${month.currentAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Selector<BankProvider, double>(
                            selector: (_, p) => p.getSurplus(
                              bankId: widget.bank.id,
                              monthId: month.id,
                            ),
                            builder: (context, surplus, _) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (surplus >= 0
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  surplus >= 0 ? '+₹${surplus.toStringAsFixed(0)}' : '₹${surplus.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: surplus >= 0
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFEF4444),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(width: 12),

                      // Expand Icon
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF9AA0A6),
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              if (_isExpanded)
                Container(
                  height: 1,
                  color: const Color(0xFF2D3748),
                ),

              // Month Details (Expandable)
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Month Stats
                      _MonthStatRow(
                        icon: Icons.savings_rounded,
                        label: 'Current Amount',
                        value: '₹${month.currentAmount.toStringAsFixed(0)}',
                        valueColor: const Color(0xFF60A5FA),
                      ),
                      const SizedBox(height: 12),
                      _MonthStatRow(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Income This Month',
                        value: '₹${month.incomeThisMonth.toStringAsFixed(0)}',
                        valueColor: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 12),
                      _MonthStatRow(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Total Added',
                        value: '₹${month.totalAdded.toStringAsFixed(0)}',
                        valueColor: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 12),
                      _MonthStatRow(
                        icon: Icons.savings_rounded,
                        label: 'Previous Surplus',
                        value: '₹${month.surplusPreviousMonth.toStringAsFixed(0)}',
                        valueColor: const Color(0xFF60A5FA),
                      ),
                      const SizedBox(height: 20),

                      // Transaction History Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Transaction History',
                            style: TextStyle(
                              color: Color(0xFFE8EAED),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Entries List
                      _TransactionsList(
                        bankId: widget.bank.id,
                        monthId: month.id,
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

  @override
  void dispose() {
    context.read<BankProvider>().stopListeningMonthEntries(
      widget.bank.id,
      '${widget.year}-${DateTime.now().month.toString().padLeft(2, '0')}',
    );
    super.dispose();
  }
}

class _MonthStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _MonthStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9AA0A6), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9AA0A6),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRANSACTIONS LIST
// ═══════════════════════════════════════════════════════════════════════════

class _TransactionsList extends StatelessWidget {
  final String bankId;
  final String monthId;

  const _TransactionsList({
    required this.bankId,
    required this.monthId,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<BankProvider, List<BankMonthEntry>>(
      selector: (_, p) => p.getMonthEntries(bankId, monthId),
      builder: (_, entries, __) {
        if (entries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3748).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(
                  color: Color(0xFF9AA0A6),
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D3748).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => Container(
              height: 1,
              color: const Color(0xFF374151),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            itemBuilder: (_, i) {
              final e = entries[i];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.description ?? 'No description',
                            style: const TextStyle(
                              color: Color(0xFFE8EAED),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(e.createdAt.toDate()),
                            style: const TextStyle(
                              color: Color(0xFF9AA0A6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+₹${e.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (entryDate == yesterday) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}