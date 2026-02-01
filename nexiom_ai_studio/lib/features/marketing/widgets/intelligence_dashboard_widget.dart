import 'package:flutter/material.dart';
import '../services/advanced_marketing_service.dart';

class IntelligenceDashboardWidget extends StatefulWidget {
  const IntelligenceDashboardWidget({super.key});

  @override
  State<IntelligenceDashboardWidget> createState() => _IntelligenceDashboardWidgetState();
}

class _IntelligenceDashboardWidgetState extends State<IntelligenceDashboardWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdvancedMarketingService _service = AdvancedMarketingService.instance();

  bool _isLoading = false;
  Map<String, dynamic>? _dashboardData;
  List<ProactiveAlert> _alerts = [];
  List<ABTest> _abTests = [];
  List<PerformancePrediction> _predictions = [];
  List<LearningInsight> _insights = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getIntelligenceDashboard();
      
      setState(() {
        _dashboardData = data;
        _alerts = (data['alerts'] as List<dynamic>?)
            ?.map((item) => ProactiveAlert.fromJson(Map<String, dynamic>.from(item)))
            .toList() ?? [];
        _abTests = (data['abTests'] as List<dynamic>?)
            ?.map((item) => ABTest.fromJson(Map<String, dynamic>.from(item)))
            .toList() ?? [];
        _predictions = (data['predictions'] as List<dynamic>?)
            ?.map((item) => PerformancePrediction.fromJson(Map<String, dynamic>.from(item)))
            .toList() ?? [];
        _insights = (data['insights'] as List<dynamic>?)
            ?.map((item) => LearningInsight.fromJson(Map<String, dynamic>.from(item)))
            .toList() ?? [];
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Erreur: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // En-tête avec actions
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.psychology, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Intelligence Marketing Avancée',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _runCompleteAnalysis,
                icon: const Icon(Icons.analytics),
                label: const Text('Analyser'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
              ),
            ],
          ),
        ),
        
        // Onglets
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAlertsTab(),
              _buildABTestsTab(),
              _buildPredictionsTab(),
              _buildInsightsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Aucune alerte proactive',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _service.createProactiveAlerts().then((_) => _loadDashboardData()),
              icon: const Icon(Icons.refresh),
              label: const Text('Générer des alertes'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(ProactiveAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAlertIcon(alert.alertCategory),
                  color: _getAlertColor(alert.severity),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        alert.alertType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAlertColor(alert.severity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.description,
              style: const TextStyle(fontSize: 14),
            ),
            if (alert.recommendation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.recommendation,
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
            if (alert.actionRequired) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _handleAlertAction(alert),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Appliquer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildABTestsTab() {
    if (_abTests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.science, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Aucun test A/B en cours',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _service.createABTest(
                testName: 'Format Test ${DateTime.now().millisecondsSinceEpoch}',
                testType: 'format',
              ).then((_) => _loadDashboardData()),
              icon: const Icon(Icons.add),
              label: const Text('Créer un test A/B'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _abTests.length,
      itemBuilder: (context, index) {
        final test = _abTests[index];
        return _buildABTestCard(test);
      },
    );
  }

  Widget _buildABTestCard(ABTest test) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.purple, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.testName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Test A/B: ${test.testType.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(test.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    test.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Variantes
            Row(
              children: [
                Expanded(
                  child: _buildVariantCard('Variant A', test.variantA, true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVariantCard('Variant B', test.variantB, false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Résultats
            if (test.winner != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getWinnerColor(test.winner!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Gagnant: ${test.winner!.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _service.analyzeABTest(test.id),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analyser'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleABTestAction(test),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Appliquer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantCard(String title, Map<String, dynamic> variant, bool isFirst) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFirst ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFirst ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isFirst ? Colors.blue[700] : Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          ...variant.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    if (_predictions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Aucune prédiction disponible',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _service.generatePerformancePredictions(
                predictionType: 'engagement',
                daysAhead: 7,
              ).then((_) => _loadDashboardData()),
              icon: const Icon(Icons.refresh),
              label: const Text('Générer des prédictions'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _predictions.length,
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return _buildPredictionCard(prediction);
      },
    );
  }

  Widget _buildPredictionCard(PerformancePrediction prediction) {
    final accuracy = prediction.accuracyScore != null 
        ? (prediction.accuracyScore! * 100).toStringAsFixed(1)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prédiction ${prediction.predictionType}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Date: ${_formatDate(prediction.predictionDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (accuracy != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getAccuracyColor(double.parse(accuracy)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Précision: $accuracy%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            // Valeur prédite
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.show_chart, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Valeur prédite: ${prediction.predictedValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Intervalle de confiance
            Row(
              children: [
                Text(
                  'Intervalle: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${prediction.confidenceIntervalLower.toStringAsFixed(2)} - ${prediction.confidenceIntervalUpper.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    if (_insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Aucun insight disponible',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _service.analyzeAdvancedPatterns().then((_) => _loadDashboardData()),
              icon: const Icon(Icons.refresh),
              label: const Text('Analyser les patterns'),
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
        return _buildInsightCard(insight);
      },
    );
  }

  Widget _buildInsightCard(LearningInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getInsightIcon(insight.insightType),
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.insightTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        insight.insightType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Impact: ${(insight.impactScore * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Confiance: ${(insight.confidenceScore * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              insight.insightDescription,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            
            if (insight.actionableRecommendation.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700], size: 16),
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
  }

  Future<void> _runCompleteAnalysis() async {
    setState(() => _isLoading = true);

    try {
      await _service.runCompleteAnalysis();
      await _loadDashboardData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analyse complète terminée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'analyse'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAlertAction(ProactiveAlert alert) async {
    // Implémenter l'action pour l'alerte
    print('Action requise pour alerte: ${alert.title}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action en cours d\'implémentation'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _handleABTestAction(ABTest test) async {
    // Implémenter l'action pour le test A/B
    print('Action requise pour test: ${test.testName}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application en cours d\'implémentation'),
          backgroundColor: Colors.purple,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getAlertColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getWinnerColor(String winner) {
    switch (winner) {
      case 'variant_a':
        return Colors.blue;
      case 'variant_b':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) {
      return Colors.green;
    } else if (accuracy >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getAlertIcon(String category) {
    switch (category) {
      case 'opportunity':
        return Icons.trending_up;
      case 'risk':
        return Icons.warning;
      case 'optimization':
        return Icons.settings;
      case 'trend':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'pattern':
        return Icons.pattern;
      case 'correlation':
        return Icons.compare_arrows;
      case 'anomaly':
        return Icons.error;
      case 'trend':
        return Icons.trending_up;
      default:
        return Icons.psychology;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
