/// Provides global timing information for frame updates and physics ticks.
class Time {
  Time._();

  static double _deltaTime = 0.0;
  static double _unscaledDeltaTime = 0.0;
  static double _time = 0.0;
  static double _realtimeSinceStartup = 0.0;
  static double _fixedDeltaTime = 0.02; // Default 50 Hz physics
  static double _timeScale = 1.0;
  static int _frameCount = 0;

  /// The completion time in seconds since the last frame (scaled by [timeScale]).
  static double get deltaTime => _deltaTime;

  /// The time-scale independent interval in seconds from the last frame to the current one.
  static double get unscaledDeltaTime => _unscaledDeltaTime;

  /// The total elapsed time in seconds since the game started, scaled by [timeScale].
  static double get time => _time;

  /// The real time in seconds since the game started, unaffected by [timeScale].
  static double get realtimeSinceStartup => _realtimeSinceStartup;

  /// The interval in seconds at which physics and fixed frame rate updates are performed.
  static double get fixedDeltaTime => _fixedDeltaTime;
  static set fixedDeltaTime(double value) {
    if (value > 0) {
      _fixedDeltaTime = value;
    }
  }

  /// The scale at which time passes. Can be used for slow-motion effects or paused when 0.
  static double get timeScale => _timeScale;
  static set timeScale(double value) {
    if (value >= 0) {
      _timeScale = value;
    }
  }

  /// The total number of frames that have passed.
  static int get frameCount => _frameCount;

  /// Internal engine update step.
  static void internalUpdate(double rawDt) {
    _unscaledDeltaTime = rawDt;
    _deltaTime = rawDt * _timeScale;
    _time += _deltaTime;
    _realtimeSinceStartup += rawDt;
    _frameCount++;
  }

  /// Resets the time clock (useful for testing or starting a new scene).
  static void internalReset() {
    _deltaTime = 0.0;
    _unscaledDeltaTime = 0.0;
    _time = 0.0;
    _realtimeSinceStartup = 0.0;
    _fixedDeltaTime = 0.02;
    _timeScale = 1.0;
    _frameCount = 0;
  }
}
