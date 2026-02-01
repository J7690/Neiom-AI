import 'package:flutter/material.dart';

import '../services/strategy_service.dart';

class BrandRulesPage extends StatefulWidget {
  const BrandRulesPage({super.key});

  @override
  State<BrandRulesPage> createState() => _BrandRulesPageState();
}

class _BrandRulesPageState extends State<BrandRulesPage> {
  final _svc = StrategyService.instance();

  final _localeCtrl = TextEditingController(text: 'fr_BF');
  final _forbiddenCtrl = TextEditingController();
  final _disclaimersCtrl = TextEditingController();
  final _escalateCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  bool _loading = false;
  List<dynamic> _rules = const [];
  String? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.listBrandRules(limit: 200);
      setState(() => _rules = items);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _selectRule(Map<String, dynamic> rule) {
    final locale = rule['locale']?.toString() ?? '';
    final forbidden = (rule['forbidden_terms'] as List?)?.cast<String>() ?? <String>[];
    final disclaimers = (rule['required_disclaimers'] as List?)?.cast<String>() ?? <String>[];
    final escalate = (rule['escalate_on_keywords'] as List?)?.cast<String>() ?? <String>[];
    setState(() {
      _selectedLocale = locale;
      _localeCtrl.text = locale;
      _forbiddenCtrl.text = forbidden.join(', ');
      _disclaimersCtrl.text = disclaimers.join(', ');
      _escalateCtrl.text = escalate.join(', ');
    });
  }

  void _newRule() {
    setState(() {
      _selectedLocale = null;
      _localeCtrl.text = 'fr_BF';
      _forbiddenCtrl.clear();
      _disclaimersCtrl.clear();
      _escalateCtrl.clear();
    });
  }

  Future<void> _save() async {
    final locale = _localeCtrl.text.trim();
    if (locale.isEmpty) return;
    final forbidden = _forbiddenCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final disclaimers = _disclaimersCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final escalate = _escalateCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    setState(() => _loading = true);
    try {
      await _svc.upsertBrandRules(locale: locale, forbiddenTerms: forbidden, requiredDisclaimers: disclaimers, escalateOn: escalate);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Règles enregistrées')));
      }
      setState(() => _selectedLocale = locale);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final locale = _selectedLocale ?? _localeCtrl.text.trim();
    if (locale.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _svc.deleteBrandRules(locale);
      await _refresh();
      _newRule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Règles supprimées')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRules {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _rules.map((e) => (e as Map).cast<String, dynamic>()).toList();
    if (q.isEmpty) return list;
    return list.where((r) => (r['locale']?.toString().toLowerCase() ?? '').contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Règles de marque'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Locales', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher une locale...'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _loading && _rules.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                itemCount: _filteredRules.length,
                                itemBuilder: (context, i) {
                                  final r = _filteredRules[i];
                                  final loc = r['locale']?.toString() ?? '';
                                  final forb = (r['forbidden_terms'] as List?)?.length ?? 0;
                                  final disc = (r['required_disclaimers'] as List?)?.length ?? 0;
                                  final esc = (r['escalate_on_keywords'] as List?)?.length ?? 0;
                                  final selected = _selectedLocale == loc;
                                  return ListTile(
                                    selected: selected,
                                    title: Text(loc),
                                    subtitle: Text('Interdits: $forb • Mentions: $disc • Escalade: $esc'),
                                    onTap: () => _selectRule(r),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(onPressed: _loading ? null : _newRule, child: const Text('Nouveau')),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Éditer la règle', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(controller: _localeCtrl, decoration: const InputDecoration(labelText: 'Locale (ex: fr_BF)')),
                      const SizedBox(height: 8),
                      TextField(controller: _forbiddenCtrl, decoration: const InputDecoration(labelText: 'Termes interdits (séparés par ,)')),
                      const SizedBox(height: 8),
                      TextField(controller: _disclaimersCtrl, decoration: const InputDecoration(labelText: 'Disclaimers requis (séparés par ,)')),
                      const SizedBox(height: 8),
                      TextField(controller: _escalateCtrl, decoration: const InputDecoration(labelText: 'Mots-clés escalade (séparés par ,)')),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _loading || (_selectedLocale == null && _localeCtrl.text.trim().isEmpty) ? null : _delete,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      )
                    ],
                  ),
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
    _localeCtrl.dispose();
    _forbiddenCtrl.dispose();
    _disclaimersCtrl.dispose();
    _escalateCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}
