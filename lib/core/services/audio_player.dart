import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Play audio from URL or asset
  Future<void> play(String source, {bool isAsset = false}) async {
    try {
      if (isAsset) {
        await _audioPlayer.play(AssetSource(source));
      } else {
        await _audioPlayer.play(UrlSource(source));
      }
      _isPlaying = true;
    } catch (e) {
      debugPrint('Play error: $e');
    }
  }

  /// Pause audio
  Future<void> pause() async {
    if (!_isPlaying) return;
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  /// Resume audio
  Future<void> resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
  }

  /// Stop audio
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  /// Dispose player
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
