import 'package:flutter/material.dart';

import '../services/advanced_marketing_service.dart';
import '../services/marketing_service.dart';

class StudioBrainInsightsPage extends StatefulWidget {
  const StudioBrainInsightsPage({super.key});

  @override
  State<StudioBrainInsightsPage> createState() => _StudioBrainInsightsPageState();
}

class _StudioBrainInsightsPageState extends State<StudioBrainInsightsPage>
    with SingleTickerProviderStateMixin {
  final AdvancedMarketingService _advancedService = AdvancedMarketingService.instance();
  final MarketingService _marketingService = MarketingService.instance();

  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  List<LearningInsight> _insights = [];
  List<Map<String, dynamic>> _analysisRuns = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final insights = await _advancedService.getLearningInsights(limit: 20);
      final runs = await _marketingService.getRecentStudioAnalysisRuns(limit: 20);

      setState(() {
        _insights = insights;
        _analysisRuns = runs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights du cerveau Nexiom'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.psychology), text: 'Insights apprentissage'),
            Tab(icon: Icon(Icons.history), text: 'Exécutions du cerveau'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _insights.isEmpty && _analysisRuns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildInsightsTab(),
        _buildRunsTab(),
      ],
    );
  }

  Widget _buildInsightsTab() {
    if (_insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun insight enregistré pour le moment.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _insights.length,
      itemBuilder: (context, index) {
        final insight = _insights[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.insightTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  insight.insightDescription,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text('Impact ${(insight.impactScore * 100).toStringAsFixed(0)}%'),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label:
                          Text('Confiance ${(insight.confidenceScore * 100).toStringAsFixed(0)}%'),
                    ),
                  ],
                ),
                if (insight.actionableRecommendation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight.actionableRecommendation,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRunsTab() {
    if (_analysisRuns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucune exécution du cerveau enregistrée pour le moment.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _analysisRuns.length,
      itemBuilder: (context, index) {
        final run = _analysisRuns[index];
        final source = run['source']?.toString() ?? 'marketing_brain';
        final createdAtStr = run['created_at']?.toString() ?? '';
        Map<String, dynamic>? inputMetrics;
        try {
          inputMetrics = (run['input_metrics'] as Map?)?.cast<String, dynamic>();
        } catch (_) {
          inputMetrics = null;
        }
        final objective = inputMetrics?['objective']?.toString();
        final market = inputMetrics?['market']?.toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.psychology_alt),
            title: Text(source),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (objective != null && objective.isNotEmpty)
                  Text('Objectif: $objective'),
                if (market != null && market.isNotEmpty)
                  Text('Marché: $market'),
                if (createdAtStr.isNotEmpty)
                  Text(
                    'Analyse: $createdAtStr',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
