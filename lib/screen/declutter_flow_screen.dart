import 'package:closet_organizer/provider/closet_provider.dart';
import 'package:closet_organizer/screen/declutter_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;


class DeclutterFlowScreen extends StatefulWidget {
  final List<ClothingItem> items;
  final String originalImagePath;

  const DeclutterFlowScreen({
    Key? key,
    required this.items,
    required this.originalImagePath,
  }) : super(key: key);

  @override
  State<DeclutterFlowScreen> createState() => _DeclutterFlowScreenState();
}

class _DeclutterFlowScreenState extends State<DeclutterFlowScreen> 
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final List<SwipeableCard> _cards = [];
  
  // 判定結果を保存
  final Map<String, JudgmentType> _judgments = {};
  
  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    // 最初の3枚のカードを準備
    for (int i = 0; i < math.min(3, widget.items.length); i++) {
      _cards.add(SwipeableCard(
        key: ValueKey(widget.items[i].id),
        item: widget.items[i],
        onSwipe: _handleSwipe,
        isFront: i == 0,
      ));
    }
  }

  void _handleSwipe(ClothingItem item, SwipeDirection direction) {
    // 判定を保存
    JudgmentType judgment;
    switch (direction) {
      case SwipeDirection.left:
        judgment = JudgmentType.discard;
        break;
      case SwipeDirection.right:
        judgment = JudgmentType.keep;
        break;
      case SwipeDirection.up:
        judgment = JudgmentType.pending;
        break;
    }
    
    setState(() {
      _judgments[item.id] = judgment;
      
      // Providerに判定を保存
      final provider = Provider.of<ClosetProvider>(context, listen: false);
      provider.judgeItem(item.id, judgment);
      
      // カードを削除
      _cards.removeAt(0);
      
      // 次のアイテムを追加
      _currentIndex++;
      if (_currentIndex + 2 < widget.items.length) {
        _cards.add(SwipeableCard(
          key: ValueKey(widget.items[_currentIndex + 2].id),
          item: widget.items[_currentIndex + 2],
          onSwipe: _handleSwipe,
          isFront: false,
        ));
      }
      
      // 最前面のカードを更新
      if (_cards.isNotEmpty) {
        _cards[0] = SwipeableCard(
          key: ValueKey(_cards[0].item.id),
          item: _cards[0].item,
          onSwipe: _handleSwipe,
          isFront: true,
        );
      }
    });
    
    // 全て判定完了したら結果画面へ
    if (_currentIndex >= widget.items.length) {
      _showResults();
    }
  }

  void _showResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DeclutterResultScreen(
          items: widget.items,
          judgments: _judgments,
          originalImagePath: widget.originalImagePath,
        ),
      ),
    );
  }

  int get _remainingItems => widget.items.length - _currentIndex;
  double get _progress => _currentIndex / widget.items.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('断捨離中'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 説明テキスト
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '残り $_remainingItems アイテム',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInstruction(
                      Icons.arrow_back,
                      '捨てる',
                      Colors.red,
                    ),
                    _buildInstruction(
                      Icons.arrow_upward,
                      '迷う',
                      Colors.orange,
                    ),
                    _buildInstruction(
                      Icons.arrow_forward,
                      '残す',
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // カードスタック
          Expanded(
            child: _cards.isEmpty
                ? const Center(
                    child: Text(
                      '全てのアイテムを判定しました！',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: _cards.reversed.toList(),
                  ),
          ),
          
          // 統計情報
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatistic(
                  '残す',
                  _judgments.values.where((j) => j == JudgmentType.keep).length,
                  Colors.green,
                ),
                _buildStatistic(
                  '迷う',
                  _judgments.values.where((j) => j == JudgmentType.pending).length,
                  Colors.orange,
                ),
                _buildStatistic(
                  '捨てる',
                  _judgments.values.where((j) => j == JudgmentType.discard).length,
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistic(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
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
}

// スワイプ方向
enum SwipeDirection { left, right, up }

// スワイプ可能なカード
class SwipeableCard extends StatefulWidget {
  final ClothingItem item;
  final Function(ClothingItem, SwipeDirection) onSwipe;
  final bool isFront;

  const SwipeableCard({
    Key? key,
    required this.item,
    required this.onSwipe,
    required this.isFront,
  }) : super(key: key);

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late Animation<double> _rotationAnimation;
  
  Offset _dragStart = Offset.zero;
  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isFront) return;
    _dragStart = details.localPosition;
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isFront) return;
    setState(() {
      _dragPosition = details.localPosition - _dragStart;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isFront) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final dragDistance = _dragPosition.dx.abs();
    final dragDistanceY = _dragPosition.dy;
    
    // スワイプ判定
    if (dragDistance > screenWidth * 0.4) {
      // 横スワイプ
      final direction = _dragPosition.dx > 0 
          ? SwipeDirection.right 
          : SwipeDirection.left;
      _animateSwipe(direction);
    } else if (dragDistanceY < -100 && dragDistance < screenWidth * 0.2) {
      // 上スワイプ
      _animateSwipe(SwipeDirection.up);
    } else {
      // 元に戻す
      setState(() {
        _dragPosition = Offset.zero;
        _isDragging = false;
      });
    }
  }

  void _animateSwipe(SwipeDirection direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    Offset endPosition;
    double endRotation;
    
    switch (direction) {
      case SwipeDirection.left:
        endPosition = Offset(-screenWidth * 2, 0);
        endRotation = -0.4;
        break;
      case SwipeDirection.right:
        endPosition = Offset(screenWidth * 2, 0);
        endRotation = 0.4;
        break;
      case SwipeDirection.up:
        endPosition = Offset(0, -screenWidth * 2);
        endRotation = 0;
        break;
    }
    
    _animation = Tween<Offset>(
      begin: _dragPosition,
      end: endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: _dragPosition.dx / screenWidth * 0.4,
      end: endRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward().then((_) {
      widget.onSwipe(widget.item, direction);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final opacity = widget.isFront ? 1.0 : 0.8;
    final scale = widget.isFront ? 1.0 : 0.9;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = _isDragging ? _dragPosition : _animation.value;
        final rotation = _isDragging 
            ? _dragPosition.dx / screenWidth * 0.4
            : _rotationAnimation.value;
        
        return Transform.translate(
          offset: position,
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: _buildCard(opacity),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(double opacity) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // ドラッグ中の判定表示
    Color? borderColor;
    String? label;
    if (_isDragging && widget.isFront) {
      if (_dragPosition.dx > screenWidth * 0.2) {
        borderColor = Colors.green;
        label = '残す';
      } else if (_dragPosition.dx < -screenWidth * 0.2) {
        borderColor = Colors.red;
        label = '捨てる';
      } else if (_dragPosition.dy < -50) {
        borderColor = Colors.orange;
        label = '迷う';
      }
    }
    
    return Opacity(
      opacity: opacity,
      child: Container(
        width: screenWidth * 0.85,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor ?? Colors.grey[300]!,
            width: borderColor != null ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリチップ
                  Chip(
                    label: Text(widget.item.category),
                    backgroundColor: _getCategoryColor(widget.item.category),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  
                  // アイテム名
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 判断補助の質問
                  const Text(
                    '考えてみましょう',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildQuestion('最後に着たのはいつですか？'),
                  _buildQuestion('これからも着る予定はありますか？'),
                  _buildQuestion('同じようなアイテムを持っていませんか？'),
                  _buildQuestion('このアイテムを着て幸せを感じますか？'),
                ],
              ),
            ),
            
            // ドラッグ中のラベル表示
            if (label != null)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
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
    );
  }

  Widget _buildQuestion(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              question,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
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
}