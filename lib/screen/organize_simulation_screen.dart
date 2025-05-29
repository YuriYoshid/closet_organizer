import 'dart:io';
import 'package:flutter/material.dart';
import 'organize_suggestions_screen.dart';

class OrganizeSimulationScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, Map<String, dynamic>> areaDetails;
  final OrganizationSuggestion suggestion;

  const OrganizeSimulationScreen({
    Key? key,
    required this.imagePath,
    required this.areaDetails,
    required this.suggestion,
  }) : super(key: key);

  @override
  State<OrganizeSimulationScreen> createState() => _OrganizeSimulationScreenState();
}

class _OrganizeSimulationScreenState extends State<OrganizeSimulationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Map<String, Offset> _itemPositions = {};
  final Map<String, SimulatedItem> _simulatedItems = {};
  bool _showBefore = true;
  bool _isApplied = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _initializeSimulation();
  }

  void _initializeSimulation() {
    // シミュレーション用のアイテムを初期化
    int index = 0;
    for (final entry in widget.areaDetails.entries) {
      final areaId = entry.key;
      final details = entry.value;
      
      // エリアごとにアイテムを生成
      final itemCount = details['itemCount'] ?? 0;
      for (int i = 0; i < itemCount && i < 3; i++) {
        final itemId = '${areaId}_item_$i';
        _simulatedItems[itemId] = SimulatedItem(
          id: itemId,
          areaId: areaId,
          category: details['category'],
          name: '${details['category']} ${i + 1}',
          color: _getCategoryColor(details['category']),
          originalPosition: Offset(100.0 + (index % 3) * 100, 100.0 + (index ~/ 3) * 100),
        );
        _itemPositions[itemId] = _simulatedItems[itemId]!.originalPosition;
        index++;
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'トップス':
        return Colors.blue;
      case 'ボトムス':
        return Colors.green;
      case 'アウター':
        return Colors.orange;
      case 'シューズ':
        return Colors.purple;
      case 'バッグ':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  void _toggleBeforeAfter() {
    setState(() {
      _showBefore = !_showBefore;
    });
    
    if (_showBefore) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  void _applyChanges() {
    setState(() {
      _isApplied = true;
    });
    
    // 成功メッセージを表示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('変更を適用しました！'),
        backgroundColor: Colors.green,
      ),
    );
    
    // 少し待ってから前の画面に戻る
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置シミュレーション'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _toggleBeforeAfter,
            icon: Icon(
              _showBefore ? Icons.arrow_forward : Icons.arrow_back,
              color: Theme.of(context).primaryColor,
            ),
            label: Text(
              _showBefore ? 'After' : 'Before',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 提案内容
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Row(
              children: [
                Icon(widget.suggestion.icon, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.suggestion.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.suggestion.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // シミュレーション表示エリア
          Expanded(
            child: Stack(
              children: [
                // 背景画像
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // シミュレーションアイテム
                ..._simulatedItems.entries.map((entry) {
                  final item = entry.value;
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    left: _showBefore 
                        ? item.originalPosition.dx 
                        : _getOptimizedPosition(item).dx,
                    top: _showBefore 
                        ? item.originalPosition.dy 
                        : _getOptimizedPosition(item).dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        if (!_showBefore) {
                          setState(() {
                            _itemPositions[item.id] = Offset(
                              _itemPositions[item.id]!.dx + details.delta.dx,
                              _itemPositions[item.id]!.dy + details.delta.dy,
                            );
                          });
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCategoryIcon(item.category),
                              color: Colors.white,
                              size: 30,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                
                // ビフォー/アフターラベル
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _showBefore ? Colors.grey : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _showBefore ? 'Before' : 'After',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 操作説明
          if (!_showBefore)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'アイテムをドラッグして位置を調整できます',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          
          // アクションボタン
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('別の提案を見る'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isApplied ? null : _applyChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isApplied ? '適用済み' : 'この配置を適用'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Offset _getOptimizedPosition(SimulatedItem item) {
    // 提案に基づいて最適化された位置を計算
    // ここでは簡単なロジックで実装
    
    final details = widget.areaDetails.values
        .firstWhere((d) => d['category'] == item.category, 
                    orElse: () => {});
    
    final frequency = details['usageFrequency'] ?? 3.0;
    
    // 使用頻度が高いものは上部に配置
    if (frequency >= 4) {
      return Offset(
        item.originalPosition.dx,
        100 + (item.originalPosition.dy % 100),
      );
    }
    // 使用頻度が低いものは下部に配置
    else if (frequency <= 2) {
      return Offset(
        item.originalPosition.dx,
        300 + (item.originalPosition.dy % 100),
      );
    }
    
    // カスタム位置が設定されている場合はそれを使用
    return _itemPositions[item.id] ?? item.originalPosition;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'トップス':
        return Icons.checkroom;
      case 'ボトムス':
        return Icons.accessibility;
      case 'アウター':
        return Icons.ac_unit;
      case 'シューズ':
        return Icons.directions_walk;
      case 'バッグ':
        return Icons.shopping_bag;
      default:
        return Icons.inventory_2;
    }
  }
}

// シミュレーション用アイテムクラス
class SimulatedItem {
  final String id;
  final String areaId;
  final String category;
  final String name;
  final Color color;
  final Offset originalPosition;

  SimulatedItem({
    required this.id,
    required this.areaId,
    required this.category,
    required this.name,
    required this.color,
    required this.originalPosition,
  });
}