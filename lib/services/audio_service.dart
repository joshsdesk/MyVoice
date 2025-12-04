import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class AudioService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _uuid = const Uuid();
  
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  // Initialize recorder (check permissions)
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  // Start recording
  Future<String?> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'recording_${_uuid.v4()}.m4a';
        final path = p.join(directory.path, fileName);

        // Start recording to file
        await _audioRecorder.start(const RecordConfig(), path: path);
        _isRecording = true;
        return path;
      }
      return null;
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  // Play audio file
  Future<void> playAudio(String filePath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
  }

  // Delete audio file
  Future<void> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting audio file: $e');
    }
  }
  
  // Dispose resources
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
