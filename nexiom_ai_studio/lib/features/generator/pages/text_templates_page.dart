import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/text_template.dart';
import '../services/text_template_service.dart';

class TextTemplatesPage extends StatefulWidget {
  final bool pickMode;
  final String? categoryFilter;

  const TextTemplatesPage({
    super.key,
    this.pickMode = false,
    this.categoryFilter,
  });

  @override
  State<TextTemplatesPage> createState() => _TextTemplatesPageState();
}

class _TextTemplatesPageState extends State<TextTemplatesPage> {
  final _service = TextTemplateService.instance();

  bool _isLoading = false;
  List<TextTemplate> _templates = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _service.listTemplates();
      if (!mounted) return;
      setState(() {
        final filter = widget.categoryFilter;
        if (filter == null) {
          _templates = list;
        } else {
          _templates = list
              .where(
                (t) => t.category == filter || t.category == 'generic',
              )
              .toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du chargement des templates: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTemplate() async {
    final nameController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'generic';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouveau template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du template',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Texte',
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: category,
                  items: const [
                    DropdownMenuItem(
                      value: 'video_script',
                      child: Text('Script vidéo / voix off'),
                    ),
                    DropdownMenuItem(
                      value: 'image_overlay',
                      child: Text('Texte sur image (CTA, numéro...)'),
                    ),
                    DropdownMenuItem(
                      value: 'generic',
                      child: Text('Générique'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      category = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    final name = nameController.text.trim();
    final content = contentController.text.trim();
    if (name.isEmpty || content.isEmpty) {
      return;
    }

    try {
      await _service.createTemplate(
        name: name,
        content: content,
        category: category,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création du template: $e')),
      );
    }
  }

  Future<void> _copyContent(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texte copié dans le presse-papiers.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickMode ? 'Sélectionner un template' : 'Mes templates'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!widget.pickMode)
            IconButton(
              onPressed: _createTemplate,
              icon: const Icon(Icons.add),
              tooltip: 'Nouveau template',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Templates de texte',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enregistrez vos scripts vidéo, textes d\'annonces et CTA pour les réutiliser rapidement.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              )
            else if (_templates.isEmpty)
              const Text(
                'Aucun template pour le moment. Ajoutez-en un avec le bouton + en haut à droite.',
                style: TextStyle(color: Colors.white70),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    final card = Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF0F172A),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                t.category == 'video_script'
                                    ? Icons.movie_filter_outlined
                                    : t.category == 'image_overlay'
                                        ? Icons.image_outlined
                                        : Icons.notes,
                                color: Colors.cyanAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!widget.pickMode)
                                IconButton(
                                  onPressed: () => _copyContent(t.content),
                                  icon:
                                      const Icon(Icons.copy, color: Colors.white70),
                                  tooltip: 'Copier le texte',
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.content,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );

                    if (widget.pickMode) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).pop(t),
                        child: card,
                      );
                    }

                    return card;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
