import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/area_detail_form.dart';
import 'organize_area_selection_screen.dart';

class SpaceAnalysisScreen extends StatefulWidget {
  final String imagePath;
  final List<AreaSelection> areas;

  const SpaceAnalysisScreen({
    Key? key,
    required this.imagePath,
    required this.areas,
  }) : super(key: key);

  @override
  State<SpaceAnalysisScreen> createState() => _SpaceAnalysisScreenState();
}

class _SpaceAnalysisScreenState extends State<SpaceAnalysisScreen> {
  final Map<String, Map<String, dynamic>> _areaDetails = {};
  int _currentAreaIndex = 0;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    // 各エリアの初期データを設定
    for (final area in widget.areas) {
      _areaDetails[area.id] = {
        'name': area.name,
        'category': area.category,
        'rect': area.rect,
        'color': area.color,
      };
    }
  }

  void _saveAreaDetail(String areaId, Map<String, dynamic> details) {
    setState(() {
      _areaDetails[areaId]!.addAll(details);
      
      // 次のエリアへ移動または分析開始
      if (_currentAreaIndex < widget.areas.length - 1) {
        _currentAreaIndex++;
      } else {
        _startAnalysis();
      }
    });
  }

  void _startAnalysis() {
    setState(() {
      _isAnalyzing = true;
    });

    // 分析完了をシミュレート
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    });
  }

  double _calculateOverallUsageRate() {
    if (_areaDetails.isEmpty) return 0;
    
    double totalUsage = 0;
    int count = 0;
    
    for (final details in _areaDetails.values) {
      if (details.containsKey('usageRate')) {
        totalUsage += details['usageRate'];
        count++;
      }
    }
    
    return count > 0 ? totalUsage / count : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentArea = widget.areas[_currentAreaIndex];
    final allDetailsEntered = _areaDetails.values
        .every((details) => details.containsKey('itemCount'));

    return Scaffold(
      appBar: AppBar(
        title: Text(allDetailsEntered ? '空間分析結果' : 'エリア情報入力'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isAnalyzing,
        message: '空間を分析中...',
        child: allDetailsEntered
            ? _buildAnalysisResults()
            : _buildAreaDetailInput(currentArea),
      ),
    );
  }

  Widget _buildAreaDetailInput(AreaSelection area) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 進捗表示
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Text(
                  'エリア ${_currentAreaIndex + 1} / ${widget.areas.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentAreaIndex + 1) / widget.areas.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // エリアの画像プレビュー
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                  ),
                  // 現在のエリアをハイライト
                  CustomPaint(
                    painter: AreaHighlightPainter(
                      areas: widget.areas,
                      highlightIndex: _currentAreaIndex,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // エリア詳細フォーム
          Padding(
            padding: const EdgeInsets.all(16),
            child: AreaDetailForm(
              areaName: area.name,
              category: area.category,
              onSave: (details) => _saveAreaDetail(area.id, details),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    final overallUsageRate = _calculateOverallUsageRate();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 全体の使用率
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'クローゼット全体の空間使用率',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: CircularProgressIndicator(
                          value: overallUsageRate / 100,
                          strokeWidth: 15,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getUsageRateColor(overallUsageRate),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${overallUsageRate.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getUsageRateLabel(overallUsageRate),
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // エリア別分析
          const Text(
            'エリア別分析',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...widget.areas.map((area) {
            final details = _areaDetails[area.id]!;
            return _buildAreaAnalysisCard(area, details);
          }).toList(),
          
          const SizedBox(height: 16),
          
          // 使用頻度分析
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
                    '使用頻度分析',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFrequencyChart(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // アクションボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceedToSuggestions,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'AI最適化提案を見る',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaAnalysisCard(AreaSelection area, Map<String, dynamic> details) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: area.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(details['category']),
            color: Colors.white,
          ),
        ),
        title: Text(
          details['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${details['category']} - ${details['itemCount']}個'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (details['usageRate'] ?? 0) / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getUsageRateColor(details['usageRate'] ?? 0),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '使用率: ${details['usageRate']?.toStringAsFixed(0) ?? 0}%',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '整理度: ${details['organizationLevel'] ?? '不明'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildFrequencyChart() {
    final frequencyData = <String, int>{};
    
    for (final details in _areaDetails.values) {
      final frequency = details['usageFrequency'] ?? 3.0;
      String label;
      
      if (frequency <= 1.5) label = 'ほとんど使わない';
      else if (frequency <= 2.5) label = '月に数回';
      else if (frequency <= 3.5) label = '週に数回';
      else if (frequency <= 4.5) label = '毎日';
      else label = '1日に何度も';
      
      frequencyData[label] = (frequencyData[label] ?? 0) + 1;
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: frequencyData.values.isEmpty 
              ? 1 
              : frequencyData.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final labels = frequencyData.keys.toList();
                  if (value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[value.toInt()].split(' ').first,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
          ),
          borderData: FlBorderData(show: false),
          barGroups: frequencyData.entries.map((entry) {
            final index = frequencyData.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: Colors.blue,
                  width: 30,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getUsageRateColor(double rate) {
    if (rate < 60) return Colors.green;
    if (rate < 80) return Colors.orange;
    return Colors.red;
  }

  String _getUsageRateLabel(double rate) {
    if (rate < 60) return '余裕あり';
    if (rate < 80) return '適度';
    return '混雑';
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

  void _proceedToSuggestions() {
    // TODO: AI提案画面へ遷移（Day 6で実装）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI提案機能は明日実装予定です')),
    );
  }
}

// エリアハイライト用のCustomPainter
class AreaHighlightPainter extends CustomPainter {
  final List<AreaSelection> areas;
  final int highlightIndex;

  AreaHighlightPainter({
    required this.areas,
    required this.highlightIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < areas.length; i++) {
      final area = areas[i];
      final paint = Paint()
        ..color = i == highlightIndex
            ? area.color.withOpacity(0.5)
            : area.color.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = i == highlightIndex
            ? area.color.withOpacity(0.8)
            : area.color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == highlightIndex ? 3 : 1;

      canvas.drawRect(area.rect, paint);
      canvas.drawRect(area.rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}