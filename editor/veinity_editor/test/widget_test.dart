import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veinity_editor/main.dart';

void main() {
  testWidgets('Veinity Editor launches with authentic Unity-style layout and theme', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VeinityEditorApp());
    await tester.pump(const Duration(milliseconds: 16));

    // 1. Verify Unity Menu Bar & Toolbar
    expect(find.text('File'), findsOneWidget);
    expect(find.text('GameObject'), findsOneWidget);
    expect(find.text('Component'), findsOneWidget);
    expect(find.text('Pivot'), findsOneWidget);
    expect(find.text('Global'), findsOneWidget);

    // 2. Verify Hierarchy Panel Tab & Items
    expect(find.text('Hierarchy'), findsOneWidget);
    expect(find.text('SampleScene'), findsOneWidget);
    expect(find.text('Main Cube'), findsNWidgets(2)); // in Hierarchy and Inspector header

    // 3. Verify Viewport Tabs
    expect(find.text('Scene'), findsOneWidget);
    expect(find.text('Game'), findsOneWidget);
    expect(find.text('Shaded'), findsOneWidget);
    expect(find.text('Gizmos'), findsOneWidget);
    expect(find.text('Persp'), findsOneWidget); // Unity orientation cone

    // 4. Verify Inspector Panel Tab & Transform Fields
    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Transform'), findsOneWidget);
    expect(find.text('Position'), findsOneWidget);
    expect(find.text('Rotation'), findsOneWidget);
    expect(find.text('Scale'), findsOneWidget);
    expect(find.text('Add Component'), findsOneWidget);

    // 5. Verify Bottom Project & Console Tabs
    expect(find.text('Project'), findsOneWidget);
    expect(find.text('Console'), findsOneWidget);
    expect(find.text('Assets'), findsNWidgets(2)); // in Top Menu and Project folder tree
    expect(find.text('Scenes'), findsOneWidget);

    // 6. Test Play Button Toggle
    final playButtonFinder = find.byTooltip('Play');
    expect(playButtonFinder, findsOneWidget);
    await tester.tap(playButtonFinder);
    await tester.pump(const Duration(milliseconds: 16));

    // Verify stop tooltip is now present
    expect(find.byTooltip('Stop Play Mode'), findsOneWidget);
    await tester.tap(find.byTooltip('Stop Play Mode'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byTooltip('Play'), findsOneWidget);
  });
}
