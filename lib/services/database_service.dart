import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/word.dart';
import '../models/child_profile.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all local database operations for MyVoice
/// Everything stays on the device — no cloud storage.
/// TODO: Add backup/restore functionality
/// TODO: Handle database migrations if schema changes
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final _uuid = const Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'myvoice_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create Words table
        await db.execute('''
          CREATE TABLE words(
            id TEXT PRIMARY KEY,
            wordText TEXT NOT NULL,
            category TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        // Create Recordings table
        await db.execute('''
          CREATE TABLE recordings(
            id TEXT PRIMARY KEY,
            wordId TEXT NOT NULL,
            filePath TEXT NOT NULL,
            recordedAt TEXT NOT NULL,
            notes TEXT,
            FOREIGN KEY(wordId) REFERENCES words(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // --- Child Profile (Stored in SharedPreferences for simplicity) ---

  Future<void> saveChildProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_profile', jsonEncode(profile.toJson()));
  }

  Future<ChildProfile?> getChildProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString('child_profile');
    if (profileString == null) return null;
    return ChildProfile.fromJson(jsonDecode(profileString));
  }

  // --- Words CRUD ---

  Future<List<Word>> getAllWords() async {
    final db = await database;
    
    // Get all words
    final List<Map<String, dynamic>> wordMaps = await db.query('words', orderBy: 'updatedAt DESC');
    
    List<Word> words = [];
    
    for (var wordMap in wordMaps) {
      final wordId = wordMap['id'] as String;
      
      // Get recordings for this word
      final List<Map<String, dynamic>> recordingMaps = await db.query(
        'recordings',
        where: 'wordId = ?',
        whereArgs: [wordId],
        orderBy: 'recordedAt DESC',
      );
      
      final recordings = recordingMaps.map((map) => Recording.fromJson(map)).toList();
      words.add(Word.fromJson(wordMap, recordings));
    }
    
    return words;
  }

  Future<void> saveWord(Word word) async {
    final db = await database;
    await db.insert(
      'words',
      word.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteWord(String id) async {
    final db = await database;
    // Recordings will be deleted automatically due to CASCADE, 
    // but we should also delete the actual files (handled in UI/Service layer usually)
    await db.delete(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Recordings CRUD ---

  Future<void> saveRecording(Recording recording) async {
    final db = await database;
    await db.insert(
      'recordings',
      recording.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Update the word's updatedAt timestamp
    await db.update(
      'words',
      {'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [recording.wordId],
    );
  }

  Future<void> deleteRecording(String id) async {
    final db = await database;
    await db.delete(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
