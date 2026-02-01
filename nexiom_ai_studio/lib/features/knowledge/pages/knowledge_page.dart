import 'package:flutter/material.dart';

import '../services/knowledge_service.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  final _svc = KnowledgeService.instance();

  final _sourceCtrl = TextEditingController(text: 'doc');
  final _titleCtrl = TextEditingController();
  final _localeCtrl = TextEditingController(text: 'fr_BF');
  final _contentCtrl = TextEditingController();

  final _queryCtrl = TextEditingController();
  final _searchLocaleCtrl = TextEditingController(text: 'fr_BF');

  final _listLocaleCtrl = TextEditingController(text: 'fr_BF');
  final _tagCtrl = TextEditingController();

  bool _loading = false;
  List<dynamic> _results = const [];
  List<dynamic> _docs = const [];
  Map<String, dynamic>? _docDetail;

  Future<void> _ingest() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _svc.ingestDocument(
        source: _sourceCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        locale: _localeCtrl.text.trim(),
        content: _contentCtrl.text,
      );
      _titleCtrl.clear();
      _contentCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document indexé')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _listDocs() async {
    setState(() => _loading = true);
    try {
      final res = await _svc.listDocuments(
        locale: _listLocaleCtrl.text.trim().isEmpty ? null : _listLocaleCtrl.text.trim(),
        tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
        limit: 100,
      );
      setState(() { _docs = res; _docDetail = null; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _previewDoc(String id) async {
    setState(() => _loading = true);
    try {
      final d = await _svc.getDocument(id: id);
      setState(() => _docDetail = d);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await _svc.searchKnowledge(query: q, locale: _searchLocaleCtrl.text.trim());
      setState(() => _results = res);
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
        title: const Text('Connaissances (RAG)'),
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
                          const Text('Indexer un document'),
                          TextField(controller: _sourceCtrl, decoration: const InputDecoration(labelText: 'Source')), 
                          const SizedBox(height: 8),
                          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Titre')), 
                          const SizedBox(height: 8),
                          TextField(controller: _localeCtrl, decoration: const InputDecoration(labelText: 'Locale (ex: fr_BF)')), 
                          const SizedBox(height: 8),
                          TextField(controller: _contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Contenu')), 
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loading ? null : _ingest, child: const Text('Indexer')),
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
                          const Text('Recherche'),
                          TextField(controller: _queryCtrl, decoration: const InputDecoration(labelText: 'Question / Mots-clés')),
                          const SizedBox(height: 8),
                          TextField(controller: _searchLocaleCtrl, decoration: const InputDecoration(labelText: 'Locale')),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loading ? null : _search, child: const Text('Rechercher')),
                          const SizedBox(height: 12),
                          ..._results.map((e) {
                            final m = (e as Map);
                            final title = m['title']?.toString() ?? '';
                            final score = m['score']?.toString() ?? '';
                            final snippet = m['snippet']?.toString() ?? '';
                            return ListTile(
                              title: Text(title),
                              subtitle: Text('score=$score\n$snippet'),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mes documents'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextField(controller: _listLocaleCtrl, decoration: const InputDecoration(labelText: 'Locale (optionnel)'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _tagCtrl, decoration: const InputDecoration(labelText: 'Tag (optionnel)'))),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: _loading ? null : _listDocs, child: const Text('Charger')),
                    ]),
                    const SizedBox(height: 12),
                    if (_docs.isEmpty)
                      const Text('Aucun document listé.', style: TextStyle(color: Colors.black54))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _docs.map((e) {
                          final m = (e as Map).cast<String, dynamic>();
                          final id = (m['id'] ?? '').toString();
                          final title = (m['title'] ?? '').toString();
                          final locale = (m['locale'] ?? '').toString();
                          final tags = (m['tags'] as List?)?.join(', ') ?? '';
                          final created = (m['created_at'] ?? '').toString();
                          return ListTile(
                            title: Text(title),
                            subtitle: Text('locale=$locale • $tags\n$created'),
                            trailing: TextButton(onPressed: _loading ? null : () => _previewDoc(id), child: const Text('Voir')),
                          );
                        }).toList(),
                      ),
                    if (_docDetail != null) ...[
                      const Divider(),
                      Text('Prévisualisation', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text((_docDetail!['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(((_docDetail!['content'] ?? '') as String).substring(0, (((_docDetail!['content'] ?? '') as String).length > 800 ? 800 : ((_docDetail!['content'] ?? '') as String).length))),
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
    _sourceCtrl.dispose();
    _titleCtrl.dispose();
    _localeCtrl.dispose();
    _contentCtrl.dispose();
    _queryCtrl.dispose();
    _searchLocaleCtrl.dispose();
    _listLocaleCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }
}
