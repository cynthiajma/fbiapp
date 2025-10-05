import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'character_library.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    Get.put(FluttermojiController());

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Character',
      theme: ThemeData(primarySwatch: Colors.red),
      //home: const AvatarPage(),
      home: const CharacterLibraryPage(),
    );
  }
}

class AvatarPage extends StatelessWidget {
  const AvatarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Character'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FluttermojiCircleAvatar(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: FluttermojiCustomizer()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FluttermojiSaveWidget(),
          ),
        ],
      ),
    );
  }
}
