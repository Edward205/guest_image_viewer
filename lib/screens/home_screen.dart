import 'package:flutter/material.dart';
import 'package:guest_image_viewer/screens/image_viewer_screen.dart';
import 'package:guest_image_viewer/state/shared_image_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for image updates to potentially navigate automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final imageProvider = Provider.of<SharedImageProvider>(
        context,
        listen: false,
      );
      if (imageProvider.imagePaths.isNotEmpty) {
        _navigateToViewer(context, imageProvider.imagePaths);
      }
    });
  }

  void _navigateToViewer(BuildContext context, List<String> imagePaths) {
    // Use pushReplacement to prevent going back to the empty home screen easily
    // OR use push and let the viewer handle back navigation with PIN
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(imagePaths: imagePaths),
      ),
      // Don't clear images here, clear them when successfully exiting the viewer
      // ).then((_) {
      //    // Clear images when returning from viewer
      //    Provider.of<SharedImageProvider>(context, listen: false).clearImages();
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the image provider
    return Consumer<SharedImageProvider>(
      builder: (context, imageProvider, child) {
        // If images arrive while HomeScreen is visible, navigate
        if (imageProvider.imagePaths.isNotEmpty) {
          // Schedule navigation for after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Check if viewer is already topmost route to prevent duplicates
            if (ModalRoute.of(context)?.settings.name != '/image_viewer') {
              _navigateToViewer(context, imageProvider.imagePaths);
            }
          });
        }

        // Display instructions if no images are loaded yet
        return Scaffold(
          appBar: AppBar(
            title: const Text('Guest Image Viewer'),
            automaticallyImplyLeading: false, // Prevent back without PIN logic
          ),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Share images from your gallery or another app to view them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 100),
                  Text(
                    "This app was generated by Gemini 2.5 Pro.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
