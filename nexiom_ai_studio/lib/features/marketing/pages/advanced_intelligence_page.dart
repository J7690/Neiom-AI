import 'package:flutter/material.dart';
import '../services/advanced_marketing_service.dart';
import '../widgets/intelligence_dashboard_widget.dart';
import 'facebook_knowledge_page.dart';
import 'studio_brain_insights_page.dart';
import 'studio_marketing_assistant_page.dart';

class AdvancedIntelligencePage extends StatefulWidget {
  const AdvancedIntelligencePage({super.key});

  @override
  State<AdvancedIntelligencePage> createState() => _AdvancedIntelligencePageState();
}

class _AdvancedIntelligencePageState extends State<AdvancedIntelligencePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligence Marketing Avancée'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FacebookKnowledgePage(),
                ),
              );
            },
            icon: const Icon(Icons.rule),
            tooltip: 'Connaissance Facebook',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StudioBrainInsightsPage(),
                ),
              );
            },
            icon: const Icon(Icons.psychology_alt),
            tooltip: 'Insights du cerveau',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StudioMarketingAssistantPage(),
                ),
              );
            },
            icon: const Icon(Icons.support_agent),
            tooltip: 'Assistant marketing',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdvancedIntelligencePage(),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: const IntelligenceDashboardWidget(),
    );
  }
}

