import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/facebook_service.dart';

class FacebookPostComposer extends StatefulWidget {
  final VoidCallback? onPostPublished;

  const FacebookPostComposer({super.key, this.onPostPublished});

  @override
  State<FacebookPostComposer> createState() => _FacebookPostComposerState();
}

class _FacebookPostComposerState extends State<FacebookPostComposer> {
  final FacebookService _facebookService = FacebookService.instance();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();

  String _selectedType = 'text';
  bool _isPublishing = false;
  String? _publishError;
  FacebookPostResponse? _lastPostResult;

  final List<Map<String, dynamic>> _postTypes = [
    {'value': 'text', 'label': 'Texte', 'icon': Icons.text_fields},
    {'value': 'image', 'label': 'Image', 'icon': Icons.image},
    {'value': 'video', 'label': 'Vidéo', 'icon': Icons.video_file},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.post_add, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Composer une publication',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sélection du type de publication
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Type de publication',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _postTypes.map((type) {
                      final isSelected = _selectedType == type['value'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type['value']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  color: isSelected ? Colors.white : Colors.grey[600],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Message
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Écrivez votre message ici...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_messageController.text.length} caractères',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // URL du média (image/vidéo)
          if (_selectedType != 'text') ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URL ${_selectedType == 'image' ? 'de l\'image' : 'de la vidéo'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _selectedType == 'image' 
                          ? _imageUrlController 
                          : _videoUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/${_selectedType}.jpg',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(_selectedType == 'image' ? Icons.image : Icons.video_file),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'L\'URL doit être accessible publiquement',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Bouton de publication
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPublishing
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text('Confirmer la publication'),
                            content: const Text(
                              'Vous allez publier ce contenu immédiatement sur la page Facebook configurée. Confirmer ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Confirmer'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmed == true) {
                        _publishPost();
                      }
                    },
              icon: _isPublishing 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isPublishing ? 'Publication...' : 'Publier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Erreur de publication
          if (_publishError != null)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _publishError!,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _publishError = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),

          // Résultat de la publication
          if (_lastPostResult != null) ...[
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        const Text(
                          'Publication réussie',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_lastPostResult!.postId != null)
                      Text('ID: ${_lastPostResult!.postId}'),
                    if (_lastPostResult!.url != null)
                      Text('URL: ${_lastPostResult!.url}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _lastPostResult!.url ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('URL copiée')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copier URL'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => setState(() => _lastPostResult = null),
                          icon: const Icon(Icons.clear),
                          label: const Text('Effacer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _publishPost() async {
    final message = _messageController.text.trim();
    
    if (message.isEmpty) {
      setState(() => _publishError = 'Le message est obligatoire');
      return;
    }

    if (_selectedType == 'image' && _imageUrlController.text.trim().isEmpty) {
      setState(() => _publishError = 'L\'URL de l\'image est obligatoire');
      return;
    }

    if (_selectedType == 'video' && _videoUrlController.text.trim().isEmpty) {
      setState(() => _publishError = 'L\'URL de la vidéo est obligatoire');
      return;
    }

    setState(() {
      _isPublishing = true;
      _publishError = null;
      _lastPostResult = null;
    });

    try {
      final request = FacebookPostRequest(
        type: _selectedType,
        message: message,
        imageUrl: _selectedType == 'image' ? _imageUrlController.text.trim() : null,
        videoUrl: _selectedType == 'video' ? _videoUrlController.text.trim() : null,
      );

      final result = await _facebookService.publishPost(request);

      setState(() {
        _isPublishing = false;
        _lastPostResult = result;
      });

      if (result.isSuccess) {
        // Réinitialiser le formulaire
        _messageController.clear();
        _imageUrlController.clear();
        _videoUrlController.clear();
        
        // Notifier le parent
        widget.onPostPublished?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publication réussie !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _publishError = result.error ?? 'Erreur inconnue');
      }
    } catch (e) {
      setState(() {
        _isPublishing = false;
        _publishError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }
}
