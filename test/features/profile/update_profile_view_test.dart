import 'package:dr_hair/features/auth/domain/models/user_model.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_cubit.dart';
import 'package:dr_hair/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:dr_hair/features/profile/presentation/views/update_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

void main() {
  group('UpdateProfileView Widget Tests', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit();
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

    testWidgets('picking image updates photo source and dismisses sheet', (tester) async {
      final fakePicker = _FakeImagePicker(
        mockResult: XFile('/mock/path/profile.jpg'),
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp(home: UpdateProfileView(imagePicker: fakePicker)),
        ),
      );

      // Tap on avatar to open sheet
      await tester.tap(find.bySemanticsLabel('Change profile photo'));
      await tester.pumpAndSettle();

      // Pick from gallery
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();

      expect(fakePicker.lastSource, ImageSource.gallery);
      expect(find.text('Profile photo updated'), findsOneWidget);
    });

    testWidgets('removing photo clears photo and shows confirmation', (tester) async {
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

      expect(find.text('Profile photo removed'), findsOneWidget);
    });

    testWidgets('saving changes updates AuthCubit and pops view', (tester) async {
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

      // Edit name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Yashveer Soni'),
        'Dr. Yashveer Sharma',
      );

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(authCubit.state.user?.name, 'Dr. Yashveer Sharma');
    });
  });
}
