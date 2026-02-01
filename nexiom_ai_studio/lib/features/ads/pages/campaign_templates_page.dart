import 'package:flutter/material.dart';
import 'dart:convert';

import '../../strategy/services/strategy_service.dart';
import '../services/campaign_templates_service.dart';

class CampaignTemplatesPage extends StatefulWidget {
  const CampaignTemplatesPage({super.key});

  @override
  State<CampaignTemplatesPage> createState() => _CampaignTemplatesPageState();
}

class _CampaignTemplatesPageState extends State<CampaignTemplatesPage> {
  final _svc = CampaignTemplatesService.instance();
  final _policy = StrategyService.instance();

  final _nameCtrl = TextEditingController();
  final _objective = ValueNotifier<String>('messages');
  final List<String> _objectives = const ['messages','leads','traffic'];
  final _channels = <String, bool>{
    'whatsapp': true,
    'facebook': true,
    'instagram': false,
    'tiktok': false,
    'youtube': false,
  };
  final _toneCtrl = TextEditingController(text: 'neutre');
  final _personasCtrl = TextEditingController(text: '[]');
  final _briefCtrl = TextEditingController();
  final _localeCtrl = TextEditingController(text: 'fr_BF');

  bool _loading = false;
  List<dynamic> _templates = const [];
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _policyResult;
  Map<String, dynamic>? _brandRules;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.listTemplates(limit: 100);
      setState(() => _templates = items);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<String> _selectedChannels() => _channels.entries.where((e) => e.value).map((e) => e.key).toList();

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      List<dynamic> personas;
      try { personas = (personasFromText(_personasCtrl.text)); } catch (_) { personas = <dynamic>[]; }
      await _svc.upsertTemplate(
        name: _nameCtrl.text.trim(),
        objective: _objective.value,
        personas: personas,
        channels: _selectedChannels(),
        tone: _toneCtrl.text.trim().isEmpty ? 'neutre' : _toneCtrl.text.trim(),
        brief: _briefCtrl.text.trim().isEmpty ? null : _briefCtrl.text.trim(),
        metadata: <String, dynamic>{},
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modèle enregistré')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _open(String id) async {
    setState(() => _loading = true);
    try {
      final t = await _svc.getTemplate(id);
      setState(() => _preview = t);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkPolicy() async {
    final text = _briefCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await _policy.contentPolicyCheck(text: text, locale: _localeCtrl.text.trim());
      final br = await _policy.getBrandRules(_localeCtrl.text.trim());
      setState(() { _policyResult = res; _brandRules = br; });
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> personasFromText(String s) {
    // very permissive: try to parse as JSON array, else split by lines
    try {
      final parsed = s.trim();
      if (parsed.isEmpty) return <dynamic>[];
      final obj = parsed.startsWith('[') ? parsed : '[$parsed]';
      return List<dynamic>.from(
        (const JsonDecoder()).convert(obj) as List,
      );
    } catch (_) {
      return s.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modèles de Campagne + Brief'),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
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
                    const Text('Créer / Mettre à jour un modèle'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom du modèle'))),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _objective.value,
                        items: _objectives.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                        onChanged: (v) { if (v!=null) setState(() => _objective.value = v); },
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Wrap(spacing: 12, children: _channels.keys.map((ch) => FilterChip(
                      label: Text(ch),
                      selected: _channels[ch] == true,
                      onSelected: (sel) { setState(() => _channels[ch] = sel); },
                    )).toList()),
                    const SizedBox(height: 8),
                    TextField(controller: _toneCtrl, decoration: const InputDecoration(labelText: 'Ton (ex: neutre, persuasif)')),
                    const SizedBox(height: 8),
                    TextField(controller: _personasCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Personas (JSON array ou lignes)')),
                    const SizedBox(height: 8),
                    TextField(controller: _briefCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Brief de campagne')),
                    const SizedBox(height: 8),
                    Row(children: [
                      ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')), const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _localeCtrl, decoration: const InputDecoration(labelText: 'Locale pour check policy'))),
                      const SizedBox(width: 12),
                      OutlinedButton(onPressed: _loading ? null : _checkPolicy, child: const Text('Vérifier policy')),
                    ]),
                    if (_policyResult != null) ...[
                      const SizedBox(height: 8),
                      Text('Policy: ${_policyResult!['allowed'] == true ? 'OK' : 'Bloqué'}'),
                      Text('Raisons: ${(_policyResult!['reasons'] as List?)?.join(', ') ?? ''}'),
                      if (_brandRules != null) ...[
                        const SizedBox(height: 8),
                        const Text('Règles de marque:'),
                        Text('Locale: ${(_brandRules!['locale'] ?? '').toString()}'),
                        Text('Termes interdits: ${(((_brandRules!['forbidden_terms'] ?? []) as List).join(', '))}'),
                        Text('Mentions obligatoires: ${(((_brandRules!['required_disclaimers'] ?? []) as List).join(', '))}'),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Modèles existants'),
                    const SizedBox(height: 8),
                    _loading && _templates.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                      : Column(children: _templates.map((e) {
                          final m = (e as Map).cast<String, dynamic>();
                          final id = (m['id'] ?? '').toString();
                          final name = (m['name'] ?? '').toString();
                          final obj = (m['objective'] ?? '').toString();
                          final ch = (m['channels'] as List?)?.join(', ') ?? '';
                          return Card(
                            child: ListTile(
                              title: Text(name),
                              subtitle: Text('objectif: $obj • canaux: $ch'),
                              trailing: TextButton(onPressed: _loading ? null : () => _open(id), child: const Text('Voir')),
                            ),
                          );
                        }).toList()),
                    if (_preview != null) ...[
                      const Divider(),
                      Text('Aperçu modèle', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text((_preview!['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('objectif: ${(_preview!['objective'] ?? '').toString()}'),
                      Text('personas: ${(_preview!['personas']?.toString() ?? '')}'),
                      Text('canaux: ${(((_preview!['channels'] ?? []) as List).join(', '))}'),
                      if ((_preview!['brief'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const Text('Brief:'),
                        Text((_preview!['brief'] ?? '').toString()),
                      ]
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _toneCtrl.dispose();
    _personasCtrl.dispose();
    _briefCtrl.dispose();
    _localeCtrl.dispose();
    super.dispose();
  }
}
