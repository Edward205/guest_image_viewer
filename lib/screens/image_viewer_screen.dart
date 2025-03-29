import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guest_image_viewer/main.dart'; // For pinStorageKey
import 'package:provider/provider.dart';
import 'package:guest_image_viewer/state/shared_image_provider.dart';


class ImageViewerScreen extends StatefulWidget {
  final List<String> imagePaths;

  const ImageViewerScreen({super.key, required this.imagePaths});

   @override
  // Add route name for checking in home_screen
   RouteSettings get settings => const RouteSettings(name: '/image_viewer');


  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final PageController _pageController = PageController();
  final _storage = const FlutterSecureStorage();
  int _currentPage = 0;


  // --- PIN Verification Logic ---
  Future<bool> _verifyPin(String enteredPin) async {
    final String? storedPin = await _storage.read(key: pinStorageKey);
    return storedPin != null && storedPin == enteredPin;
  }

  Future<bool> _showPinDialog() async {
    final pinController = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must enter PIN or cancel
      builder: (BuildContext context) {
        String? errorText;
        // Use StatefulBuilder to update error text inside the dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Enter PIN to Exit'),
              content: TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                       hintText: 'PIN',
                       errorText: errorText,
                   ),
                   onChanged: (_) => setStateDialog(() => errorText = null), // Clear error on change
                 ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false), // Didn't exit
                ),
                ElevatedButton(
                  child: const Text('Confirm'),
                  onPressed: () async {
                    final enteredPin = pinController.text;
                    if (await _verifyPin(enteredPin)) {
                      SystemNavigator.pop();
                    } else {
                       setStateDialog(() { // Update dialog state
                         errorText = 'Incorrect PIN';
                       });
                       pinController.clear();
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
    pinController.dispose();
    return result ?? false; // Return true if PIN was correct, false otherwise
  }
 // --- End PIN Verification ---


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use WillPopScope to intercept the back button press
    return WillPopScope(
      onWillPop: () async {
        bool allowExit = await _showPinDialog();
        if (allowExit) {
           // Clear images *after* successfully exiting
            Provider.of<SharedImageProvider>(context, listen: false).clearImages();
        }
        return allowExit; // Allow pop only if PIN was correct
      },
      child: Scaffold(
        // Extend body behind AppBar to make image fullscreen
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black, // Background for image viewing
        appBar: AppBar(
           title: Text('Image ${_currentPage + 1} of ${widget.imagePaths.length}'),
           backgroundColor: Colors.black.withOpacity(0.5), // Semi-transparent AppBar
           elevation: 0,
           // Back button is handled by WillPopScope, but we show it visually
           leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                 // Trigger the same PIN check as the system back button
                 bool allowExit = await _showPinDialog();
                 if (allowExit && mounted) {
                     Provider.of<SharedImageProvider>(context, listen: false).clearImages();
                     Navigator.of(context).pop();
                 }
              },
            ),
         ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: widget.imagePaths.length,
          onPageChanged: (index) {
             setState(() {
               _currentPage = index;
             });
          },
          itemBuilder: (context, index) {
            final imagePath = widget.imagePaths[index];
            final imageFile = File(imagePath); // Create File object

            // Basic error handling for file access
            return FutureBuilder<bool>(
                future: imageFile.exists(),
                builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.data == true) {
                         return InteractiveViewer( // Allows zooming/panning
                           panEnabled: true,
                           minScale: 0.5,
                           maxScale: 4.0,
                           child: Center(
                             child: Image.file(
                               imageFile,
                               fit: BoxFit.contain, // Fit image within screen bounds
                               errorBuilder: (context, error, stackTrace) {
                                 print("Error loading image file $imagePath: $error");
                                  return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50));
                               },
                             ),
                           ),
                         );
                      } else {
                        print("Image file not found at path: $imagePath");
                         return const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 50));
                      }
                   } else {
                     // Show loader while checking file existence
                     return const Center(child: CircularProgressIndicator());
                   }
                },
             );
          },
        ),
      ),
    );
  }
}