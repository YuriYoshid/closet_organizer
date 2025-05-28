import 'dart:convert';
import 'package:closet_organizer/provider/closet_provider.dart';
import 'package:closet_organizer/utlis/image_helper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIApiService {
  static String get apiKey => dotenv.env['OPENAI_API_KEY'] ?? 'YOUR_OPENAI_API_KEY';
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  // 画像からクローゼットアイテムを認識
  static Future<List<ClothingItem>> analyzeClosetImage(String imagePath) async {
    try {
      // 画像をBase64に変換
      final String base64Image = await ImageHelper.imageToBase64(imagePath);
      
      // APIリクエストボディ
      final Map<String, dynamic> requestBody = {
        'model': 'gpt-4-vision-preview',
        'messages': [
          {
            'role': 'system',
            'content': '''あなたはクローゼット整理の専門家です。
画像からクローゼット内のアイテムを認識し、カテゴリ分けして返してください。
各アイテムについて以下の形式で返してください：
- カテゴリ（トップス、ボトムス、アウター、シューズ、バッグ、アクセサリー、その他）
- 具体的なアイテム名（例：白いTシャツ、デニムパンツ、黒いコートなど）
- 色
- 推定される使用頻度（高、中、低）

JSONフォーマットで返してください。'''
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'このクローゼットの中のアイテムを認識して、リストアップしてください。'
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                  'detail': 'high'
                }
              }
            ]
          }
        ],
        'max_tokens': 1000
      };

      // APIリクエスト
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String content = data['choices'][0]['message']['content'];
        
        // レスポンスをパース
        return _parseClothingItems(content);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('画像分析に失敗しました: $e');
    }
  }

  // 整理整頓の提案を取得
  static Future<List<String>> getOrganizationSuggestions(
    String imagePath,
    Map<String, ClosetArea> areas,
  ) async {
    try {
      final String base64Image = await ImageHelper.imageToBase64(imagePath);
      
      final Map<String, dynamic> requestBody = {
        'model': 'gpt-4-vision-preview',
        'messages': [
          {
            'role': 'system',
            'content': '''あなたはプロの整理収納アドバイザーです。
クローゼットの画像を分析し、以下の観点から具体的な改善提案をしてください：
1. 空間の有効活用
2. アイテムの配置最適化
3. 使用頻度に基づいた配置
4. 見た目の美しさ
5. 取り出しやすさ'''
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'このクローゼットの整理整頓について、具体的な改善提案を5つ教えてください。'
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                  'detail': 'high'
                }
              }
            ]
          }
        ],
        'max_tokens': 800
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String content = data['choices'][0]['message']['content'];
        
        // 提案をリスト形式でパース
        return _parseSuggestions(content);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('提案の取得に失敗しました: $e');
    }
  }

  // 画像比較（デイリーチェック用）
  static Future<Map<String, dynamic>> compareImages(
    String beforeImagePath,
    String afterImagePath,
  ) async {
    try {
      final String base64Before = await ImageHelper.imageToBase64(beforeImagePath);
      final String base64After = await ImageHelper.imageToBase64(afterImagePath);
      
      final Map<String, dynamic> requestBody = {
        'model': 'gpt-4-vision-preview',
        'messages': [
          {
            'role': 'system',
            'content': '2つのクローゼット画像を比較し、整理状態の変化を分析してください。'
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': '1枚目が前日、2枚目が今日のクローゼットです。改善点と悪化した点を教えてください。'
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Before',
                }
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64After',
                }
              }
            ]
          }
        ],
        'max_tokens': 500
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String content = data['choices'][0]['message']['content'];
        
        return {
          'analysis': content,
          'score': _calculateScore(content),
        };
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('画像比較に失敗しました: $e');
    }
  }

  // レスポンスパース用のヘルパーメソッド
  static List<ClothingItem> _parseClothingItems(String content) {
    try {
      // GPTのレスポンスからJSON部分を抽出
      final RegExp jsonRegex = RegExp(r'\[[\s\S]*\]');
      final Match? match = jsonRegex.firstMatch(content);
      
      if (match != null) {
        final List<dynamic> items = jsonDecode(match.group(0)!);
        return items.map((item) {
          return ClothingItem(
            id: DateTime.now().millisecondsSinceEpoch.toString() + item['name'],
            name: item['name'] ?? '不明なアイテム',
            category: item['category'] ?? 'その他',
            createdAt: DateTime.now(),
          );
        }).toList();
      }
      
      // JSON形式でない場合は、テキストから抽出
      final List<ClothingItem> parsedItems = [];
      final lines = content.split('\n');
      
      for (final line in lines) {
        if (line.contains('：') || line.contains('-')) {
          final parts = line.split(RegExp(r'[：\-]'));
          if (parts.length >= 2) {
            parsedItems.add(ClothingItem(
              id: DateTime.now().millisecondsSinceEpoch.toString() + parts[1].trim(),
              name: parts[1].trim(),
              category: _detectCategory(parts[0].trim()),
              createdAt: DateTime.now(),
            ));
          }
        }
      }
      
      return parsedItems;
    } catch (e) {
      print('パースエラー: $e');
      return [];
    }
  }

  static String _detectCategory(String text) {
    if (text.contains('トップス') || text.contains('シャツ') || text.contains('Tシャツ')) {
      return 'トップス';
    } else if (text.contains('ボトムス') || text.contains('パンツ') || text.contains('スカート')) {
      return 'ボトムス';
    } else if (text.contains('アウター') || text.contains('コート') || text.contains('ジャケット')) {
      return 'アウター';
    } else if (text.contains('シューズ') || text.contains('靴')) {
      return 'シューズ';
    } else if (text.contains('バッグ') || text.contains('鞄')) {
      return 'バッグ';
    }
    return 'その他';
  }

  static List<String> _parseSuggestions(String content) {
    final List<String> suggestions = [];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && 
          (trimmed.startsWith(RegExp(r'[0-9]')) || 
           trimmed.startsWith('・') || 
           trimmed.startsWith('-'))) {
        // 番号や記号を削除してテキストのみ抽出
        final text = trimmed.replaceAll(RegExp(r'^[0-9\.\-・]+\s*'), '');
        if (text.isNotEmpty) {
          suggestions.add(text);
        }
      }
    }
    
    return suggestions.take(5).toList(); // 最大5つの提案
  }

  static int _calculateScore(String analysis) {
    // 簡単なスコア計算（改善に関連する単語をカウント）
    int score = 70; // 基準スコア
    
    final positiveWords = ['改善', '整理', 'きれい', '良い', '向上'];
    final negativeWords = ['悪化', '散らか', '乱れ', '汚い'];
    
    for (final word in positiveWords) {
      if (analysis.contains(word)) score += 5;
    }
    
    for (final word in negativeWords) {
      if (analysis.contains(word)) score -= 5;
    }
    
    return score.clamp(0, 100);
  }
}