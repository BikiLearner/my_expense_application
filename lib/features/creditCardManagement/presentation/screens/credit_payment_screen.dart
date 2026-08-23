// lib/features/creditCardManagement/presentation/screen/credit_payment_screen.dart
import 'package:expence_app/core/theme/app_color.dart';
import 'package:expence_app/features/bank/presentation/provider/bank_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/bank_selector_field.dart';
import '../../../bank/data/model/bank_model.dart';
import '../../data/model/billing_cycle_model.dart';
import '../../data/model/credit_card.dart';
import '../provider/credit_card_payment_provider.dart';

const double _kDesktopBreakpoint = 900;
const double _kMaxContentWidth = 980;

class CreditPaymentScreen extends StatefulWidget {
  final CreditCardModel creditCard;
  final BillingCycleModel billingCycle;
  final bool isCurrentCycle;

  const CreditPaymentScreen({
    super.key,
    required this.creditCard,
    required this.billingCycle,
    required this.isCurrentCycle,
  });

  @override
  State<CreditPaymentScreen> createState() => _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends State<CreditPaymentScreen> {
  late CreditCardDetailsProvider provider;
  late BankModel currentBank;

  @override
  void initState() {
    super.initState();

    provider = context.read<CreditCardDetailsProvider>();

    currentBank = context.read<BankProvider>().banks.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      provider.paymentScreenFieldInit(
        widget.creditCard,
        widget.billingCycle,
        bank: currentBank,
        isCurrentCycle: widget.isCurrentCycle,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CreditCardDetailsProvider>();
    return Scaffold(
      backgroundColor: AppColor.creditSurface,
      appBar: AppBar(
        backgroundColor: AppColor.creditSurface,
        elevation: 0,
        foregroundColor: AppColor.creditAccent,
        title: const Text(
          'Make Payment',
          style: TextStyle(
            color: AppColor.creditAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: Form(
                  key: provider.formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 20,
                    ),
                    child: isDesktop
                        ? _DesktopLayout(provider: provider)
                        : _MobileLayout(provider: provider),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Mobile: single column, stacked sections
// ─────────────────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final CreditCardDetailsProvider provider;

  const _MobileLayout({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Payment Method',
          icon: Icons.account_balance_wallet_rounded,
          child: _BankDropdown(provider: provider),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Payment Date',
          icon: Icons.calendar_month_rounded,
          child: _DateTile(provider: provider),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Amount Breakdown',
          icon: Icons.receipt_long_rounded,
          child: _AmountFields(provider: provider),
        ),
        const SizedBox(height: 16),
        _TotalCard(provider: provider),
        const _ErrorText(),
        const SizedBox(height: 24),
        _ConfirmButton(provider: provider),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Desktop: two-column — left rail (summary + method + date),
// right column (amount breakdown + total + confirm)
// ─────────────────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final CreditCardDetailsProvider provider;

  const _DesktopLayout({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Payment Method',
                icon: Icons.account_balance_wallet_rounded,
                child: _BankDropdown(provider: provider),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Payment Date',
                icon: Icons.calendar_month_rounded,
                child: _DateTile(provider: provider),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'Amount Breakdown',
                icon: Icons.receipt_long_rounded,
                child: _AmountFields(provider: provider),
              ),
              const SizedBox(height: 16),
              _TotalCard(provider: provider),
              const _ErrorText(),
              const SizedBox(height: 24),
              _ConfirmButton(provider: provider),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared section wrapper — consistent card chrome across mobile/desktop
// ─────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.cardBg.withOpacity(.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColor.creditAccent.withOpacity(.85),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColor.creditAccent.withOpacity(.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Summary card — outstanding balance for the cycle
// ─────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<CreditCardDetailsProvider, BillingCycleModel?>(
      selector: (_, p) => p.paymentBillingCycle,
      builder: (context, cycle, __) {
        final provider = context.read<CreditCardDetailsProvider>();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColor.creditGradientStart,
                AppColor.creditGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColor.creditBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.35),
                blurRadius: 24,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.creditAccent.withOpacity(.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      size: 16,
                      color: AppColor.creditAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.paymentCreditCard.cardName,
                      style: TextStyle(
                        color: AppColor.creditAccent.withOpacity(.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'AMOUNT DUE',
                style: TextStyle(
                  color: AppColor.creditAccent.withOpacity(.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${(cycle?.totalAmount ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColor.creditAccent,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Outstanding for this cycle',
                style: TextStyle(
                  color: AppColor.creditAccent.withOpacity(.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Bank dropdown
// ─────────────────────────────────────────────────────────────────────────
class _BankDropdown extends StatelessWidget {
  final CreditCardDetailsProvider provider;

  const _BankDropdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Selector<CreditCardDetailsProvider, BankModel?>(
      selector: (_, p) => p.selectedBank,
      builder: (_, selectedBank, __) {
        return BankSelectorField(
          selectedBankId: selectedBank?.id,
          includeCash: false,
          label: 'Paid From',
          onChanged: provider.setSelectedBank,
          validator: (bank) => bank == null ? 'Select a bank' : null,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Date tile
// ─────────────────────────────────────────────────────────────────────────
class _DateTile extends StatelessWidget {
  final CreditCardDetailsProvider provider;

  const _DateTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Selector<CreditCardDetailsProvider, DateTime>(
      selector: (_, p) => p.paymentDate,
      builder: (context, paymentDate, __) {
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: paymentDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) provider.setPaymentDate(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColor.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColor.creditAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${paymentDate.day.toString().padLeft(2, '0')}/'
                  '${paymentDate.month.toString().padLeft(2, '0')}/'
                  '${paymentDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: AppColor.creditAccent.withOpacity(.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Amount fields — 2-column grid on wide screens, stacked on narrow
// ─────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────
// Amount fields — 2-column grid on wide screens, stacked on narrow.
// Interest / GST / Other Charges support a ₹ ⇄ % toggle.
// ─────────────────────────────────────────────────────────────────────────
class _AmountFields extends StatelessWidget {
  final CreditCardDetailsProvider provider;

  const _AmountFields({required this.provider});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 420;

        final tiles = <Widget>[
          _AmountField(
            controller: provider.expenseAmountCtrl,
            label: 'Expense Amount',
            icon: Icons.receipt_long_rounded,
          ),
          _PercentableAmountField(
            provider: provider,
            label: 'Interest',
            icon: Icons.percent_rounded,
            amountCtrl: provider.interestCtrl,
            percentCtrl: provider.interestPercentCtrl,
            modeSelector: (p) => p.interestMode,
            onModeChanged: provider.setInterestMode,
          ),
          _AmountField(
            controller: provider.lateFeeCtrl,
            label: 'Late Fee',
            icon: Icons.warning_amber_rounded,
          ),
          _PercentableAmountField(
            provider: provider,
            label: 'GST',
            icon: Icons.request_quote_rounded,
            amountCtrl: provider.gstCtrl,
            percentCtrl: provider.gstPercentCtrl,
            modeSelector: (p) => p.gstMode,
            onModeChanged: provider.setGstMode,
          ),
          _PercentableAmountField(
            provider: provider,
            label: 'Other Charges',
            icon: Icons.more_horiz_rounded,
            amountCtrl: provider.otherChargesCtrl,
            percentCtrl: provider.otherChargesPercentCtrl,
            modeSelector: (p) => p.otherChargesMode,
            onModeChanged: provider.setOtherChargesMode,
          ),
        ];

        if (!twoCol) {
          return Column(
            children: [
              for (final t in tiles) ...[
                t,
                const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final t in tiles)
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: t,
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// A field that can be entered as a flat ₹ amount OR as a % of the
// expense amount. Tapping the trailing chip toggles the mode; the
// resolved ₹ amount is always shown as a helper line under the field.
// ─────────────────────────────────────────────────────────────────────────
class _PercentableAmountField extends StatelessWidget {
  final CreditCardDetailsProvider provider;
  final String label;
  final IconData icon;
  final TextEditingController amountCtrl;
  final TextEditingController percentCtrl;
  final AmountInputMode Function(CreditCardDetailsProvider) modeSelector;
  final ValueChanged<AmountInputMode> onModeChanged;

  const _PercentableAmountField({
    required this.provider,
    required this.label,
    required this.icon,
    required this.amountCtrl,
    required this.percentCtrl,
    required this.modeSelector,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<CreditCardDetailsProvider, AmountInputMode>(
      selector: (_, p) => modeSelector(p),
      builder: (context, mode, __) {
        final isPercent = mode == AmountInputMode.percentage;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: isPercent
                      ? TextFormField(
                    controller: percentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: '$label (%)',
                      labelStyle: TextStyle(
                        color: AppColor.creditAccent.withOpacity(.5),
                        fontSize: 13,
                      ),
                      suffixText: '%',
                      suffixStyle: TextStyle(
                        color: AppColor.creditAccent.withOpacity(.7),
                      ),
                      prefixIcon: Icon(
                        icon,
                        color: AppColor.creditAccent,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: AppColor.cardBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: AppColor.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColor.creditAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final v = double.tryParse(value);
                      if (v == null) return 'Invalid %';
                      if (v < 0 || v > 100) return '0–100 only';
                      return null;
                    },
                  )
                      : _AmountField(
                    controller: amountCtrl,
                    label: label,
                    icon: icon,
                  ),
                ),
                const SizedBox(width: 8),
                _ModeToggleChip(
                  isPercent: isPercent,
                  onTap: () => onModeChanged(
                    isPercent
                        ? AmountInputMode.amount
                        : AmountInputMode.percentage,
                  ),
                ),
              ],
            ),
            if (isPercent)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: AnimatedBuilder(
                  animation: amountCtrl,
                  builder: (context, __) {
                    return Text(
                      '≈ ₹${amountCtrl.text.isEmpty ? '0' : amountCtrl.text}',
                      style: TextStyle(
                        color: AppColor.creditAccent.withOpacity(.55),
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Small ₹ / % toggle button shown beside percentable fields.
// ─────────────────────────────────────────────────────────────────────────
class _ModeToggleChip extends StatelessWidget {
  final bool isPercent;
  final VoidCallback onTap;

  const _ModeToggleChip({required this.isPercent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        width: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColor.creditAccent.withOpacity(.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.creditAccent.withOpacity(.3)),
        ),
        child: Text(
          isPercent ? '%' : '₹',
          style: const TextStyle(
            color: AppColor.creditAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool highlight;

  const _AmountField({
    required this.controller,
    required this.label,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: highlight ? AppColor.creditAccent : Colors.white,
        fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
        fontSize: highlight ? 18 : 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColor.creditAccent.withOpacity(.5),
          fontSize: 13,
        ),
        prefixText: '₹ ',
        prefixStyle: TextStyle(color: AppColor.creditAccent.withOpacity(.7)),
        prefixIcon: Icon(icon, color: AppColor.creditAccent, size: 18),
        filled: true,
        fillColor: highlight
            ? AppColor.creditAccent.withOpacity(.08)
            : AppColor.cardBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: highlight
                ? AppColor.creditAccent.withOpacity(.4)
                : AppColor.cardBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.creditAccent, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null) return 'Invalid amount';
        return null;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Total card — visually distinct footer summary before confirm
// ─────────────────────────────────────────────────────────────────────────
class _TotalCard extends StatelessWidget {
  final CreditCardDetailsProvider provider;

  const _TotalCard({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.creditAccent.withOpacity(.12),
            AppColor.creditAccent.withOpacity(.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColor.creditAccent.withOpacity(.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColor.creditAccent.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColor.creditAccent,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Paid',
                  style: TextStyle(
                    color: AppColor.creditAccent.withOpacity(.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Final payment amount',
                  style: TextStyle(
                    color: AppColor.creditAccent.withOpacity(.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: _AmountField(
              controller: provider.totalPaidCtrl,
              label: 'Total Paid',
              icon: Icons.account_balance_wallet_rounded,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText();

  @override
  Widget build(BuildContext context) {
    return Selector<CreditCardDetailsProvider, String?>(
      selector: (_, p) => p.errorMessage,
      builder: (_, errorMessage, __) {
        if (errorMessage == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final CreditCardDetailsProvider provider;

  const _ConfirmButton({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<CreditCardDetailsProvider, bool>(
      selector: (_, p) => p.isSubmitting,
      builder: (context, isSubmitting, __) {
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
              try {
                final success = await provider.submit();

                if (success && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e, stack) {
                debugPrint('❌ PAYMENT ERROR: $e');
                debugPrint('❌ PAYMENT STACK:');
                debugPrintStack(stackTrace: stack);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Payment failed: ${e.toString()}',
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.creditAccent,
              foregroundColor: AppColor.creditDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColor.creditDark,
              ),
            )
                : ListenableBuilder(
              listenable: provider.totalPaidCtrl,
              builder: (context, _) {
                return Text(
                  'Confirm Payment · ₹${provider.totalPaidCtrl.text}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
