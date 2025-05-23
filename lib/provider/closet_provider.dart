import 'package:flutter/foundation.dart';

// プロバイダークラス（状態管理）
class ClosetProvider extends ChangeNotifier {
  // クローゼットアイテムのリスト
  List<ClothingItem> _items = [];
  List<ClothingItem> get items => _items;

  // エリア情報
  Map<String, ClosetArea> _areas = {};
  Map<String, ClosetArea> get areas => _areas;

  // ストリーク情報
  int _streakDays = 0;
  int get streakDays => _streakDays;
  
  DateTime? _lastCheckIn;
  DateTime? get lastCheckIn => _lastCheckIn;

  // アイテムを追加
  void addItem(ClothingItem item) {
    _items.add(item);
    notifyListeners();
  }

  // アイテムを削除
  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  // エリアを追加
  void addArea(ClosetArea area) {
    _areas[area.id] = area;
    notifyListeners();
  }

  // デイリーチェックイン
  void checkIn() {
    final now = DateTime.now();
    
    if (_lastCheckIn != null) {
      final difference = now.difference(_lastCheckIn!).inDays;
      if (difference == 1) {
        _streakDays++;
      } else if (difference > 1) {
        _streakDays = 1;
      }
    } else {
      _streakDays = 1;
    }
    
    _lastCheckIn = now;
    notifyListeners();
  }

  // アイテムの断捨離判定
  void judgeItem(String itemId, JudgmentType judgment) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index].judgment = judgment;
      notifyListeners();
    }
  }
}

// 衣類アイテムのモデル
class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String? imagePath;
  final DateTime createdAt;
  JudgmentType? judgment;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    this.imagePath,
    required this.createdAt,
    this.judgment,
  });
}

// クローゼットエリアのモデル
class ClosetArea {
  final String id;
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
  final String category;
  final int itemCount;
  final double usageRate;

  ClosetArea({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.category,
    required this.itemCount,
    required this.usageRate,
  });
}

// 判定タイプ
enum JudgmentType {
  keep,     // 残す
  discard,  // 捨てる
  pending,  // 迷う
}