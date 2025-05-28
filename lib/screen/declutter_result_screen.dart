import 'dart:io';
import 'package:closet_organizer/provider/closet_provider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class DeclutterResultScreen extends StatefulWidget {
  final List<ClothingItem> items;
  final Map<String, JudgmentType> judgments;
  final String originalImagePath;

  const DeclutterResultScreen({
    Key? key,
    required this.items,
    required this.judgments,
    required this.originalImagePath,
  }) : super(key: key);

  @override
  State<DeclutterResultScreen> createState() => _DeclutterResultScreenState();
}

class _DeclutterResultScreenState extends State<DeclutterResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showBeforeAfter = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _saveProgress();
  }

  void _saveProgress() {
    // TODO: 進捗をローカルに保存
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get keepCount => widget.judgments.values.where((j) => j == JudgmentType.keep).length;
  int get discardCount => widget.judgments.values.where((j) => j == JudgmentType.discard).length;
  int get pendingCount => widget.judgments.values.where((j) => j == JudgmentType.pending).length;
  double get reductionRate => (discardCount / widget.items.length * 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('断捨離完了！'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResults,
          ),
        ],
      ),
      body: Column(
        children: [
          // サマリーカード
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.celebration,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'お疲れさまでした！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.items.length}個のアイテムを整理しました',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryItem(
                      '削減率',
                      '${reductionRate.toStringAsFixed(0)}%',
                      Icons.trending_down,
                    ),
                    _buildSummaryItem(
                      '捨てる',
                      '$discardCount個',
                      Icons.delete_outline,
                    ),
                    _buildSummaryItem(
                      '残す',
                      '$keepCount個',
                      Icons.favorite_outline,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // タブバー
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: '統計'),
              Tab(text: 'アイテム'),
              Tab(text: '次のステップ'),
            ],
          ),

          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(),
                _buildItemsTab(),
                _buildNextStepsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 円グラフ
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '判定結果の内訳',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: keepCount.toDouble(),
                            title: '残す\n$keepCount',
                            color: Colors.green,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: discardCount.toDouble(),
                            title: '捨てる\n$discardCount',
                            color: Colors.red,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: pendingCount.toDouble(),
                            title: '迷う\n$pendingCount',
                            color: Colors.orange,
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // カテゴリ別統計
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'カテゴリ別の削減',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildCategoryStats(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ビフォー/アフターボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showBeforeAfter = true;
                });
                _showBeforeAfterDialog();
              },
              icon: const Icon(Icons.compare),
              label: const Text('ビフォー/アフターを見る'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryStats() {
    final Map<String, Map<JudgmentType, int>> categoryStats = {};
    
    for (final item in widget.items) {
      if (!categoryStats.containsKey(item.category)) {
        categoryStats[item.category] = {
          JudgmentType.keep: 0,
          JudgmentType.discard: 0,
          JudgmentType.pending: 0,
        };
      }
      
      final judgment = widget.judgments[item.id];
      if (judgment != null) {
        categoryStats[item.category]![judgment] = 
            categoryStats[item.category]![judgment]! + 1;
      }
    }

    return categoryStats.entries.map((entry) {
      final total = entry.value.values.reduce((a, b) => a + b);
      final discarded = entry.value[JudgmentType.discard] ?? 0;
      final percentage = total > 0 ? (discarded / total * 100) : 0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 3,
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 50 ? Colors.red : Colors.orange,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildItemsTab() {
    final List<String> tabs = ['残す', '迷う', '捨てる'];
    final List<JudgmentType> types = [
      JudgmentType.keep,
      JudgmentType.pending,
      JudgmentType.discard,
    ];
    final List<Color> colors = [Colors.green, Colors.orange, Colors.red];

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final count = widget.judgments.values
                  .where((j) => j == types[index])
                  .length;
              
              return Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('$tab ($count)'),
                  ],
                ),
              );
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: types.map((type) {
                final items = widget.items.where((item) {
                  return widget.judgments[item.id] == type;
                }).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'アイテムがありません',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(item.category),
                          child: Icon(
                            _getCategoryIcon(item.category),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text(item.category),
                        trailing: type == JudgmentType.pending
                            ? TextButton(
                                onPressed: () => _showReconsiderDialog(item),
                                child: const Text('再検討'),
                              )
                            : null,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 実行タスク
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.task_alt, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        '実行すること',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTask(
                    '捨てるアイテムを袋に入れる',
                    '$discardCount個のアイテムを処分します',
                    false,
                  ),
                  _buildTask(
                    '迷うアイテムを一時保管',
                    '$pendingCount個を別の場所に保管し、1ヶ月後に再検討',
                    false,
                  ),
                  _buildTask(
                    '残すアイテムを整理',
                    'クローゼットに戻す前にカテゴリ別に整理',
                    false,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // アドバイス
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'アドバイス',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._generateAdvice(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // アクションボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scheduleNextSession,
              icon: const Icon(Icons.calendar_today),
              label: const Text('次回の断捨離を予約'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTask(String title, String subtitle, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isCompleted,
            onChanged: (value) {
              // TODO: タスクの完了状態を保存
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _generateAdvice() {
    final List<Widget> advice = [];
    
    if (reductionRate > 30) {
      advice.add(_buildAdviceItem(
        '素晴らしい断捨離でした！',
        'これだけのアイテムを手放せたのは大きな進歩です。',
        Icons.star,
        Colors.amber,
      ));
    }

    if (pendingCount > 5) {
      advice.add(_buildAdviceItem(
        '迷うアイテムの扱い方',
        '1ヶ月使わなかったら手放すルールを設定しましょう。',
        Icons.access_time,
        Colors.orange,
      ));
    }

    // カテゴリ別のアドバイス
    final categoryCount = <String, int>{};
    for (final item in widget.items) {
      if (widget.judgments[item.id] == JudgmentType.keep) {
        categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
      }
    }

    if (categoryCount.isNotEmpty) {
      final mostKeptCategory = categoryCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      advice.add(_buildAdviceItem(
        '$mostKeptCategoryが多めです',
        'このカテゴリは本当に全て必要か、もう一度考えてみましょう。',
        Icons.inventory_2,
        Colors.blue,
      ));
    }

    return advice;
  }

  Widget _buildAdviceItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBeforeAfterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('ビフォー/アフター'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ビフォー画像
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(widget.originalImagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(
                    Icons.arrow_downward,
                    size: 32,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  // アフター（仮想イメージ）
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green[50],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Colors.green[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reductionRate.toStringAsFixed(0)}%削減！',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          '$discardCount個のアイテムを手放しました',
                          style: TextStyle(
                            color: Colors.green[600],
                          ),
                        ),
                      ],
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

  void _showReconsiderDialog(ClothingItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: const Text('このアイテムをどうしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.judgments[item.id] = JudgmentType.keep;
              });
              Navigator.pop(context);
            },
            child: const Text('残す', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.judgments[item.id] = JudgmentType.discard;
              });
              Navigator.pop(context);
            },
            child: const Text('捨てる', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _shareResults() {
    // TODO: 結果をシェアする機能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('シェア機能は開発中です')),
    );
  }

  void _scheduleNextSession() {
    // TODO: カレンダーに次回の断捨離を登録
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('カレンダー連携は開発中です')),
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
      default:
        return Icons.inventory_2;
    }
  }
}