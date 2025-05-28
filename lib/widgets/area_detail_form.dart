import 'package:flutter/material.dart';

class AreaDetailForm extends StatefulWidget {
  final String areaName;
  final String category;
  final Function(Map<String, dynamic>) onSave;

  const AreaDetailForm({
    Key? key,
    required this.areaName,
    required this.category,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AreaDetailForm> createState() => _AreaDetailFormState();
}

class _AreaDetailFormState extends State<AreaDetailForm> {
  final _formKey = GlobalKey<FormState>();
  int _itemCount = 0;
  double _usageFrequency = 3.0;
  String _organizationLevel = '普通';
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // エリア名とカテゴリ表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(widget.category),
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.areaName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // アイテム数
          const Text(
            'アイテム数（概数）',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _itemCount.toDouble(),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  label: _itemCount.toString(),
                  onChanged: (value) {
                    setState(() {
                      _itemCount = value.toInt();
                    });
                  },
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_itemCount個',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 使用頻度
          const Text(
            '使用頻度',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('低'),
              Expanded(
                child: Slider(
                  value: _usageFrequency,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) {
                    setState(() {
                      _usageFrequency = value;
                    });
                  },
                ),
              ),
              const Text('高'),
            ],
          ),
          Center(
            child: Chip(
              label: Text(_getFrequencyLabel(_usageFrequency)),
              backgroundColor: _getFrequencyColor(_usageFrequency),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 整理状態
          const Text(
            '現在の整理状態',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['とても整理されている', '整理されている', '普通', '少し乱雑', '乱雑']
                .map((level) => ChoiceChip(
                      label: Text(level),
                      selected: _organizationLevel == level,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _organizationLevel = level;
                          });
                        }
                      },
                    ))
                .toList(),
          ),
          
          const SizedBox(height: 24),
          
          // メモ
          const Text(
            'メモ（任意）',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '例：季節物が多い、取り出しにくい位置にある等',
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 保存ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAreaDetails,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '保存',
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

  void _saveAreaDetails() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'itemCount': _itemCount,
        'usageFrequency': _usageFrequency,
        'organizationLevel': _organizationLevel,
        'notes': _notesController.text,
        'usageRate': _calculateUsageRate(),
      });
    }
  }

  double _calculateUsageRate() {
    // 簡易的な使用率計算
    // アイテム数と整理状態から推定
    double rate = (_itemCount / 50) * 100;
    
    if (_organizationLevel == '乱雑') {
      rate = rate * 1.2;
    } else if (_organizationLevel == 'とても整理されている') {
      rate = rate * 0.8;
    }
    
    return rate.clamp(0, 100);
  }

  String _getFrequencyLabel(double value) {
    if (value <= 1.5) return 'ほとんど使わない';
    if (value <= 2.5) return '月に数回';
    if (value <= 3.5) return '週に数回';
    if (value <= 4.5) return '毎日';
    return '1日に何度も';
  }

  Color _getFrequencyColor(double value) {
    if (value <= 2) return Colors.grey;
    if (value <= 3) return Colors.blue;
    if (value <= 4) return Colors.orange;
    return Colors.red;
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}