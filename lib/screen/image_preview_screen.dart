import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'item_recognition_screen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;
  final String mode; // 'declutter' or 'organize' or 'daily'

  const ImagePreviewScreen({
    Key? key,
    required this.imagePath,
    required this.mode,
  }) : super(key: key);

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _isSaving = false;

  Future<String> _saveImageToAppDirectory(String sourcePath) async {
    try {
      // アプリのドキュメントディレクトリを取得
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      
      // closet_imagesフォルダを作成
      final Directory closetImagesDir = Directory('$appDocPath/closet_images');
      if (!await closetImagesDir.exists()) {
        await closetImagesDir.create(recursive: true);
      }
      
      // ユニークなファイル名を生成
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
      final String savedPath = path.join(closetImagesDir.path, fileName);
      
      // ファイルをコピー
      final File sourceFile = File(sourcePath);
      await sourceFile.copy(savedPath);
      
      return savedPath;
    } catch (e) {
      throw Exception('画像の保存に失敗しました: $e');
    }
  }

  Future<void> _confirmAndSaveImage() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 画像を永続的な場所に保存
      final String savedPath = await _saveImageToAppDirectory(widget.imagePath);
      
      if (mounted) {
        if (widget.mode == 'declutter') {
          // 断捨離モードの場合は認識画面へ
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ItemRecognitionScreen(
                imagePath: savedPath,
              ),
            ),
          );
        } else {
          // TODO: 他のモードの処理
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('画像を保存しました！'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '撮影した画像',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 撮り直し
              Navigator.pop(context);
            },
            child: const Text(
              '撮り直す',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 画像表示エリア
            Expanded(
              child: Center(
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // 下部のアクションエリア
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'この画像で進めますか？',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getModeDescription(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _confirmAndSaveImage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _getButtonText(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getModeDescription() {
    switch (widget.mode) {
      case 'declutter':
        return 'AIがクローゼット内のアイテムを認識し、\n断捨離のお手伝いをします';
      case 'organize':
        return 'AIが空間を分析し、\n効率的な収納方法を提案します';
      case 'daily':
        return '前日と比較して、\nクローゼットの状態をチェックします';
      default:
        return '画像を分析します';
    }
  }

  String _getButtonText() {
    switch (widget.mode) {
      case 'declutter':
        return 'アイテムを認識する';
      case 'organize':
        return '空間を分析する';
      case 'daily':
        return 'チェックインする';
      default:
        return '次へ進む';
    }
  }
}