import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/photo_source_bottom_sheet.dart';
import '../viewmodels/care_cubit.dart';

/// Reusable bottom sheet for capturing and logging scalp progress check-in photos.
class AddPhotoCheckInBottomSheet extends StatefulWidget {
  const AddPhotoCheckInBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => const AddPhotoCheckInBottomSheet(),
    );
  }

  @override
  State<AddPhotoCheckInBottomSheet> createState() =>
      _AddPhotoCheckInBottomSheetState();
}

class _AddPhotoCheckInBottomSheetState
    extends State<AddPhotoCheckInBottomSheet> {
  String? _localImagePath;
  String _region = 'Crown / Vertex';
  String _shedding = 'Low / Normal';
  int _density = 4;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.selectionClick();
    await PhotoSourceBottomSheet.show(
      context,
      title: 'Scalp Progress Photo',
      subtitle: 'Capture a clear photo under bright, direct light',
      cameraTitle: 'Open Camera',
      cameraSubtitle: 'Snap a fresh scalp or hairline photo',
      galleryTitle: 'Select from Gallery',
      gallerySubtitle: 'Choose from your saved photos',
      onSelectSource: (source) async {
        try {
          final picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: source,
            maxWidth: 1280,
            maxHeight: 1280,
            imageQuality: 85,
          );
          if (image != null && mounted) {
            setState(() => _localImagePath = image.path);
            HapticFeedback.lightImpact();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not access image: $e')),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log Hair Progress Check-in',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload consistent scalp photos to track follicle density changes.',
                style: TextStyle(fontSize: 12.5, color: AppColors.secondaryDark),
              ),
              const SizedBox(height: 16),

              // Image Picker Trigger Box
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _localImagePath != null
                          ? AppColors.primary
                          : AppColors.border,
                      width: _localImagePath != null ? 2 : 1,
                    ),
                  ),
                  child: _localImagePath != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(_localImagePath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      LucideIcons.camera,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Retake',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.primary5,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap to capture or upload photo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Camera or photo gallery',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                'Target Scalp Region',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  'Crown / Vertex',
                  'Frontal Hairline',
                  'Temples',
                  'Overall Scalp',
                ].map(
                  (r) => ChoiceChip(
                    label: Text(r),
                    selected: _region == r,
                    onSelected: (val) {
                      if (val) setState(() => _region = r);
                    },
                  ),
                ).toList(),
              ),

              const SizedBox(height: 14),
              const Text(
                'Current Daily Shedding Level',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['Low / Normal', 'Moderate', 'Noticeable', 'Heavy'].map(
                  (s) => ChoiceChip(
                    label: Text(s),
                    selected: _shedding == s,
                    onSelected: (val) {
                      if (val) setState(() => _shedding = s);
                    },
                  ),
                ).toList(),
              ),

              const SizedBox(height: 14),
              const Text(
                'Follicle Density Feel',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (starIndex) {
                  final score = starIndex + 1;
                  return IconButton(
                    icon: Icon(
                      LucideIcons.star,
                      color: score <= _density
                          ? AppColors.starGold
                          : AppColors.border,
                      size: 26,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _density = score);
                    },
                  );
                }),
              ),

              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Clinical Notes / Scalp Feel',
                  hintText: 'e.g. Less hair fall during combing, new baby hairs forming.',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Save Progress Photo',
                  variant: AppButtonVariant.filled,
                  onPressed: () {
                    final image = _localImagePath ??
                        'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=600';

                    context.read<CareCubit>().addProgressCheckIn(
                      date: DateTime.now(),
                      imagePath: image,
                      scalpRegion: _region,
                      sheddingLevel: _shedding,
                      notes: _notesController.text.trim().isEmpty
                          ? 'Logged regular monthly check-in photo.'
                          : _notesController.text.trim(),
                      densityRating: _density,
                    );

                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Progress check-in logged! Clinical team notified.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
