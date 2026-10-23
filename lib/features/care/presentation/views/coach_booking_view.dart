import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_animated_dropdown.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/care_widgets.dart';
import '../../../../core/widgets/app_toast.dart';

/// Book In-Clinic Physical Appointment View
/// Dedicated appointment booking exclusively for physical in-person consultations,
/// 60x scalp dermoscopy, and clinical examinations at the Dr. Hair Mansarovar Clinic in Jaipur.
class CoachBookingView extends StatefulWidget {
  const CoachBookingView({super.key});

  @override
  State<CoachBookingView> createState() => _CoachBookingViewState();
}

typedef AppointmentBookingView = CoachBookingView;

class _CoachBookingViewState extends State<CoachBookingView> {
  static const String clinicName = 'Dr. Hair Clinic & Hair Restoration Centre';
  static const String clinicAddress =
      '111/398, Vijay Path, opp. Shipra banquet, near Shipra Path, Jhalana Chhod, Mansarovar, Jaipur, Rajasthan 302020';
  static const String clinicPhone = '+91 80580 56789';
  static const String clinicHours = '09:30 AM – 08:30 PM (Mon–Sat)';

  int _selectedDoctorIndex = 0;
  late DateTime _selectedDate;
  late DateTime _calendarMonth;
  String _selectedSlot = '11:30 AM';
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Priya Verma',
      'role': 'Chief Dermatologist & Senior Trichologist',
      'degrees': 'MBBS, MD (AIIMS New Delhi)',
      'exp': '8+ yrs exp',
      'rating': '4.9',
      'reviews': '420+',
      'specialty': '60x Scalp Dermoscopy & Follicular Staging',
      'avatar': 'https://images.unsplash.com/photo-1594824813637-883a9e652a6a?q=80&w=300',
    },
    {
      'name': 'Dr. Arvind Mehta',
      'role': 'Senior Hair Restoration Surgeon',
      'degrees': 'MBBS, DVD, Fellow ISHRS',
      'exp': '12+ yrs exp',
      'rating': '5.0',
      'reviews': '680+',
      'specialty': 'Follicular Mapping, Scalp Health & PRP',
      'avatar': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=300',
    },
    {
      'name': 'Dr. Sneha Kapoor',
      'role': 'Consultant Trichologist & Scalp Specialist',
      'degrees': 'MBBS, DDVL (Trichology Specialist)',
      'exp': '7+ yrs exp',
      'rating': '4.9',
      'reviews': '350+',
      'specialty': 'Micro-Needling, Mesotherapy & Hair Density',
      'avatar': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=300',
    },
  ];

  final List<String> _timeSlots = [
    '10:00 AM',
    '11:30 AM',
    '01:00 PM',
    '02:30 PM',
    '04:00 PM',
    '05:30 PM',
    '07:00 PM',
    '08:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    DateTime defaultDay = now.add(const Duration(days: 1));
    if (defaultDay.weekday == DateTime.sunday) {
      defaultDay = defaultDay.add(const Duration(days: 1));
    }
    _selectedDate = DateTime(defaultDay.year, defaultDay.month, defaultDay.day);
    _calendarMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps() async {
    HapticFeedback.lightImpact();
    final query = Uri.encodeComponent('$clinicName, $clinicAddress');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(context,
          const SnackBar(
            content: Text('Opening Google Maps location...'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    }
  }

  DateTime _parseSlotDateTime(DateTime date, String slot) {
    try {
      final parts = slot.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return DateTime(date.year, date.month, date.day, 11, 30);
    }
  }

  String _formatUtcForCalendar(DateTime dt) {
    final u = dt.toUtc();
    final y = u.year.toString().padLeft(4, '0');
    final m = u.month.toString().padLeft(2, '0');
    final d = u.day.toString().padLeft(2, '0');
    final h = u.hour.toString().padLeft(2, '0');
    final min = u.minute.toString().padLeft(2, '0');
    final s = u.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  Future<void> _addToGoogleCalendar(
    Map<String, dynamic> doctor,
    DateTime date,
    String slot,
  ) async {
    HapticFeedback.lightImpact();
    final start = _parseSlotDateTime(date, slot);
    final end = start.add(const Duration(minutes: 45));
    final startUtc = _formatUtcForCalendar(start);
    final endUtc = _formatUtcForCalendar(end);

    final title = Uri.encodeComponent(
      'Dr. Hair In-Clinic Visit - ${doctor['name']}',
    );
    final location = Uri.encodeComponent('$clinicName, $clinicAddress');
    final details = Uri.encodeComponent(
      'Physical consultation with ${doctor['name']} (${doctor['role']}) at Dr. Hair Clinic.\n'
      'Address: $clinicAddress\n'
      'Clinic Phone: $clinicPhone\n'
      'Guidelines: Please arrive 10 minutes early for 60x Scalp Dermoscopy scan.',
    );

    final googleUrl = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$startUtc/$endUtc&details=$details&location=$location',
    );

    try {
      final launched = await launchUrl(
        googleUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(googleUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context,
          const SnackBar(
            content: Text('Opening Google Calendar...'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    }
  }

  Future<void> _addToAppleCalendar(
    Map<String, dynamic> doctor,
    DateTime date,
    String slot,
  ) async {
    HapticFeedback.lightImpact();
    final start = _parseSlotDateTime(date, slot);
    final end = start.add(const Duration(minutes: 45));
    final startUtc = _formatUtcForCalendar(start);
    final endUtc = _formatUtcForCalendar(end);
    final stampUtc = _formatUtcForCalendar(DateTime.now());
    final uid = 'dh-${start.millisecondsSinceEpoch}@drhair.health';

    final icsContent = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Dr. Hair Clinic//Appointment Reminder//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:$stampUtc',
      'DTSTART:$startUtc',
      'DTEND:$endUtc',
      'SUMMARY:Dr. Hair In-Clinic Visit - ${doctor['name']}',
      'DESCRIPTION:Physical consultation with ${doctor['name']} (${doctor['role']}) at Dr. Hair Clinic. Arrive 10 minutes prior for scalp dermoscopy scan. Phone: $clinicPhone',
      'LOCATION:$clinicAddress',
      'STATUS:CONFIRMED',
      'BEGIN:VALARM',
      'TRIGGER:-PT60M',
      'ACTION:DISPLAY',
      'DESCRIPTION:Dr. Hair appointment reminder in 1 hour',
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR',
    ].join('\r\n');

    final dataUri = Uri.dataFromString(
      icsContent,
      mimeType: 'text/calendar',
      encoding: utf8,
    );

    try {
      final launched = await launchUrl(
        dataUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await SharePlus.instance.share(
          ShareParams(
            text:
                'Dr. Hair In-Clinic Appointment with ${doctor['name']} on ${careMonthName(date.month)} ${date.day}, ${date.year} at $slot.\nLocation: $clinicAddress\nPhone: $clinicPhone',
            subject: 'Dr. Hair Clinic Appointment - ${doctor['name']}',
          ),
        );
      }
    } catch (_) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            text:
                'Dr. Hair In-Clinic Appointment with ${doctor['name']} on ${careMonthName(date.month)} ${date.day}, ${date.year} at $slot.\nLocation: $clinicAddress\nPhone: $clinicPhone',
            subject: 'Dr. Hair Clinic Appointment - ${doctor['name']}',
          ),
        );
      } catch (_) {
        if (mounted) {
          AppToast.show(context,
            const SnackBar(
              content: Text('Apple Calendar reminder ready.'),
              backgroundColor: AppColors.primaryDark,
            ),
          );
        }
      }
    }
  }

  void _showCancelDialog(
    BuildContext context,
    String bookingId,
    String doctorName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Appointment?'),
        content: Text(
          'Are you sure you want to cancel your scheduled in-person visit with $doctorName at the Mansarovar clinic?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Appointment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CareCubit>().cancelCoachBooking(bookingId);
              HapticFeedback.mediumImpact();
              AppToast.show(context,
                const SnackBar(
                  content: Text('In-clinic appointment has been cancelled.'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            child: const Text(
              'Cancel Booking',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CONFIRMATION MODAL PASS ---
  void _showConfirmationPass(
    Map<String, dynamic> doctor,
    DateTime date,
    String slot,
  ) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Indicator
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Success Icon & Badge
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Color(0xFF059669),
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Appointment Confirmed!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'In-Person Consultation Pass · Jaipur Clinic',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 18),

              // Professional Medical Pass Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary5,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header of Pass: Token & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PASS #DH-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-0${_selectedDoctorIndex + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'CONFIRMED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18, color: AppColors.primary100),

                    // Attending Specialist Details
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CustomCachedImage(
                            imageUrl: doctor['avatar'] as String,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                doctor['degrees'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                doctor['specialty'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18, color: AppColors.primary100),

                    // Date, Time & Consultation Fee
                    Row(
                      children: [
                        Expanded(
                          child: _buildPassItem(
                            'DATE',
                            '${careMonthName(date.month)} ${date.day}, ${date.year}',
                          ),
                        ),
                        Expanded(child: _buildPassItem('TIME', slot)),
                        Expanded(
                          child: _buildPassItem(
                            'CONSULTATION',
                            '₹0 (Plan Benefit)',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18, color: AppColors.primary100),

                    // Hospital Venue Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                clinicName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                clinicAddress,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Arrival Guidelines
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary100),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Arrive 10 mins early for 60x Scalp Dermoscopy scan. Keep scalp oil-free.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.secondaryDark,
                                height: 1.3,
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

              // Calendar Reminders Section (Google Calendar & Apple Calendar)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ADD REMINDER TO YOUR CALENDAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryDark,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  // Google Calendar Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.primary),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () => _addToGoogleCalendar(doctor, date, slot),
                      icon: const Icon(
                        LucideIcons.calendar,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Google Calendar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Apple Calendar Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.primaryDark),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () => _addToAppleCalendar(doctor, date, slot),
                      icon: const Icon(
                        LucideIcons.apple,
                        size: 15,
                        color: AppColors.primaryDark,
                      ),
                      label: const Text(
                        'Apple Calendar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Done',
                  variant: AppButtonVariant.filled,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  // --- BOOKING BOTTOM SHEET (Opens strictly after tapping any specialist card) ---
  void _openBookingBottomSheet(Map<String, dynamic> doctor) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final daysInMonth = DateTime(
              _calendarMonth.year,
              _calendarMonth.month + 1,
              0,
            ).day;
            final firstWeekday = DateTime(
              _calendarMonth.year,
              _calendarMonth.month,
              1,
            ).weekday; // 1 = Mon
            final leadingBlanks = firstWeekday - 1;
            const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

            void changeSheetMonth(int delta) {
              final currentMonthStart = DateTime(now.year, now.month, 1);
              final targetMonth = DateTime(
                _calendarMonth.year,
                _calendarMonth.month + delta,
                1,
              );
              if (targetMonth.isBefore(currentMonthStart)) return;
              final maxMonth = DateTime(now.year, now.month + 3, 1);
              if (targetMonth.isAfter(maxMonth)) return;

              HapticFeedback.selectionClick();
              setModalState(() {
                _calendarMonth = targetMonth;
              });
              setState(() {
                _calendarMonth = targetMonth;
              });
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag pill & Title Header
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Book Appointment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Physical Visit · Mansarovar, Jaipur Clinic',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),

                    const Divider(height: 20, color: AppColors.border),

                    // 1. SELECTED ATTENDANT DETAILS ONLY (No list of other doctors!)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary5,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary100),
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: CustomCachedImage(
                              imageUrl: doctor['avatar'] as String,
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        doctor['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Attending Specialist',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  doctor['degrees'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doctor['specialty'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Select Appointment Date (Slide Interactive Calendar)
                    careSectionHeader(title: 'SELECT APPOINTMENT DATE'),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Month Header & Chevrons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary5,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      LucideIcons.calendar,
                                      size: 15,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_getMonthName(_calendarMonth.month)} ${_calendarMonth.year}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.chevronLeft,
                                      size: 17,
                                    ),
                                    color:
                                        _calendarMonth.isAfter(
                                          DateTime(now.year, now.month, 1),
                                        )
                                        ? AppColors.primaryDark
                                        : AppColors.border,
                                    visualDensity: VisualDensity.compact,
                                    onPressed:
                                        _calendarMonth.isAfter(
                                          DateTime(now.year, now.month, 1),
                                        )
                                        ? () => changeSheetMonth(-1)
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.chevronRight,
                                      size: 17,
                                    ),
                                    color: AppColors.primaryDark,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => changeSheetMonth(1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Weekday Headers
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: weekdays.asMap().entries.map((entry) {
                              final isSun = entry.key == 6;
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSun
                                          ? AppColors.danger.withValues(
                                              alpha: 0.6,
                                            )
                                          : AppColors.secondaryDark,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 6),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 8),

                          // Day Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: leadingBlanks + daysInMonth,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 5,
                                  childAspectRatio: 1.05,
                                ),
                            itemBuilder: (context, index) {
                              if (index < leadingBlanks) {
                                return const SizedBox.shrink();
                              }
                              final dayNumber = index - leadingBlanks + 1;
                              final dayDate = DateTime(
                                _calendarMonth.year,
                                _calendarMonth.month,
                                dayNumber,
                              );
                              final isPast = dayDate.isBefore(today);
                              final isSunday =
                                  dayDate.weekday == DateTime.sunday;
                              final isAvailable = !isPast && !isSunday;
                              final isSelected = _isSameDay(
                                dayDate,
                                _selectedDate,
                              );
                              final isToday = _isSameDay(dayDate, today);

                              return GestureDetector(
                                onTap: isAvailable
                                    ? () {
                                        HapticFeedback.selectionClick();
                                        setModalState(
                                          () => _selectedDate = dayDate,
                                        );
                                        setState(() => _selectedDate = dayDate);
                                      }
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isToday
                                              ? AppColors.primary5
                                              : Colors.transparent),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isToday
                                                ? AppColors.primary100
                                                : Colors.transparent),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$dayNumber',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSelected || isToday
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : (isPast
                                                    ? AppColors.border
                                                    : (isSunday
                                                          ? AppColors
                                                                .secondaryDark
                                                                .withValues(
                                                                  alpha: 0.35,
                                                                )
                                                          : AppColors
                                                                .primaryDark)),
                                        ),
                                      ),
                                      if (isAvailable && !isSelected) ...[
                                        const SizedBox(height: 2),
                                        Container(
                                          width: 3.5,
                                          height: 3.5,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF059669),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 8),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 6),

                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF059669),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Available Date',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.secondaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.border,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Closed (Sun)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.secondaryDark,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${careMonthName(_selectedDate.month)} ${_selectedDate.day} Selected',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 3. Appointment Timing (Custom Animated Dropdown)
                    careSectionHeader(title: 'APPOINTMENT TIME'),
                    const SizedBox(height: 6),
                    CustomAnimatedDropdown<String>(
                      value: _selectedSlot,
                      prefixIcon: LucideIcons.clock,
                      hintText: 'Select appointment timing...',
                      items: _timeSlots.map((slot) {
                        final isMorning =
                            slot.contains('AM') || slot.startsWith('12:');
                        final isPopular =
                            slot == '11:30 AM' || slot == '05:30 PM';
                        return DropdownOption<String>(
                          value: slot,
                          label: slot,
                          subtitle: isMorning
                              ? 'Morning Session · Scalp Dermoscopy'
                              : 'Evening Session · Scalp Dermoscopy',
                          icon: LucideIcons.clock,
                          tag: isPopular ? 'Popular' : 'Available',
                        );
                      }).toList(),
                      onChanged: (newSlot) {
                        setModalState(() => _selectedSlot = newSlot);
                        setState(() => _selectedSlot = newSlot);
                      },
                    ),

                    const SizedBox(height: 18),

                    // 4. Visit Notes (Optional)
                    careSectionHeader(title: 'VISIT NOTES (OPTIONAL)'),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Mention any hair loss symptoms, queries, or medical history for the doctor...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm In-Clinic Appointment Button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'Confirm In-Clinic Appointment',
                        variant: AppButtonVariant.filled,
                        onPressed: () {
                          final notesText = _notesController.text.trim();
                          final combinedNotes = notesText.isEmpty
                              ? 'In-person clinic consultation at Mansarovar, Jaipur.'
                              : 'In-person clinic consultation at Mansarovar, Jaipur. Note: $notesText';

                          // Update Cubit
                          context.read<CareCubit>().bookCoach(
                            coachName: doctor['name'] as String,
                            role: doctor['role'] as String,
                            avatarUrl: doctor['avatar'] as String,
                            date: _selectedDate,
                            timeSlot: _selectedSlot,
                            consultationType:
                                'Physical In-Clinic Visit · Jaipur',
                            notes: combinedNotes,
                          );

                          // Close booking bottom sheet
                          Navigator.pop(sheetContext);

                          // Open professional confirmation pass modal
                          _showConfirmationPass(
                            doctor,
                            _selectedDate,
                            _selectedSlot,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        final allBookings = state.coachBookings;
        final upcomingBookings = allBookings
            .where(
              (b) =>
                  b.status == 'Confirmed' ||
                  (b.status != 'Cancelled' &&
                      b.status != 'Attended' &&
                      b.status != 'Completed'),
            )
            .toList();
        final attendedBookings = allBookings
            .where((b) => b.status == 'Attended' || b.status == 'Completed')
            .toList();
        final cancelledBookings = allBookings
            .where((b) => b.status == 'Cancelled')
            .toList();

        return DefaultTabController(
          length: 3,
          child: CarePageScaffold(
            title: 'Appointments',
            isScrollable: false,
            padding: EdgeInsets.zero,
            child: NestedScrollView(
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. HOSPITAL / CLINIC LOCATION CARD (Single Clinic: Mansarovar, Jaipur)
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0.94, end: 1.0),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary100),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.06,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
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
                                          color: AppColors.primary5,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.building2,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              clinicName,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                            Text(
                                              'Our Clinic Location · Mansarovar, Jaipur',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF059669),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Clinic Address Text
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          LucideIcons.mapPin,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Expanded(
                                        child: Text(
                                          clinicAddress,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textPrimary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.clock,
                                        size: 13,
                                        color: AppColors.secondaryDark,
                                      ),
                                      const SizedBox(width: 5),
                                      const Expanded(
                                        child: Text(
                                          clinicHours,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.secondaryDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.phone,
                                        size: 13,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 5),
                                      const Expanded(
                                        child: Text(
                                          clinicPhone,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Prominent Open in Google Maps Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary5,
                                        foregroundColor: AppColors.primary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: const BorderSide(
                                            color: AppColors.primary100,
                                          ),
                                        ),
                                      ),
                                      onPressed: _openGoogleMaps,
                                      icon: const Icon(
                                        LucideIcons.navigation,
                                        size: 15,
                                        color: AppColors.primary,
                                      ),
                                      label: const Text(
                                        'Open in Google Maps',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2. ATTENDANT / SPECIALIST DETAILS (Horizontal Scrollable with Direct Tap Action)
                          careSectionHeader(title: 'ATTENDING SPECIALISTS'),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 138,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              clipBehavior: Clip.none,
                              itemCount: _doctors.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, idx) {
                                final doctor = _doctors[idx];
                                return DoctorSelectionCard(
                                  doctor: doctor,
                                  onTap: () {
                                    setState(() => _selectedDoctorIndex = idx);
                                    _openBookingBottomSheet(doctor);
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),

                  // 3. PINNED TAB BAR FOR APPOINTMENTS FILTER (Upcoming, Attended, Cancelled)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      tabBar: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.secondaryDark,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'Upcoming (${upcomingBookings.length})'),
                          Tab(text: 'Attended (${attendedBookings.length})'),
                          Tab(text: 'Cancelled (${cancelledBookings.length})'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Tab 1: Upcoming Appointments
                  _buildBookingsList(
                    bookings: upcomingBookings,
                    emptyTitle: 'No Upcoming Visits Scheduled',
                    emptySubtitle: 'Tap any attending specialist above to schedule an in-person consultation and scalp dermoscopy scan in Jaipur.',
                    isUpcoming: true,
                  ),

                  // Tab 2: Attended Appointments
                  _buildBookingsList(
                    bookings: attendedBookings,
                    emptyTitle: 'No Attended Visits Yet',
                    emptySubtitle: 'Your completed in-clinic physical consultations and dermoscopy review records will appear here.',
                    isUpcoming: false,
                  ),

                  // Tab 3: Cancelled Appointments
                  _buildBookingsList(
                    bookings: cancelledBookings,
                    emptyTitle: 'No Cancelled Visits',
                    emptySubtitle:
                        'You have no cancelled in-clinic appointment records.',
                    isUpcoming: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsList({
    required List<dynamic> bookings,
    required String emptyTitle,
    required String emptySubtitle,
    required bool isUpcoming,
  }) {
    if (bookings.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primary5,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUpcoming
                      ? LucideIcons.calendarCheck
                      : (emptyTitle.contains('Attended')
                            ? LucideIcons.checkCheck
                            : LucideIcons.calendarX),
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      physics: const BouncingScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        final isCancelled = b.status == 'Cancelled';
        final isAttended = b.status == 'Attended' || b.status == 'Completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCancelled ? AppColors.border : AppColors.primary100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomCachedImage(
                      imageUrl: b.avatarUrl as String,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                b.coachName as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCancelled
                                    ? AppColors.danger.withValues(alpha: 0.1)
                                    : (isAttended
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFECFDF5)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAttended
                                    ? 'Attended'
                                    : (b.status as String? ?? 'Confirmed'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCancelled
                                      ? AppColors.danger
                                      : (isAttended
                                            ? AppColors.primary
                                            : const Color(0xFF059669)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Mansarovar Clinic · ${b.timeSlot}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          '${careMonthName((b.date as DateTime).month)} ${(b.date as DateTime).day}, ${(b.date as DateTime).year}',
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
              if (isUpcoming && !isCancelled) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: _openGoogleMaps,
                        icon: const Icon(
                          LucideIcons.navigation,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Open in Maps',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 18,
                        ),
                        side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showCancelDialog(
                        context,
                        b.id as String,
                        b.coachName as String,
                      ),
                      icon: const Icon(LucideIcons.x, size: 13),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// SliverPersistentHeaderDelegate for pinning the filter TabBar in [NestedScrollView].
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height + 12;

  @override
  double get maxExtent => tabBar.preferredSize.height + 12;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: shrinkOffset > 0 ? 0.05 : 0.02,
              ),
              blurRadius: shrinkOffset > 0 ? 8 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}
