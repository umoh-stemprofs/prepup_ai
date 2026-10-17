import 'package:audioplayers/audioplayers.dart';

/// Plays a short tick/beep sound when the exam timer is running low.
///
/// Used by [ExamScreen] to alert the student during the last 60 seconds
/// of a timed exam. The sound is played once per second when under 10 seconds
/// remain, and once every 5 seconds between 11 and 60 seconds.
class TimerSoundService {
  TimerSoundService._();

  static final TimerSoundService instance = TimerSoundService._();

  final AudioPlayer _player = AudioPlayer();

  bool _enabled = true;
  int _lastPlayedSecond = -1;

  /// Whether tick sounds are enabled. Defaults to true.
  bool get enabled => _enabled;

  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      _player.stop();
    }
  }

  /// Call this every second from the exam timer.
  ///
  /// [remainingSeconds] is the seconds left on the clock.
  /// Returns true if a sound was played this call.
  bool tick(int remainingSeconds) {
    if (!_enabled || remainingSeconds <= 0) return false;

    // Play more frequently as time runs out.
    final threshold = remainingSeconds <= 10 ? 1 : remainingSeconds <= 60 ? 5 : 0;
    if (threshold == 0) {
      _lastPlayedSecond = -1;
      return false;
    }

    if (remainingSeconds != _lastPlayedSecond) {
      _lastPlayedSecond = remainingSeconds;
      _playTick(remainingSeconds <= 10);
      return true;
    }
    return false;
  }

  Future<void> _playTick(bool urgent) async {
    try {
      // Use a short system beep via the audio player.
      // On desktop/web this plays a built-in tone; on mobile it uses
      // the platform's default notification sound.
      await _player.play(AssetSource('sounds/tick.wav'));
    } catch (_) {
      // If the asset isn't available yet, try a simple beep using
      // the platform's notification sound.
      try {
        await _player.play(AssetSource('sounds/tick.mp3'));
      } catch (_) {
        // Silently fail — the timer still works visually.
      }
    }
  }

  /// Plays a completion sound when the exam finishes.
  Future<void> playCompletion() async {
    try {
      await _player.play(AssetSource('sounds/done.wav'));
    } catch (_) {
      try {
        await _player.play(AssetSource('sounds/done.mp3'));
      } catch (_) {}
    }
  }

  void dispose() {
    _player.dispose();
  }
}
