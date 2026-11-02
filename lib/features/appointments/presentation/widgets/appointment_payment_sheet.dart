import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';

class AppointmentPaymentResult {
  final int amount;
  final String paymentMethod;
  final String paymentStatus;
  final String transactionId;

  const AppointmentPaymentResult({
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionId,
  });
}

class AppointmentPaymentSheet extends StatefulWidget {
  final DateTime startsAt;
  final String doctorName;
  final int fee;

  const AppointmentPaymentSheet({
    super.key,
    required this.startsAt,
    this.doctorName = 'Dr. Jai Bansal',
    this.fee = 500,
  });

  static Future<AppointmentPaymentResult?> show(
    BuildContext context, {
    required DateTime startsAt,
    String doctorName = 'Dr. Jai Bansal',
    int fee = 500,
  }) {
    return showModalBottomSheet<AppointmentPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppointmentPaymentSheet(
        startsAt: startsAt,
        doctorName: doctorName,
        fee: fee,
      ),
    );
  }

  @override
  State<AppointmentPaymentSheet> createState() =>
      _AppointmentPaymentSheetState();
}

class _AppointmentPaymentSheetState extends State<AppointmentPaymentSheet> {
  String _selectedMethod = 'UPI'; // 'UPI', 'Card', 'Netbanking', 'Cash at Clinic'
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final timeStr = TimeOfDay.fromDateTime(widget.startsAt).format(context);
    final dateStr =
        '${widget.startsAt.day}/${widget.startsAt.month}/${widget.startsAt.year}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary5,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.creditCard,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultation Checkout',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Secure OPD token reservation & fee payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Appointment Summary Pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.calendarCheck,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.doctorName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dateStr at $timeStr · Physical Clinic Visit',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Payment Method Section
              const Text(
                'SELECT PAYMENT METHOD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryDark,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 8),

              _buildPaymentOption(
                id: 'UPI',
                title: 'UPI (GPay / PhonePe / Paytm / QR)',
                subtitle: 'Instant OPD token confirmation',
                icon: LucideIcons.smartphone,
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                id: 'Card',
                title: 'Credit / Debit Card',
                subtitle: 'Visa, Mastercard, RuPay',
                icon: LucideIcons.creditCard,
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                id: 'Netbanking',
                title: 'Netbanking',
                subtitle: 'All major Indian banks supported',
                icon: LucideIcons.landmark,
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                id: 'Cash at Clinic',
                title: 'Pay Cash at Clinic Desk',
                subtitle: 'Pay ₹500 upon arrival at reception',
                icon: LucideIcons.banknote,
              ),

              const SizedBox(height: 18),

              // Fee Breakdown
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildFeeRow('In-Clinic Consultation Fee', '₹${widget.fee}'),
                    const SizedBox(height: 6),
                    _buildFeeRow('Trichoscopy & Scalp Examination', 'INCLUDED'),
                    const SizedBox(height: 6),
                    _buildFeeRow('OPD Registration & Token Fee', 'FREE'),
                    const Divider(color: AppColors.border, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          '₹${widget.fee}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Policy Reassurance
              Row(
                children: [
                  const Icon(
                    LucideIcons.shieldCheck,
                    size: 14,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '100% refundable if cancelled up to 2 hours prior to slot.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Pay & Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.checkCircle2, size: 18),
                  label: Text(
                    _isProcessing
                        ? 'Confirming Payment…'
                        : _selectedMethod == 'Cash at Clinic'
                            ? 'Confirm Booking (Pay ₹${widget.fee} at Clinic)'
                            : 'Pay ₹${widget.fee} & Confirm Visit',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary5 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.secondaryDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color:
                          isSelected ? AppColors.primaryDark : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? LucideIcons.checkCircle2
                  : LucideIcons.circle,
              size: 18,
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryDark,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    // Simulated short payment verification delay (e.g. UPI/Card handshake)
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final isCash = _selectedMethod == 'Cash at Clinic';
    final result = AppointmentPaymentResult(
      amount: widget.fee,
      paymentMethod: _selectedMethod,
      paymentStatus: isCash ? 'Pending' : 'Paid',
      transactionId: isCash
          ? ''
          : 'TXN-CLINIC-${DateTime.now().millisecondsSinceEpoch}',
    );

    Navigator.pop(context, result);
  }
}

