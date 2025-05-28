import 'dart:io';
import 'package:closet_organizer/provider/closet_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrganizeAreaSelectionScreen extends StatefulWidget {
  final String imagePath;

  const OrganizeAreaSelectionScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<OrganizeAreaSelectionScreen> createState() => _OrganizeAreaSelectionScreenState();
}

class _OrganizeAreaSelectionScreenState extends State<OrganizeAreaSelectionScreen> {
  final List<AreaSelection> _selectedAreas = [];
  Offset? _startPoint;
  Offset? _endPoint;
  bool _isSelecting = false;
  final GlobalKey _imageKey = GlobalKey();
  Size? _imageSize;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateImageSize();
    });
  }

  void _calculateImageSize() {
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _imageSize = renderBox.size;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _startPoint = details.localPosition;
      _endPoint = details.localPosition;
      _isSelecting = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _endPoint = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_startPoint != null && _endPoint != null && _imageSize != null) {
      final rect = Rect.fromPoints(_startPoint!, _endPoint!);
      
      // 最小サイズチェック
      if (rect.width > 50 && rect.height > 50) {
        _showAreaNameDialog(rect);
      }
    }
    
    setState(() {
      _startPoint = null;
      _endPoint = null;
      _isSelecting = false;
    });
  }

  void _showAreaNameDialog(Rect rect) {
    final TextEditingController nameController = TextEditingController();
    String selectedCategory = 'トップス';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エリアの設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'エリア名',
                hintText: '例：上段ハンガー部分',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                border: OutlineInputBorder(),
              ),
              items: ['トップス', 'ボトムス', 'アウター', 'シューズ', 'バッグ', 'アクセサリー', 'その他']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedCategory = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _selectedAreas.add(
                    AreaSelection(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      rect: rect,
                      category: selectedCategory,
                      color: _getCategoryColor(selectedCategory),
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'トップス':
        return Colors.blue.withOpacity(0.3);
      case 'ボトムス':
        return Colors.green.withOpacity(0.3);
      case 'アウター':
        return Colors.orange.withOpacity(0.3);
      case 'シューズ':
        return Colors.purple.withOpacity(0.3);
      case 'バッグ':
        return Colors.pink.withOpacity(0.3);
      case 'アクセサリー':
        return Colors.amber.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.3);
    }
  }

  void _deleteArea(String id) {
    setState(() {
      _selectedAreas.removeWhere((area) => area.id == id);
    });
  }

  void _proceedToAnalysis() {
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('少なくとも1つのエリアを選択してください')),
      );
      return;
    }

    // Providerにエリア情報を保存
    final provider = Provider.of<ClosetProvider>(context, listen: false);
    for (final area in _selectedAreas) {
      provider.addArea(
        ClosetArea(
          id: area.id,
          name: area.name,
          x: area.rect.left / _imageSize!.width,
          y: area.rect.top / _imageSize!.height,
          width: area.rect.width / _imageSize!.width,
          height: area.rect.height / _imageSize!.height,
          category: area.category,
          itemCount: 0, // 後で更新
          usageRate: 0, // 後で計算
        ),
      );
    }

    // 次の画面へ
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpaceAnalysisScreen(
          imagePath: widget.imagePath,
          areas: _selectedAreas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('エリア選択'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedAreas.isNotEmpty ? _proceedToAnalysis : null,
            child: Text(
              '次へ (${_selectedAreas.length})',
              style: TextStyle(
                color: _selectedAreas.isNotEmpty
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 説明テキスト
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'クローゼット内のエリアをドラッグで選択してください',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          
          // 画像とエリア選択
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // クローゼット画像
                  Image.file(
                    File(widget.imagePath),
                    key: _imageKey,
                    fit: BoxFit.contain,
                  ),
                  
                  // 選択済みエリア
                  if (_imageSize != null)
                    ...List.generate(_selectedAreas.length, (index) {
                      final area = _selectedAreas[index];
                      return Positioned(
                        left: area.rect.left,
                        top: area.rect.top,
                        width: area.rect.width,
                        height: area.rect.height,
                        child: GestureDetector(
                          onTap: () => _showAreaDetailDialog(area),
                          child: Container(
                            decoration: BoxDecoration(
                              color: area.color,
                              border: Border.all(
                                color: area.color.withOpacity(0.8),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      area.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _deleteArea(area.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  
                  // 選択中のエリア
                  if (_isSelecting && _startPoint != null && _endPoint != null)
                    Positioned(
                      left: _startPoint!.dx < _endPoint!.dx ? _startPoint!.dx : _endPoint!.dx,
                      top: _startPoint!.dy < _endPoint!.dy ? _startPoint!.dy : _endPoint!.dy,
                      width: (_endPoint!.dx - _startPoint!.dx).abs(),
                      height: (_endPoint!.dy - _startPoint!.dy).abs(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 選択済みエリアリスト
          if (_selectedAreas.isNotEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: _selectedAreas.length,
                itemBuilder: (context, index) {
                  final area = _selectedAreas[index];
                  return Card(
                    margin: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: area.color.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  area.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            area.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showAreaDetailDialog(AreaSelection area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(area.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('カテゴリ: ${area.category}'),
            const SizedBox(height: 8),
            Text('サイズ: ${area.rect.width.toInt()} x ${area.rect.height.toInt()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteArea(area.id);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

// エリア選択データクラス
class AreaSelection {
  final String id;
  final String name;
  final Rect rect;
  final String category;
  final Color color;

  AreaSelection({
    required this.id,
    required this.name,
    required this.rect,
    required this.category,
    required this.color,
  });
}

// 空間分析画面（スタブ）
class SpaceAnalysisScreen extends StatelessWidget {
  final String imagePath;
  final List<AreaSelection> areas;

  const SpaceAnalysisScreen({
    Key? key,
    required this.imagePath,
    required this.areas,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('空間分析'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              '${areas.length}個のエリアを分析中...',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Day 5-6で実装予定',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}