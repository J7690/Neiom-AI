import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

import '../services/ads_service.dart';

class AdsRecoPage extends StatefulWidget {
  const AdsRecoPage({super.key});

  @override
  State<AdsRecoPage> createState() => _AdsRecoPageState();
}

class _AdsRecoPageState extends State<AdsRecoPage> {
  final _svc = AdsService.instance();

  final _objective = ValueNotifier<String>('messages');
  final List<String> _objectives = const ['messages', 'leads', 'traffic'];
  final _budgetCtrl = TextEditingController(text: '50000');
  final _daysCtrl = TextEditingController(text: '7');
  final _localesCtrl = TextEditingController(text: 'fr_BF');
  final _interestsCtrl = TextEditingController(text: 'informatique, formation');
  final Set<String> _channels = {'facebook','instagram'};

  bool _loading = false;
  bool _creating = false;
  Map<String, dynamic>? _reco;

  Future<void> _run() async {
    setState(() => _loading = true);
    try {
      final budget = num.tryParse(_budgetCtrl.text.trim()) ?? 0;
      final days = int.tryParse(_daysCtrl.text.trim()) ?? 7;
      final locales = _localesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final interests = _interestsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final reco = await _svc.recommendCampaigns(
        objective: _objective.value,
        budget: budget,
        days: days,
        locales: locales.isEmpty ? const ['fr_BF'] : locales,
        interests: interests,
        channels: _channels.toList(),
      );
      setState(() => _reco = reco);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createCampaign() async {
    setState(() => _creating = true);
    try {
      final budget = num.tryParse(_budgetCtrl.text.trim()) ?? 0;
      final days = int.tryParse(_daysCtrl.text.trim()) ?? 7;
      final locales = _localesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final interests = _interestsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final res = await _svc.createAdsFromRecommendation(
        objective: _objective.value,
        budget: budget,
        days: days,
        locales: locales.isEmpty ? const ['fr_BF'] : locales,
        interests: interests,
        channels: _channels.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Campagne créée: ${res['campaign_id']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Création campagne échouée: $e')));
      }
    } finally {
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommandations Ads'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Paramètres')
                    ,const SizedBox(height: 8),
                    Row(children: [
                      DropdownButton<String>(
                        value: _objective.value,
                        items: _objectives.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) { if (v!=null) setState(() => _objective.value = v); },
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _budgetCtrl, decoration: const InputDecoration(labelText: 'Budget total'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      SizedBox(width: 80, child: TextField(controller: _daysCtrl, decoration: const InputDecoration(labelText: 'Jours'), keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextField(controller: _localesCtrl, decoration: const InputDecoration(labelText: 'Locales (comma)'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _interestsCtrl, decoration: const InputDecoration(labelText: 'Intérêts (comma)'))),
                    ]),
                    const SizedBox(height: 8),
                    const Text('Canaux'),
                    Wrap(spacing: 8, children: ['facebook','instagram','tiktok','youtube'].map((ch){
                      final sel = _channels.contains(ch);
                      return FilterChip(label: Text(ch), selected: sel, onSelected: (v){ setState((){ v ? _channels.add(ch) : _channels.remove(ch); }); });
                    }).toList()),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _loading ? null : _run, child: const Text('Générer recommandations')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _reco != null) ...[
              Text('Objectif: ${_reco!['objective']} | Budget: ${_reco!['budget_total']} | Jours: ${_reco!['days']} | Quotidien: ${_reco!['daily_budget']}'),
              const SizedBox(height: 8),
              Text('Locales: ${( (_reco!['locales'] as List?) ?? const []).join(', ')} | Placements: ${( (_reco!['channels'] as List?) ?? const []).join(', ')}'),
              const SizedBox(height: 8),
              const Text('Top creatives'),
              ...((( _reco!['top_creatives'] as List?) ?? const []).map((e){
                final m = (e as Map).cast<String, dynamic>();
                return Card(child: ListTile(title: Text(m['content']?.toString() ?? ''), subtitle: Text('Score: ${m['score']} | ER: ${m['engagement_rate']}')));
              }).toList()),
              const SizedBox(height: 8),
              const Text('Proposition'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text((_reco!['proposal'] ?? {}).toString()),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton(
                  onPressed: _creating ? null : _createCampaign,
                  child: _creating
                      ? const SizedBox(height:16, width:16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Créer campagne'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.adsCampaigns),
                  child: const Text('Voir campagnes'),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
