import 'package:flutter/material.dart';

import '../services/marketing_assistant_service.dart';

class StudioMarketingAssistantPage extends StatefulWidget {
  const StudioMarketingAssistantPage({super.key});

  @override
  State<StudioMarketingAssistantPage> createState() => _StudioMarketingAssistantPageState();
}

class _StudioMarketingAssistantPageState extends State<StudioMarketingAssistantPage> {
  late final MarketingAssistantService _service;
  Future<AssistantReport?>? _future;

  @override
  void initState() {
    super.initState();
    _service = MarketingAssistantService.instance();
    _future = _service.getAssistantReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Marketing Nexiom'),
      ),
      body: FutureBuilder<AssistantReport?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Erreur lors du chargement de l\'assistant marketing : ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final report = snapshot.data;
          if (report == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aucun diagnostic n\'a encore été produit par l\'assistant marketing.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.diagnostic != null) ...[
                  Text(
                    'Diagnostic global',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(report.diagnostic!.summary),
                  const SizedBox(height: 12),
                  if (report.diagnostic!.whatWorks.isNotEmpty) ...[
                    Text(
                      'Ce qui marche',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    ...report.diagnostic!.whatWorks
                        .map((e) => _Bullet(text: e))
                        .toList(),
                    const SizedBox(height: 12),
                  ],
                  if (report.diagnostic!.whatTires.isNotEmpty) ...[
                    Text(
                      'Ce qui fatigue',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    ...report.diagnostic!.whatTires
                        .map((e) => _Bullet(text: e))
                        .toList(),
                    const SizedBox(height: 12),
                  ],
                  if (report.diagnostic!.whatIsMissing.isNotEmpty) ...[
                    Text(
                      'Ce qui manque',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    ...report.diagnostic!.whatIsMissing
                        .map((e) => _Bullet(text: e))
                        .toList(),
                    const SizedBox(height: 24),
                  ],
                ],
                Text(
                  'Recommandations (3 actions)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (report.recommendations.isEmpty)
                  const Text('Aucune recommandation n\'a été renvoyée.'),
                ...report.recommendations.map((rec) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Objectif : ${rec.objective}  •  Priorité : ${rec.priority}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(rec.explanation),
                          const SizedBox(height: 8),
                          if (rec.actions.isNotEmpty) ...[
                            const Text('Actions proposées :'),
                            const SizedBox(height: 4),
                            ...rec.actions
                                .map((a) => _Bullet(text: a))
                                .toList(),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
