import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/indian_number_formatter.dart';
import '../widgets/edit_bank_month_dialog.dart';
import '../../data/model/bank_model.dart';
import '../../data/model/bank_month_entry_model.dart';
import '../../data/model/bank_month_model.dart';
import '../provider/bank_provider.dart';
import '../widgets/bank_transfer_dialog.dart';
import 'bank_analysis_screen.dart';

class BankAccountPage extends StatefulWidget {
  final BankModel bank;

  const BankAccountPage({super.key, required this.bank});

  @override
  State<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends State<BankAccountPage> {
  String get _currentMonthId {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    // 🔥 Start listening ONCE
    context.read<BankProvider>().listenBankMonths(widget.bank.id);
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
        title: Row(
          children: [
            const Icon(Icons.account_balance, color: Color(0xFF64FFDA)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.bank.bankName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF64FFDA),
        foregroundColor: const Color(0xFF121212),
        onPressed: () {
          showAddMonthAmountDialog(context, widget.bank);
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Amount',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Selector<BankProvider, List<BankMonthModel>>(
        selector: (_, p) => p.getBankMonths(widget.bank.id),
        builder: (context, months, _) {
          if (months.isEmpty) {
            return _buildEmptyState();
          }
          return _buildMonthList(months);
        },
      ),
    );
  }

  // 🎨 Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first amount to get started',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 📋 Month List
  Widget _buildMonthList(List<BankMonthModel> months) {
    return Column(
      children: [
        // 💰 Current Balance Banner
        Selector<BankProvider, BankMonthModel?>(
          selector: (_, p) => p
              .getBankMonths(widget.bank.id)
              .firstWhere(
                (m) => m.id == _currentMonthId,
                orElse: () => BankMonthModel(
                  id: _currentMonthId,
                  totalAdded: 0,
                  currentAmount: 0,
                  surplusPreviousMonth: 0,
                  incomeThisMonth: 0,
                ),
              ),
          builder: (context, month, _) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF2A5298)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Month Balance',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${month!.currentAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ➕ Add Surplus Button
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<BankProvider>()
                              .ensureBankMonthExistsWithDialog(
                                bankId: widget.bank.id,
                                monthId: _currentMonthId,
                                context: context,
                                showWaring: true,
                              );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Surplus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.shade400,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _BankInfoChip(
                        icon: Icons.trending_up,
                        label: 'Income (This Month)',
                        value: '₹${month.incomeThisMonth.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 12),
                      _BankInfoChip(
                        icon: Icons.history,
                        label: 'Surplus',
                        value:
                            '₹${month.surplusPreviousMonth.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BankNavigationCard(
                    icon: Icons.history,
                    title: 'Bank Expense Details',
                    subtitle: 'View detailed bank-wise expenses',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BankAnalysisScreen(bank: widget.bank),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _BankNavigationCard(
                    icon: Icons.comment_bank,
                    title: 'Self transfer',
                    subtitle: 'Transfer your bank amount to other',
                    onTap: () {
                      showBankTransferDialog(context, widget.bank);
                    },
                  ),
                ],
              ),
            );
          },
        ),

        // 📅 Month Records Title
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF64FFDA), size: 20),
              const SizedBox(width: 8),
              Text(
                'Transaction History',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF64FFDA).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${months.length} ${months.length == 1 ? 'Month' : 'Months'}',
                  style: const TextStyle(
                    color: Color(0xFF64FFDA),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 🗓️ Month Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: months.length,
            itemBuilder: (_, i) {
              return _MonthCard(month: months[i], bankId: widget.bank.id);
            },
          ),
        ),
      ],
    );
  }

  void showBankActionsBottomSheet(
    BuildContext context, {
    required BankModel bank,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🔹 Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔹 Title
                const Text(
                  'Bank Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// ➕ Add Amount
                _ActionTile(
                  icon: Icons.add_circle_rounded,
                  iconColor: const Color(0xFF64FFDA),
                  title: 'Add Amount',
                  subtitle: 'Add money to this bank',
                  onTap: () {
                    Navigator.pop(context);
                    showAddMonthAmountDialog(context, bank);
                  },
                ),

                const Divider(color: Color(0xFF2C2C2C)),

                /// 🔄 Transfer Money
                _ActionTile(
                  icon: Icons.swap_horiz_rounded,
                  iconColor: Colors.orangeAccent,
                  title: 'Transfer Money',
                  subtitle: 'Move funds to another bank',
                  onTap: () {
                    Navigator.pop(context);
                    showBankTransferDialog(context, bank);
                  },
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showBankTransferDialog(
    BuildContext context,
    BankModel currentBank,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BankTransferDialog(currentBank: currentBank),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }
}

class _BankNavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BankNavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF64FFDA).withOpacity(0.18),
              const Color(0xFF64FFDA).withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF64FFDA).withOpacity(0.35)),
        ),
        child: Row(
          children: [
            // 🔹 Icon badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF64FFDA)),
            ),

            const SizedBox(width: 12),

            // 🔹 Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),

            // 🔹 Arrow
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF64FFDA),
            ),
          ],
        ),
      ),
    );
  }
}

// 📊 Bank Info Chip
class _BankInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BankInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64FFDA), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
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

// 🗓️ Month Card with Expandable Entries
class _MonthCard extends StatefulWidget {
  final BankMonthModel month;
  final String bankId;

  const _MonthCard({required this.month, required this.bankId});

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF64FFDA).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              if (_isExpanded) {
                context.read<BankProvider>().listenMonthEntries(
                  bankId: widget.bankId,
                  monthId: widget.month.id,
                );
              } else {
                context.read<BankProvider>().stopListeningMonthEntries(
                  widget.bankId,
                  widget.month.id,
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64FFDA).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF64FFDA),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatMonthId(widget.month.id),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => EditBankMonthDialog(
                              bankId: widget.bankId,
                              month: widget.month,
                            ),
                          );
                        },
                        child: Icon(Icons.edit, color: Colors.redAccent),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF64FFDA),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[800], thickness: 1),
                  const SizedBox(height: 12),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          icon: Icons.add_circle_outline,
                          label: 'Added',
                          value:
                              '₹${widget.month.totalAdded.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[800]),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.add_circle_outline,
                          label: 'This Month Added',
                          value:
                              '₹${widget.month.incomeThisMonth.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[800]),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.account_balance_wallet,
                          label: 'Balance',
                          value:
                              '₹${widget.month.currentAmount.toStringAsFixed(2)}',
                          color: const Color(0xFF64FFDA),
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[800]),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.account_balance_wallet,
                          label: 'surplus',
                          value:
                              '₹${widget.month.surplusPreviousMonth.toStringAsFixed(2)}',
                          color: const Color(0xFF64FFDA),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable Entries Section
          if (_isExpanded)
            Selector<BankProvider, List<BankMonthEntry>>(
              selector: (_, p) =>
                  p.getMonthEntries(widget.bankId, widget.month.id),
              builder: (_, entries, __) {
                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No entries',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF121212),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Transactions (${entries.length})',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Colors.grey[800], height: 1),
                        itemBuilder: (_, i) {
                          return _EntryTile(entry: entries[i]);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatMonthId(String monthId) {
    try {
      final parts = monthId.split('-');
      final year = parts[0];
      final monthNum = int.parse(parts[1]);
      final months = [
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
        'December',
      ];
      return '${months[monthNum - 1]} $year';
    } catch (e) {
      return monthId;
    }
  }
}

// 📝 Entry Tile
// Replace your existing _EntryTile widget with this updated version

class _EntryTile extends StatelessWidget {
  final BankMonthEntry entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTransferOut = entry.type == 'transfer_out';
    final isTransferIn = entry.type == 'transfer_in';
    final isTransfer = isTransferOut || isTransferIn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon based on type
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTransferOut
                  ? Colors.orange.withOpacity(0.15)
                  : (isTransferIn
                        ? Colors.blue.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isTransferOut
                  ? Icons.arrow_forward_rounded
                  : (isTransferIn
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_upward),
              color: isTransferOut
                  ? Colors.orange
                  : (isTransferIn ? Colors.blue : Colors.green),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '₹${entry.amount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isTransferOut ? Colors.orange : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isTransfer) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isTransferOut
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isTransferOut ? 'OUT' : 'IN',
                          style: TextStyle(
                            color: isTransferOut ? Colors.orange : Colors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.description,
                  style: TextStyle(
                    color: isTransfer ? Colors.grey[400] : Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatEntryDate(entry.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),

                // Show related bank for transfers
                if (isTransfer) ...[
                  const SizedBox(height: 4),
                  Selector<BankProvider, String>(
                    selector: (_, provider) {
                      final bankId = isTransferOut
                          ? entry.targetBankId
                          : entry.sourceBankId;
                      return provider.getTransactionBankName(bankId);
                    },
                    builder: (_, bankName, __) {
                      return Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            color: Colors.grey[600],
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTransferOut ? 'To: $bankName' : 'From: $bankName',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEntryDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// 📈 Stat Item
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// 💬 Add Amount Dialog
// 💬 Add Amount Dialog
Future<void> showAddMonthAmountDialog(
  BuildContext context,
  BankModel bank,
) async {
  final formKey = GlobalKey<FormState>();
  final amountCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController(); // 🆕
  bool isLoading = false;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64FFDA).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_circle, color: Color(0xFF64FFDA)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Amount',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Selector<BankProvider, double>(
                    selector: (_, p) {
                      final month = p
                          .getBankMonths(bank.id)
                          .firstWhere(
                            (m) =>
                                m.id ==
                                '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
                            orElse: () => BankMonthModel(
                              id: '',
                              totalAdded: 0,
                              currentAmount: 0,
                              surplusPreviousMonth: 0,
                              incomeThisMonth: 0,
                            ),
                          );
                      return month.currentAmount;
                    },
                    builder: (_, balance, __) {
                      return Text(
                        'Current Balance: ₹${balance.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 💰 Amount
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      IndianNumberFormatter(),
                    ],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      labelStyle: const TextStyle(color: Color(0xFF64FFDA)),
                      hintText: 'Enter amount to add',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(
                        Icons.currency_rupee,
                        color: Color(0xFF64FFDA),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF64FFDA),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter amount';
                      }
                      final cleanValue = v.replaceAll(',', '');
                      final amount = double.tryParse(cleanValue);
                      if (amount == null) {
                        return 'Enter valid amount';
                      }
                      if (amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // 📝 Description (NEW)
                  TextFormField(
                    controller: descriptionCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: const TextStyle(color: Color(0xFF64FFDA)),
                      hintText: 'e.g. Salary, Cashback, Adjustment',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(
                        Icons.notes,
                        color: Color(0xFF64FFDA),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF64FFDA),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64FFDA),
                  foregroundColor: const Color(0xFF121212),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() => isLoading = true);

                        try {
                          final cleanAmount = amountCtrl.text.replaceAll(
                            ',',
                            '',
                          );

                          await context.read<BankProvider>().addMonthAmount(
                            bankId: bank.id,
                            amount: double.parse(cleanAmount),
                            description: descriptionCtrl.text.trim(), // 🆕
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Amount added successfully'),
                                backgroundColor: Color(0xFF64FFDA),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF121212)),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Add',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}
