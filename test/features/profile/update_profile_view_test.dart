import 'dart:async';
import 'dart:typed_data';

import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:dr_hair/features/profile/presentation/views/update_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../auth/fake_auth_repository.dart';

class _FakeImagePicker implements ImagePicker {
  final XFile? mockResult;
  ImageSource? lastSource;

  _FakeImagePicker({this.mockResult});

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    return mockResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SlowAuthRepository extends FakeAuthRepository {
  Completer<UserModel>? completer;

  @override
  Future<UserModel> updateProfile({
    String? name,
    int? age,
    bool clearAge = false,
    String? gender,
    String? city,
    String? occupation,
    String? profileUrl,
    bool clearProfileUrl = false,
  }) async {
    if (completer != null) {
      return completer!.future;
    }
    return super.updateProfile(
      name: name,
      age: age,
      clearAge: clearAge,
      gender: gender,
      city: city,
      occupation: occupation,
      profileUrl: profileUrl,
      clearProfileUrl: clearProfileUrl,
    );
  }
}

void main() {
  group('UpdateProfileView Widget Tests', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit(repository: FakeAuthRepository());
    });

    tearDown(() {
      authCubit.close();
    });

    testWidgets('renders initial profile fields and avatar', (tester) async {
      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const MaterialApp(home: UpdateProfileView()),
        ),
      );

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Change Profile Photo'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byIcon(LucideIcons.camera), findsWidgets);
    });

    testWidgets('tapping Change Profile Photo opens PhotoSourceBottomSheet', (tester) async {
      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const MaterialApp(home: UpdateProfileView()),
        ),
      );

      // Tap Change Profile Photo text
      await tester.tap(find.text('Change Profile Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Remove Profile Photo'), findsOneWidget);
    });

    testWidgets('picking photo updates avatar preview and uploads photo upon saving', (tester) async {
      // 1x1 valid transparent PNG bytes
      final validPngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);
      final fakePicker = _FakeImagePicker(
        mockResult: XFile.fromData(validPngBytes, name: 'avatar_test.png'),
      );

      final fakeRepo = FakeAuthRepository();
      final cubit = AuthCubit(repository: fakeRepo);
      cubit.emit(
        cubit.state.copyWith(
          status: AuthStatus.authenticated,
          user: UserModel.demoPatient(),
        ),
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: cubit,
          child: MaterialApp(home: UpdateProfileView(imagePicker: fakePicker)),
        ),
      );

      // Initially no Image.memory
      expect(find.byType(Image), findsNothing);

      // Tap on avatar to open sheet
      await tester.tap(find.bySemanticsLabel('Change profile photo'));
      await tester.pumpAndSettle();

      // Pick from gallery
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();

      expect(fakePicker.lastSource, ImageSource.gallery);
      // Avatar now displays Image.memory
      expect(find.byType(Image), findsWidgets);

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Photo uploaded and URL updated
      expect(cubit.state.user?.photoUrl, 'https://example.test/profile.jpg');

      cubit.close();
    });

    testWidgets('shows Skeletonizer and NO CircularProgressIndicator when saving is in progress', (tester) async {
      final slowRepo = _SlowAuthRepository();
      slowRepo.completer = Completer<UserModel>();
      final cubit = AuthCubit(repository: slowRepo);
      cubit.emit(
        cubit.state.copyWith(
          status: AuthStatus.authenticated,
          user: UserModel.demoPatient(),
        ),
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const MaterialApp(home: UpdateProfileView()),
        ),
      );
      await tester.pumpAndSettle();

      // No CircularProgressIndicator initially
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(); // Advance into saving state where _isSaving is true

      // CircularProgressIndicator must NOT exist
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Skeletonizer must be active in widget tree
      expect(
        find.byWidgetPredicate((widget) => widget is Skeletonizer),
        findsWidgets,
      );

      // Complete async save
      slowRepo.completer!.complete(UserModel.demoPatient());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      cubit.close();
    });

    testWidgets('removing photo clears it without showing a toast', (tester) async {
      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const MaterialApp(home: UpdateProfileView()),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Change profile photo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove Profile Photo'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byIcon(LucideIcons.userRound), findsWidgets);
    });

    testWidgets('validates name input rejects numbers and short length', (tester) async {
      authCubit.emit(
        authCubit.state.copyWith(
          status: AuthStatus.authenticated,
          user: UserModel.demoPatient(),
        ),
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const MaterialApp(home: UpdateProfileView()),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;

      // Test name with numbers
      await tester.enterText(nameField, 'Rahul123');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Name should not contain numbers'), findsOneWidget);

      // Test name too short
      await tester.enterText(nameField, 'A');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Enter at least 2 characters'), findsOneWidget);
    });

    testWidgets('validates age input rejects out of range numbers', (tester) async {
      authCubit.emit(
        authCubit.state.copyWith(
          status: AuthStatus.authenticated,
          user: UserModel.demoPatient(),
        ),
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const MaterialApp(home: UpdateProfileView()),
        ),
      );

      final ageField = find.byType(TextFormField).at(1);

      await tester.enterText(ageField, '150');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a whole number from 1 to 120'), findsOneWidget);
    });
  });
}
