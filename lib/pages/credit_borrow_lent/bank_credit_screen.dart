import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/credit_model.dart';
import '../../providers/bank_provider.dart';
import '../../providers/credit_provider.dart';

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
class _BorrowTab extends StatelessWidget {
  const _BorrowTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BankCreditProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.borrow.isEmpty) {
      return const _EmptyState('No borrowed money');
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
            // YOU will connect this to Expense flow
            provider.completeBorrow(
              credit: credit,
              context: context,
              payBorrowAsExpense: () async {
                // Call your existing expense flow here
              },
            );
          },
        );
      },
    );
  }
}
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
      return const _EmptyState('No lent money');
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
          onAction: () async {
            await creditProvider.receiveLent(
              credit: credit,
              bankProvider: bankProvider,
            );
          },
        );
      },
    );
  }
}
class _CompletedTab extends StatelessWidget {
  const _CompletedTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BankCreditProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.completed.isEmpty) {
      return const _EmptyState('No completed credits');
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            credit.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
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
          const SizedBox(height: 10),
          if (showAction)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ),
        ],
      ),
    );
  }
}
class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
