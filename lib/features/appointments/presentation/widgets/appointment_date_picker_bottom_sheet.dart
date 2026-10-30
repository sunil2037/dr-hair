import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';

class AppointmentDatePickerBottomSheet extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialSlot;

  const AppointmentDatePickerBottomSheet({
    super.key,
    this.initialDate,
    this.initialSlot,
  });

  /// Static helper to open the reusable bottom sheet
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    String? initialSlot,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppointmentDatePickerBottomSheet(
        initialDate: initialDate,
        initialSlot: initialSlot,
      ),
    );
  }

  @override
  State<AppointmentDatePickerBottomSheet> createState() =>
      _AppointmentDatePickerBottomSheetState();
}

class _AppointmentDatePickerBottomSheetState
    extends State<AppointmentDatePickerBottomSheet> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  String? _selectedSlot;

  // Dr. Jai Bansal's Official Sitting Time Slots
  static const List<String> _morningSlots = [
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
  ];

  static const List<String> _eveningSlots = [
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
  ];

  // Official Clinic Holidays (Year-Month-Day formatted)
  static const Set<String> _clinicHolidays = {
    '2026-11-01', // Diwali
    '2026-11-02', // Goverdhan Puja
    '2026-12-25', // Christmas
    '2027-01-26', // Republic Day
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);

    if (widget.initialDate != null) {
      _selectedDate = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
      );
      _selectedSlot = widget.initialSlot;
    } else {
      // Pick first upcoming valid working day
      var candidate = now;
      if (candidate.weekday == DateTime.sunday || _isHoliday(candidate)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      _selectedDate = DateTime(candidate.year, candidate.month, candidate.day);
    }
  }

  bool _isHoliday(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _clinicHolidays.contains(key);
  }

  bool _isSunday(DateTime date) => date.weekday == DateTime.sunday;

  bool _isPastDay(DateTime date) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return date.isBefore(startOfToday);
  }

  DateTime _combineDateAndTime(DateTime date, String slotStr) {
    final parts = slotStr.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    if (parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts[1] == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isSlotPast(DateTime date, String slotStr) {
    final slotTime = _combineDateAndTime(date, slotStr);
    return slotTime.isBefore(DateTime.now());
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _prevMonth() {
    final now = DateTime.now();
    if (_focusedMonth.year == now.year && _focusedMonth.month <= now.month) {
      return; // Cannot go prior to current month
    }
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canGoPrev =
        _focusedMonth.year > now.year || _focusedMonth.month > now.month;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Clinic Visit Slot',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dr. Jai Bansal · Room 101 · Sector 29, Gurugram',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // Scrollable Calendar & Slots Body
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              children: [
                // Month Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _monthName(_focusedMonth),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: canGoPrev ? _prevMonth : null,
                          icon: Icon(
                            LucideIcons.chevronLeft,
                            size: 18,
                            color: canGoPrev ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                        IconButton(
                          onPressed: _nextMonth,
                          icon: const Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Weekday Header
                _buildWeekdayHeader(),

                const SizedBox(height: 6),

                // Calendar Days Grid
                _buildDaysGrid(),

                const SizedBox(height: 12),

                // Legend / Notifications
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary5,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.info, color: AppColors.primary, size: 14),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mon – Sat Open · Sundays & Holidays are Closed for OPD',
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

                const SizedBox(height: 18),

                // Slots Section (Visible when date is picked)
                if (_selectedDate != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dr. Jai Bansal Sitting Slots',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        _selectedDateFormatted(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _buildSlotCategory('Morning Session (10:00 AM – 01:00 PM)', _morningSlots),
                  const SizedBox(height: 14),
                  _buildSlotCategory('Evening Session (03:30 PM – 07:00 PM)', _eveningSlots),
                ],
              ],
            ),
          ),

          // Bottom Confirmation Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Selected Appointment Slot',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedSlotSummary(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: (_selectedDate != null && _selectedSlot != null)
                      ? () {
                          final combined = _combineDateAndTime(
                            _selectedDate!,
                            _selectedSlot!,
                          );
                          Navigator.of(context).pop(combined);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirm Slot',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _selectedSlotSummary() {
    if (_selectedDate == null) return 'Select a date';
    if (_selectedSlot == null) return 'Choose time slot';
    return '${MaterialLocalizations.of(context).formatMediumDate(_selectedDate!)} · $_selectedSlot';
  }

  String _selectedDateFormatted() {
    if (_selectedDate == null) return '';
    return MaterialLocalizations.of(context).formatMediumDate(_selectedDate!);
  }

  String _monthName(DateTime month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S (Off)'];
    return Row(
      children: weekdays.map((day) {
        final isSunday = day.contains('Off');
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSunday ? const Color(0xFFEF4444) : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // In Dart weekday: Mon=1, Sun=7. We want Mon at index 0.
    final leadingEmpty = firstDayOfMonth.weekday - 1;

    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: List.generate(7, (colIndex) {
              final dayIndex = rowIndex * 7 + colIndex - leadingEmpty + 1;
              if (dayIndex < 1 || dayIndex > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }

              final cellDate = DateTime(year, month, dayIndex);
              final isPast = _isPastDay(cellDate);
              final isSunday = _isSunday(cellDate);
              final isHoliday = _isHoliday(cellDate);
              final isDisabled = isPast || isSunday || isHoliday;

              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == cellDate.year &&
                  _selectedDate!.month == cellDate.month &&
                  _selectedDate!.day == cellDate.day;

              return Expanded(
                child: GestureDetector(
                  onTap: isDisabled
                      ? () {
                          if (isSunday) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dr. Jai Bansal\'s clinic is closed on Sundays (Weekly Off).'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else if (isHoliday) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Selected date is an official clinic holiday.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      : () {
                          setState(() {
                            _selectedDate = cellDate;
                            _selectedSlot = null; // reset slot for new date
                          });
                        },
                  child: Container(
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isSunday
                          ? const Color(0xFFFEF2F2)
                          : isHoliday
                          ? const Color(0xFFFFFBEB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : isSunday
                          ? Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.4))
                          : isHoliday
                          ? Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayIndex.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isDisabled
                                ? isSunday
                                ? const Color(0xFFEF4444)
                                : isHoliday
                                ? const Color(0xFFD97706)
                                : AppColors.textMuted
                                : AppColors.primaryDark,
                          ),
                        ),
                        if (isSunday)
                          const Text(
                            'Off',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          )
                        else if (isHoliday)
                          const Text(
                            'Holiday',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildSlotCategory(String title, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isPast = _selectedDate != null && _isSlotPast(_selectedDate!, slot);
            final isSelected = _selectedSlot == slot;

            return ChoiceChip(
              label: Text(
                slot,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isPast
                      ? AppColors.textMuted
                      : isSelected
                      ? Colors.white
                      : AppColors.primaryDark,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFF8FAFC),
              disabledColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : isPast
                      ? const Color(0xFFE2E8F0)
                      : AppColors.border,
                ),
              ),
              onSelected: isPast
                  ? null
                  : (selected) {
                      setState(() {
                        _selectedSlot = selected ? slot : null;
                      });
                    },
            );
          }).toList(),
        ),
      ],
    );
  }
}
