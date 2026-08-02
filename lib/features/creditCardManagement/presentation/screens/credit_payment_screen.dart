// import 'package:expence_app/core/theme/app_color.dart';
// import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
// import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
//
// import '../../../bank/data/model/bank_model.dart';
// import '../../../bank/presentation/provider/bank_provider.dart';
// import '../provider/credit_card_payment_provider.dart';
//
// /// Screen to record a payment against the *current* billing cycle.
// ///
// /// Every field of [CreditPaymentModel] is shown as an editable input,
// /// prefilled from [CreditCardDetailsProvider]:
// ///   - `billingCycleId`, `expenseAmount` -> current billing cycle (Selector)
// ///   - `bankId` / `bankName`             -> bank dropdown (BankProvider)
// ///   - `interest`, `lateFee`, `gst`, `otherCharges` -> default 0, editable
// ///   - `totalPaid`                        -> auto-computed, but overridable
// ///   - `paymentDate`                      -> defaults to today, editable
// ///
// /// NOTE: getter/method names marked `// ASSUMPTION:` below are guesses
// /// based on what was visible in your other files. Rename to match your
// /// actual `CreditCardDetailsProvider` API.
// class CreditPaymentScreen extends StatefulWidget {
//   const CreditPaymentScreen({super.key});
//
//   @override
//   State<CreditPaymentScreen> createState() => _CreditPaymentScreenState();
// }
//
// class _CreditPaymentScreenState extends State<CreditPaymentScreen> {
//
//
//
//   String? _billingCycleId;
//   BankModel? _selectedBank;
//   DateTime _paymentDate = DateTime.now();
//   bool _isSubmitting = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Seed everything ONCE from the provider so the fields start
//     // pre-filled, then live as local editable state afterwards.
//     final detailsProvider = context.read<CreditCardDetailsProvider>();
//     final bankProvider = context.read<BankProvider>();
//
//     // ASSUMPTION: provider exposes the currently open billing cycle here.
//     final BillingCycleModel? cycle = detailsProvider.currentBillingCycle;
//     // ASSUMPTION: provider exposes the currently selected credit card here.
//     final CreditCardModel? card = detailsProvider.creditCard;
//
//     _billingCycleId = cycle?.id;
//
//     _expenseAmountCtrl = TextEditingController(
//       text: (cycle?.totalAmount ?? 0).toStringAsFixed(2),
//     );
//     _interestCtrl = TextEditingController(text: '0.00');
//     _lateFeeCtrl = TextEditingController(text: '0.00');
//     _gstCtrl = TextEditingController(text: '0.00');
//     _otherChargesCtrl = TextEditingController(text: '0.00');
//     _totalPaidCtrl = TextEditingController(
//       text: (cycle?.totalAmount ?? 0).toStringAsFixed(2),
//     );
//
//     // Recompute total whenever any component changes, unless the user
//     // has manually overridden the total field themselves.
//     for (final c in [
//       _expenseAmountCtrl,
//       _interestCtrl,
//       _lateFeeCtrl,
//       _gstCtrl,
//       _otherChargesCtrl,
//     ]) {
//       c.addListener(_recomputeTotal);
//     }
//
//     // Default the bank to the card's linked bank if you track that on
//     // CreditCardModel; otherwise fall back to the first available bank.
//     // ASSUMPTION: CreditCardModel has a `bankId` field to match against.
//     if (bankProvider.banks.isNotEmpty) {
//       _selectedBank = bankProvider.banks.firstWhere(
//             (b) => b.id == ?.bankId,
//         orElse: () => bankProvider.banks.first,
//       );
//     }
//   }
//
//   void _recomputeTotal() {
//     final total = _parsed(_expenseAmountCtrl) +
//         _parsed(_interestCtrl) +
//         _parsed(_lateFeeCtrl) +
//         _parsed(_gstCtrl) +
//         _parsed(_otherChargesCtrl);
//     _totalPaidCtrl.text = total.toStringAsFixed(2);
//   }
//
//   double _parsed(TextEditingController c) => double.tryParse(c.text) ?? 0;
//
//   @override
//   void dispose() {
//     _expenseAmountCtrl.dispose();
//     _interestCtrl.dispose();
//     _lateFeeCtrl.dispose();
//     _gstCtrl.dispose();
//     _otherChargesCtrl.dispose();
//     _totalPaidCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _paymentDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.dark(
//               primary: AppColor.creditAccent,
//               onPrimary: AppColor.creditDark,
//               surface: AppColor.creditCard,
//               onSurface: AppColor.creditAccent,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() => _paymentDate = picked);
//     }
//   }
//
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_selectedBank == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a payment bank')),
//       );
//       return;
//     }
//     if (_billingCycleId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No active billing cycle found')),
//       );
//       return;
//     }
//
//     setState(() => _isSubmitting = true);
//     //
//     // final payment = CreditPaymentModel(
//     //   id: '', // ASSUMPTION: id is assigned by Firestore / repository layer.
//     //   billingCycleId: _billingCycleId!,
//     //   bankId: _selectedBank!.id,
//     //   bankName: _selectedBank!.bankName,
//     //   expenseAmount: _parsed(_expenseAmountCtrl),
//     //   interest: _parsed(_interestCtrl),
//     //   lateFee: _parsed(_lateFeeCtrl),
//     //   gst: _parsed(_gstCtrl),
//     //   otherCharges: _parsed(_otherChargesCtrl),
//     //   totalPaid: _parsed(_totalPaidCtrl),
//     //   expenseId: '', // ASSUMPTION: generated server-side / by repository.
//     //   paymentDate: _paymentDate,
//     //   createdAt: DateTime.now(),
//     // );
//
//     try {
//       // ASSUMPTION: CreditCardDetailsProvider exposes this method.
//       // await context.read<CreditCardDetailsProvider>().makePayment(payment);
//       if (mounted) Navigator.of(context).pop(true);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Payment failed: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColor.creditSurface,
//       appBar: AppBar(
//         backgroundColor: AppColor.creditSurface,
//         elevation: 0,
//         foregroundColor: AppColor.creditAccent,
//         title: const Text(
//           'Make Payment',
//           style: TextStyle(
//             color: AppColor.creditAccent,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
//           children: [
//             _summaryCard(),
//             const SizedBox(height: 20),
//             _sectionLabel('Payment Method'),
//             const SizedBox(height: 10),
//             _bankDropdown(),
//             const SizedBox(height: 20),
//             _sectionLabel('Payment Date'),
//             const SizedBox(height: 10),
//             _dateTile(),
//             const SizedBox(height: 20),
//             _sectionLabel('Amount Breakdown'),
//             const SizedBox(height: 10),
//             _amountField(
//               controller: _expenseAmountCtrl,
//               label: 'Expense Amount',
//               icon: Icons.receipt_long_rounded,
//             ),
//             const SizedBox(height: 12),
//             _amountField(
//               controller: _interestCtrl,
//               label: 'Interest',
//               icon: Icons.percent_rounded,
//             ),
//             const SizedBox(height: 12),
//             _amountField(
//               controller: _lateFeeCtrl,
//               label: 'Late Fee',
//               icon: Icons.warning_amber_rounded,
//             ),
//             const SizedBox(height: 12),
//             _amountField(
//               controller: _gstCtrl,
//               label: 'GST',
//               icon: Icons.request_quote_rounded,
//             ),
//             const SizedBox(height: 12),
//             _amountField(
//               controller: _otherChargesCtrl,
//               label: 'Other Charges',
//               icon: Icons.more_horiz_rounded,
//             ),
//             const SizedBox(height: 20),
//             _sectionLabel('Total Paid'),
//             const SizedBox(height: 10),
//             _amountField(
//               controller: _totalPaidCtrl,
//               label: 'Total Paid',
//               icon: Icons.account_balance_wallet_rounded,
//               highlight: true,
//             ),
//             const SizedBox(height: 28),
//             _confirmButton(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _sectionLabel(String text) {
//     return Text(
//       text,
//       style: TextStyle(
//         color: AppColor.creditAccent.withOpacity(.6),
//         fontSize: 13,
//         fontWeight: FontWeight.w600,
//         letterSpacing: .4,
//       ),
//     );
//   }
//
//   /// Live provider-driven summary — this is the piece that genuinely
//   /// benefits from Selector, since it just displays state rather than
//   /// feeding an editable controller.
//   Widget _summaryCard() {
//     return Selector<CreditCardDetailsProvider, _SummaryView>(
//       selector: (_, provider) => _SummaryView(
//         cardName: provider.creditCard.cardName, // ASSUMPTION
//         outstanding: provider.currentBillingCycle?.totalAmount ?? 0,
//         status: provider.currentBillingCycle?.status ?? 'active',
//       ),
//       builder: (context, summary, _) {
//         final statusColor = switch (summary.status.toLowerCase()) {
//           'paid' => AppColor.creditPaid,
//           'active' => AppColor.creditEMI,
//           _ => AppColor.creditLimit,
//         };
//
//         return Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [AppColor.creditGradientStart, AppColor.creditGradientEnd],
//             ),
//             borderRadius: BorderRadius.circular(22),
//             border: Border.all(color: AppColor.creditBorder),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(.4),
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       summary.cardName,
//                       style: TextStyle(
//                         color: AppColor.creditAccent.withOpacity(.7),
//                         fontSize: 15,
//                       ),
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(.15),
//                       borderRadius: BorderRadius.circular(30),
//                       border: Border.all(color: statusColor.withOpacity(.4)),
//                     ),
//                     child: Text(
//                       summary.status.toUpperCase(),
//                       style: TextStyle(
//                         color: statusColor,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 '₹${summary.outstanding.toStringAsFixed(0)}',
//                 style: const TextStyle(
//                   color: AppColor.creditAccent,
//                   fontSize: 30,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 'Outstanding for this cycle',
//                 style: TextStyle(
//                   color: AppColor.creditAccent.withOpacity(.5),
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _bankDropdown() {
//     return Selector<BankProvider, List<BankModel>>(
//       selector: (_, provider) => provider.banks,
//       builder: (context, banks, _) {
//         return DropdownButtonFormField<BankModel>(
//           initialValue: _selectedBank,
//           isExpanded: true,
//           dropdownColor: AppColor.cardBg,
//           decoration: InputDecoration(
//             labelText: 'Paid From',
//             labelStyle: TextStyle(color: AppColor.creditAccent.withOpacity(.5)),
//             prefixIcon: const Icon(
//               Icons.account_balance_wallet_rounded,
//               color: AppColor.creditAccent,
//             ),
//             filled: true,
//             fillColor: AppColor.cardBg,
//             contentPadding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: AppColor.cardBorder),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide:
//               const BorderSide(color: AppColor.creditAccent, width: 2),
//             ),
//           ),
//           icon: Icon(
//             Icons.keyboard_arrow_down_rounded,
//             color: AppColor.creditAccent.withOpacity(.7),
//           ),
//           items: banks.map((bank) {
//             return DropdownMenuItem<BankModel>(
//               value: bank,
//               child: Row(
//                 children: [
//                   Icon(
//                     bank.id == 'cash'
//                         ? Icons.money_rounded
//                         : Icons.account_balance_rounded,
//                     size: 20,
//                     color: AppColor.creditAccent,
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     bank.bankName,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//           validator: (value) => value == null ? 'Select a bank' : null,
//           onChanged: (bank) => setState(() => _selectedBank = bank),
//         );
//       },
//     );
//   }
//
//   Widget _dateTile() {
//     return InkWell(
//       onTap: _pickDate,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         decoration: BoxDecoration(
//           color: AppColor.cardBg,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: AppColor.cardBorder),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.calendar_month_rounded, color: AppColor.creditAccent),
//             const SizedBox(width: 12),
//             Text(
//               '${_paymentDate.day.toString().padLeft(2, '0')}/'
//                   '${_paymentDate.month.toString().padLeft(2, '0')}/'
//                   '${_paymentDate.year}',
//               style: const TextStyle(color: Colors.white, fontSize: 15),
//             ),
//             const Spacer(),
//             Icon(Icons.edit_rounded,
//                 size: 18, color: AppColor.creditAccent.withOpacity(.6)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _amountField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     bool highlight = false,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//       inputFormatters: [
//         FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
//       ],
//       style: TextStyle(
//         color: highlight ? AppColor.creditAccent : Colors.white,
//         fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
//         fontSize: highlight ? 18 : 15,
//       ),
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: TextStyle(color: AppColor.creditAccent.withOpacity(.5)),
//         prefixText: '₹ ',
//         prefixStyle: TextStyle(color: AppColor.creditAccent.withOpacity(.7)),
//         prefixIcon: Icon(icon, color: AppColor.creditAccent, size: 20),
//         filled: true,
//         fillColor: highlight
//             ? AppColor.creditAccent.withOpacity(.08)
//             : AppColor.cardBg,
//         contentPadding:
//         const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide.none,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: highlight
//                 ? AppColor.creditAccent.withOpacity(.4)
//                 : AppColor.cardBorder,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColor.creditAccent, width: 2),
//         ),
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) return 'Required';
//         if (double.tryParse(value) == null) return 'Invalid amount';
//         return null;
//       },
//     );
//   }
//
//   Widget _confirmButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 54,
//       child: ElevatedButton(
//         onPressed: _isSubmitting ? null : _submit,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColor.creditAccent,
//           foregroundColor: AppColor.creditDark,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//         ),
//         child: _isSubmitting
//             ? const SizedBox(
//           height: 22,
//           width: 22,
//           child: CircularProgressIndicator(
//             strokeWidth: 2.4,
//             color: AppColor.creditDark,
//           ),
//         )
//             : Text(
//           'Confirm Payment · ₹${_totalPaidCtrl.text}',
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _SummaryView {
//   final String cardName;
//   final double outstanding;
//   final String status;
//
//   const _SummaryView({
//     required this.cardName,
//     required this.outstanding,
//     required this.status,
//   });
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//           other is _SummaryView &&
//               cardName == other.cardName &&
//               outstanding == other.outstanding &&
//               status == other.status;
//
//   @override
//   int get hashCode => Object.hash(cardName, outstanding, status);
// }