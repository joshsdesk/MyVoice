import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dbService = DatabaseService();
  ChildProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _dbService.getChildProfile();
    if (mounted) {
      setState(() => _profile = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (_profile != null) ...[
            _buildSectionHeader('Child Profile'),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_profile!.name),
              subtitle: Text('${_profile!.age} years old'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                // TODO: Implement edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile coming soon')),
                );
              },
            ),
          ],
          
          _buildSectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Data'),
            subtitle: const Text('Save all recordings to a file'),
            onTap: () {
              // TODO: Implement export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming in Phase 4')),
              );
            },
          ),
          
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('MyVoice Version'),
            subtitle: Text('1.0.0 (Phase 1)'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.teal.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
