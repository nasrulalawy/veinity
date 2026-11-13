import 'package:flutter_test/flutter_test.dart';
import 'package:sandbox_3d/main.dart';

void main() {
  testWidgets('Sandbox 3D app launches successfully', (tester) async {
    await tester.pumpWidget(const VeinityDemoApp());

    // Verify Title is present
    expect(find.text('🎮 VEINITY 3D ENGINE'), findsOneWidget);
    expect(find.text('Spawn 3D Cube'), findsOneWidget);

    // Pump a few frame ticks
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    // Tap Spawn 3D Cube
    await tester.tap(find.text('Spawn 3D Cube'));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Cubes Spawned: 1'), findsOneWidget);
  });
}
