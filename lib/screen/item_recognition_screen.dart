import 'dart:io';
import 'package:closet_organizer/provider/closet_provider.dart';
import 'package:closet_organizer/screen/declutter_flow_screen.dart';
import 'package:closet_organizer/service/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/loading_overlay.dart';

class ItemRecognitionScreen extends StatefulWidget {
  final String imagePath;

  const ItemRecognitionScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<ItemRecognitionScreen> createState() => _ItemRecognitionScreenState();
}

class _ItemRecognitionScreenState extends State<ItemRecognitionScreen> {
  bool _isLoading = true;
  String? _error;
  List<ClothingItem> _recognizedItems = [];
  Map<String, List<ClothingItem>> _categorizedItems = {};

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // OpenAI APIで画像を分析
      final items = await OpenAIApiService.analyzeClosetImage(widget.imagePath);

      // カテゴリごとに分類
      final Map<String, List<ClothingItem>> categorized = {};
      for (final item in items) {
        if (!categorized.containsKey(item.category)) {
          categorized[item.category] = [];
        }
        categorized[item.category]!.add(item);
      }

      setState(() {
        _recognizedItems = items;
        _categorizedItems = categorized;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _proceedToDeclutter() {
    // Providerに認識したアイテムを保存
    final provider = Provider.of<ClosetProvider>(context, listen: false);
    for (final item in _recognizedItems) {
      provider.addItem(item);
    }

    // 断捨離フローへ遷移
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DeclutterFlowScreen(
          items: _recognizedItems,
          originalImagePath: widget.imagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('認識されたアイテム'),
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'AIがアイテムを分析中...',
        child: _error != null
            ? _buildErrorView()
            : _recognizedItems.isEmpty && !_isLoading
                ? _buildEmptyView()
                : _buildResultView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _analyzeImage,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'アイテムが見つかりませんでした',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('撮り直す'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return Column(
      children: [
        // 画像プレビュー
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: FileImage(File(widget.imagePath)),
              fit: BoxFit.contain,
            ),
          ),
        ),
        
        // 認識結果のサマリー
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                Icons.checkroom,
                '${_recognizedItems.length}',
                'アイテム',
              ),
              _buildSummaryItem(
                Icons.category,
                '${_categorizedItems.length}',
                'カテゴリ',
              ),
            ],
          ),
        ),
        
        // カテゴリ別リスト
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _categorizedItems.length,
            itemBuilder: (context, index) {
              final category = _categorizedItems.keys.elementAt(index);
              final items = _categorizedItems[category]!;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text('${items.length}個のアイテム'),
                  initiallyExpanded: true,
                  children: items.map((item) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCategoryColor(category),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(item.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          _editItemName(item);
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        
        // 確認ボタン
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _recognizedItems.isNotEmpty ? _proceedToDeclutter : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '断捨離を開始',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
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
      case 'アクセサリー':
        return Colors.amber;
      default:
        return Colors.grey;
    }
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
      case 'アクセサリー':
        return Icons.watch;
      default:
        return Icons.inventory_2;
    }
  }

  void _editItemName(ClothingItem item) {
    final controller = TextEditingController(text: item.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイテム名を編集'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'アイテム名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item.name = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}