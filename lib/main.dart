import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guest_image_viewer/screens/home_screen.dart';
import 'package:guest_image_viewer/screens/pin_setup_screen.dart';
import 'package:guest_image_viewer/state/shared_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:permission_handler/permission_handler.dart';


const String pinStorageKey = 'app_pin';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: Request storage permission proactively on Android
  // (especially for older versions or specific scenarios)
  if (Platform.isAndroid) {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    // For scoped storage on Android 10+ this might not be strictly needed
    // for reading shared files, but doesn't hurt.
     var photoStatus = await Permission.photos.status; // For Android 13+
     if (!photoStatus.isGranted) {
       await Permission.photos.request();
     }
  }


  final storage = FlutterSecureStorage();
  final String? storedPin = await storage.read(key: pinStorageKey);

  runApp(
    ChangeNotifierProvider(
      create: (context) => SharedImageProvider(),
      child: MyApp(isPinSet: storedPin != null && storedPin.isNotEmpty),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isPinSet;

  const MyApp({super.key, required this.isPinSet});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _handleInitialAndStreamIntents();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _handleInitialAndStreamIntents() {
    final imageProvider = Provider.of<SharedImageProvider>(context, listen: false);

    // For sharing images when the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        print("Received initial shared media: ${value.map((f) => f.path).toList()}");
        final imagePaths = value.where((f) => f.type == SharedMediaType.image).map((f) => f.path).toList();
         if(imagePaths.isNotEmpty) {
           imageProvider.setImages(imagePaths);
         }
      }
    }).catchError((err) {
         print("Error getting initial media: $err");
    });

    // For sharing images while the app is open
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
       if (value.isNotEmpty) {
        print("Received stream shared media: ${value.map((f) => f.path).toList()}");
         final imagePaths = value.where((f) => f.type == SharedMediaType.image).map((f) => f.path).toList();
         if(imagePaths.isNotEmpty) {
           imageProvider.setImages(imagePaths);
           // Optionally navigate if not already on viewer,
           // but Home screen will react to provider changes
         }
       }
    }, onError: (err) {
      print("Error in media stream: $err");
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guest Image Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Start on PIN setup if no PIN exists, otherwise go to Home
      initialRoute: widget.isPinSet ? '/' : '/pin_setup',
      routes: {
        '/': (context) => const HomeScreen(),
        '/pin_setup': (context) => const PinSetupScreen(),
        // ImageViewerScreen is usually pushed dynamically from HomeScreen
      },
       debugShowCheckedModeBanner: false,
    );
  }
}