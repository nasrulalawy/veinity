import '../ecs/scene.dart';
import '../input/input.dart';
import '../time/time.dart';

/// Drives the engine tick loop with fixed-step physics accumulator
/// and variable-step rendering/logic updates.
class GameLoop {
  Scene scene;
  bool _isRunning = false;
  double _accumulator = 0.0;

  /// Maximum time allowed per frame update to avoid the "spiral of death" during lag spikes.
  double maxFrameTime = 0.25;

  GameLoop(this.scene);

  bool get isRunning => _isRunning;

  void start() {
    _isRunning = true;
    _accumulator = 0.0;
  }

  void stop() {
    _isRunning = false;
  }

  /// Advances the engine by [rawDeltaTimeInSeconds].
  ///
  /// Can be called from Flutter's `Ticker`, requestAnimationFrame, or an isolate loop.
  void tick(double rawDeltaTimeInSeconds) {
    if (!_isRunning) return;

    // Clamp frame time to prevent simulation explosion during debugging or stutter
    final dt = rawDeltaTimeInSeconds.clamp(0.0, maxFrameTime);

    // 1. Advance global time
    Time.internalUpdate(dt);

    // 2. Fixed physics steps using accumulator
    _accumulator += Time.deltaTime;
    final fixedDt = Time.fixedDeltaTime;

    while (_accumulator >= fixedDt) {
      scene.fixedUpdate(fixedDt);
      _accumulator -= fixedDt;
    }

    // 3. Variable logic update & late update
    scene.update(Time.deltaTime);

    // 4. Input frame cleanup
    Input.internalEndFrame();
  }
}

