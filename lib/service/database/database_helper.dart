import 'package:notes/service/database/table/folder.dart';
import 'package:notes/service/database/table/note.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'Notes.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folderId INTEGER,
            title TEXT NOT NULL,
            description TEXT,
            colorPicked INTEGER,
            dateTime TEXT,
            isFavorite INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folderName TEXT NOT NULL,
            folderDateTime TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS folders_tmp (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              folderName TEXT NOT NULL,
              folderDateTime TEXT
            )
          ''');
          await db.execute('''
            INSERT INTO folders_tmp (folderName, folderDateTime)
            SELECT folderName, folderDateTime FROM folders
          ''');
          await db.execute('DROP TABLE folders');
          await db.execute('ALTER TABLE folders_tmp RENAME TO folders');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS notes_tmp (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              folderId INTEGER,
              title TEXT NOT NULL,
              description TEXT,
              dateTime TEXT,
              isFavorite INTEGER NOT NULL DEFAULT 0
            )
          ''');

          await db.execute('''
            INSERT INTO notes_tmp (id, folderId, title, description, dateTime, isFavorite)
            SELECT id, folderId, title, description, dateTime, 0 FROM notes
          ''');

          await db.execute('DROP TABLE notes');
          await db.execute('ALTER TABLE notes_tmp RENAME TO notes');
        }
      },
    );
  }

  Future<int> insertNote(Notes note) async {
    final db = await database;
    return await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Notes>> getNotes({int? folderId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: folderId != null ? 'folderId = ?' : null,
      whereArgs: folderId != null ? [folderId] : null,
      orderBy: 'id DESC',
    );
    return maps.map((map) => Notes.fromMap(map)).toList();
  }

  Future<int> updateNote(Notes note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'notes',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Folders> insertFolder(String name) async {
    final db = await database;

    final folder = Folders(
      folderName: name,
      folderDateTime: DateTime.now().toIso8601String(),
    );

    final id = await db.insert('folders', folder.toMap());
    folder.id = id;
    return folder;
  }

  Future<List<Folders>> getFolders() async {
    final db = await database;
    final maps = await db.query('folders', orderBy: 'id DESC');
    return maps.map((map) => Folders.fromMap(map)).toList();
  }

  Future<Folders?> getFolderById(int id) async {
    final db = await database;
    final result = await db.query('folders', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Folders.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateFolder(Folders folder) async {
    final db = await database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

}
