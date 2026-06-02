
import 'package:flutter/foundation.dart';

class LayoutConfigLogic extends ChangeNotifier {
  bool _dark = false;
  bool _isGridStyle = true;

  bool get dark => _dark;
  bool get isGridStyle => _isGridStyle;

  void toggleDark() {
    _dark = !_dark;
    notifyListeners();
  }

  void toggleStyle() {
    _isGridStyle = !_isGridStyle;
    notifyListeners();
  }
}