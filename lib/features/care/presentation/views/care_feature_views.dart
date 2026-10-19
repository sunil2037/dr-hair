import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class _CarePage extends StatelessWidget {
  final String title;
  final Widget child;

  const _CarePage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: Text(title), backgroundColor: AppColors.background),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  );
}

Widget _card({required Widget child}) => Container(
  width: double.infinity,
  margin: const EdgeInsets.only(bottom: 14),
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.border),
  ),
  child: child,
);

class RoutineTrackerView extends StatefulWidget {
  const RoutineTrackerView({super.key});

  @override
  State<RoutineTrackerView> createState() => _RoutineTrackerViewState();
}

class _RoutineTrackerViewState extends State<RoutineTrackerView> {
  final List<bool> _done = [false, false, false];
  final List<String> _tasks = [
    'Apply scalp serum',
    'Take nutrition supplement',
    'Drink 8 glasses of water',
  ];

  @override
  Widget build(BuildContext context) => _CarePage(
    title: 'Daily Routine',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today’s progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _done.where((v) => v).length / _done.length,
                minHeight: 9,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(
                '${_done.where((v) => v).length} of ${_done.length} routine steps complete',
              ),
            ],
          ),
        ),
        ...List.generate(
          _tasks.length,
          (i) => _card(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _done[i],
              onChanged: (v) => setState(() => _done[i] = v ?? false),
              title: Text(
                _tasks[i],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                i == 0
                    ? 'Evening · Follow your prescribed dosage'
                    : i == 1
                    ? 'After breakfast'
                    : 'Throughout the day',
              ),
            ),
          ),
        ),
        const Text(
          'Your routine resets each day. Follow your clinician’s instructions.',
          style: TextStyle(color: AppColors.secondaryDark),
        ),
      ],
    ),
  );
}

class ProgressTrackingView extends StatefulWidget {
  const ProgressTrackingView({super.key});

  @override
  State<ProgressTrackingView> createState() => _ProgressTrackingViewState();
}

class _ProgressTrackingViewState extends State<ProgressTrackingView> {
  final List<DateTime> _checkins = [
    DateTime(2026, 10, 1),
    DateTime(2026, 9, 1),
  ];

  @override
  Widget build(BuildContext context) => _CarePage(
    title: 'Hair Progress',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your progress journal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Take photos in consistent lighting and angles to compare changes over time. Your photos stay on this device in this demo.',
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDate: DateTime.now(),
              );
              if (date != null && context.mounted) {
                setState(() => _checkins.insert(0, date));
              }
            },
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add progress check-in'),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'CHECK-IN HISTORY',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        ..._checkins.map(
          (d) => _card(
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.photo_camera_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${d.day}/${d.month}/${d.year}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Text(
                  'Photo entry',
                  style: TextStyle(color: AppColors.secondaryDark),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class CoachBookingView extends StatefulWidget {
  const CoachBookingView({super.key});

  @override
  State<CoachBookingView> createState() => _CoachBookingViewState();
}

class _CoachBookingViewState extends State<CoachBookingView> {
  String? _slot;

  @override
  Widget build(BuildContext context) => _CarePage(
    title: 'Book a Hair Coach',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Talk through your care plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Choose a time for a 15-minute guidance call with the Dr.Hair care team.',
              ),
            ],
          ),
        ),
        const Text(
          'AVAILABLE TIMES · TODAY',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        RadioGroup<String>(
          groupValue: _slot,
          onChanged: (value) => setState(() => _slot = value),
          child: Column(
            children: [
              ...['11:00 AM', '2:30 PM', '5:00 PM'].map(
                (slot) => _card(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: slot,
                    title: Text(slot),
                    subtitle: const Text('Phone call · 15 minutes'),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _slot == null
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Coach booking is unavailable until scheduling is connected.',
                      ),
                    ),
                  ),
            child: const Text('Request a call'),
          ),
        ),
      ],
    ),
  );
}

class DietPlanView extends StatefulWidget {
  const DietPlanView({super.key});

  @override
  State<DietPlanView> createState() => _DietPlanViewState();
}

class _DietPlanViewState extends State<DietPlanView> {
  int _day = 0;
  final List<bool> _checked = [false, false, false];
  final List<List<String>> _meals = [
    [
      'Eggs or paneer with fruit',
      'Dal, greens and whole grains',
      'Curd with nuts',
    ],
    [
      'Sprouts or yogurt with fruit',
      'Beans, vegetables and rice',
      'Seeds with a light snack',
    ],
    [
      'Oats with nuts and berries',
      'Paneer/tofu with vegetables',
      'Lentils and leafy greens',
    ],
  ];

  @override
  Widget build(BuildContext context) => _CarePage(
    title: 'Nutrition Guide',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: const Text(
            'A balanced diet can support overall hair health. This sample guide is general information, not a medical diet prescription.',
            style: TextStyle(height: 1.4),
          ),
        ),
        Wrap(
          spacing: 8,
          children: List.generate(
            3,
            (i) => ChoiceChip(
              label: Text('Day ${i + 1}'),
              selected: _day == i,
              onSelected: (_) => setState(() {
                _day = i;
                _checked.fillRange(0, _checked.length, false);
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (i) => _card(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _checked[i],
              onChanged: (v) => setState(() => _checked[i] = v ?? false),
              title: Text(
                ['Breakfast', 'Lunch', 'Snack / dinner'][i],
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(_meals[_day][i]),
            ),
          ),
        ),
      ],
    ),
  );
}

class RemindersView extends StatefulWidget {
  const RemindersView({super.key});

  @override
  State<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends State<RemindersView> {
  final List<bool> _enabled = [true, true, false];
  final List<String> _labels = [
    'Evening scalp serum',
    'Morning supplement',
    'Monthly progress check-in',
  ];

  @override
  Widget build(BuildContext context) => _CarePage(
    title: 'Reminders',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: const Text(
            'Choose which care reminders you want to see. Notifications require system permission when connected to a notification service.',
            style: TextStyle(height: 1.4),
          ),
        ),
        ...List.generate(
          _labels.length,
          (i) => _card(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enabled[i],
              onChanged: (v) => setState(() => _enabled[i] = v),
              title: Text(
                _labels[i],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                i == 0
                    ? 'Daily · 8:00 PM'
                    : i == 1
                    ? 'Daily · 9:00 AM'
                    : 'First day of each month',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class OrderTrackingView extends StatelessWidget {
  const OrderTrackingView({super.key});

  @override
  Widget build(BuildContext context) => _CarePage(
    title: 'Orders & Delivery',
    child: _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your orders and delivery updates will appear here after checkout is connected.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4, color: AppColors.secondaryDark),
          ),
        ],
      ),
    ),
  );
}
