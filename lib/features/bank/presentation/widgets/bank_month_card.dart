import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/bank_month_entry_model.dart';
import '../../data/model/bank_month_model.dart';
import '../provider/bank_provider.dart';
import 'edit_bank_month_dialog.dart';

class MonthCard extends StatefulWidget {
  final BankMonthModel month;
  final String bankId;

  const MonthCard({required this.month, required this.bankId});

  @override
  State<MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<MonthCard> {
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
              if(!_isExpanded) {
                context.read<BankProvider>().fetchBankMonthEntries(
                  bankId: widget.bankId,
                  monthId: widget.month.id,
                );
              }
              setState(() {
                _isExpanded = !_isExpanded;
              });
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
