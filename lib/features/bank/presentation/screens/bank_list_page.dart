import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/bank_model.dart';
import '../../data/model/bank_month_model.dart';
import '../provider/bank_provider.dart';
import 'bank_form_page.dart';
import 'bank_account_details_screen.dart';

class BankPage extends StatefulWidget {
  const BankPage({super.key});

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.account_balance, color: Color(0xFF64FFDA)),
            const SizedBox(width: 12),
            const Text(
              'My Banks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF64FFDA),
        foregroundColor: const Color(0xFF121212),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BankFormPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Bank',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Selector<BankProvider, _BankListState>(
        selector: (_, provider) =>
            _BankListState(provider.isLoading, provider.banks),
        builder: (context, state, _) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          if (state.banks.isEmpty) {
            return _buildEmptyState();
          }

          return _buildBankList(state.banks);
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
            Icons.account_balance_outlined,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No banks added yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first bank account',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 📋 Bank List with Total Summary
  Widget _buildBankList(List<BankModel> banks) {
    final provider = context.read<BankProvider>();
    final totalBalance = banks.fold<double>(0.0, (sum, bank) {
      final month = provider.getCurrentMonthForBank(bank.id);
      return sum + (month?.currentAmount ?? 0);
    });

    return Column(
      children: [
        // 💰 Total Balance Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${totalBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${banks.length} ${banks.length == 1 ? 'Bank' : 'Banks'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 🏦 Bank Cards List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banks.length,
            itemBuilder: (_, i) {
              return _BankCard(bank: banks[i]);
            },
          ),
        ),
      ],
    );
  }
}

class _BankListState {
  final bool isLoading;
  final List<BankModel> banks;

  const _BankListState(this.isLoading, this.banks);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BankListState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          banks == other.banks;

  @override
  int get hashCode => isLoading.hashCode ^ banks.hashCode;
}

// 🎴 Beautiful Bank Card
class _BankCard extends StatelessWidget {
  final BankModel bank;

  const _BankCard({required this.bank});

  @override
  Widget build(BuildContext context) {
    return Selector<BankProvider, BankMonthModel?>(
      selector: (_, provider) => provider.getCurrentMonthForBank(bank.id),
      builder: (_, month, __) {
        final currentBalance = month?.currentAmount ?? 0;
        final surplus = month?.surplusPreviousMonth ?? 0;
        final incomeThisMonth = month?.incomeThisMonth ?? 0;

        return _buildCard(
          context,
          currentBalance: currentBalance,
          surplus: surplus,
          incomeThisMonth: incomeThisMonth,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required double currentBalance,
    required double surplus,
    required double incomeThisMonth,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BankAccountDetailScreen(bank: bank)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bank name
              Text(
                bank.bankName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // 💰 CURRENT MONTH BALANCE
              Text(
                '₹${currentBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF64FFDA),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
              Divider(color: Colors.grey[800]),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                    label: 'Surplus',
                    value: '₹${surplus.toStringAsFixed(0)}',
                  ),
                  _InfoChip(
                    label: 'Income (This Month)',
                    value: '₹${incomeThisMonth.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 📊 Info Chip Widget
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _InfoChip({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
