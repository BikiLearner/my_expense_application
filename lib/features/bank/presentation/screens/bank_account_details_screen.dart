import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/shared/dialogs/app_loader_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/indian_number_formatter.dart';
import '../../data/model/bank_model.dart';
import '../../data/model/bank_month_entry_model.dart';
import '../../data/model/bank_month_model.dart';
import '../provider/bank_provider.dart';
import '../widgets/bank_details_navigation_card.dart';
import '../widgets/bank_info_chip.dart';
import '../widgets/bank_month_card.dart';
import '../widgets/bank_transfer_dialog.dart';
import '../widgets/edit_bank_month_dialog.dart';
import 'bank_analysis_screen.dart';

class BankAccountDetailScreen extends StatefulWidget {
  final BankModel bank;

  const BankAccountDetailScreen({super.key, required this.bank});

  @override
  State<BankAccountDetailScreen> createState() => _BankAccountDetailScreenState();
}

class _BankAccountDetailScreenState extends State<BankAccountDetailScreen> {
  String get _currentMonthId {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
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
                          AppLoader.show(context, message: "Init bank");
                          context
                              .read<BankProvider>()
                              .ensureBankMonthExistsWithDialog(
                                bankId: widget.bank.id,
                                context: context,
                                showWaring: true,
                              );
                          AppLoader.hide();
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
                      BankInfoChip(
                        icon: Icons.trending_up,
                        label: 'Income (This Month)',
                        value: '₹${month.incomeThisMonth.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 12),
                      BankInfoChip(
                        icon: Icons.history,
                        label: 'Surplus',
                        value:
                            '₹${month.surplusPreviousMonth.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BankNavigationCard(
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
                  BankNavigationCard(
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
              return MonthCard(month: months[i], bankId: widget.bank.id);
            },
          ),
        ),
      ],
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



// 🗓️ Month Card with Expandable Entries

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
                            description: descriptionCtrl.text.trim(),
                            context: context, // 🆕
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
