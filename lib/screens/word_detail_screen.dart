import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/word.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';

class WordDetailScreen extends StatefulWidget {
  final String wordId;

  const WordDetailScreen({super.key, required this.wordId});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final _dbService = DatabaseService();
  final _audioService = AudioService();
  Word? _word;
  bool _isLoading = true;
  final bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _loadWord();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadWord() async {
    setState(() => _isLoading = true);
    final words = await _dbService.getAllWords();
    try {
      final word = words.firstWhere((w) => w.id == widget.wordId);
      if (mounted) {
        setState(() {
          _word = word;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Word not found (maybe deleted)
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteWord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word?'),
        content: Text('Are you sure you want to delete "${_word?.wordText}" and all its recordings?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && _word != null) {
      // Delete audio files first
      for (var rec in _word!.recordings) {
        await _audioService.deleteAudioFile(rec.filePath);
      }
      await _dbService.deleteWord(_word!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _addRecording() async {
    // Show simple recording dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RecordingDialog(
        onSave: (path) async {
          if (_word != null) {
            final recording = Recording(
              id: const Uuid().v4(),
              wordId: _word!.id,
              filePath: path,
              recordedAt: DateTime.now(),
            );
            await _dbService.saveRecording(recording);
            _loadWord(); // Reload to show new recording
          }
        },
      ),
    );
  }

  Future<void> _deleteRecording(Recording recording) async {
    await _audioService.deleteAudioFile(recording.filePath);
    await _dbService.deleteRecording(recording.id);
    _loadWord();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_word == null) return const Scaffold(body: Center(child: Text('Word not found')));

    return Scaffold(
      appBar: AppBar(
        title: Text(_word!.wordText),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteWord,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            color: Colors.teal.shade50,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    _word!.wordText[0].toUpperCase(),
                    style: TextStyle(fontSize: 40, color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _word!.wordText,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_word!.recordings.length} recordings',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _word!.recordings.length,
              itemBuilder: (context, index) {
                final recording = _word!.recordings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.play_arrow, color: Colors.white),
                    ),
                    title: Text(
                      DateFormat('MMM d, y • h:mm a').format(recording.recordedAt),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => _deleteRecording(recording),
                    ),
                    onTap: () => _audioService.playAudio(recording.filePath),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecording,
        icon: const Icon(Icons.mic),
        label: const Text('Add Recording'),
      ),
    );
  }
}

// Simple dialog for adding a new recording to an existing word
class _RecordingDialog extends StatefulWidget {
  final Function(String) onSave;

  const _RecordingDialog({required this.onSave});

  @override
  State<_RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<_RecordingDialog> {
  final _audioService = AudioService();
  bool _isRecording = false;
  String? _path;

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioService.stopRecording();
      setState(() {
        _isRecording = false;
        _path = path;
      });
    } else {
      if (await _audioService.hasPermission()) {
        setState(() => _isRecording = true);
        await _audioService.startRecording();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record New Sample'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.teal,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_isRecording ? 'Recording...' : (_path != null ? 'Recorded!' : 'Tap to record')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _path != null
              ? () {
                  widget.onSave(_path!);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
