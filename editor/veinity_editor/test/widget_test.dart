import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veinity_editor/main.dart';

void main() {
  testWidgets('Veinity Editor launches with complete Unity-style IDE layout', (tester) async {
    // Set a desktop resolution (1600 x 900)
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VeinityEditorApp());
    await tester.pump(const Duration(milliseconds: 16));

    // 1. Verify Toolbar
    expect(find.text('VEINITY'), findsOneWidget);
    expect(find.text('3D ENGINE'), findsOneWidget);
    expect(find.text('Add Object'), findsOneWidget);

    // 2. Verify Hierarchy & Default Objects ("Main Cube" is both in Hierarchy and Inspector)
    expect(find.text('HIERARCHY'), findsOneWidget);
    expect(find.text('Main Cube'), findsNWidgets(2));
    expect(find.text('Ground'), findsOneWidget);
    expect(find.text('Directional Light'), findsOneWidget);

    // 3. Verify Inspector
    expect(find.text('INSPECTOR'), findsOneWidget);
    expect(find.text('Transform'), findsOneWidget);
    expect(find.text('Mesh Renderer'), findsOneWidget);
    expect(find.text('Rigidbody 3D'), findsOneWidget);

    // 4. Verify Viewport Status Badge (initially EDITING)
    expect(find.text('EDITING'), findsOneWidget);

    // 5. Test Play Button Toggle
    final playButtonFinder = find.byTooltip('Play');
    expect(playButtonFinder, findsOneWidget);
    await tester.tap(playButtonFinder);
    await tester.pump(const Duration(milliseconds: 16));

    // Verify it switches to PLAYING
    expect(find.text('PLAYING'), findsOneWidget);

    // Stop Play
    final stopButtonFinder = find.byTooltip('Stop');
    await tester.tap(stopButtonFinder);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('EDITING'), findsOneWidget);
  });
}
