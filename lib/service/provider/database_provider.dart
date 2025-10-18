import '../database/database_helper.dart';
import '../database/table/folder.dart';
import '../database/table/note.dart';
import 'package:flutter/material.dart';

class NoteProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Notes> _notes = [];
  List<Folders> _folders = [];
  bool _isLoading = false;

  List<Notes> get notes => _notes;
  List<Folders> get folders => _folders;
  bool get isLoading => _isLoading;

  Future<void> loadNotes({int? folderId}) async {
    _setLoading(true);
    List<Notes> loadedNotes;
    if (folderId == null) {
      loadedNotes = await _databaseHelper.getNotes();
    } else {
      loadedNotes = await _databaseHelper.getNotes(folderId: folderId);
    }

    _notes = loadedNotes;
    _setLoading(false);
  }

  Future<void> addOrUpdateNotes(Notes note) async {
    if (note.id == null) {
      await _databaseHelper.insertNote(note);
    } else {
      await _databaseHelper.updateNote(note);
    }
    await loadNotes();
  }

  Future<void> deleteNotes(int id) async {
    await _databaseHelper.deleteNote(id);
    await loadNotes();
  }

  Future<void> favoriteNotes(Notes note) async {
    final updatedNotes = note.copyWith(isFavorite: !note.isFavorite);
    await _databaseHelper.updateNote(updatedNotes);
    await loadNotes();
  }

  List<Notes> get favoriteNotesList =>
      _notes.where((w) => w.isFavorite).toList();

  Future<void> loadFolders() async {
    _folders = await _databaseHelper.getFolders();
    notifyListeners();
  }

  Future<Folders> addFolder(String folderName) async {
    final folder = await _databaseHelper.insertFolder(folderName);
    await loadFolders();
    return folder;
  }

  Future<void> updateFolder(Folders folder) async {
    await _databaseHelper.updateFolder(folder);
    await loadNotes();
    await loadFolders();
  }

  Future<void> deleteFolder(int id) async {
    await _databaseHelper.deleteFolder(id);
    await loadNotes();
    await loadFolders();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
