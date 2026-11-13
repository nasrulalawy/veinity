# Veinity Engine 🚀

> **A Unity-class 3D Game Engine where developers code 100% in Flutter & Dart.**

---

## 🏛 Architecture Overview

```text
veinity/
├── packages/
│   ├── veinity_core/       # Pure Dart: Scene Graph, GameObject, Component, Transform, Math, Physics, Input, Loop
│   └── veinity_flutter/    # Flutter integration: GameViewport widget, Input bridge, Software 3D fallback renderer, Touch Joystick
└── examples/
    └── sandbox_3d/         # Fully interactive 3D demo with Player, Physics, Rotating Collectibles, and Flutter HUD
```

### 1. Developer Scripting Experience (Unity `MonoBehaviour` in Dart)
```dart
class PlayerController extends Component {
  double speed = 6.0;
  late Rigidbody3D _rb;

  @override
  void onStart() {
    _rb = getComponent<Rigidbody3D>();
  }

  @override
  void onUpdate(double dt) {
    final h = Input.getAxis(InputAxis.horizontal);
    final v = Input.getAxis(InputAxis.vertical);

    if (h != 0 || v != 0) {
      final dir = Vector3(h, 0.0, v).normalized();
      transform.translate(dir * speed * dt, Space.world);
    }

    if (Input.isActionJustPressed('Jump')) {
      _rb.applyImpulse(Vector3(0.0, 5.0, 0.0));
    }
  }
}
```

### 2. Seamless Flutter UI Overlay
```dart
GameViewport(
  scene: myScene,
  overlayBuilder: (context, scene) {
    return Stack(
      children: [
        Positioned(
          top: 16,
          left: 16,
          child: HealthBarWidget(), // Pure Flutter Widget!
        ),
        const Positioned(
          bottom: 24,
          left: 24,
          child: VirtualJoystick(), // On-screen touch joystick
        ),
      ],
    );
  },
)
```

---

## 🎮 Running the 3D Sandbox Demo

```bash
cd examples/sandbox_3d
flutter run -d macos # or windows, linux, chrome, android, ios
```

- **Controls**:
  - `W, A, S, D` or `Arrow Keys`: Move player
  - `Space`: Jump
  - **On-Screen Touch**: Virtual Joystick + Jump Button
  - **Button "Spawn 3D Cube"**: Dynamically spawns physics cubes falling from the sky.

