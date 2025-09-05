import 'package:flutter/foundation.dart';

class TabsController extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setIndex(int i) {
    if (i == _index) return; // evita rebuild desnecessário
    _index = i;
    notifyListeners();
  }
}
