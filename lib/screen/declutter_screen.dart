import 'package:flutter/material.dart';
import 'camera_screen.dart';

class DeclutterScreen extends StatelessWidget {
  const DeclutterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cleaning_services,
              size: 100,
              color: Colors.purple,
            ),
            const SizedBox(height: 32),
            const Text(
              'クローゼットをスッキリさせましょう！',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'まずはクローゼット全体を撮影して、\nAIが整理のお手伝いをします',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraScreen(mode: 'declutter'),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('クローゼットを撮影'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // TODO: ギャラリーから選択
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('ギャラリーから選択'),
            ),
          ],
        ),
      ),
    );
  }
}