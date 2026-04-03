import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isMuted = false;
  bool _isInitialized = false;

  bool get isMuted => _isMuted;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (_isMuted) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _tts.stop();
    }
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      _tts.stop();
    }
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
