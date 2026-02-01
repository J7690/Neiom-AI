import 'package:flutter/material.dart';

import '../services/advanced_marketing_service.dart';

class FacebookKnowledgePage extends StatefulWidget {
  const FacebookKnowledgePage({super.key});

  @override
  State<FacebookKnowledgePage> createState() => _FacebookKnowledgePageState();
}

class _FacebookKnowledgePageState extends State<FacebookKnowledgePage> {
  final AdvancedMarketingService _service = AdvancedMarketingService.instance();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.listFacebookKnowledge();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _editItem({Map<String, dynamic>? existing}) async {
    final categoryController = TextEditingController(text: existing?['category']?.toString() ?? '');
    final objectiveController = TextEditingController(text: existing?['objective']?.toString() ?? '');

    String objectiveValue = existing?['objective']?.toString() ?? '';

    String payloadText = '';
    try {
      final payload = existing?['payload'] as Map?;
      final map = payload?.cast<String, dynamic>();
      payloadText = map?['text']?.toString() ?? '';
    } catch (_) {}

    final textController = TextEditingController(text: payloadText);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'Nouvelle règle Facebook' : 'Modifier la règle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    hintText: 'Ex: timing, format, hook, call_to_action',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: objectiveValue.isEmpty ? null : objectiveValue,
                  decoration: const InputDecoration(
                    labelText: 'Objectif principal',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'visibility', child: Text('Visibilité / portée')),
                    DropdownMenuItem(value: 'notoriety', child: Text('Notoriété de marque')),
                    DropdownMenuItem(value: 'engagement', child: Text('Engagement')),
                    DropdownMenuItem(value: 'conversion', child: Text('Conversion')),
                    DropdownMenuItem(value: 'global', child: Text('Global / générique')),
                  ],
                  onChanged: (value) {
                    objectiveValue = value ?? '';
                    objectiveController.text = objectiveValue;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Règles / connaissances',
                    hintText:
                        'Décrire en français les règles que l\'algorithme Facebook semble suivre pour ce cas (ce qui aide, ce qui pénalise, exemples, etc.).',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (categoryController.text.trim().isEmpty || textController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _service.upsertFacebookKnowledge(
        id: existing?['id']?.toString(),
        category: categoryController.text.trim(),
        objective: objectiveValue.isEmpty ? null : objectiveValue,
        text: textController.text.trim(),
      );
      await _loadItems();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Supprimer la règle ?'),
          content: const Text('Cette connaissance sera supprimée du cerveau Facebook.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _service.deleteFacebookKnowledge(id);
      await _loadItems();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connaissance Facebook (cerveau)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () => _editItem(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
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
              onPressed: _loadItems,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_alt, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucune connaissance Facebook enregistrée. Ajoutez vos règles pour guider le cerveau.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final category = item['category']?.toString() ?? '';
          final objective = item['objective']?.toString() ?? '';

          String rulesText = '';
          try {
            final payload = item['payload'] as Map?;
            final map = payload?.cast<String, dynamic>();
            rulesText = map?['text']?.toString() ?? '';
          } catch (_) {}

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.rule),
              title: Text(category),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (objective.isNotEmpty)
                    Text('Objectif: $objective'),
                  if (rulesText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        rulesText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editItem(existing: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      final id = item['id']?.toString();
                      if (id == null || id.isEmpty) return;
                      _deleteItem(id);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
