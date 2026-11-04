import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/media/data/media_upload_api.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/app_local_cache.dart';
import '../../../treatment/data/patient_clinical_api.dart';
import '../../data/hair_image_detector.dart';
import '../../domain/models/hair_photo_analysis.dart';
import 'hair_test_state.dart';

class HairTestCubit extends Cubit<HairTestState> {
  final ImagePicker _imagePicker;
  final AppLocalCache _cache;
  final MediaUploadApi? _mediaUploadApi;
  final Dio? _dio;
  final PatientClinicalApi _clinicalApi;
  String? _patientId;
  String? _sessionToken;

  String get _draftKey => _patientId != null && _patientId!.isNotEmpty
      ? 'hair_test_draft_${_patientId}_v2'
      : 'hair_test_draft_v2';
  String get _legacyDraftKey => _patientId != null && _patientId!.isNotEmpty
      ? 'hair_test_draft_${_patientId}_v1'
      : 'hair_test_draft_v1';
  String get _completedKey => _patientId != null && _patientId!.isNotEmpty
      ? 'has_completed_hair_test_$_patientId'
      : 'has_completed_hair_test';
  String get _stageKey => _patientId != null && _patientId!.isNotEmpty
      ? 'hair_test_stage_$_patientId'
      : 'hair_test_stage';
  String get _dandruffKey => _patientId != null && _patientId!.isNotEmpty
      ? 'hair_test_dandruff_$_patientId'
      : 'hair_test_dandruff';
  String get _nameKey => _patientId != null && _patientId!.isNotEmpty
      ? 'hair_test_name_$_patientId'
      : 'hair_test_name';
  String get _ageKey => _patientId != null && _patientId!.isNotEmpty
      ? 'hair_test_age_$_patientId'
      : 'hair_test_age';

  HairTestCubit({
    ImagePicker? imagePicker,
    AppLocalCache? cache,
    MediaUploadApi? mediaUploadApi,
    Dio? dio,
    PatientClinicalApi? clinicalApi,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _cache = cache ?? AppLocalCache.instance,
        // ignore: prefer_initializing_formals
        _mediaUploadApi = mediaUploadApi,
        // ignore: prefer_initializing_formals
        _dio = dio,
        _clinicalApi = clinicalApi ??
            PatientClinicalApi(
              client: dio != null
                  ? DioClient(baseUrl: ApiEndpoints.backendBaseUrl, customDio: dio)
                  : null,
            ),
        super(const HairTestState());

  Future<void> bindPatient(String? patientId, {String? sessionToken}) async {
    if (patientId == null || patientId.isEmpty) {
      _patientId = null;
      _sessionToken = null;
      if (!isClosed) emit(const HairTestState());
      return;
    }
    _patientId = patientId;
    _sessionToken = sessionToken;
    await loadSavedState();
    if (sessionToken != null && sessionToken.isNotEmpty) {
      await _syncWithBackend(sessionToken);
    }
  }

  Future<void> _syncWithBackend(String token) async {
    try {
      final record = await _clinicalApi.getClinicalRecord(token);
      final assessments = record['assessments'] as List? ?? [];
      final submitted = assessments
          .whereType<Map>()
          .where((a) => a['status'] != 'draft')
          .toList();
      if (submitted.isNotEmpty) {
        final latest = submitted.first;
        final refNo = latest['reference_no']?.toString();
        final stage = latest['hair_loss_stage']?.toString();
        if (!isClosed) {
          emit(
            state.copyWith(
              isCompleted: true,
              isSubmitted: true,
              referenceNo: refNo,
              stage: stage,
              name: latest['full_name']?.toString() ?? state.name,
              age: latest['age']?.toString() ?? state.age,
              dandruff: latest['dandruff']?.toString() ?? state.dandruff,
            ),
          );
        }
        await _cache.put(_completedKey, true);
        if (stage != null) await _cache.put(_stageKey, stage);
        return;
      }
    } catch (_) {}

    try {
      final dioToUse = _dio ??
          DioClient(
            baseUrl: ApiEndpoints.backendBaseUrl,
            enableDebugLogging: false,
          ).dio;
      final response = await dioToUse.get<Map<String, dynamic>>(
        ApiEndpoints.patientAssessmentDraft,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final draft = response.data?['data']?['draft'];
      if (draft is Map && draft['formData'] is Map && !isClosed) {
        final formData = Map<String, dynamic>.from(draft['formData'] as Map);
        final step = (draft['step'] as num?)?.toInt() ?? 0;
        emit(
          state.copyWith(
            currentStep: step.clamp(0, state.totalSteps - 1),
            name: formData['full_name']?.toString() ??
                formData['name']?.toString() ??
                state.name,
            age: formData['age']?.toString() ?? state.age,
            selectedGender: formData['gender']?.toString() ??
                formData['selectedGender']?.toString() ??
                state.selectedGender,
            stage: formData['stage']?.toString() ?? state.stage,
            primaryConcern: formData['primary_concern']?.toString() ??
                formData['primaryConcern']?.toString() ??
                formData['main_concern']?.toString() ??
                state.primaryConcern,
            duration: formData['duration']?.toString() ?? state.duration,
            dandruff: formData['dandruff']?.toString() ?? state.dandruff,
            gutHealth: formData['gut_health']?.toString() ??
                formData['gutHealth']?.toString() ??
                state.gutHealth,
            stressLevel: formData['stress_level']?.toString() ??
                formData['stressLevel']?.toString() ??
                state.stressLevel,
            familyHistory: formData['family_history']?.toString() ??
                formData['familyHistory']?.toString() ??
                state.familyHistory,
            allergyStatus: formData['allergy_status']?.toString() ??
                formData['allergyStatus']?.toString() ??
                state.allergyStatus,
            allergyDetails: formData['allergy_details']?.toString() ??
                formData['allergyDetails']?.toString() ??
                state.allergyDetails,
            currentMedicationsStatus:
                formData['current_medications_status']?.toString() ??
                    formData['currentMedicationsStatus']?.toString() ??
                    state.currentMedicationsStatus,
            currentMedications: formData['current_medications']?.toString() ??
                formData['currentMedications']?.toString() ??
                state.currentMedications,
          ),
        );
        _cache.put(_draftKey, jsonEncode(_draftJson()));
      }
    } catch (_) {}
  }

  Future<void> loadSavedState() async {
    try {
      await _cache.remove(_legacyDraftKey);
      final hasCompleted = _cache.getBool(_completedKey) ??
          _cache.getBool('has_completed_hair_test') ??
          false;
      var restored = state;
      final rawDraft = _cache.getString(_draftKey) ??
          _cache.getString('hair_test_draft_v2');
      if (rawDraft != null) {
        try {
          final draft = jsonDecode(rawDraft) as Map<String, dynamic>;
          restored = state.copyWith(
            currentStep: ((draft['currentStep'] as num?)?.toInt() ?? 0)
                .clamp(0, state.totalSteps - 1)
                .toInt(),
            isRetesting: draft['isRetesting'] as bool? ?? false,
            name: draft['name'] as String?,
            age: draft['age'] as String?,
            selectedGender: draft['selectedGender'] as String?,
            stage: draft['stage'] as String?,
            primaryConcern: draft['primaryConcern'] as String?,
            duration: draft['duration'] as String?,
            dandruff: draft['dandruff'] as String?,
            gutHealth: draft['gutHealth'] as String?,
            stressLevel: draft['stressLevel'] as String?,
            familyHistory: draft['familyHistory'] as String?,
            allergyStatus: draft['allergyStatus'] as String?,
            allergyDetails: draft['allergyDetails'] as String? ?? '',
            currentMedicationsStatus:
                draft['currentMedicationsStatus'] as String?,
            currentMedications: draft['currentMedications'] as String? ?? '',
            photos:
                (draft['photos'] as Map?)?.map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ) ??
                const {},
            photoAnalysis: (draft['photoAnalysis'] as Map?)?.map(
                  (key, value) => MapEntry(
                    key.toString(),
                    HairPhotoAnalysis.fromJson(
                      Map<String, dynamic>.from(value as Map),
                    ),
                  ),
                ) ??
                const {},
          );
        } catch (_) {
          await _cache.remove(_draftKey);
        }
      }
      final savedStage = _cache.getString(_stageKey) ??
          _cache.getString('hair_test_stage');
      final savedDandruff = _cache.getString(_dandruffKey) ??
          _cache.getString('hair_test_dandruff');
      final savedName = _cache.getString(_nameKey) ??
          _cache.getString('hair_test_name') ??
          '';
      final savedAge = _cache.getString(_ageKey) ??
          _cache.getString('hair_test_age') ??
          '';

      if (hasCompleted) {
        final hasObservedPattern = restored.primaryConcern != null;
        emit(
          restored.copyWith(
            isCompleted: true,
            name: savedName,
            age: savedAge,
            stage: hasObservedPattern
                ? null
                : savedStage ?? 'Stage 1 - Mild temple thinning',
            clearStage: hasObservedPattern,
            dandruff: savedDandruff ?? 'Severe Dandruff & Flakes',
          ),
        );
      } else if (rawDraft != null) {
        emit(restored);
      }
    } catch (_) {}
  }

  Future<void> nextStep({
    String? sessionToken,
    String? patientName,
    int? patientAge,
    String? patientGender,
  }) async {
    final validationMessage = _validationMessageForCurrentStep();
    if (validationMessage != null) {
      emit(state.copyWith(errorMessage: validationMessage));
      return;
    }

    if (state.currentStep < state.totalSteps - 1) {
      emit(
        state.copyWith(
          currentStep: state.currentStep + 1,
          clearErrorMessage: true,
        ),
      );
      _saveDraft();
    } else {
      await submitTest(
        sessionToken: sessionToken,
        patientName: patientName,
        patientAge: patientAge,
        patientGender: patientGender,
      );
    }
  }

  String? _validationMessageForCurrentStep() {
    return _validationMessageForState(state, state.currentStep);
  }

  Future<void> skipPhotosAndSubmit({
    String? sessionToken,
    String? patientName,
    int? patientAge,
    String? patientGender,
  }) async {
    emit(state.copyWith(currentStep: state.totalSteps - 1));
    await submitTest(
      sessionToken: sessionToken,
      patientName: patientName,
      patientAge: patientAge,
      patientGender: patientGender,
    );
  }

  void prevStep() {
    if (state.currentStep > 0) {
      emit(
        state.copyWith(
          currentStep: state.currentStep - 1,
          clearErrorMessage: true,
        ),
      );
      _saveDraft();
    }
  }

  Future<void> submitTest({
    String? sessionToken,
    String? patientName,
    int? patientAge,
    String? patientGender,
  }) async {
    if (state.isSubmitting) return;
    if (sessionToken?.trim().isNotEmpty == true) {
      for (var step = 0; step < state.totalSteps - 1; step++) {
        final message = _validationMessageForStep(step);
        if (message != null) {
          emit(state.copyWith(currentStep: step, errorMessage: message));
          return;
        }
      }
    } else {
      if (state.primaryConcern == null && state.stage == null) {
        emit(state.copyWith(currentStep: 0, errorMessage: 'Choose an illustration, or select “Not sure.”'));
        return;
      }
    }
    final name = patientName?.trim().isNotEmpty == true
        ? patientName!.trim()
        : state.name.trim();
    final age = patientAge?.toString() ?? state.age.trim();
    final gender = patientGender?.trim().isNotEmpty == true
        ? patientGender!.trim()
        : state.selectedGender;
    final stage = state.stage ?? state.primaryConcern;
    final duration = state.duration ?? '1 - 3 years';
    final dandruff = state.dandruff ?? 'Mild / None';
    final gutHealth = state.gutHealth ?? 'Normal';
    final stressLevel = state.stressLevel ?? 'Moderate';
    final familyHistory = state.familyHistory ?? 'No known family history';

    if (sessionToken?.trim().isNotEmpty == true) {
      if (name.isEmpty) {
        emit(
          state.copyWith(
            errorMessage: 'Complete your profile before sending the assessment to the clinic.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isSubmitting: true,
          clearErrorMessage: true,
          name: name,
          age: age,
        ),
      );

      final uploadedUrls = <String, String>{};
      final uploadedPublicIds = <String, String>{};
      if (state.photos.isNotEmpty) {
        try {
          final uploader = _mediaUploadApi ?? MediaUploadApi(dio: _dio);
          final filesToUpload = <MultipartFile>[];
          final fileKeys = <String>[];
          for (final entry in state.photos.entries) {
            final path = entry.value;
            if (path.isNotEmpty) {
              if (path.startsWith('http://') || path.startsWith('https://')) {
                uploadedUrls[entry.key] = path;
              } else {
                filesToUpload.add(await MultipartFile.fromFile(path, filename: path.split('/').last));
                fileKeys.add(entry.key);
              }
            }
          }
          if (filesToUpload.isNotEmpty) {
            final uploadResult = await uploader.uploadFiles(
              token: sessionToken!,
              purpose: 'assessment',
              files: filesToUpload,
            );
            for (var i = 0; i < uploadResult.length; i++) {
              final url = uploadResult[i]['url']?.toString();
              if (url != null && url.isNotEmpty) {
                uploadedUrls[fileKeys[i]] = url;
              }
              final publicId = (uploadResult[i]['public_id'] ?? uploadResult[i]['asset_id'])?.toString();
              if (publicId != null && publicId.isNotEmpty) {
                uploadedPublicIds[fileKeys[i]] = publicId;
              }
            }
          }
        } catch (uploadError) {
          emit(
            state.copyWith(
              isSubmitting: false,
              errorMessage: 'Could not upload assessment photos. Please try again.',
            ),
          );
          return;
        }
      }

      try {
        final client = _dio != null
            ? null
            : DioClient(
                baseUrl: ApiEndpoints.backendBaseUrl,
              );
        final dioToUse = _dio ?? client!.dio;
        final response = await dioToUse.post<Map<String, dynamic>>(
          ApiEndpoints.hairTestSubmitForm,
          data: FormData.fromMap({
            'full_name': name,
            if (age.isNotEmpty) 'age': age,
            if (gender?.isNotEmpty == true)
              'gender': gender,
            'duration': duration,
            if (state.primaryConcern?.isNotEmpty == true)
              'primary_concern': state.primaryConcern,
            if (stage?.isNotEmpty == true) 'stage': stage,
            'dandruff': dandruff,
            'gut_health': gutHealth,
            'stress_level': stressLevel,
            'family_history': familyHistory,
            if (state.allergyStatus?.isNotEmpty == true)
              'allergy_status': state.allergyStatus,
            if (state.allergyDetails.trim().isNotEmpty)
              'allergy_details': state.allergyDetails.trim(),
            if (state.currentMedicationsStatus?.isNotEmpty == true)
              'current_medications_status': state.currentMedicationsStatus,
            if (state.currentMedications.trim().isNotEmpty)
              'current_medications': state.currentMedications.trim(),
            if (uploadedUrls['Front Hairline'] != null)
              'photo_front_url': uploadedUrls['Front Hairline'],
            if (uploadedPublicIds['Front Hairline'] != null)
              'photo_front_id': uploadedPublicIds['Front Hairline'],
            if (uploadedUrls['Crown / Top'] != null)
              'photo_top_url': uploadedUrls['Crown / Top'],
            if (uploadedPublicIds['Crown / Top'] != null)
              'photo_top_id': uploadedPublicIds['Crown / Top'],
            if (uploadedUrls['Side Profile / Temples'] != null)
              'photo_left_url': uploadedUrls['Side Profile / Temples'],
            if (uploadedPublicIds['Side Profile / Temples'] != null)
              'photo_left_id': uploadedPublicIds['Side Profile / Temples'],
          }),
          options: Options(
            contentType: Headers.multipartFormDataContentType,
            headers: {'Authorization': 'Bearer $sessionToken'},
          ),
        );
        final referenceNo = response.data?['reference_no']?.toString() ??
            response.data?['data']?['reference_no']?.toString() ??
            response.data?['data']?['test']?['reference_no']?.toString();
        emit(
          state.copyWith(
            referenceNo: referenceNo,
            isSubmitting: false,
            isSubmitted: true,
            isCompleted: true,
            isRetesting: false,
            clearErrorMessage: true,
          ),
        );
      } on DioException catch (dioErr) {
        final serverMessage = dioErr.response?.data is Map
            ? (dioErr.response?.data['message'] ??
                    dioErr.response?.data['error']?['message'])
                ?.toString()
            : null;
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: serverMessage ??
                'Assessment could not be sent to the clinic. Check your connection and try again.',
          ),
        );
        return;
      } catch (_) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: 'Assessment could not be sent to the clinic. Check your connection and try again.',
          ),
        );
        return;
      }
    } else {
      emit(
        state.copyWith(
          isSubmitted: true,
          isCompleted: true,
          isRetesting: false,
          clearErrorMessage: true,
          name: name,
          age: age,
          stage: stage,
          duration: duration,
          dandruff: dandruff,
          gutHealth: gutHealth,
          stressLevel: stressLevel,
          familyHistory: familyHistory,
        ),
      );
    }

    try {
      await _cache.put(_completedKey, true);
      await _cache.put('has_completed_hair_test', true);
      await _cache.put('has_skipped_hair_test', false);
      if (state.stage != null) {
        await _cache.put(_stageKey, state.stage!);
        await _cache.put('hair_test_stage', state.stage!);
      } else {
        await _cache.remove(_stageKey);
        await _cache.remove('hair_test_stage');
      }
      if (state.dandruff != null) {
        await _cache.put(_dandruffKey, state.dandruff!);
        await _cache.put('hair_test_dandruff', state.dandruff!);
      }
      await _cache.put(_nameKey, state.name);
      await _cache.put(_ageKey, state.age);
      await _cache.remove(_draftKey);
      if (sessionToken != null && sessionToken.isNotEmpty) {
        final dioToUse = _dio ??
            DioClient(
              baseUrl: ApiEndpoints.backendBaseUrl,
              enableDebugLogging: false,
            ).dio;
        unawaited(() async {
          try {
            await dioToUse.delete<Map<String, dynamic>>(
              ApiEndpoints.patientAssessmentDraft,
              options:
                  Options(headers: {'Authorization': 'Bearer $sessionToken'}),
            );
          } catch (_) {}
        }());
      }
    } catch (_) {}
  }

  String? _validationMessageForStep(int step) {
    final answerState = state.copyWith(currentStep: step);
    // Keep the same validation rules for forward navigation and submission.
    return _validationMessageForState(answerState, step);
  }

  String? _validationMessageForState(HairTestState value, int step) {
    switch (step) {
      case 0:
        return value.primaryConcern == null && value.stage == null
            ? 'Choose an illustration, or select “Not sure.”'
            : null;
      case 1:
        return value.duration == null
            ? 'Choose how long you have noticed hair loss to continue.'
            : null;
      case 2:
        return value.dandruff == null
            ? 'Choose a scalp condition to continue.'
            : null;
      case 3:
        return value.stressLevel == null
            ? 'Choose a stress level to continue.'
            : null;
      case 4:
        return value.gutHealth == null
            ? 'Choose a digestion and gut-health option to continue.'
            : null;
      case 5:
        return null;
      case 6:
        if (value.allergyStatus == null) {
          return 'Choose an allergy option to continue.';
        }
        if (value.allergyStatus == 'Yes, I have allergies' &&
            value.allergyDetails.trim().isEmpty) {
          return 'List the known allergies, or choose “Not sure.”';
        }
        if (value.currentMedicationsStatus == null) {
          return 'Choose a medicines and supplements option to continue.';
        }
        if (value.currentMedicationsStatus == 'Yes' &&
            value.currentMedications.trim().isEmpty) {
          return 'List current medicines or supplements, or choose “Not sure.”';
        }
        return null;
      default:
        return null;
    }
  }

  void startRetest() {
    emit(
      state.copyWith(
        isRetesting: true,
        isSubmitted: false,
        currentStep: 0,
        clearReferenceNo: true,
        clearErrorMessage: true,
      ),
    );
    _saveDraft();
  }

  Future<void> markAssessmentSkipped() async {
    await _cache.put('has_skipped_hair_test', true);
  }

  void dismissReport() {
    emit(
      state.copyWith(
        isSubmitted: false,
        isRetesting: false,
        currentStep: 0,
        clearErrorMessage: true,
      ),
    );
  }

  void setPatientInfo({String? name, String? age}) {
    emit(
      state.copyWith(
        name: name ?? state.name,
        age: age ?? state.age,
        clearErrorMessage: true,
      ),
    );
    _saveDraft();
  }

  void selectGender(String gender) {
    emit(state.copyWith(selectedGender: gender, clearErrorMessage: true));
    _saveDraft();
  }

  void selectStage(String stage) {
    emit(
      state.copyWith(
        stage: stage,
        primaryConcern: stage,
        clearErrorMessage: true,
      ),
    );
    _saveDraft();
  }

  void selectPrimaryConcern(String concern) {
    emit(
      state.copyWith(
        primaryConcern: concern,
        clearStage: true,
        clearErrorMessage: true,
      ),
    );
    _saveDraft();
  }

  void selectDandruff(String condition) {
    emit(state.copyWith(dandruff: condition, clearErrorMessage: true));
    _saveDraft();
  }

  void selectGutHealth(String gut) {
    emit(state.copyWith(gutHealth: gut, clearErrorMessage: true));
    _saveDraft();
  }

  void selectStressLevel(String level) {
    emit(state.copyWith(stressLevel: level, clearErrorMessage: true));
    _saveDraft();
  }

  void selectFamilyHistory(String history) {
    emit(state.copyWith(familyHistory: history, clearErrorMessage: true));
    _saveDraft();
  }

  void setAllergyStatus(String status) {
    emit(state.copyWith(allergyStatus: status, clearErrorMessage: true));
    _saveDraft();
  }

  void setAllergyDetails(String details) {
    emit(state.copyWith(allergyDetails: details, clearErrorMessage: true));
    _saveDraft();
  }

  void setCurrentMedicationsStatus(String status) {
    emit(
      state.copyWith(currentMedicationsStatus: status, clearErrorMessage: true),
    );
    _saveDraft();
  }

  void setCurrentMedications(String medications) {
    emit(
      state.copyWith(currentMedications: medications, clearErrorMessage: true),
    );
    _saveDraft();
  }

  void selectDuration(String duration) {
    emit(state.copyWith(duration: duration, clearErrorMessage: true));
    _saveDraft();
  }

  Future<void> pickPhoto({
    required String label,
    required ImageSource source,
  }) async {
    emit(state.copyWith(isPickingImage: true, errorMessage: null));
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        final updatedPhotos = Map<String, String>.from(state.photos);
        updatedPhotos[label] = pickedFile.path;

        final updatedAnalysis =
            Map<String, HairPhotoAnalysis>.from(state.photoAnalysis);
        updatedAnalysis[label] = HairPhotoAnalysis(
          label: label,
          photoPath: pickedFile.path,
          status: HairDetectionStatus.analyzing,
          confidence: 0.0,
          message: 'Analyzing scalp and hair features...',
          details: 'Scanning follicular density...',
        );

        emit(state.copyWith(
          photos: updatedPhotos,
          photoAnalysis: updatedAnalysis,
          isPickingImage: false,
        ));
        _saveDraft();

        final analysis = await HairImageDetector.analyze(
          pickedFile.path,
          label: label,
        );
        final finalAnalysis =
            Map<String, HairPhotoAnalysis>.from(state.photoAnalysis);
        finalAnalysis[label] = analysis;
        emit(state.copyWith(photoAnalysis: finalAnalysis));
        _saveDraft();
      } else {
        emit(state.copyWith(isPickingImage: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isPickingImage: false,
          errorMessage: 'Could not open the image picker. Please try again.',
        ),
      );
    }
  }

  Future<void> setPhoto(
    String label,
    String path, [
    HairPhotoAnalysis? precomputedAnalysis,
  ]) async {
    final updatedPhotos = Map<String, String>.from(state.photos);
    updatedPhotos[label] = path;

    final initialAnalysis = precomputedAnalysis ??
        HairPhotoAnalysis(
          label: label,
          photoPath: path,
          status: HairDetectionStatus.analyzing,
          confidence: 0.0,
          message: 'Analyzing scalp and hair features...',
          details: 'Scanning...',
        );

    final updatedAnalysis =
        Map<String, HairPhotoAnalysis>.from(state.photoAnalysis);
    updatedAnalysis[label] = initialAnalysis;

    emit(state.copyWith(
      photos: updatedPhotos,
      photoAnalysis: updatedAnalysis,
      clearErrorMessage: true,
    ));
    _saveDraft();

    if (precomputedAnalysis != null) return;

    final analysis = await HairImageDetector.analyze(path, label: label);
    if (isClosed) return;
    final finalAnalysis =
        Map<String, HairPhotoAnalysis>.from(state.photoAnalysis);
    finalAnalysis[label] = analysis;
    emit(state.copyWith(photoAnalysis: finalAnalysis));
    _saveDraft();
  }

  void removePhoto(String label) {
    final updatedPhotos = Map<String, String>.from(state.photos);
    updatedPhotos.remove(label);
    final updatedAnalysis =
        Map<String, HairPhotoAnalysis>.from(state.photoAnalysis);
    updatedAnalysis.remove(label);
    emit(state.copyWith(
      photos: updatedPhotos,
      photoAnalysis: updatedAnalysis,
      clearErrorMessage: true,
    ));
    _saveDraft();
  }

  Map<String, dynamic> _draftJson() => {
    'currentStep': state.currentStep,
    'isRetesting': state.isRetesting,
    'name': state.name,
    'age': state.age,
    'selectedGender': state.selectedGender,
    'stage': state.stage,
    'primaryConcern': state.primaryConcern,
    'duration': state.duration,
    'dandruff': state.dandruff,
    'gutHealth': state.gutHealth,
    'stressLevel': state.stressLevel,
    'familyHistory': state.familyHistory,
    'allergyStatus': state.allergyStatus,
    'allergyDetails': state.allergyDetails,
    'currentMedicationsStatus': state.currentMedicationsStatus,
    'currentMedications': state.currentMedications,
    'photos': state.photos,
    'photoAnalysis': state.photoAnalysis.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };

  void _saveDraft() {
    _cache.put(_draftKey, jsonEncode(_draftJson()));
    final token = _sessionToken;
    if (token != null && token.isNotEmpty) {
      final dioToUse = _dio ??
          DioClient(
            baseUrl: ApiEndpoints.backendBaseUrl,
            enableDebugLogging: false,
          ).dio;
      unawaited(() async {
        try {
          await dioToUse.put<Map<String, dynamic>>(
            ApiEndpoints.patientAssessmentDraft,
            data: {
              'step': state.currentStep,
              'formData': _draftJson(),
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } catch (_) {}
      }());
    }
  }

  void reset() {
    emit(const HairTestState());
    _saveDraft();
  }

  Future<void> clearSavedAssessment() async {
    for (final key in [
      _draftKey,
      _legacyDraftKey,
      _completedKey,
      _stageKey,
      _dandruffKey,
      _nameKey,
      _ageKey,
      'hair_test_draft_v2',
      'hair_test_draft_v1',
      'has_completed_hair_test',
      'has_skipped_hair_test',
      'hair_test_stage',
      'hair_test_dandruff',
      'hair_test_name',
      'hair_test_age',
    ]) {
      await _cache.remove(key);
    }
    final token = _sessionToken;
    if (token != null && token.isNotEmpty) {
      try {
        final dioToUse = _dio ??
            DioClient(
              baseUrl: ApiEndpoints.backendBaseUrl,
              enableDebugLogging: false,
            ).dio;
        await dioToUse.delete<Map<String, dynamic>>(
          ApiEndpoints.patientAssessmentDraft,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {}
    }
    emit(const HairTestState());
  }
}
