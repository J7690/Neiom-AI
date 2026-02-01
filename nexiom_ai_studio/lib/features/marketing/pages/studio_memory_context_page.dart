import 'package:flutter/material.dart';

import '../services/marketing_service.dart';

class StudioMemoryContextPage extends StatefulWidget {
  const StudioMemoryContextPage({super.key});

  @override
  State<StudioMemoryContextPage> createState() => _StudioMemoryContextPageState();
}

class _StudioMemoryContextPageState extends State<StudioMemoryContextPage> {
  final MarketingService _service = MarketingService.instance();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _contexts = [];

  @override
  void initState() {
    super.initState();
    _loadContexts();
  }

  Future<void> _loadContexts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contexts = await _service.listStudioMemoryContexts();
      setState(() {
        _contexts = contexts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createContext() async {
    final labelController = TextEditingController();
    final detailsController = TextEditingController();
    String selectedType = 'formation';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nouveau contexte à promouvoir'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du contexte',
                    hintText: 'Ex: Promo formation BTS Banque',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de contexte',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'formation',
                      child: Text('Formation à promouvoir'),
                    ),
                    DropdownMenuItem(
                      value: 'offre',
                      child: Text('Offre spéciale / promotion'),
                    ),
                    DropdownMenuItem(
                      value: 'produit',
                      child: Text('Produit ou service'),
                    ),
                    DropdownMenuItem(
                      value: 'activite',
                      child: Text('Activité / campagne'),
                    ),
                    DropdownMenuItem(
                      value: 'autre',
                      child: Text('Autre'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    selectedType = value;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Détails à transmettre au cerveau',
                    hintText:
                        'Expliquer en langage naturel ce qui doit être mis en avant (formation, offre, produit, cible, période, contraintes, etc.)',
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
                if (labelController.text.trim().isEmpty) {
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

    final label = labelController.text.trim();
    final details = detailsController.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _service.createStudioMemoryContext(
        label: label,
        payload: {
          'type': selectedType,
          if (details.isNotEmpty) 'details': details,
        },
      );
      await _loadContexts();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _setActiveContext(String id) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _service.setActiveStudioContext(id);
    await _loadContexts();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contexte actif mis à jour pour le cerveau Nexiom.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contexte du Studio Nexiom'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createContext,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _contexts.isEmpty) {
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
              onPressed: _loadContexts,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_contexts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.memory, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun contexte enregistré. Créez un contexte pour une formation, une offre ou un produit à promouvoir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContexts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contexts.length,
        itemBuilder: (context, index) {
          final ctx = _contexts[index];
          final bool isActive = ctx['is_active'] == true;
          final label = ctx['label']?.toString() ?? '';
          final payload = ctx['payload'] as Map?;
          String? type;
          String? details;
          try {
            final map = payload?.cast<String, dynamic>();
            type = map?['type']?.toString();
            details = map?['details']?.toString();
          } catch (_) {}

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                Icons.memory,
                color: isActive ? Colors.blue : Colors.grey,
              ),
              title: Text(label),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (type != null && type.isNotEmpty)
                    Text('Type: $type'),
                  if (details != null && details.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        details,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              trailing: isActive
                  ? const Chip(
                      label: Text('Actif'),
                      backgroundColor: Colors.blueAccent,
                      labelStyle: TextStyle(color: Colors.white),
                    )
                  : TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              final id = ctx['id']?.toString();
                              if (id == null || id.isEmpty) return;
                              _setActiveContext(id);
                            },
                      child: const Text('Activer'),
                    ),
            ),
          );
        },
      ),
    );
  }
}
