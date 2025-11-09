import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewTypeProvider with ChangeNotifier {
  static const String _prefKey = 'isGridView';
  bool _isGridView = false;

  bool get isGridView => _isGridView;

  ViewTypeProvider() {
    _loadFromPrefs();
  }

  void toggleView(bool value) {
    _isGridView = value;
    _saveToPrefs();
    notifyListeners();
  }

  // Load the value from SharedPreferences
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isGridView = prefs.getBool(_prefKey) ?? false; // default to false (list view)
    notifyListeners();
  }

  // Save the value to SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_prefKey, _isGridView);
  }
}
