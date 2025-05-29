import 'dart:io';
import 'package:closet_organizer/provider/closet_provider.dart';
import 'package:closet_organizer/service/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/loading_overlay.dart';
import 'organize_simulation_screen.dart';

class OrganizeSuggestionsScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, Map<String, dynamic>> areaDetails;

  const OrganizeSuggestionsScreen({
    Key? key,
    required this.imagePath,
    required this.areaDetails,
  }) : super(key: key);

  @override
  State<OrganizeSuggestionsScreen> createState() => _OrganizeSuggestionsScreenState();
}

class _OrganizeSuggestionsScreenState extends State<OrganizeSuggestionsScreen> {
  List<OrganizationSuggestion> _suggestions = [];
  bool _isLoading = true;
  String? _error;
  int _selectedSuggestionIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // OpenAI APIから提案を取得
      final provider = Provider.of<ClosetProvider>(context, listen: false);
      final suggestions = await OpenAIApiService.getOrganizationSuggestions(
        widget.imagePath,
        provider.areas,
      );

      // 提案をパースして構造化
      setState(() {
        _suggestions = _parseSuggestions(suggestions);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<OrganizationSuggestion> _parseSuggestions(List<String> rawSuggestions) {
    final List<OrganizationSuggestion> suggestions = [];
    
    // 頻度ベースの提案
    final highFrequencyAreas = widget.areaDetails.entries
        .where((e) => (e.value['usageFrequency'] ?? 0) >= 4)
        .map((e) => e.value['name'] as String)
        .toList();
    
    if (highFrequencyAreas.isNotEmpty) {
      suggestions.add(OrganizationSuggestion(
        title: '頻繁に使うアイテムを手前に',
        description: '${highFrequencyAreas.join("、")}を取り出しやすい位置に移動しましょう',
        priority: SuggestionPriority.high,
        icon: Icons.access_time,
        affectedAreas: highFrequencyAreas,
        actions: [
          '目線の高さに移動',
          '手前に配置',
          'グループ化して整理',
        ],
      ));
    }

    // 空間活用の提案
    final underutilizedAreas = widget.areaDetails.entries
        .where((e) => (e.value['usageRate'] ?? 0) < 40)
        .map((e) => e.value['name'] as String)
        .toList();
    
    if (underutilizedAreas.isNotEmpty) {
      suggestions.add(OrganizationSuggestion(
        title: '空間を有効活用',
        description: '${underutilizedAreas.join("、")}にまだ余裕があります',
        priority: SuggestionPriority.medium,
        icon: Icons.space_dashboard,
        affectedAreas: underutilizedAreas,
        actions: [
          '収納ボックスを追加',
          '仕切りを使って整理',
          '季節物を収納',
        ],
      ));
    }

    // 整理状態の改善提案
    final messyAreas = widget.areaDetails.entries
        .where((e) => e.value['organizationLevel'] == '乱雑' || 
                     e.value['organizationLevel'] == '少し乱雑')
        .map((e) => e.value['name'] as String)
        .toList();
    
    if (messyAreas.isNotEmpty) {
      suggestions.add(OrganizationSuggestion(
        title: '整理整頓が必要なエリア',
        description: '${messyAreas.join("、")}を整理しましょう',
        priority: SuggestionPriority.high,
        icon: Icons.cleaning_services,
        affectedAreas: messyAreas,
        actions: [
          'カテゴリ別に分類',
          '不要なものを取り除く',
          'ラベルを付けて管理',
        ],
      ));
    }

    // APIからの提案も追加
    for (int i = 0; i < rawSuggestions.length && i < 3; i++) {
      suggestions.add(OrganizationSuggestion(
        title: 'AI提案 ${i + 1}',
        description: rawSuggestions[i],
        priority: SuggestionPriority.medium,
        icon: Icons.auto_awesome,
        affectedAreas: [],
        actions: [],
      ));
    }

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('整理整頓の提案'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'AIが最適な配置を分析中...',
        child: _error != null
            ? _buildErrorView()
            : _buildSuggestionsView(),
      ),
      bottomNavigationBar: _selectedSuggestionIndex >= 0
          ? Container(
              padding: const EdgeInsets.all(16),
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
              child: ElevatedButton(
                onPressed: _proceedToSimulation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'この提案をシミュレーション',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
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
              onPressed: _loadSuggestions,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsView() {
    if (_suggestions.isEmpty) {
      return const Center(
        child: Text(
          '提案がありません',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // ヘッダー
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_suggestions.length}個の改善提案があります',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 提案リスト
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              final isSelected = _selectedSuggestionIndex == index;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSuggestionIndex = isSelected ? -1 : index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(suggestion.priority)
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                suggestion.icon,
                                color: _getPriorityColor(suggestion.priority),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    suggestion.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (suggestion.priority == SuggestionPriority.high)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '優先度高',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          suggestion.description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                        if (suggestion.affectedAreas.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: suggestion.affectedAreas
                                .map((area) => Chip(
                                      label: Text(
                                        area,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: Colors.grey[200],
                                    ))
                                .toList(),
                          ),
                        ],
                        if (suggestion.actions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            '実行アクション:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...suggestion.actions.map((action) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.green[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      action,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return Colors.red;
      case SuggestionPriority.medium:
        return Colors.orange;
      case SuggestionPriority.low:
        return Colors.green;
    }
  }

  void _proceedToSimulation() {
    if (_selectedSuggestionIndex < 0) return;
    
    final selectedSuggestion = _suggestions[_selectedSuggestionIndex];
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrganizeSimulationScreen(
          imagePath: widget.imagePath,
          areaDetails: widget.areaDetails,
          suggestion: selectedSuggestion,
        ),
      ),
    );
  }
}

// 提案データクラス
class OrganizationSuggestion {
  final String title;
  final String description;
  final SuggestionPriority priority;
  final IconData icon;
  final List<String> affectedAreas;
  final List<String> actions;

  OrganizationSuggestion({
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
    required this.affectedAreas,
    required this.actions,
  });
}

enum SuggestionPriority {
  high,
  medium,
  low,
}