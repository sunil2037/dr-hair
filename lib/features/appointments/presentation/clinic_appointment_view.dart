import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/route_names.dart';
import '../../auth/presentation/viewmodels/auth_cubit.dart';
import '../domain/clinic_appointment.dart';
import 'clinic_appointment_cubit.dart';
import 'widgets/appointment_date_picker_bottom_sheet.dart';

class ClinicAppointmentView extends StatefulWidget {
  const ClinicAppointmentView({super.key});

  @override
  State<ClinicAppointmentView> createState() => _ClinicAppointmentViewState();
}

class _ClinicAppointmentViewState extends State<ClinicAppointmentView> {
  DateTime? _startsAt;
  final TextEditingController _reasonController = TextEditingController();
  String? _replacingId;
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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

    final userReason = _reasonController.text.trim();
    final finalReason = userReason.isEmpty
        ? 'General hair & scalp consultation'
        : userReason;

    setState(() => _saving = true);
    final error = await context.read<ClinicAppointmentCubit>().saveRequest(
      patientId: patientId,
      startsAt: _startsAt!,
      reason: finalReason,
      replacingId: _replacingId,
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
                              'Sector 29, Gurugram, Delhi NCR · 122002\nNear IFFCO Chowk Metro Station',
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
                      ? 'Confirm In-Clinic Appointment'
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
                    .forPatient(patientId);

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
                              'Venue: Dr. Hair Clinic · Room 101 · Sector 29, Gurugram',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
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
                                    onPressed: () => context
                                        .read<ClinicAppointmentCubit>()
                                        .cancel(request.id, patientId),
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
    );
  }
}
