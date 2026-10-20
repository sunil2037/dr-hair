import 'package:dr_hair/core/widgets/photo_source_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('PhotoSourceBottomSheet Widget Tests', () {
    testWidgets('renders camera, gallery options, and remove option when hasExistingPhoto is true', (tester) async {
      ImageSource? selectedSource;
      bool removeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PhotoSourceBottomSheet.show(
                  context,
                  title: 'Upload Photo',
                  subtitle: 'Select source for scalp photo',
                  hasExistingPhoto: true,
                  onSelectSource: (source) => selectedSource = source,
                  onRemovePhoto: () => removeCalled = true,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Photo'), findsOneWidget);
      expect(find.text('Select source for scalp photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Remove Photo'), findsOneWidget);

      // Tap Take Photo
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(selectedSource, ImageSource.camera);
      expect(removeCalled, false);
      expect(find.text('Take Photo'), findsNothing); // Sheet dismissed
    });

    testWidgets('selecting gallery triggers gallery callback', (tester) async {
      ImageSource? selectedSource;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PhotoSourceBottomSheet.show(
                  context,
                  title: 'Profile Photo',
                  hasExistingPhoto: false,
                  onSelectSource: (source) => selectedSource = source,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Remove photo is not visible when hasExistingPhoto is false
      expect(find.text('Remove Photo'), findsNothing);

      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();

      expect(selectedSource, ImageSource.gallery);
    });

    testWidgets('selecting remove photo triggers onRemovePhoto callback', (tester) async {
      bool removeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PhotoSourceBottomSheet.show(
                  context,
                  hasExistingPhoto: true,
                  onSelectSource: (_) {},
                  onRemovePhoto: () => removeCalled = true,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();

      expect(removeCalled, true);
    });
  });
}
