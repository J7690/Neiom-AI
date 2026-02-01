import 'package:flutter/material.dart';

import '../services/strategy_service.dart';

class StrategyPage extends StatefulWidget {
  const StrategyPage({super.key});

  @override
  State<StrategyPage> createState() => _StrategyPageState();
}

class _StrategyPageState extends State<StrategyPage> {
  final _svc = StrategyService.instance();

  final _titleCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _localeCtrl = TextEditingController(text: 'fr_BF');
  final _forbiddenCtrl = TextEditingController();
  final _disclaimersCtrl = TextEditingController();
  final _escalateCtrl = TextEditingController();
  final _policyTextCtrl = TextEditingController();

  final Set<String> _selectedChannels = {'facebook', 'instagram'};
  final List<String> _allChannels = const ['facebook', 'instagram', 'tiktok', 'youtube', 'whatsapp'];

  bool _loading = false;
  List<dynamic> _strategies = const [];
  String? _policyResult;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.listStrategyPlans(limit: 50);
      setState(() => _strategies = items);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createStrategy() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _svc.createStrategyPlan(
        title: title,
        objective: _objectiveCtrl.text.trim().isEmpty ? null : _objectiveCtrl.text.trim(),
        channels: _selectedChannels.toList(),
        kpis: const ['leads', 'engagement', 'messages'],
        hypotheses: const ['hooks courts', 'call-to-action clair'],
      );
      _titleCtrl.clear();
      _objectiveCtrl.clear();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stratégie créée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id, bool approve) async {
    setState(() => _loading = true);
    try {
      await _svc.approveStrategyPlan(id: id, approve: approve);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveBrandRules() async {
    final locale = _localeCtrl.text.trim();
    final forbidden = _forbiddenCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final disclaimers = _disclaimersCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final escalate = _escalateCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    setState(() => _loading = true);
    try {
      await _svc.upsertBrandRules(locale: locale, forbiddenTerms: forbidden, requiredDisclaimers: disclaimers, escalateOn: escalate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Règles de marque enregistrées')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkPolicy() async {
    final txt = _policyTextCtrl.text;
    setState(() => _loading = true);
    try {
      final res = await _svc.contentPolicyCheck(text: txt, locale: _localeCtrl.text.trim());
      setState(() => _policyResult = res.toString());
    } catch (e) {
      setState(() => _policyResult = 'Erreur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stratégie Marketing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Créer une stratégie', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Titre')),
                            const SizedBox(height: 8),
                            TextField(controller: _objectiveCtrl, decoration: const InputDecoration(labelText: 'Objectif')),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _allChannels.map((ch) {
                                final sel = _selectedChannels.contains(ch);
                                return FilterChip(
                                  label: Text(ch),
                                  selected: sel,
                                  onSelected: (v) {
                                    setState(() {
                                      if (v) {
                                        _selectedChannels.add(ch);
                                      } else {
                                        _selectedChannels.remove(ch);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loading ? null : _createStrategy,
                              child: const Text('Créer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Règles de marque', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(controller: _localeCtrl, decoration: const InputDecoration(labelText: 'Locale (ex: fr_BF)')),
                            const SizedBox(height: 8),
                            TextField(controller: _forbiddenCtrl, decoration: const InputDecoration(labelText: 'Termes interdits (séparés par ,)')),
                            const SizedBox(height: 8),
                            TextField(controller: _disclaimersCtrl, decoration: const InputDecoration(labelText: 'Disclaimers requis (séparés par ,)')),
                            const SizedBox(height: 8),
                            TextField(controller: _escalateCtrl, decoration: const InputDecoration(labelText: 'Mots-clés escalade (séparés par ,)')),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loading ? null : _saveBrandRules,
                              child: const Text('Enregistrer les règles'),
                            ),
                            const Divider(height: 24),
                            const Text('Vérification de policy'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _policyTextCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(labelText: 'Texte à vérifier'),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _loading ? null : _checkPolicy,
                                  child: const Text('Vérifier'),
                                ),
                                const SizedBox(width: 12),
                                if (_policyResult != null)
                                  Expanded(
                                    child: Text(
                                      _policyResult!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Stratégies récentes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh)),
                ],
              ),
              const SizedBox(height: 8),
              _loading && _strategies.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  : Column(
                      children: _strategies.map((e) {
                        final id = (e as Map)['id']?.toString() ?? '';
                        final title = e['title']?.toString() ?? '';
                        final status = e['status']?.toString() ?? '';
                        final channels = (e['channels'] as List?)?.cast<String>() ?? <String>[];
                        return Card(
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text('Status: $status • Canaux: ${channels.join(', ')}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: _loading ? null : () => _approve(id, true),
                                  child: const Text('Approuver'),
                                ),
                                TextButton(
                                  onPressed: _loading ? null : () => _approve(id, false),
                                  child: const Text('Rejeter'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _objectiveCtrl.dispose();
    _localeCtrl.dispose();
    _forbiddenCtrl.dispose();
    _disclaimersCtrl.dispose();
    _escalateCtrl.dispose();
    _policyTextCtrl.dispose();
    super.dispose();
  }
}
