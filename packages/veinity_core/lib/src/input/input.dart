import 'package:vector_math/vector_math_64.dart';

/// Predefined standard input axes.
class InputAxis {
  static const String horizontal = 'Horizontal';
  static const String vertical = 'Vertical';
  static const String mouseX = 'Mouse X';
  static const String mouseY = 'Mouse Y';
}

/// Global input manager providing unified access to keyboard, mouse, touch, and gamepad inputs.
class Input {
  Input._();

  static final Map<String, double> _axes = {
    InputAxis.horizontal: 0.0,
    InputAxis.vertical: 0.0,
    InputAxis.mouseX: 0.0,
    InputAxis.mouseY: 0.0,
  };

  static final Set<String> _keysHeld = {};
  static final Set<String> _keysDown = {};
  static final Set<String> _keysUp = {};

  static final Set<String> _actionsHeld = {};
  static final Set<String> _actionsDown = {};
  static final Set<String> _actionsUp = {};

  static Vector2 _mousePosition = Vector2.zero();
  static Vector2 _mouseDelta = Vector2.zero();
  static Vector2 _scrollDelta = Vector2.zero();

  // --- Axis queries ---

  /// Returns the current value of the virtual axis identified by [axisName] (-1.0 to 1.0).
  static double getAxis(String axisName) => _axes[axisName] ?? 0.0;

  /// Returns 1.0, -1.0, or 0.0 with no smoothing filtering.
  static double getAxisRaw(String axisName) {
    final val = getAxis(axisName);
    if (val > 0.001) return 1.0;
    if (val < -0.001) return -1.0;
    return 0.0;
  }

  // --- Key queries ---

  /// Returns true while the user holds down the key identified by [keyName].
  static bool getKey(String keyName) => _keysHeld.contains(keyName);

  /// Returns true during the frame the user starts pressing down the key.
  static bool getKeyDown(String keyName) => _keysDown.contains(keyName);

  /// Returns true during the frame the user releases the key.
  static bool getKeyUp(String keyName) => _keysUp.contains(keyName);

  // --- Action queries ---

  /// Returns true while the virtual action (e.g. 'Jump', 'Fire') is held down.
  static bool isAction(String actionName) => _actionsHeld.contains(actionName);

  /// Returns true in the frame the action was pressed.
  static bool isActionJustPressed(String actionName) => _actionsDown.contains(actionName);

  /// Returns true in the frame the action was released.
  static bool isActionJustReleased(String actionName) => _actionsUp.contains(actionName);

  // --- Mouse / Pointer queries ---

  /// Current mouse position in screen coordinates.
  static Vector2 get mousePosition => _mousePosition;

  /// Mouse movement delta since the previous frame.
  static Vector2 get mouseDelta => _mouseDelta;

  /// Mouse scroll delta this frame.
  static Vector2 get scrollDelta => _scrollDelta;

  // --- Engine Internal Injection Methods ---

  /// Sets the value of a virtual axis.
  static void internalSetAxis(String axisName, double value) {
    _axes[axisName] = value.clamp(-1.0, 1.0);
  }

  /// Injects a key event from the platform or UI.
  static void internalSetKey(String keyName, bool isPressed) {
    if (isPressed) {
      if (!_keysHeld.contains(keyName)) {
        _keysDown.add(keyName);
      }
      _keysHeld.add(keyName);
    } else {
      _keysHeld.remove(keyName);
      _keysUp.add(keyName);
    }
  }

  /// Injects a high-level action (e.g., from on-screen button or joystick).
  static void internalSetAction(String actionName, bool isPressed) {
    if (isPressed) {
      if (!_actionsHeld.contains(actionName)) {
        _actionsDown.add(actionName);
      }
      _actionsHeld.add(actionName);
    } else {
      _actionsHeld.remove(actionName);
      _actionsUp.add(actionName);
    }
  }

  /// Injects mouse position and delta.
  static void internalSetMouse(Vector2 position, Vector2 delta, [Vector2? scroll]) {
    _mousePosition = position;
    _mouseDelta = delta;
    if (scroll != null) {
      _scrollDelta = scroll;
    }
    _axes[InputAxis.mouseX] = delta.x;
    _axes[InputAxis.mouseY] = delta.y;
  }

  /// Clears edge triggers at the end of each frame.
  static void internalEndFrame() {
    _keysDown.clear();
    _keysUp.clear();
    _actionsDown.clear();
    _actionsUp.clear();
    _mouseDelta = Vector2.zero();
    _scrollDelta = Vector2.zero();
    _axes[InputAxis.mouseX] = 0.0;
    _axes[InputAxis.mouseY] = 0.0;
  }

  /// Clears all input state.
  static void internalReset() {
    _axes.clear();
    _axes[InputAxis.horizontal] = 0.0;
    _axes[InputAxis.vertical] = 0.0;
    _axes[InputAxis.mouseX] = 0.0;
    _axes[InputAxis.mouseY] = 0.0;
    _keysHeld.clear();
    _keysDown.clear();
    _keysUp.clear();
    _actionsHeld.clear();
    _actionsDown.clear();
    _actionsUp.clear();
    _mousePosition = Vector2.zero();
    _mouseDelta = Vector2.zero();
    _scrollDelta = Vector2.zero();
  }
}
