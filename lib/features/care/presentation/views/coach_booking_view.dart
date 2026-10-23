import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../viewmodels/care_cubit.dart';
import '../viewmodels/care_state.dart';
import '../widgets/care_widgets.dart';

/// Book In-Clinic Physical Appointment View
/// Dedicated appointment booking exclusively for in-person physical consultations,
/// 60x scalp dermoscopy, and clinical examinations at Dr. Hair Medical Centres.
class CoachBookingView extends StatefulWidget {
  const CoachBookingView({super.key});

  @override
  State<CoachBookingView> createState() => _CoachBookingViewState();
}

typedef AppointmentBookingView = CoachBookingView;

class _CoachBookingViewState extends State<CoachBookingView> {
  int _selectedClinicIndex = 0;
  int _selectedSpecialistIndex = 0;
  late DateTime _selectedDate;
  late DateTime _calendarMonth;
  String _selectedSlot = '11:30 AM';
  String _consultationType = 'Physical Scalp Dermoscopy & Diagnosis (30m)';
  final TextEditingController _notesController = TextEditingController();
  final Set<String> _selectedSymptoms = {
    'Excessive Shedding',
    'Crown Thinning',
  };

  final List<Map<String, dynamic>> _clinics = [
    {
      'name': 'Dr. Hair Medical Centre - Bandra (W)',
      'city': 'Mumbai',
      'address': 'Crystal Point, 3rd Floor, Linking Road, Bandra West, Mumbai - 400050',
      'landmark': 'Opposite National College',
      'timings': '09:30 AM - 08:30 PM (Mon–Sat)',
      'facilities': '60x Dermoscopy Lab · Trichology Suite · Valet Parking',
      'phone': '+91 22 4589 1200',
      'badge': 'Main Centre',
    },
    {
      'name': 'Dr. Hair Clinical Centre - Indiranagar',
      'city': 'Bengaluru',
      'address':
          '100ft Road, Near Metro Pillar 84, Indiranagar, Bengaluru - 560038',
      'landmark': 'Near BDA Complex',
      'timings': '10:00 AM - 08:00 PM (Mon–Sat)',
      'facilities': 'Microscopic Hair Lab · Clinical Exam Suites',
      'phone': '+91 80 6712 3400',
      'badge': 'Metro Connected',
    },
    {
      'name': 'Dr. Hair Specialist Clinic - South Extension',
      'city': 'Delhi NCR',
      'address':
          'E-14, Main Ring Road, South Extension Part II, New Delhi - 110049',
      'landmark': 'Near AIIMS Metro Station',
      'timings': '09:30 AM - 08:30 PM (Mon–Sat)',
      'facilities': 'Scalp Biopsy Unit · Senior MD Doctors On-Duty',
      'phone': '+91 11 4982 7700',
      'badge': 'Senior MDs On-Duty',
    },
  ];

  final List<Map<String, dynamic>> _specialists = [
    {
      'name': 'Dr. Priya Verma',
      'role': 'Senior Dermatologist & Trichologist',
      'degrees': 'MBBS, MD (AIIMS New Delhi)',
      'exp': '8+ yrs clinical exp',
      'rating': '4.9',
      'reviews': '420+',
      'specialty': '60x Scalp Dermoscopy, Miniaturization & PRP',
      'tag': 'In Clinic Today',
      'tagColor': const Color(0xFF059669),
      'avatar': 'https://images.unsplash.com/photo-1594824813637-883a9e652a6a?q=80&w=300',
    },
    {
      'name': 'Dr. Arvind Mehta',
      'role': 'Chief Hair Restoration Surgeon',
      'degrees': 'MBBS, DVD, Fellow ISHRS',
      'exp': '12+ yrs clinical exp',
      'rating': '5.0',
      'reviews': '680+',
      'specialty': 'Follicular Mapping, Scalp Health & Surgical Triage',
      'tag': 'Senior Specialist',
      'tagColor': const Color(0xFF2563EB),
      'avatar': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=300',
    },
    {
      'name': 'Dr. Sneha Kulkarni',
      'role': 'Consultant Clinical Trichologist',
      'degrees': 'M.Sc Clinical Trichology, DNB',
      'exp': '6+ yrs clinical exp',
      'rating': '4.8',
      'reviews': '310+',
      'specialty': 'Telogen Effluvium, Scalp Sebum Profiling & Barrier Care',
      'tag': 'Slots Available',
      'tagColor': const Color(0xFFD97706),
      'avatar': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=300',
    },
  ];

  final List<String> _physicalConsultationTypes = [
    'Physical Scalp Dermoscopy & Diagnosis (30m)',
    'In-Clinic Follow-up & Progress Scan (20m)',
    'PRP & Clinical Procedure Consultation (30m)',
  ];

  final Map<String, List<String>> _timeSlotsGrouped = {
    'Morning Sessions': ['09:30 AM', '10:30 AM', '11:30 AM'],
    'Afternoon Sessions': ['02:00 PM', '03:30 PM', '04:30 PM'],
    'Evening Sessions': ['06:00 PM', '07:15 PM', '08:00 PM'],
  };

  final List<String> _commonSymptoms = [
    'Excessive Shedding',
    'Receding Hairline',
    'Crown Thinning',
    'Dandruff / Itch',
    'Scalp Inflammation',
    'Review Blood Reports',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to tomorrow or next business day if tomorrow is Sunday
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

  void _toggleSymptom(String symptom) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        if (_selectedSymptoms.length > 1) {
          _selectedSymptoms.remove(symptom);
        }
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  void _showClinicDirectionsDialog(
    BuildContext context,
    Map<String, dynamic> clinic,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary5,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.mapPin,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                clinic['city'] as String,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clinic['name'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              clinic['address'] as String,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 14,
                        color: AppColors.secondaryDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        clinic['timings'] as String,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.phone,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        clinic['phone'] as String,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          clinic['facilities'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Parking: Free patient valet parking available at building entrance.',
              style: TextStyle(fontSize: 11, color: AppColors.secondaryDark),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Opening Maps for ${clinic['name']}... (Demo Preview)',
                  ),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            icon: const Icon(LucideIcons.navigation, size: 14),
            label: const Text('Get Directions'),
          ),
        ],
      ),
    );
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
          'Are you sure you want to cancel your in-clinic consultation with $doctorName? You can re-schedule at any time.',
          style: const TextStyle(fontSize: 12, height: 1.4),
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
              ScaffoldMessenger.of(context).showSnackBar(
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

  void _confirmBooking() {
    final specialist = _specialists[_selectedSpecialistIndex];
    final clinic = _clinics[_selectedClinicIndex];
    final symptomsText = _selectedSymptoms.join(', ');
    final notesText = _notesController.text.trim();
    final combinedNotes = notesText.isEmpty
        ? 'Location: ${clinic['name']}. Concerns: $symptomsText'
        : 'Location: ${clinic['name']}. Concerns: $symptomsText. Notes: $notesText';

    context.read<CareCubit>().bookCoach(
      coachName: specialist['name'] as String,
      role: specialist['role'] as String,
      avatarUrl: specialist['avatar'] as String,
      date: _selectedDate,
      timeSlot: _selectedSlot,
      consultationType: 'In-Clinic Physical Visit · ${clinic['city']}',
      notes: combinedNotes,
    );

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
              ),
              child: const Icon(
                LucideIcons.check,
                color: Color(0xFF059669),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Appointment Confirmed!',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your in-person clinic consultation with ${specialist['name']} is scheduled for ${careMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year} at $_selectedSlot.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary5,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary100),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: CustomCachedImage(
                          imageUrl: specialist['avatar'] as String,
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
                              specialist['name'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              specialist['role'] as String,
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
                  const Divider(height: 20, color: AppColors.primary100),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clinic['name'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              clinic['address'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.primary100),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem('Mode', 'In-Clinic Visit'),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildSummaryItem(
                          'Slot',
                          '$_selectedSlot (${careMonthName(_selectedDate.month)} ${_selectedDate.day})',
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem('Fee', '₹0 (Free Plan)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, size: 15, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please arrive 10 minutes prior to your slot. Bring past blood tests or prescription notes if available.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryDark,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Appointment reminder added to your calendar.',
                          ),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    },
                    icon: const Icon(
                      LucideIcons.calendarPlus,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Add to Calendar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    text: 'Done',
                    variant: AppButtonVariant.filled,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  // --- INTERACTIVE CALENDAR HELPERS ---
  void _changeMonth(int delta) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final targetMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + delta,
      1,
    );

    // Don't navigate to past months
    if (targetMonth.isBefore(currentMonthStart)) return;
    // Don't navigate beyond 3 months ahead
    final maxMonth = DateTime(now.year, now.month + 3, 1);
    if (targetMonth.isAfter(maxMonth)) return;

    HapticFeedback.selectionClick();
    setState(() {
      _calendarMonth = targetMonth;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildCalendarWidget() {
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
    ).weekday; // 1 = Mon, 7 = Sun
    final leadingBlanks = firstWeekday - 1; // 0 for Mon, 6 for Sun

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header & Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_getMonthName(_calendarMonth.month)} ${_calendarMonth.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 18),
                    color:
                        _calendarMonth.isAfter(DateTime(now.year, now.month, 1))
                        ? AppColors.primaryDark
                        : AppColors.border,
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        _calendarMonth.isAfter(DateTime(now.year, now.month, 1))
                        ? () => _changeMonth(-1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 18),
                    color: AppColors.primaryDark,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Weekdays header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              final isWeekend = day == 'Sun';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isWeekend
                          ? AppColors.danger.withValues(alpha: 0.7)
                          : AppColors.secondaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
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
              final isSunday = dayDate.weekday == DateTime.sunday;
              final isAvailable = !isPast && !isSunday;
              final isSelected = _isSameDay(dayDate, _selectedDate);
              final isToday = _isSameDay(dayDate, today);

              return GestureDetector(
                onTap: isAvailable
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedDate = dayDate;
                        });
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday ? AppColors.primary5 : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday
                                ? AppColors.primary100
                                : Colors.transparent),
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isPast
                                        ? AppColors.border
                                        : (isSunday
                                              ? AppColors.secondaryDark
                                                    .withValues(alpha: 0.4)
                                              : AppColors.primaryDark)),
                            ),
                          ),
                          if (isAvailable && !isSelected) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Calendar Status & Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Available Date',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Closed / Sunday',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
              Text(
                '${careMonthName(_selectedDate.month)} ${_selectedDate.day} Selected',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        final activeBookings = state.coachBookings;

        return CarePageScaffold(
          title: 'Book Appointment',
          padding: const EdgeInsets.only(top: 16, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Medical Consultation Banner (Physical In-Clinic)
                    careCard(
                      backgroundColor: AppColors.primary5,
                      border: Border.all(color: AppColors.primary100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'In-Clinic Physical Appointment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    Text(
                                      'Dr. Hair Medical Centre · Scalp Dermoscopy',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.secondaryDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Book an in-person clinical visit at our hair medical center. Includes 60x microscopic trichoscopy, follicular miniaturization staging, and doctor diagnosis.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.secondaryDark,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Trust highlights for Physical Visit
                          Row(
                            children: [
                              _buildTrustBadge(
                                LucideIcons.microscope,
                                '60x Dermoscopy',
                              ),
                              const SizedBox(width: 8),
                              _buildTrustBadge(
                                LucideIcons.stethoscope,
                                'Physical Exam',
                              ),
                              const SizedBox(width: 8),
                              _buildTrustBadge(
                                LucideIcons.mapPin,
                                'In-Clinic Only',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Active Scheduled In-Clinic Bookings Section
                    if (activeBookings.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      careSectionHeader(
                        title:
                            'UPCOMING CLINIC VISITS (${activeBookings.where((b) => b.status != 'Cancelled').length})',
                      ),
                      ...activeBookings.map((b) {
                        final isCancelled = b.status == 'Cancelled';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isCancelled
                                  ? AppColors.border
                                  : AppColors.primary100,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: CustomCachedImage(
                                      imageUrl: b.avatarUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                b.coachName,
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isCancelled
                                                    ? AppColors.danger
                                                          .withValues(
                                                            alpha: 0.1,
                                                          )
                                                    : const Color(0xFFECFDF5),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                b.status,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: isCancelled
                                                      ? AppColors.danger
                                                      : const Color(0xFF059669),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          b.role,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.secondaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              LucideIcons.mapPin,
                                              size: 13,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'In-Clinic Visit · ${b.timeSlot}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (b.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    b.notes,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                              if (!isCancelled) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () =>
                                            _showClinicDirectionsDialog(
                                              context,
                                              _clinics[_selectedClinicIndex],
                                            ),
                                        icon: const Icon(
                                          LucideIcons.navigation,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Clinic Directions',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        visualDensity: VisualDensity.compact,
                                        side: BorderSide(
                                          color: AppColors.danger.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _showCancelDialog(
                                        context,
                                        b.id,
                                        b.coachName,
                                      ),
                                      icon: const Icon(LucideIcons.x, size: 13),
                                      label: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 12,
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
                      }),
                      const SizedBox(height: 10),
                    ],

                    // Step 1: Select Clinic Branch
                    careSectionHeader(title: '1. SELECT CLINIC CENTRE'),
                  ],
                ),
              ),

              // Clinic Branch Selection Cards
              CareHorizontalScrollRow(
                itemCount: _clinics.length,
                spacing: 12,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, idx) {
                  final clinic = _clinics[idx];
                  final isSelected = _selectedClinicIndex == idx;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedClinicIndex = idx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 270,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary5 : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.02),
                            blurRadius: isSelected ? 10 : 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  LucideIcons.building2,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.secondaryDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  clinic['city'] as String,
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
                                  color: const Color(0xFF059669)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  clinic['badge'] as String,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            clinic['name'] as String,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clinic['address'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 12,
                                color: AppColors.secondaryDark,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  clinic['timings'] as String,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.secondaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 2: Consultation Procedure
                    careSectionHeader(title: '2. CLINICAL EXAMINATION TYPE'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _physicalConsultationTypes.map((type) {
                        final isSelected = _consultationType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _consultationType = type);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Step 3: Select Specialist
                    careSectionHeader(title: '3. SELECT ATTENDING DOCTOR'),
                  ],
                ),
              ),

              // Specialist Carousel with natural 16px edge padding
              CareHorizontalScrollRow(
                itemCount: _specialists.length,
                spacing: 12,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, idx) {
                  final specialist = _specialists[idx];
                  final isSelected = _selectedSpecialistIndex == idx;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSpecialistIndex = idx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 260,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary5 : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.02),
                            blurRadius: isSelected ? 10 : 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  ClipOval(
                                    child: CustomCachedImage(
                                      imageUrl: specialist['avatar'] as String,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.badgeCheck,
                                        color: AppColors.primary,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (specialist['tagColor'] as Color)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        specialist['tag'] as String,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              specialist['tagColor'] as Color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      specialist['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      specialist['degrees'] as String,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.secondaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            specialist['role'] as String,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specialist['specialty'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 16, color: AppColors.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.star,
                                    size: 12,
                                    color: Color(0xFFEAB308),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${specialist['rating']} (${specialist['reviews']})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Text(
                                  specialist['exp'] as String,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 4: Calendar with Available Dates
                    careSectionHeader(title: '4. SELECT APPOINTMENT DATE'),
                    const SizedBox(height: 4),
                    _buildCalendarWidget(),

                    const SizedBox(height: 20),

                    // Step 5: Time Slots
                    careSectionHeader(title: '5. SELECT TIME SLOT'),
                    ..._timeSlotsGrouped.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: entry.value.map((slot) {
                                final isSelected = _selectedSlot == slot;
                                return ChoiceChip(
                                  label: Text(slot),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedSlot = slot);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 14),

                    // Step 6: Scalp Symptoms & Notes
                    careSectionHeader(title: '6. SCALP SYMPTOMS & CONCERNS'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _commonSymptoms.map((symptom) {
                        final isSelected = _selectedSymptoms.contains(symptom);
                        return FilterChip(
                          label: Text(symptom),
                          selected: isSelected,
                          onSelected: (_) => _toggleSymptom(symptom),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Additional visit notes: e.g. Noticeable thinning at hairline, itchiness after shampoo...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Pricing / Plan Benefit Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.shieldCheck,
                              color: Color(0xFF059669),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'In-Clinic Benefit: ₹0 Consultation Fee',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                                Text(
                                  'Standard ₹1,200 clinic dermoscopy fee waived for registered patients.',
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
                    ),

                    const SizedBox(height: 20),

                    // Confirm Physical Appointment Button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'Confirm In-Clinic Appointment',
                        variant: AppButtonVariant.filled,
                        onPressed: _confirmBooking,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
