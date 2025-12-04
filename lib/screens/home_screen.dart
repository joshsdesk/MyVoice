import 'package:flutter/material.dart';
import '../models/word.dart';
import '../models/child_profile.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbService = DatabaseService();
  List<Word> _words = [];
  ChildProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profile = await _dbService.getChildProfile();
    final words = await _dbService.getAllWords();
    
    if (mounted) {
      setState(() {
        _profile = profile;
        _words = words;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile != null ? '${_profile!.name}\'s Voice' : 'MyVoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings').then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_none, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No words recorded yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap the + button to add your first word'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    final word = _words[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text(
                            word.wordText.isNotEmpty ? word.wordText[0].toUpperCase() : '?',
                            style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          word.wordText,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${word.recordings.length} recording${word.recordings.length == 1 ? '' : 's'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/word_detail',
                            arguments: word.id,
                          ).then((_) => _loadData());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add_word').then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Word'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
