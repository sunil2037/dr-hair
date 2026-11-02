import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_hair/features/videos/presentation/views/videos_view.dart';
import 'package:dr_hair/features/videos/presentation/viewmodels/videos_cubit.dart';

void main() {
  testWidgets('VideosView renders safely on web without dart:io Platform exceptions', (
    tester,
  ) async {
    final cubit = VideosCubit();
    await tester.pumpWidget(
      MaterialApp(
        home: VideosView(cubit: cubit),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(VideosView), findsOneWidget);
    expect(tester.takeException(), isNull);
    cubit.close();
  });
}

