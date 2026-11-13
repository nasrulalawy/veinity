import 'package:veinity_core/veinity_core.dart';

class PlayerMovement extends Component {
  double speed = 10.0;

  @override
  void onUpdate(double dt) {
    final horizontal = Input.getAxis(InputAxis.horizontal);
    final vertical = Input.getAxis(InputAxis.vertical);

    if (horizontal != 0.0 || vertical != 0.0) {
      final direction = Vector3(horizontal, 0.0, vertical).normalized();
      transform.translate(direction * speed * dt);
      print('Player moved to position: ${transform.position}');
    }
  }
}

void main() {
  final scene = Scene('MainLevel');
  final loop = GameLoop(scene);

  // Create a Player GameObject
  final player = GameObject('Player', 'Player');
  player.transform.position = Vector3(0.0, 1.0, 0.0);
  player.addComponent(PlayerMovement());
  player.addComponent(MeshRenderer(primitiveType: PrimitiveType.cube));
  player.addComponent(Rigidbody3D(mass: 70.0));

  scene.addGameObject(player);

  // Start engine loop
  loop.start();

  // Simulate moving right
  Input.internalSetAxis(InputAxis.horizontal, 1.0);

  // Run a frame of 16ms
  loop.tick(0.016);
  print('Simulated 1 frame: Player position is ${player.transform.position}');
}
