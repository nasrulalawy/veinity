import 'package:test/test.dart';
import 'package:veinity_core/veinity_core.dart';

class TestController extends Component {
  bool awakeCalled = false;
  bool startCalled = false;
  int updateCount = 0;
  int fixedUpdateCount = 0;
  bool destroyedCalled = false;

  @override
  void onAwake() {
    super.onAwake();
    awakeCalled = true;
  }

  @override
  void onStart() {
    super.onStart();
    startCalled = true;
  }

  @override
  void onUpdate(double dt) {
    updateCount++;
  }

  @override
  void onFixedUpdate(double fixedDt) {
    fixedUpdateCount++;
  }

  @override
  void onDestroy() {
    destroyedCalled = true;
    super.onDestroy();
  }
}

void main() {
  setUp(() {
    Time.internalReset();
    Input.internalReset();
  });

  group('Transform and Hierarchy', () {
    test('local to world position calculation', () {
      final parentObj = GameObject('Parent');
      parentObj.transform.position = Vector3(10.0, 0.0, 0.0);

      final childObj = GameObject('Child');
      childObj.transform.parent = parentObj.transform;
      childObj.transform.localPosition = Vector3(0.0, 5.0, 0.0);

      expect(childObj.transform.position.x, closeTo(10.0, 0.001));
      expect(childObj.transform.position.y, closeTo(5.0, 0.001));
      expect(childObj.transform.position.z, closeTo(0.0, 0.001));
    });

    test('translate and lookAt', () {
      final obj = GameObject('Looker');
      obj.transform.position = Vector3(0.0, 0.0, -10.0);
      obj.transform.lookAt(Vector3.zero());

      expect(obj.transform.forward.z, closeTo(1.0, 0.01));
    });
  });

  group('GameObject & Component Lifecycle', () {
    test('Awake, Start, Update, and Destroy cycle via Scene and GameLoop', () {
      final scene = Scene('TestScene');
      final loop = GameLoop(scene);

      final hero = GameObject('Hero', 'Player');
      final controller = hero.addComponent(TestController());
      scene.addGameObject(hero);

      expect(controller.awakeCalled, isFalse);
      expect(controller.startCalled, isFalse);

      loop.start();

      // First tick (e.g. 0.016s)
      loop.tick(0.016);

      expect(controller.awakeCalled, isTrue);
      expect(controller.startCalled, isTrue);
      expect(controller.updateCount, equals(1));

      // Destroy object
      hero.destroy();
      expect(controller.destroyedCalled, isTrue);

      // Subsequent tick should not update destroyed component
      loop.tick(0.016);
      expect(controller.updateCount, equals(1));
    });

    test('Scene search by name and tag', () {
      final scene = Scene('SearchScene');
      final player = GameObject('PlayerCharacter', 'Player');
      final enemy1 = GameObject('Goblin1', 'Enemy');
      final enemy2 = GameObject('Goblin2', 'Enemy');

      scene.addGameObject(player);
      scene.addGameObject(enemy1);
      scene.addGameObject(enemy2);

      expect(scene.find('PlayerCharacter'), equals(player));
      expect(scene.findWithTag('Enemy').length, equals(2));
      expect(scene.findGameObjectWithTag('Player'), equals(player));
    });
  });

  group('Input System', () {
    test('axes and keys simulation', () {
      Input.internalSetAxis(InputAxis.horizontal, 0.8);
      expect(Input.getAxis(InputAxis.horizontal), closeTo(0.8, 0.001));
      expect(Input.getAxisRaw(InputAxis.horizontal), equals(1.0));

      Input.internalSetKey('Space', true);
      expect(Input.getKey('Space'), isTrue);
      expect(Input.getKeyDown('Space'), isTrue);

      // Simulate frame end
      Input.internalEndFrame();
      expect(Input.getKey('Space'), isTrue);
      expect(Input.getKeyDown('Space'), isFalse); // Edge trigger consumed

      // Release key
      Input.internalSetKey('Space', false);
      expect(Input.getKey('Space'), isFalse);
      expect(Input.getKeyUp('Space'), isTrue);
    });
  });

  group('Physics 3D', () {
    test('Rigidbody3D integrates gravity and movement', () {
      final scene = Scene('PhysicsScene');
      final loop = GameLoop(scene);

      final ball = GameObject('Ball');
      ball.transform.position = Vector3(0.0, 10.0, 0.0);
      final rb = ball.addComponent(Rigidbody3D(mass: 2.0, useGravity: true));
      scene.addGameObject(ball);

      loop.start();

      // Advance physics simulation by 0.1s (5 fixed ticks at 50Hz)
      loop.tick(0.1);

      // Ball should have fallen downwards due to gravity
      expect(ball.transform.position.y, lessThan(10.0));
      expect(rb.velocity.y, lessThan(0.0));
    });
  });
}
