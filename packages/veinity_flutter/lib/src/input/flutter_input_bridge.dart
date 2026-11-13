import 'package:flutter/services.dart';
import 'package:veinity_core/veinity_core.dart';

/// Maps Flutter [KeyEvent]s and pointer events into the Veinity [Input] system.
class FlutterInputBridge {
  FlutterInputBridge._();

  static void handleKeyEvent(KeyEvent event) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;

    // Direct key registration
    final keyLabel = event.logicalKey.keyLabel;
    if (isDown) {
      Input.internalSetKey(keyLabel, true);
    } else if (isUp) {
      Input.internalSetKey(keyLabel, false);
    }

    // Standard gaming key bindings
    _updateAxisFromKeys();
  }

  static void _updateAxisFromKeys() {
    double horizontal = 0.0;
    double vertical = 0.0;

    if (Input.getKey('Key D') || Input.getKey('Arrow Right') || Input.getKey('D')) {
      horizontal += 1.0;
    }
    if (Input.getKey('Key A') || Input.getKey('Arrow Left') || Input.getKey('A')) {
      horizontal -= 1.0;
    }

    if (Input.getKey('Key W') || Input.getKey('Arrow Up') || Input.getKey('W')) {
      vertical += 1.0;
    }
    if (Input.getKey('Key S') || Input.getKey('Arrow Down') || Input.getKey('S')) {
      vertical -= 1.0;
    }

    Input.internalSetAxis(InputAxis.horizontal, horizontal);
    Input.internalSetAxis(InputAxis.vertical, vertical);

    // Jump
    if (Input.getKey('Space') || Input.getKey(' ')) {
      Input.internalSetAction('Jump', true);
    } else {
      Input.internalSetAction('Jump', false);
    }
  }
}
