import 'dart:io';
import 'package:closet_organizer/service/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/loading_overlay.dart';

class DailyComparisonScreen extends StatefulWidget {
  final String todayImagePath;
  final String yesterdayImagePath;
  final int streakDays;

  const DailyComparisonScreen({
    Key? key,
    required this.todayImagePath,
    required this.yesterdayImagePath,
    required this.streakDays,
  }) : super(key: key);

  @override
  State<DailyComparisonScreen> createState() => _DailyComparisonScreenState();
}

class _DailyComparisonScreenState extends State<DailyComparisonScreen> {
  bool _isAnalyzing = true;
  String? _analysis;
  int _score = 0;
  String? _error;
  bool _showToday = true;

  @override
  void initState() {
    super.initState();
    _analyzeImages();
  }

  Future<void> _analyzeImages() async {
    try {
      setState(() {
        _isAnalyzing = true;
        _error = null;
      });

      // OpenAI APIで画像を比較
      final result = await OpenAIApiService.compareImages(
        widget.yesterdayImagePath,
        widget.todayImagePath,
      );

      setState(() {
        _analysis = result['analysis'];
        _score = result['score'];
        _isAnalyzing = false;
      });

      // スコアを保存
      await _saveScore();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
        // エラー時はデフォルトのメッセージとスコアを設定
        _analysis = '画像の分析に失敗しましたが、チェックインは記録されました！';
        _score = 70;
      });
    }
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setInt('score_$today', _score);
  }

  Color _getScoreColor() {
    if (_score >= 80) return Colors.green;
    if (_score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage() {
    if (_score >= 80) return '素晴らしい！';
    if (_score >= 60) return 'まずまずです';
    return '改善の余地あり';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('デイリー比較'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ストリーク表示
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 20,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.streakDays}日',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isAnalyzing,
        message: '画像を分析中...',
        child: Column(
          children: [
            // 画像比較エリア
            Expanded(
              child: Stack(
                children: [
                  // 画像表示
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_showToday),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_showToday
                              ? widget.todayImagePath
                              : widget.yesterdayImagePath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  // 日付ラベル
                  Positioned(
                    top: 32,
                    left: 32,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _showToday ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _showToday ? '今日' : '昨日',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // 切り替えボタン
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showToday = false;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                backgroundColor: !_showToday
                                    ? Theme.of(context).primaryColor
                                    : null,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    bottomLeft: Radius.circular(30),
                                  ),
                                ),
                              ),
                              child: Text(
                                '昨日',
                                style: TextStyle(
                                  color: !_showToday
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showToday = true;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                backgroundColor: _showToday
                                    ? Theme.of(context).primaryColor
                                    : null,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(30),
                                    bottomRight: Radius.circular(30),
                                  ),
                                ),
                              ),
                              child: Text(
                                '今日',
                                style: TextStyle(
                                  color: _showToday
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 分析結果
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // スコア表示
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getScoreColor().withOpacity(0.1),
                          border: Border.all(
                            color: _getScoreColor(),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_score',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(),
                                ),
                              ),
                              Text(
                                'スコア',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getScoreMessage(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: _score / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getScoreColor(),
                              ),
                              minHeight: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 分析コメント
                  const Text(
                    'AIからのフィードバック',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _analysis ?? '分析中...',
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // アクションボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'ホームに戻る',
                        style: TextStyle(
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
}