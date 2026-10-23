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

/// 3. Coach Booking View
/// Dedicated appointment booking for video/phone trichologist consultation with Dr.Hair specialists.
class CoachBookingView extends StatefulWidget {
  const CoachBookingView({super.key});

  @override
  State<CoachBookingView> createState() => _CoachBookingViewState();
}

class _CoachBookingViewState extends State<CoachBookingView> {
  int _selectedCoachIndex = 0;
  int _selectedDateOffset = 1; // Tomorrow
  String _selectedSlot = '11:30 AM';
  String _consultationType = 'Video Consultation (15 mins)';
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, String>> _coaches = [
    {
      'name': 'Dr. Priya Verma',
      'role': 'Senior Trichologist & MD',
      'exp': '8+ yrs exp',
      'avatar':
          'https://images.unsplash.com/photo-1594824813637-883a9e652a6a?q=80&w=300',
    },
    {
      'name': 'Aman Saxena',
      'role': 'Clinical Hair Health Coach',
      'exp': '5+ yrs exp',
      'avatar':
          'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=300',
    },
  ];

  final List<String> _slots = [
    '10:00 AM',
    '11:30 AM',
    '02:00 PM',
    '03:30 PM',
    '05:00 PM',
    '06:30 PM',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CareCubit, CareState>(
      builder: (context, state) {
        return CarePageScaffold(
          title: 'Talk to a Hair Coach',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              careCard(
                backgroundColor: AppColors.primary5,
                border: Border.all(color: AppColors.primary100),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dedicated Trichology Guidance',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review your ongoing treatment response, adjust topical dosages, or ask clinical diet questions with your Dr.Hair coach.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.secondaryDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Active Scheduled Bookings (if any)
              if (state.coachBookings.isNotEmpty) ...[
                careSectionHeader(title: 'SCHEDULED CONSULTATIONS'),
                ...state.coachBookings.map((b) {
                  final isCancelled = b.status == 'Cancelled';
                  return careCard(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CustomCachedImage(
                            imageUrl: b.avatarUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.coachName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${b.consultationType} · ${b.timeSlot}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCancelled
                                      ? AppColors.danger.withValues(alpha: 0.1)
                                      : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
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
                        ),
                        if (!isCancelled)
                          IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            tooltip: 'Cancel booking',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.read<CareCubit>().cancelCoachBooking(
                                b.id,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Consultation cancelled.'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],

              careSectionHeader(title: '1. SELECT YOUR SPECIALIST'),
              Row(
                children: _coaches.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final coach = entry.value;
                  final isSelected = _selectedCoachIndex == idx;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCoachIndex = idx);
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: idx == 0 ? 10 : 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary5 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            ClipOval(
                              child: CustomCachedImage(
                                imageUrl: coach['avatar']!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              coach['name']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              coach['exp']!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              careSectionHeader(title: '2. CONSULTATION MODE'),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.video, size: 14),
                          SizedBox(width: 6),
                          Text('Video Call (15m)'),
                        ],
                      ),
                      selected:
                          _consultationType == 'Video Consultation (15 mins)',
                      onSelected: (val) {
                        if (val) {
                          setState(
                            () => _consultationType =
                                'Video Consultation (15 mins)',
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.phoneCall, size: 14),
                          SizedBox(width: 6),
                          Text('Phone Call (15m)'),
                        ],
                      ),
                      selected:
                          _consultationType == 'Phone Consultation (15 mins)',
                      onSelected: (val) {
                        if (val) {
                          setState(
                            () => _consultationType =
                                'Phone Consultation (15 mins)',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              careSectionHeader(title: '3. SELECT DATE & TIME'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(5, (i) {
                    final date = DateTime.now().add(Duration(days: i));
                    final isSelected = _selectedDateOffset == i;
                    final dayLabel = i == 0
                        ? 'Today'
                        : (i == 1
                              ? 'Tomorrow'
                              : '${date.day} ${careMonthName(date.month)}');

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDateOffset = i);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slots.map((s) {
                  final isSelected = _selectedSlot == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedSlot = s);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),
              careSectionHeader(title: '4. QUESTIONS / SYMPTOMS'),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'e.g. Experiencing mild shedding, dosage question about topical serum.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Confirm Guidance Call',
                  variant: AppButtonVariant.filled,
                  onPressed: () {
                    final chosenDate = DateTime.now().add(
                      Duration(days: _selectedDateOffset),
                    );
                    final coach = _coaches[_selectedCoachIndex];

                    context.read<CareCubit>().bookCoach(
                      coachName: coach['name']!,
                      role: coach['role']!,
                      avatarUrl: coach['avatar']!,
                      date: chosenDate,
                      timeSlot: _selectedSlot,
                      consultationType: _consultationType,
                      notes: _notesController.text.trim(),
                    );

                    HapticFeedback.mediumImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFFECFDF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.check,
                                color: Color(0xFF059669),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Consultation Booked!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Appointment with ${coach['name']} on ${careMonthName(chosenDate.month)} ${chosenDate.day} at $_selectedSlot.\nYou will receive a WhatsApp reminder 15 minutes before the call.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryDark,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
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
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
