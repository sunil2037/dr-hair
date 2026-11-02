import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/route_names.dart';
import '../../auth/presentation/viewmodels/auth_cubit.dart';
import '../../auth/presentation/views/complete_profile_view.dart';
import '../domain/clinic_appointment.dart';
import 'clinic_appointment_cubit.dart';
import 'widgets/appointment_date_picker_bottom_sheet.dart';
import 'widgets/appointment_payment_sheet.dart';

class ClinicAppointmentView extends StatefulWidget {
  const ClinicAppointmentView({super.key});

  @override
  State<ClinicAppointmentView> createState() => _ClinicAppointmentViewState();
}

class _ClinicAppointmentViewState extends State<ClinicAppointmentView> {
  DateTime? _startsAt;
  final TextEditingController _reasonController = TextEditingController();
  String? _replacingId;
  String? _accessToken;
  bool _didLoadAppointments = false;
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthCubit>().state;
    final token = auth.sessionToken;
    if (token != null && token.isNotEmpty && auth.isGuest != true) {
      _accessToken = token;
      if (!_didLoadAppointments) {
        _didLoadAppointments = true;
        context.read<ClinicAppointmentCubit>().loadFromApi(token);
      }
    }
  }

  String _dateLabel(DateTime date) =>
      '${MaterialLocalizations.of(context).formatMediumDate(date)} · ${TimeOfDay.fromDateTime(date).format(context)}';

  Future<void> _pickDateAndSlot() async {
    final picked = await AppointmentDatePickerBottomSheet.show(
      context,
      initialDate: _startsAt,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startsAt = picked;
    });
  }

  Future<void> _save(String patientId) async {
    if (_startsAt == null) {
      _message('Please select an appointment date and sitting slot.');
      return;
    }

    final auth = context.read<AuthCubit>();
    var user = auth.state.user;
    final age = user?.age;
    final gender = user?.gender?.trim();
    if (age == null || gender == null || gender.isEmpty) {
      final completed = await CompleteProfileBottomSheet.show(
        context,
        requireAgeAndGender: true,
        title: 'Complete your profile',
        subtitle:
            'Age and gender are required before booking an in-clinic consultation.',
      );
      if (completed != true || !mounted) {
        return;
      }
      user = context.read<AuthCubit>().state.user;
    }

    final activePatientId = user?.patientId ?? patientId;
    final userReason = _reasonController.text.trim();
    final finalReason = userReason.isEmpty
        ? 'General hair & scalp consultation'
        : userReason;

    AppointmentPaymentResult? payment;
    if (_replacingId == null) {
      payment = await AppointmentPaymentSheet.show(
        context,
        startsAt: _startsAt!,
        doctorName: 'Dr. Jai Bansal',
        fee: 500,
      );
      if (payment == null || !mounted) {
        return;
      }
    }

    setState(() => _saving = true);
    final error = await context.read<ClinicAppointmentCubit>().saveRequest(
      patientId: activePatientId,
      accessToken: _accessToken ?? auth.state.sessionToken ?? '',
      startsAt: _startsAt!,
      reason: finalReason,
      replacingId: _replacingId,
      consultationFee: payment?.amount ?? 500,
      paymentMethod: payment?.paymentMethod ?? 'UPI',
      paymentStatus: payment?.paymentStatus ?? 'Paid',
      paymentTransactionId: payment?.transactionId,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) {
        _startsAt = null;
        _reasonController.clear();
        _replacingId = null;
      }
    });
    _message(
      error ?? 'Appointment request submitted to Dr. Jai Bansal. OPD token assigned.',
    );
  }

  Future<void> _confirmCancel(String id, String patientId) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            const Text('Cancel this appointment?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
            const SizedBox(height: 8),
            const Text('The clinic will be notified and this sitting will be released. You can request another appointment later.', style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.secondaryDark)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext, false), child: const Text('Keep appointment'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Cancel visit'))),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      _message('Sign in again to cancel this appointment.');
      return;
    }
    final error = await context.read<ClinicAppointmentCubit>().cancel(id, patientId, accessToken: token);
    if (!mounted) return;
    _message(error ?? 'Appointment request cancelled.');
  }

  void _message(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final patientId = user?.patientId ?? 'GUEST';
    final canRequest = user != null && !user.isGuest;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'In-Clinic Appointment',
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final token = _accessToken ?? context.read<AuthCubit>().state.sessionToken;
            if (token != null && token.isNotEmpty) {
              await context.read<ClinicAppointmentCubit>().loadFromApi(token);
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
            // Doctor & Clinic Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x081A365D),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary5,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary100),
                        ),
                        child: const Icon(
                          LucideIcons.stethoscope,
                          color: AppColors.primary,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Dr. Jai Bansal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFDCFCE7),
                                    ),
                                  ),
                                  child: const Text(
                                    'Chief Trichologist',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'MBBS, MD · Reg. MCI-84920 · 12+ Years Exp.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Specialist: Hair Transplant & Scalp Trichoscopy',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  // Clinic Venue Details
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. Hair Restoration & Trichology Center',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Dr. Hair & Cosmodent Clinic, Jaipur, Rajasthan · 302017\nMon - Sat: 10:00 AM - 7:30 PM',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary5,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Sitting Hours: Mon – Sat (10 AM – 1 PM & 3:30 PM – 7 PM)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Clinic Off / Holiday Notification Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.calendarOff,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clinic is Open Mon – Sat. Sundays & Public Holidays are Closed.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Booking Form Section
            Text(
              _replacingId == null
                  ? 'Book In-Person Appointment'
                  : 'Reschedule Appointment Slot',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 14),

            // 1. Date & Slot Picker Custom Reusable Bottom Sheet trigger
            InkWell(
              onTap: _pickDateAndSlot,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _startsAt != null
                        ? AppColors.primary
                        : AppColors.border,
                    width: _startsAt != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.calendarDays,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Appointment Date & Sitting Slot',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _startsAt == null
                                ? 'Tap to choose date & sitting slot'
                                : _dateLabel(_startsAt!),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _startsAt == null
                                  ? AppColors.textMuted
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. Optional Description / Reason Input Field (Replaced Dropdown)
            TextFormField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason for visit / description (Optional)',
                hintText: 'e.g. Hair fall at crown, scalp itchiness, post-treatment check...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.fileText, size: 18),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),

            const SizedBox(height: 18),

            // Consultation Fee & OPD Token Information Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary5,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary100),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.receipt, color: AppColors.primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultation & Trichoscopy Fee: ₹500',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'UPI / Card / Pay at Clinic · Full refund if cancelled 2h prior',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Submit Button
            if (canRequest)
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(patientId),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(LucideIcons.checkCircle2, size: 18),
                label: Text(
                  _saving
                      ? 'Saving Request…'
                      : _replacingId == null
                      ? 'Proceed to Book & Pay (₹500)'
                      : 'Update Sitting Slot',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: () => context.push(RouteNames.signin),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(LucideIcons.logIn, size: 18),
                label: const Text('Sign in to Book In-Clinic Visit'),
              ),

            if (_replacingId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () => setState(() {
                    _replacingId = null;
                    _startsAt = null;
                    _reasonController.clear();
                  }),
                  child: const Text('Cancel Rescheduling'),
                ),
              ),

            const SizedBox(height: 32),

            // Patient's Existing Requests Section
            const Text(
              'Your Scheduled Visits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 10),

            BlocBuilder<ClinicAppointmentCubit, List<ClinicAppointment>>(
              builder: (context, _) {
                final requests = context
                    .read<ClinicAppointmentCubit>()
                    .forPatient(patientId, userId: user?.id);

                if (requests.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No physical clinic visits scheduled yet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: requests.map((request) {
                    final isCancelled = request.status == 'Cancelled';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.building2,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Dr. Jai Bansal Clinic Chamber',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isCancelled
                                            ? AppColors.textSecondary
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCancelled
                                        ? const Color(0xFFFEE2E2)
                                        : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isCancelled
                                          ? const Color(0xFFFECACA)
                                          : const Color(0xFFDCFCE7),
                                    ),
                                  ),
                                  child: Text(
                                    isCancelled ? 'Cancelled' : 'OPD Confirmed',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isCancelled
                                          ? const Color(0xFF991B1B)
                                          : const Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Text(
                              _dateLabel(request.startsAt),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.reason,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Venue: Dr. Hair & Cosmodent Clinic · Jaipur Clinic',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (request.tokenNumber.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.ticket,
                                          size: 12,
                                          color: Color(0xFF475569),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Token: ${request.tokenNumber}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: request.paymentStatus == 'Paid'
                                        ? const Color(0xFFECFDF5)
                                        : const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: request.paymentStatus == 'Paid'
                                          ? const Color(0xFFA7F3D0)
                                          : const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        request.paymentStatus == 'Paid'
                                            ? LucideIcons.checkCheck
                                            : LucideIcons.circleDollarSign,
                                        size: 12,
                                        color: request.paymentStatus == 'Paid'
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        request.paymentStatus == 'Paid'
                                            ? '₹${request.consultationFee} Paid (${request.paymentMethod})'
                                            : '₹${request.consultationFee} Due at Clinic',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: request.paymentStatus == 'Paid'
                                              ? const Color(0xFF047857)
                                              : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!isCancelled &&
                                request.startsAt.isAfter(DateTime.now())) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _replacingId = request.id;
                                        _startsAt = request.startsAt;
                                        _reasonController.text =
                                            request.reason == 'General hair & scalp consultation'
                                            ? ''
                                            : request.reason;
                                      });
                                    },
                                    icon: const Icon(
                                      LucideIcons.calendarClock,
                                      size: 14,
                                    ),
                                    label: const Text('Reschedule'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _confirmCancel(request.id, patientId),
                                    icon: const Icon(
                                      LucideIcons.xCircle,
                                      size: 14,
                                    ),
                                    label: const Text('Cancel Visit'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
          ),
        ),
      ),
    );
  }
}
