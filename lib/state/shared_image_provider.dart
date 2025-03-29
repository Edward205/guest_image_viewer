import 'package:flutter/foundation.dart';

class SharedImageProvider with ChangeNotifier {
  List<String> _imagePaths = [];

  List<String> get imagePaths => _imagePaths;

  // Replace current images with new ones
  void setImages(List<String> paths) {
    _imagePaths = paths;
    print("Provider updated with ${paths.length} images.");
    notifyListeners();
  }

  // Clear images (e.g., after exiting viewer)
  void clearImages() {
     if (_imagePaths.isNotEmpty) {
        _imagePaths = [];
        print("Provider images cleared.");
        notifyListeners();
     }
  }
}