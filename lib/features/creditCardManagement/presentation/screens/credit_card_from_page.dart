import 'package:expence_app/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/indian_number_formatter.dart';
import '../provider/credit_expense_provider.dart';

class CreditCardFromPage extends StatefulWidget {
  const CreditCardFromPage({super.key});

  @override
  State<CreditCardFromPage> createState() => _CreditCardFromPageState();
}

class _CreditCardFromPageState extends State<CreditCardFromPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _statementDayController = TextEditingController(text: '1');
  final _dueDayController = TextEditingController(text: '15');

  bool isSaving = false;

  @override
  void dispose() {
    _cardNameController.dispose();
    _bankNameController.dispose();
    _creditLimitController.dispose();
    _statementDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final provider = context.read<CreditExpenseProvider>();

    try {
      final cleanLimit = _creditLimitController.text.replaceAll(',', '');

      // TODO: wire up provider.addCreditCard() once implemented
      await provider.addCreditCard(
        cardName: _cardNameController.text.trim(),
        bankName: _bankNameController.text.trim(),
        creditLimit: double.parse(cleanLimit),
        statementDay: int.parse(_statementDayController.text.trim()),
        dueDay: int.parse(_dueDayController.text.trim()),
        context: context,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Credit card added successfully'),
            backgroundColor: AppColor.creditPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppColor.creditDue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.credit_card, color: AppColor.creditPrimary),
            const SizedBox(width: 12),
            const Text(
              'Add Credit Card',
              style: TextStyle(
                color: AppColor.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColor.creditGradientStart, AppColor.creditGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.creditPrimary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: AppColor.textPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Setup Your Card',
                        style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a credit card to track spending',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Card Name ──
                _buildLabel('Card Name'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _cardNameController,
                  hint: 'e.g., HDFC Millennia',
                  icon: Icons.badge_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter card name' : null,
                ),

                const SizedBox(height: 20),

                // ── Bank Name ──
                _buildLabel('Bank Name'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _bankNameController,
                  hint: 'e.g., HDFC Bank',
                  icon: Icons.account_balance_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter bank name' : null,
                ),

                const SizedBox(height: 20),

                // ── Credit Limit ──
                _buildLabel('Credit Limit'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _creditLimitController,
                  hint: 'Enter your credit limit',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    IndianNumberFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter credit limit';
                    final clean = v.replaceAll(',', '');
                    if (double.tryParse(clean) == null) return 'Enter valid amount';
                    if (double.parse(clean) <= 0) return 'Limit must be greater than 0';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Statement & Due Day Row ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Statement Day'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _statementDayController,
                            hint: '1-31',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final day = int.tryParse(v);
                              if (day == null || day < 1 || day > 31) return '1-31';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Due Day'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _dueDayController,
                            hint: '1-31',
                            icon: Icons.event_busy,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final day = int.tryParse(v);
                              if (day == null || day < 1 || day > 31) return '1-31';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Info Card ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColor.creditPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColor.creditPrimary.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColor.creditLight,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Statement day is when your bill is generated. Due day is when payment is due.',
                          style: TextStyle(
                            color: AppColor.grey400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Save Button ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.creditPrimary,
                      foregroundColor: AppColor.textPrimary,
                      disabledBackgroundColor: AppColor.grey800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppColor.creditPrimary.withOpacity(0.5),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(AppColor.textPrimary),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline),
                              SizedBox(width: 12),
                              Text(
                                'Add Credit Card',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Cancel ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColor.grey400,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColor.creditLight,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: AppColor.textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColor.grey600),
        prefixIcon: Icon(icon, color: AppColor.creditPrimary),
        filled: true,
        fillColor: AppColor.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.grey800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.grey800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.creditPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.creditDue),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.creditDue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}
