import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/credit_model.dart';
import '../../providers/bank_provider.dart';
import '../../providers/credit_provider.dart';
import '../../expense_home/provider/expence_provider.dart';

class BankCreditScreen extends StatelessWidget {
  const BankCreditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          title: const Text('Credit'),
          bottom: const TabBar(
            indicatorColor: Color(0xFF64FFDA),
            tabs: [
              Tab(text: 'Borrow'),
              Tab(text: 'Lent'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BorrowTab(),
            _LentTab(),
            _CompletedTab(),
          ],
        ),
      ),
    );
  }
}

//
// ───────────────── BORROW TAB ─────────────────
//
class _BorrowTab extends StatelessWidget {
  const _BorrowTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BankCreditProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.borrow.isEmpty) {
      return const _EmptyState(
        text: 'No borrowed money',
        subtitle: 'Track money you owe clearly here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.borrow.length,
      itemBuilder: (_, i) {
        final credit = provider.borrow[i];
        return _CreditCard(
          credit: credit,
          actionText: 'Pay',
          actionColor: Colors.orangeAccent,
          onAction: () {
            showConfirmAction(
              context: context,
              title: 'Pay Borrowed Amount?',
              message:
              'This will mark the borrow as completed and record an expense.',
              onConfirm: () {
                provider.completeBorrow(
                  credit: credit,
                  payAsExpense: () async {
                    await context.read<ExpenseProvider>().addExpense(context);
                  }
                );
              },
            );
          },
        );
      },
    );
  }
}

//
// ───────────────── LENT TAB ─────────────────
//
class _LentTab extends StatelessWidget {
  const _LentTab();

  @override
  Widget build(BuildContext context) {
    final creditProvider = context.watch<BankCreditProvider>();
    final bankProvider = context.read<BankProvider>();

    if (creditProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (creditProvider.lent.isEmpty) {
      return const _EmptyState(
        text: 'No lent money',
        subtitle: 'Money you give will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: creditProvider.lent.length,
      itemBuilder: (_, i) {
        final credit = creditProvider.lent[i];
        return _CreditCard(
          credit: credit,
          actionText: 'Receive',
          actionColor: Colors.greenAccent,
          onAction: () {
            showConfirmAction(
              context: context,
              title: 'Receive Lent Money?',
              message:
              'This will add money back to your bank and close this credit.',
              onConfirm: () async {
                await creditProvider.receiveLent(
                  credit: credit,
                  bankProvider: bankProvider,
                );
              },
            );
          },
        );
      },
    );
  }
}

//
// ───────────────── COMPLETED TAB ─────────────────
//
class _CompletedTab extends StatelessWidget {
  const _CompletedTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BankCreditProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.completed.isEmpty) {
      return const _EmptyState(
        text: 'No completed credits',
        subtitle: 'Closed credits will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.completed.length,
      itemBuilder: (_, i) {
        final credit = provider.completed[i];
        return _CreditCard(
          credit: credit,
          showAction: false,
        );
      },
    );
  }
}

//
// ───────────────── CREDIT CARD ─────────────────
//
class _CreditCard extends StatelessWidget {
  final BankCredit credit;
  final String? actionText;
  final Color? actionColor;
  final VoidCallback? onAction;
  final bool showAction;

  const _CreditCard({
    required this.credit,
    this.actionText,
    this.actionColor,
    this.onAction,
    this.showAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = credit.status == CreditStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF1A1A1A)
            : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: isCompleted
            ? Border.all(color: Colors.green.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  credit.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(credit.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${credit.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF64FFDA),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showAction) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

//
// ───────────────── STATUS CHIP ─────────────────
//
class _StatusChip extends StatelessWidget {
  final CreditStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = status == CreditStatus.completed
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

//
// ───────────────── EMPTY STATE ─────────────────
//
class _EmptyState extends StatelessWidget {
  final String text;
  final String subtitle;

  const _EmptyState({
    required this.text,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

//
// ───────────────── CONFIRMATION SHEET ─────────────────
//
Future<void> showConfirmAction({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
