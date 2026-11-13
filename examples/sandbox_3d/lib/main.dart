import 'dart:math' as math;
import 'package:flutter/material.dart' hide Transform;
import 'package:veinity_flutter/veinity_flutter.dart';

// --- Custom Game Components (MonoBehaviour style) ---

/// Rotates a GameObject continuously around its axis.
class RotatorComponent extends Component {
  Vector3 rotationSpeed = Vector3(0.0, 90.0, 0.0); // degrees per second

  RotatorComponent({Vector3? speed}) {
    if (speed != null) rotationSpeed = speed;
  }

  @override
  void onUpdate(double dt) {
    transform.rotate(rotationSpeed * dt);
  }
}

/// Creates a gentle hovering float effect.
class HoverComponent extends Component {
  final double frequency;
  final double amplitude;
  late double _initialY;

  HoverComponent({this.frequency = 3.0, this.amplitude = 0.3});

  @override
  void onStart() {
    super.onStart();
    _initialY = transform.position.y;
  }

  @override
  void onUpdate(double dt) {
    final yOffset = math.sin(Time.time * frequency) * amplitude;
    transform.position = Vector3(
      transform.position.x,
      _initialY + yOffset,
      transform.position.z,
    );
  }
}

/// Controls player movement and jumping.
class PlayerController extends Component {
  double moveSpeed = 6.0;
  double jumpForce = 5.0;
  late Rigidbody3D _rb;

  @override
  void onStart() {
    super.onStart();
    _rb = getComponent<Rigidbody3D>();
  }

  @override
  void onUpdate(double dt) {
    final h = Input.getAxis(InputAxis.horizontal);
    final v = Input.getAxis(InputAxis.vertical);

    if (h != 0 || v != 0) {
      final inputDir = Vector3(h, 0.0, v).normalized();
      transform.translate(inputDir * moveSpeed * dt, Space.world);

      // Smoothly rotate player toward movement direction
      final targetRot = QuaternionHelpers.lookRotation(inputDir);
      transform.rotation = QuaternionHelpers.slerp(transform.rotation, targetRot, 15.0 * dt);
    }

    if (Input.isActionJustPressed('Jump')) {
      _rb.applyImpulse(Vector3(0.0, jumpForce, 0.0));
    }
  }
}

/// Smoothly follows a target GameObject from a fixed offset.
class CameraFollow extends Component {
  final GameObject target;
  Vector3 offset = Vector3(0.0, 5.0, -8.0);
  double smoothSpeed = 8.0;

  CameraFollow({required this.target});

  @override
  void onLateUpdate(double dt) {
    final desiredPosition = target.transform.position + offset;
    transform.position = Vector3Helpers.lerp(
      transform.position,
      desiredPosition,
      (smoothSpeed * dt).clamp(0.0, 1.0),
    );
    transform.lookAt(target.transform.position + Vector3(0.0, 1.0, 0.0));
  }
}

// --- Main Application ---

void main() {
  runApp(const VeinityDemoApp());
}

class VeinityDemoApp extends StatelessWidget {
  const VeinityDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veinity 3D Game Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final Scene _scene;
  late final GameObject _player;
  int _cubesSpawned = 0;

  @override
  void initState() {
    super.initState();
    _buildGameScene();
  }

  void _buildGameScene() {
    _scene = Scene('Sandbox3D');

    // 1. Sunlight
    final sun = GameObject('SunLight');
    sun.transform.position = Vector3(5.0, 15.0, -5.0);
    sun.transform.lookAt(Vector3.zero());
    sun.addComponent(LightComponent(
      type: LightType.directional,
      intensity: 1.5,
      color: Vector3(1.0, 0.95, 0.8),
    ));
    _scene.addGameObject(sun);

    // 2. Ground Blocks
    for (var x = -3; x <= 3; x++) {
      for (var z = -3; z <= 3; z++) {
        final groundBlock = GameObject('Ground_${x}_$z');
        groundBlock.transform.position = Vector3(x * 1.5, -0.6, z * 1.5);
        groundBlock.transform.localScale = Vector3(1.4, 0.2, 1.4);

        final isEven = (x + z) % 2 == 0;
        final color = isEven ? Vector4(0.3, 0.35, 0.4, 1.0) : Vector4(0.2, 0.25, 0.3, 1.0);

        groundBlock.addComponent(MeshRenderer(
          primitiveType: PrimitiveType.cube,
          material: MaterialData(baseColor: color),
        ));
        _scene.addGameObject(groundBlock);
      }
    }

    // 3. Player Character
    _player = GameObject('PlayerCharacter', 'Player');
    _player.transform.position = Vector3(0.0, 0.5, 0.0);
    _player.addComponent(MeshRenderer(
      primitiveType: PrimitiveType.cube,
      material: MaterialData(baseColor: Vector4(0.2, 0.8, 0.4, 1.0)),
    ));
    _player.addComponent(Rigidbody3D(mass: 2.0, useGravity: true));
    _player.addComponent(PlayerController());
    _scene.addGameObject(_player);

    // 4. Rotating Collectibles
    for (var i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2.0);
      final collectible = GameObject('Coin_$i', 'Collectible');
      collectible.transform.position = Vector3(math.cos(angle) * 3.0, 0.8, math.sin(angle) * 3.0);
      collectible.transform.localScale = Vector3(0.5, 0.5, 0.5);
      collectible.addComponent(MeshRenderer(
        primitiveType: PrimitiveType.cube,
        material: MaterialData(baseColor: Vector4(1.0, 0.85, 0.1, 1.0)),
      ));
      collectible.addComponent(RotatorComponent(speed: Vector3(45.0, 120.0, 0.0)));
      collectible.addComponent(HoverComponent());
      _scene.addGameObject(collectible);
    }

    // 5. Camera with Follow script
    final cameraObj = GameObject('MainCamera');
    cameraObj.transform.position = Vector3(0.0, 6.0, -9.0);
    cameraObj.addComponent(CameraComponent(
      fieldOfView: 55.0,
      clearColor: Vector4(0.12, 0.14, 0.18, 1.0),
    ));
    cameraObj.addComponent(CameraFollow(target: _player));
    _scene.addGameObject(cameraObj);
  }

  void _spawnRandomCube() {
    final random = math.Random();
    final x = (random.nextDouble() - 0.5) * 6.0;
    final z = (random.nextDouble() - 0.5) * 6.0;

    final newCube = GameObject('SpawnedCube_$_cubesSpawned');
    newCube.transform.position = Vector3(x, 5.0, z);
    newCube.transform.localScale = Vector3.all(0.6 + random.nextDouble() * 0.4);

    final colors = [
      Vector4(0.9, 0.3, 0.3, 1.0),
      Vector4(0.3, 0.6, 0.9, 1.0),
      Vector4(0.9, 0.5, 0.2, 1.0),
      Vector4(0.8, 0.2, 0.8, 1.0),
    ];
    final selectedColor = colors[random.nextInt(colors.length)];

    newCube.addComponent(MeshRenderer(
      primitiveType: PrimitiveType.cube,
      material: MaterialData(baseColor: selectedColor),
    ));
    newCube.addComponent(Rigidbody3D(mass: 1.0, useGravity: true));
    newCube.addComponent(RotatorComponent(speed: Vector3(30.0, 60.0, 20.0)));

    _scene.addGameObject(newCube);

    setState(() {
      _cubesSpawned++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameViewport(
        scene: _scene,
        overlayBuilder: (context, scene) {
          return SafeArea(
            child: Stack(
              children: [
                // Top HUD Bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🎮 VEINITY 3D ENGINE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.cyanAccent),
                            ),
                            Text(
                              'Pos: (${_player.transform.position.x.toStringAsFixed(1)}, ${_player.transform.position.y.toStringAsFixed(1)}, ${_player.transform.position.z.toStringAsFixed(1)})',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            Text(
                              'Cubes Spawned: $_cubesSpawned',
                              style: const TextStyle(fontSize: 12, color: Colors.amberAccent),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Spawn Cube Button
                      ElevatedButton.icon(
                        onPressed: _spawnRandomCube,
                        icon: const Icon(Icons.add_box, size: 18),
                        label: const Text('Spawn 3D Cube'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls Help Hint (Keyboard)
                Positioned(
                  top: 100,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Keyboard: W,A,S,D / Arrows to Move\nSpace to Jump',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ),
                ),

                // Mobile Virtual Joystick (Bottom Left)
                const Positioned(
                  bottom: 24,
                  left: 24,
                  child: VirtualJoystick(radius: 55),
                ),

                // Mobile Jump Action Button (Bottom Right)
                Positioned(
                  bottom: 32,
                  right: 32,
                  child: GestureDetector(
                    onTapDown: (_) => Input.internalSetAction('Jump', true),
                    onTapUp: (_) => Input.internalSetAction('Jump', false),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'JUMP',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
