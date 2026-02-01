import 'package:flutter/material.dart';

import '../services/experiments_service.dart';

class ExperimentsPage extends StatefulWidget {
  const ExperimentsPage({super.key});

  @override
  State<ExperimentsPage> createState() => _ExperimentsPageState();
}

class _ExperimentsPageState extends State<ExperimentsPage> {
  final _svc = ExperimentsService.instance();

  // Create form
  final _nameCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _hypothesisCtrl = TextEditingController();
  final Set<String> _channels = {'facebook', 'instagram'};
  final List<String> _allChannels = const ['facebook', 'instagram', 'tiktok', 'youtube'];

  // Variants & selection
  String? _selectedExperimentId;
  List<dynamic> _experiments = const [];
  List<dynamic> _variants = const [];
  bool _loading = false;
  int _variantCount = 3;
  int _scheduleInMinutes = 5;

  @override
  void initState() {
    super.initState();
    _refreshExperiments();
  }

  Future<void> _refreshExperiments() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.listExperiments(limit: 50);
      setState(() => _experiments = items);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createExperiment() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      final exp = await _svc.createExperiment(
        name: name,
        objective: _objectiveCtrl.text.trim().isEmpty ? null : _objectiveCtrl.text.trim(),
        hypothesis: _hypothesisCtrl.text.trim().isEmpty ? null : _hypothesisCtrl.text.trim(),
        channels: _channels.toList(),
      );
      _nameCtrl.clear();
      _objectiveCtrl.clear();
      _hypothesisCtrl.clear();
      await _refreshExperiments();
      setState(() => _selectedExperimentId = exp['id'].toString());
      await _loadVariants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expérience créée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadVariants() async {
    final id = _selectedExperimentId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final items = await _svc.listVariantsForExperiment(id);
      setState(() => _variants = items);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _generateVariants() async {
    final id = _selectedExperimentId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      await _svc.generatePostVariants(experimentId: id, count: _variantCount);
      await _loadVariants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variantes générées')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _scheduleVariant(String variantId) async {
    setState(() => _loading = true);
    try {
      final when = DateTime.now().toUtc().add(Duration(minutes: _scheduleInMinutes));
      await _svc.scheduleVariantPost(variantId: variantId, scheduleAt: when);
      await _loadVariants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variante planifiée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _evaluate() async {
    final id = _selectedExperimentId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      await _svc.evaluateVariants(id);
      await _loadVariants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Évaluation enregistrée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _applyStops() async {
    final id = _selectedExperimentId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      await _svc.applyStopRules(experimentId: id, minImpressions: 100, engagementThreshold: 0.01);
      await _loadVariants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Règles d\'arrêt appliquées')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expérimentations (A/B)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                          const Text('Créer une expérience'),
                          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom')), 
                          const SizedBox(height: 8),
                          TextField(controller: _objectiveCtrl, decoration: const InputDecoration(labelText: 'Objectif')), 
                          const SizedBox(height: 8),
                          TextField(controller: _hypothesisCtrl, decoration: const InputDecoration(labelText: 'Hypothèse')), 
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _allChannels.map((ch) {
                              final sel = _channels.contains(ch);
                              return FilterChip(
                                label: Text(ch),
                                selected: sel,
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      _channels.add(ch);
                                    } else {
                                      _channels.remove(ch);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loading ? null : _createExperiment, child: const Text('Créer')),
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
                          const Text('Expériences'),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: _selectedExperimentId,
                            hint: const Text('Sélectionner une expérience'),
                            isExpanded: true,
                            items: _experiments.map((e) {
                              final m = (e as Map);
                              return DropdownMenuItem<String>(
                                value: m['id'].toString(),
                                child: Text((m['name'] ?? '').toString()),
                              );
                            }).toList(),
                            onChanged: (v) async {
                              setState(() => _selectedExperimentId = v);
                              await _loadVariants();
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Variantes:'),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true),
                                  onChanged: (v) {
                                    final n = int.tryParse(v);
                                    if (n != null && n > 0 && n <= 10) setState(() => _variantCount = n);
                                  },
                                  controller: TextEditingController(text: _variantCount.toString()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(onPressed: _loading ? null : _generateVariants, child: const Text('Générer')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Planif. +min:'),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true),
                                  onChanged: (v) {
                                    final n = int.tryParse(v);
                                    if (n != null && n >= 0 && n <= 1440) setState(() => _scheduleInMinutes = n);
                                  },
                                  controller: TextEditingController(text: _scheduleInMinutes.toString()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(onPressed: _loading ? null : _evaluate, child: const Text('Évaluer')),
                              const SizedBox(width: 8),
                              ElevatedButton(onPressed: _loading ? null : _applyStops, child: const Text('Stop rules')),
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
            const Text('Variantes'),
            const SizedBox(height: 8),
            ..._variants.map((e) {
              final m = (e as Map);
              final id = m['id']?.toString() ?? '';
              final idx = m['variant_index']?.toString() ?? '';
              final status = m['status']?.toString() ?? '';
              final text = m['content_text']?.toString() ?? '';
              final postId = m['post_id']?.toString();
              return Card(
                child: ListTile(
                  title: Text('Variante $idx — $status'),
                  subtitle: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (postId == null)
                        TextButton(
                          onPressed: _loading ? null : () => _scheduleVariant(id),
                          child: const Text('Planifier'),
                        ),
                      if (postId != null)
                        TextButton(
                          onPressed: null,
                          child: Text('Post: ${postId.substring(0, 8)}…'),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _objectiveCtrl.dispose();
    _hypothesisCtrl.dispose();
    super.dispose();
  }
}
