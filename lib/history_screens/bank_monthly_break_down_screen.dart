import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bank_model.dart';
import '../models/bank_month_entry_model.dart';
import '../models/bank_month_model.dart';
import '../providers/bank_provider.dart';

class BankMonthlyBreakdownScreen extends StatefulWidget
{
  final String year;

  const BankMonthlyBreakdownScreen({super.key, required this.year});

  @override
  State<BankMonthlyBreakdownScreen> createState() =>
  _BankMonthlyBreakdownScreenState();
}

class _BankMonthlyBreakdownScreenState
  extends State<BankMonthlyBreakdownScreen>
{

  String _getMonthName(int month) 
  {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  void initState() 
  {
    super.initState();

    final provider = context.read<BankProvider>();
    provider.listenBanks();
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          '${_getMonthName(DateTime.now().month)} ${widget.year} Breakdown',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Selector<BankProvider, List<BankModel>>(
        selector: (_, p) => p.banks,
        builder: (_, banks, __)
        {
          if (banks.isEmpty) 
          {
            return const Center(
              child: Text(
                'No banks found',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card at the top
              _SummaryCard(year: widget.year),
              const SizedBox(height: 16),

              // Bank cards
              ...List.generate(
                banks.length,
                (i) => _BankMonthCard(
                  bank: banks[i],
                  year: widget.year,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────── SUMMARY CARD

class _SummaryCard extends StatelessWidget
{
  final String year;

  const _SummaryCard({required this.year, });

  @override
  Widget build(BuildContext context) 
  {
    // Default values for now
    final double thisMonthTotal = context.read<BankProvider>().getTotalMonthAmountOfThisMonth() ?? 0;
    final double totalSurplus = context.read<BankProvider>().getTotalThisMonthSurplus();
    final double currentAmount = context.read<BankProvider>().getTotalCurrentAmountMonthAmountOfThisMonth() ?? 0;

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Color(0xFF64FFDA), size: 28),
                SizedBox(width: 12),
                Text(
                  'Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // This Month Surplus
            _SummaryRow(
              label: 'This Month total amount',
              value: '₹${thisMonthTotal.toStringAsFixed(0)}',
              valueColor: thisMonthTotal >= 0
                ? Colors.greenAccent
                : Colors.redAccent,
            ),
            const SizedBox(height: 12),

            // Total Surplus
            _SummaryRow(
              label: 'Total Surplus',
              value: '₹${totalSurplus.toStringAsFixed(0)}',
              valueColor: totalSurplus >= 0
                ? Colors.greenAccent
                : Colors.redAccent,
            ),
            const SizedBox(height: 12),

            // Current Amount
            _SummaryRow(
              label: 'Current Amount',
              value: '₹${currentAmount.toStringAsFixed(0)}',
              valueColor: const Color(0xFF64FFDA),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget
{
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) 
  {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────

class _BankMonthCard extends StatefulWidget
{
  final BankModel bank;
  final String year;

  const _BankMonthCard({
    required this.bank,
    required this.year,
  });

  @override
  State<_BankMonthCard> createState() => _BankMonthCardState();
}

class _BankMonthCardState extends State<_BankMonthCard>
{
  @override
  void initState() 
  {
    super.initState();
    final monthId =
      '${widget.year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    context.read<BankProvider>().listenBankMonths(widget.bank.id);

    // Start listening to entries immediately since always expanded
    context.read<BankProvider>().listenMonthEntries(
      bankId: widget.bank.id,
      monthId: monthId,
    );
  }

  @override
  Widget build(BuildContext context) 
  {
    final monthId =
      '${widget.year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    return Selector<BankProvider, BankMonthModel?>(
      selector: (_, p)
      {
        final months = p.getBankMonths(widget.bank.id);

        // ✅ SAFE lookup (NO CRASH)
        try
        {
          return months.firstWhere((m) => m.id == monthId);
        } catch (_)
        {
          return null;
        }
      },
      builder: (_, month, __)
      {
        // ✅ Month not available → hide card
        if (month == null) 
        {
          return const SizedBox();
        }

        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              // Header (always visible)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance,
                      color: Color(0xFF64FFDA)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.bank.bankName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${month.totalAdded.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Selector<BankProvider, double>(
                          selector: (_, p) => p.getSurplus(
                            bankId: widget.bank.id,
                            monthId: month.id,
                          ),
                          builder: (context, surplus, _)
                          {
                            return Text(
                              'Surplus: ₹${surplus.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: surplus >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Entries (always expanded)
              _MonthEntriesList(
                bankId: widget.bank.id,
                monthId: month.id,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() 
  {
    context.read<BankProvider>().stopListeningMonthEntries(
      widget.bank.id,
      '${widget.year}-${DateTime.now().month.toString().padLeft(2, '0')}',
    );
    super.dispose();
  }
}

// ─────────────────────────────────────────────

class _MonthEntriesList extends StatelessWidget
{
  final String bankId;
  final String monthId;

  const _MonthEntriesList({
    required this.bankId,
    required this.monthId,
  });

  @override
  Widget build(BuildContext context) 
  {
    return Selector<BankProvider, List<BankMonthEntry>>(
      selector: (_, p) => p.getMonthEntries(bankId, monthId),
      builder: (_, entries, __)
      {
        if (entries.isEmpty) 
        {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No entries',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (_, __) =>
          Divider(color: Colors.grey[800]),
          itemBuilder: (_, i)
          {
            final e = entries[i];
            return ListTile(
              leading:
              const Icon(Icons.add, color: Colors.greenAccent),
              title: Text(
                '₹${e.amount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                e.description ?? '',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }
}
