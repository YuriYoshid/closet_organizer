import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageHelper {
  // 画像をBase64にエンコード（API送信用）
  static Future<String> imageToBase64(String imagePath, {int maxWidth = 1024}) async {
    try {
      // 画像ファイルを読み込み
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // 画像をデコード
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('画像のデコードに失敗しました');
      }
      
      // 画像が大きすぎる場合はリサイズ
      img.Image resizedImage = originalImage;
      if (originalImage.width > maxWidth) {
        final double aspectRatio = originalImage.height / originalImage.width;
        final int newHeight = (maxWidth * aspectRatio).round();
        resizedImage = img.copyResize(
          originalImage,
          width: maxWidth,
          height: newHeight,
        );
      }
      
      // JPEGにエンコード（品質80%）
      final Uint8List compressedBytes = img.encodeJpg(resizedImage, quality: 80);
      
      // Base64にエンコード
      return base64Encode(compressedBytes);
    } catch (e) {
      throw Exception('画像の処理に失敗しました: $e');
    }
  }

  // 画像のファイルサイズを取得（MB単位）
  static Future<double> getImageSizeInMB(String imagePath) async {
    final File file = File(imagePath);
    final int bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  // 画像の情報を取得
  static Future<Map<String, dynamic>> getImageInfo(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('画像情報の取得に失敗しました');
      }
      
      return {
        'width': image.width,
        'height': image.height,
        'sizeInMB': await getImageSizeInMB(imagePath),
      };
    } catch (e) {
      throw Exception('画像情報の取得に失敗しました: $e');
    }
  }
}