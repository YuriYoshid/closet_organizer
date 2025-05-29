import 'package:closet_organizer/provider/closet_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'camera_screen.dart';
import 'daily_comparison_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DailyCheckScreen extends StatefulWidget {
  const DailyCheckScreen({Key? key}) : super(key: key);

  @override
  State<DailyCheckScreen> createState() => _DailyCheckScreenState();
}

class _DailyCheckScreenState extends State<DailyCheckScreen> {
  int _streakDays = 0;
  DateTime? _lastCheckIn;
  String? _todayImagePath;
  String? _yesterdayImagePath;
  List<CheckInRecord> _recentCheckIns = [];
  
  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _streakDays = prefs.getInt('streakDays') ?? 0;
      final lastCheckInString = prefs.getString('lastCheckIn');
      if (lastCheckInString != null) {
        _lastCheckIn = DateTime.parse(lastCheckInString);
      }
      
      _todayImagePath = prefs.getString('todayImage');
      _yesterdayImagePath = prefs.getString('yesterdayImage');
      
      // 最近のチェックイン履歴を読み込む
      _loadRecentCheckIns(prefs);
    });
  }

  void _loadRecentCheckIns(SharedPreferences prefs) {
    _recentCheckIns.clear();
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final imagePath = prefs.getString('checkIn_$dateKey');
      final score = prefs.getInt('score_$dateKey');
      
      if (imagePath != null) {
        _recentCheckIns.add(CheckInRecord(
          date: date,
          imagePath: imagePath,
          score: score ?? 0,
        ));
      }
    }
  }

  Future<void> _performDailyCheckIn(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final provider = Provider.of<ClosetProvider>(context, listen: false);
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    
    // ストリーク計算
    int newStreak = _streakDays;
    if (_lastCheckIn != null) {
      final difference = now.difference(_lastCheckIn!).inDays;
      if (difference == 1) {
        newStreak++;
      } else if (difference > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }
    
    // データを保存
    await prefs.setInt('streakDays', newStreak);
    await prefs.setString('lastCheckIn', now.toIso8601String());
    await prefs.setString('todayImage', imagePath);
    await prefs.setString('checkIn_$today', imagePath);
    
    // 昨日の画像を更新
    final yesterday = DateFormat('yyyy-MM-dd').format(
      now.subtract(const Duration(days: 1))
    );
    final yesterdayImage = prefs.getString('checkIn_$yesterday');
    if (yesterdayImage != null) {
      await prefs.setString('yesterdayImage', yesterdayImage);
    }
    
    // Providerも更新
    provider.checkIn();
    
    setState(() {
      _streakDays = newStreak;
      _lastCheckIn = now;
      _todayImagePath = imagePath;
      if (yesterdayImage != null) {
        _yesterdayImagePath = yesterdayImage;
      }
    });
    
    // 比較画面へ遷移
    if (_yesterdayImagePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DailyComparisonScreen(
            todayImagePath: imagePath,
            yesterdayImagePath: _yesterdayImagePath!,
            streakDays: newStreak,
          ),
        ),
      );
    } else {
      // 初回チェックインの場合
      _showFirstCheckInDialog();
    }
  }

  void _showFirstCheckInDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('初回チェックイン完了！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 60,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'デイリーチェックを開始しました！\n明日も忘れずにチェックインしてください。',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool get _hasCheckedInToday {
    if (_lastCheckIn == null) return false;
    final today = DateTime.now();
    return _lastCheckIn!.year == today.year &&
           _lastCheckIn!.month == today.month &&
           _lastCheckIn!.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ストリークカード
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: _streakDays > 0
                      ? [const Color(0xFF6B46C1), const Color(0xFF9333EA)]
                      : [Colors.grey[400]!, Colors.grey[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _streakDays > 0
                        ? Icons.local_fire_department
                        : Icons.local_fire_department_outlined,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_streakDays日',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    '連続チェックイン',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  if (_streakDays >= 7) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '🎉 1週間達成！',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // クイックチェックボタン
          const Text(
            '今日のクローゼット',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: _hasCheckedInToday
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraScreen(mode: 'daily'),
                      ),
                    ).then((imagePath) {
                      if (imagePath != null && imagePath is String) {
                        _performDailyCheckIn(imagePath);
                      }
                    });
                  },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasCheckedInToday
                      ? Colors.green
                      : Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
                color: _hasCheckedInToday
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
              ),
              child: _hasCheckedInToday
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 60,
                          color: Colors.green[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '本日のチェックイン完了！',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            if (_todayImagePath != null && _yesterdayImagePath != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DailyComparisonScreen(
                                    todayImagePath: _todayImagePath!,
                                    yesterdayImagePath: _yesterdayImagePath!,
                                    streakDays: _streakDays,
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('比較を見る'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'タップして撮影',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 週間カレンダー
          const Text(
            '今週の記録',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildWeeklyCalendar(),
          
          const SizedBox(height: 32),
          
          // 統計情報
          const Text(
            '今月の統計',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  value: _getMonthlyCheckIns().toString(),
                  label: 'チェックイン',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  value: '${_getAverageScore()}%',
                  label: '平均スコア',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final today = DateTime.now();
    final weekDays = List.generate(7, (index) {
      return today.subtract(Duration(days: 6 - index));
    });

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDays.map((date) {
          final isToday = date.day == today.day &&
                         date.month == today.month &&
                         date.year == today.year;
          final hasCheckIn = _recentCheckIns.any((record) =>
              record.date.day == date.day &&
              record.date.month == date.month &&
              record.date.year == date.year);

          return Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isToday
                    ? Theme.of(context).primaryColor
                    : hasCheckIn
                        ? Colors.green
                        : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isToday
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'ja').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: (isToday || hasCheckIn)
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (isToday || hasCheckIn)
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  if (hasCheckIn)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
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
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getMonthlyCheckIns() {
    final now = DateTime.now();
    return _recentCheckIns.where((record) {
      return record.date.month == now.month && record.date.year == now.year;
    }).length;
  }

  int _getAverageScore() {
    if (_recentCheckIns.isEmpty) return 0;
    final totalScore = _recentCheckIns.fold<int>(
      0,
      (sum, record) => sum + record.score,
    );
    return (totalScore / _recentCheckIns.length).round();
  }
}

// チェックイン記録クラス
class CheckInRecord {
  final DateTime date;
  final String imagePath;
  final int score;

  CheckInRecord({
    required this.date,
    required this.imagePath,
    required this.score,
  });
}