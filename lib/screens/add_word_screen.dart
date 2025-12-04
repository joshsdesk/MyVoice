import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/word.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';

class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _audioService = AudioService();
  final _dbService = DatabaseService();
  
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _wordController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioService.stopRecording();
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });
    } else {
      // Start recording
      final hasPermission = await _audioService.hasPermission();
      if (hasPermission) {
        setState(() => _isRecording = true);
        await _audioService.startRecording();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
      }
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null && !_isPlaying) {
      setState(() => _isPlaying = true);
      await _audioService.playAudio(_recordedFilePath!);
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _deleteRecording() async {
    if (_recordedFilePath != null) {
      await _audioService.deleteAudioFile(_recordedFilePath!);
      setState(() => _recordedFilePath = null);
    }
  }

  Future<void> _saveWord() async {
    if (_formKey.currentState!.validate()) {
      if (_recordedFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please record audio first')),
        );
        return;
      }

      setState(() => _isSaving = true);

      final wordId = const Uuid().v4();
      final recordingId = const Uuid().v4();
      final now = DateTime.now();

      final recording = Recording(
        id: recordingId,
        wordId: wordId,
        filePath: _recordedFilePath!,
        recordedAt: now,
      );

      final word = Word(
        id: wordId,
        wordText: _wordController.text.trim(),
        recordings: [recording], // Initial recording
        createdAt: now,
        updatedAt: now,
      );

      // Save word (recordings saved separately in DB service usually, but here we need to handle both)
      // Our DB service saveWord handles the word, but we need to save the recording too.
      // Let's modify DB service usage or do it sequentially.
      
      await _dbService.saveWord(word);
      await _dbService.saveRecording(recording);

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Word')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _wordController,
                decoration: const InputDecoration(
                  labelText: 'Word (What does it mean?)',
                  hintText: 'e.g., Ball, Eat, More',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the word';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              
              // Recording Area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    if (_recordedFilePath == null) ...[
                      const Text(
                        'Tap to Record',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.red : Colors.teal,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? Colors.red : Colors.teal).withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      if (_isRecording)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text('Recording...', style: TextStyle(color: Colors.red)),
                        ),
                    ] else ...[
                      const Text(
                        'Recording Saved!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filled(
                            onPressed: _playRecording,
                            icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                            iconSize: 32,
                          ),
                          const SizedBox(width: 24),
                          IconButton.filledTonal(
                            onPressed: _deleteRecording,
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveWord,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Word', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
