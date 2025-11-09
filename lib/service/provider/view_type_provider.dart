import 'package:flutter/material.dart';

class ViewTypeProvider with ChangeNotifier {
  bool _isGridView = false;

  bool get isGridView => _isGridView;

  void toggleView(bool value) {
    _isGridView = value;
    notifyListeners();
  }
}
