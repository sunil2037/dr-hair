import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/photo_source_bottom_sheet.dart';
import '../../../auth/presentation/viewmodels/auth_cubit.dart';
import '../../data/patient_progress_api.dart';
import '../viewmodels/care_cubit.dart';
import '../../../../core/widgets/app_toast.dart';

/// Reusable bottom sheet for capturing and logging scalp progress check-in photos
/// across 3 clinical angles: Front, Top/Crown, and Back.
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
  String? _frontImagePath;
  String? _topImagePath;
  String? _backImagePath;
  final String _region = 'Crown / Vertex';
  String _shedding = 'Low / Normal';
  bool _savingProgress = false;
  final TextEditingController _notesController = TextEditingController();
  final PatientProgressApi _progressApi = PatientProgressApi();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(String angle) async {
    HapticFeedback.selectionClick();
    String title = 'Upload Scalp Photo';
    String subtitle = 'Capture a clear photo under bright, direct light';

    if (angle == 'front') {
      title = 'Front Hairline Photo';
      subtitle = 'Snap or choose a clear photo of your frontal hairline';
    } else if (angle == 'top') {
      title = 'Top / Crown Photo';
      subtitle = 'Snap or choose a photo of the crown & vertex area';
    } else if (angle == 'back') {
      title = 'Back Scalp Photo';
      subtitle = 'Snap or choose a photo of the rear occipital region';
    }

    await PhotoSourceBottomSheet.show(
      context,
      title: title,
      subtitle: subtitle,
      cameraTitle: 'Open Camera',
      cameraSubtitle: 'Snap a fresh photo for this angle',
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
            setState(() {
              if (angle == 'front') _frontImagePath = image.path;
              if (angle == 'top') _topImagePath = image.path;
              if (angle == 'back') _backImagePath = image.path;
            });
            HapticFeedback.lightImpact();
          }
        } catch (e) {
          if (mounted) {
            AppToast.show(
              context,
              SnackBar(content: Text('Could not access image: $e')),
            );
          }
        }
      },
    );
  }

  Future<void> _saveProgressCheckIn() async {
    if (_savingProgress) return;
    final photoPaths = <String, String>{};
    if (_frontImagePath case final path?) photoPaths['front'] = path;
    if (_topImagePath case final path?) photoPaths['top'] = path;
    if (_backImagePath case final path?) photoPaths['back'] = path;
    if (photoPaths.isEmpty) {
      AppToast.show(
        context,
        const SnackBar(
          content: Text('Add at least one photo before saving your check-in.'),
        ),
      );
      return;
    }

    final date = DateTime.now();
    final checkInId = 'ci_${date.millisecondsSinceEpoch}';
    final note = _notesController.text.trim().isEmpty
        ? 'Logged 3-angle progress check-in photos.'
        : _notesController.text.trim();
    final auth = context.read<AuthCubit?>()?.state;
    final token = auth?.sessionToken;
    final shouldSync = token?.isNotEmpty == true && auth?.isGuest != true;

    setState(() => _savingProgress = true);
    try {
      if (shouldSync) {
        await _progressApi.createCheckIn(
          token: token!,
          id: checkInId,
          date: date,
          photoPaths: photoPaths,
          scalpRegion: _region,
          sheddingLevel: _shedding,
          notes: note,
          densityRating: 4,
        );
      }

      if (!mounted) return;
      context.read<CareCubit>().addProgressCheckIn(
        id: checkInId,
        date: date,
        imagePath: photoPaths.values.first,
        frontImagePath: photoPaths['front'],
        topImagePath: photoPaths['top'],
        backImagePath: photoPaths['back'],
        scalpRegion: _region,
        sheddingLevel: _shedding,
        notes: note,
        densityRating: 4,
        doctorNote: shouldSync
            ? 'Shared with the clinic. Awaiting clinician review.'
            : null,
      );
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingProgress = false);
      AppToast.show(
        context,
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Progress could not be shared with the clinic. ${error is DioException
                ? error.message ?? 'Check your connection and try again.'
                : error is FormatException
                ? error.message
                : 'Try again.'}',
          ),
        ),
      );
    }
  }

  Widget _buildPhotoSlot({
    required String angle,
    required String label,
    required String? imagePath,
    required IconData fallbackIcon,
  }) {
    final hasImage = imagePath != null;

    return Expanded(
      child: GestureDetector(
        onTap: () => _pickPhoto(angle),
        child: Container(
          height: 125,
          decoration: BoxDecoration(
            color: hasImage ? Colors.black : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage ? AppColors.primary : AppColors.border,
              width: hasImage ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(imagePath),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (angle == 'front') _frontImagePath = null;
                        if (angle == 'top') _topImagePath = null;
                        if (angle == 'back') _backImagePath = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.checkCircle2,
                          size: 11,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary5,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            fallbackIcon,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '+ Add Photo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Sheet Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
              child: Column(
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Log Hair Progress Check-in',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Upload 3 photos: Front, Top & Back views',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3-Angle Upload Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary5,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary100),
                      ),
                      child: const Text(
                        'For easier comparison, use the same angles, distance, and lighting each time. Photos stay on this device in the demo and are not reviewed by a clinician.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upload 3 Angles',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          '${[_frontImagePath, _topImagePath, _backImagePath].where((e) => e != null).length}/3 captured',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _buildPhotoSlot(
                          angle: 'front',
                          label: 'Front View',
                          imagePath: _frontImagePath,
                          fallbackIcon: LucideIcons.user,
                        ),
                        const SizedBox(width: 10),
                        _buildPhotoSlot(
                          angle: 'top',
                          label: 'Top / Crown',
                          imagePath: _topImagePath,
                          fallbackIcon: LucideIcons.sparkles,
                        ),
                        const SizedBox(width: 10),
                        _buildPhotoSlot(
                          angle: 'back',
                          label: 'Back View',
                          imagePath: _backImagePath,
                          fallbackIcon: LucideIcons.scan,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Current Daily Shedding Level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children:
                          ['Low / Normal', 'Moderate', 'Noticeable', 'Heavy']
                              .map(
                                (s) => ChoiceChip(
                                  label: Text(s),
                                  selected: _shedding == s,
                                  onSelected: (val) {
                                    if (val) setState(() => _shedding = s);
                                  },
                                ),
                              )
                              .toList(),
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        // labelText: 'Clinical Notes / Scalp Observations',
                        hintText: 'e.g. Less hair fall, thicker feel at crown, regular serum application.',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Non-Scrollable Save Button Footer
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: _savingProgress
                        ? 'Saving progress…'
                        : 'Save Progress Photos',
                    isLoading: _savingProgress,
                    isDisabled: _savingProgress,
                    variant: AppButtonVariant.filled,
                    onPressed: _saveProgressCheckIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
