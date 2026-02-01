import 'package:flutter/material.dart';

import '../services/facebook_service.dart';

class FacebookCommentsSection extends StatefulWidget {
  const FacebookCommentsSection({super.key});

  @override
  State<FacebookCommentsSection> createState() => _FacebookCommentsSectionState();
}

class _FacebookCommentsSectionState extends State<FacebookCommentsSection> {
  final FacebookService _facebookService = FacebookService.instance();

  bool _loadingPosts = false;
  bool _loadingComments = false;
  bool _processingBatch = false;
  bool _loadingQueue = false;

  List<FacebookPost> _posts = const [];
  FacebookPost? _selectedPost;
  List<FacebookComment> _comments = const [];

  String _postSearch = '';
  String _commentSearch = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loadingPosts = true;
      _error = null;
    });
    try {
      final posts = await _facebookService.listPosts(limit: 100);
      setState(() {
        _posts = posts;
        // Conserver le post sélectionné si encore présent
        if (_selectedPost != null) {
          _selectedPost = posts.firstWhere(
            (p) => p.id == _selectedPost!.id,
            orElse: () => _selectedPost!,
          );
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loadingPosts = false;
      });
    }
  }

  Future<void> _selectPost(FacebookPost post) async {
    setState(() {
      _selectedPost = post;
      _comments = const [];
    });
    await _loadCommentsForSelected();
  }

  Future<void> _loadCommentsForSelected() async {
    final post = _selectedPost;
    if (post == null) return;

    final postId = (post.facebookPostId != null && post.facebookPostId!.isNotEmpty)
        ? post.facebookPostId!
        : post.id;

    setState(() {
      _loadingComments = true;
      _error = null;
    });
    try {
      final comments = await _facebookService.getPostComments(postId, limit: 100);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loadingComments = false;
      });
    }
  }

  Future<void> _openReplyDialog(FacebookComment comment) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Répondre au commentaire'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tapez votre réponse…',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final ok = await _facebookService.replyToComment(comment.id, text);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Réponse envoyée' : 'Échec de l\'envoi de la réponse'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    if (ok) {
      await _loadCommentsForSelected();
    }
  }

  Future<void> _runBatchProcessing({required bool autoReply}) async {
    final post = _selectedPost;
    if (post == null) return;

    final postId = (post.facebookPostId != null && post.facebookPostId!.isNotEmpty)
        ? post.facebookPostId!
        : post.id;

    setState(() {
      _processingBatch = true;
      _error = null;
    });
    try {
      final stats = await _facebookService.processCommentsBatch(
        postId,
        autoReplyEnabled: autoReply,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            autoReply
                ? 'Traitement terminé: ${stats['processed']} commentaires, ${stats['autoReplied']} auto-réponses'
                : 'Analyse terminée: ${stats['processed']} commentaires, ${stats['errors']} erreurs',
          ),
        ),
      );
      await _loadCommentsForSelected();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur traitement commentaires: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingBatch = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPosts && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher une publication…',
                  ),
                  onChanged: (v) => setState(() => _postSearch = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Rafraîchir',
                onPressed: _loadingPosts ? null : _loadPosts,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'File d\'attente modération',
                onPressed: _loadingQueue ? null : _openModerationQueue,
                icon: const Icon(Icons.list_alt),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildPostsList(theme),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: _buildCommentsPanel(theme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openModerationQueue() async {
    setState(() {
      _loadingQueue = true;
    });

    final parentContext = context;
    List<Map<String, dynamic>> pending = const [];
    try {
      pending = await _facebookService.listPendingComments(limit: 100);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement file de modération: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingQueue = false;
        });
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: Text('File d\'attente modération (${pending.length})'),
              content: SizedBox(
                width: 500,
                height: 400,
                child: pending.isEmpty
                    ? const Center(
                        child: Text('Aucun commentaire en attente de modération.'),
                      )
                    : ListView.separated(
                        itemCount: pending.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final row = pending[index];
                          final id = row['id']?.toString();
                          final msg = row['message']?.toString() ?? '';
                          final fromName = row['from_name']?.toString() ?? '';
                          final created = row['created_time']?.toString() ?? '';

                          Future<void> handleAction(String status, String actionType) async {
                            if (id == null) return;
                            final ok = await _facebookService.markCommentModeration(
                              commentId: id,
                              status: status,
                              actionType: actionType,
                              actor: 'studio_user',
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Commentaire marqué comme $status'
                                      : 'Échec de la mise à jour du statut',
                                ),
                                backgroundColor: ok ? Colors.green : Colors.red,
                              ),
                            );
                            if (ok) {
                              setModalState(() {
                                pending.removeAt(index);
                              });
                            }
                          }

                          return ListTile(
                            title: Text(
                              msg,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [fromName, created]
                                  .where((e) => e.isNotEmpty)
                                  .join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Marquer comme traité',
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => handleAction('handled', 'handled'),
                                ),
                                IconButton(
                                  tooltip: 'Ignorer',
                                  icon: const Icon(Icons.visibility_off, color: Colors.grey),
                                  onPressed: () => handleAction('ignored', 'ignored'),
                                ),
                                IconButton(
                                  tooltip: 'Escalader',
                                  icon: const Icon(Icons.flag, color: Colors.orange),
                                  onPressed: () => handleAction('escalated', 'escalated'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPostsList(ThemeData theme) {
    final filtered = _posts.where((p) {
      if (p.facebookPostId == null || p.facebookPostId!.isEmpty) {
        // On privilégie les posts effectivement publiés sur Facebook
        return false;
      }
      if (_postSearch.isEmpty) return true;
      final q = _postSearch.toLowerCase();
      return p.message.toLowerCase().contains(q) || (p.type.toLowerCase().contains(q));
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('Aucune publication Facebook avec commentaires disponibles.'),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = filtered[index];
        final selected = _selectedPost?.id == post.id;
        return ListTile(
          selected: selected,
          leading: Icon(
            post.type == 'image'
                ? Icons.image
                : post.type == 'video'
                    ? Icons.videocam
                    : Icons.text_snippet,
          ),
          title: Text(
            post.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${post.status ?? 'inconnu'} • ${post.facebookPostId ?? post.id}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _selectPost(post),
        );
      },
    );
  }

  Widget _buildCommentsPanel(ThemeData theme) {
    if (_selectedPost == null) {
      return const Center(
        child: Text('Sélectionnez une publication pour voir ses commentaires.'),
      );
    }

    final filteredComments = _comments.where((c) {
      if (_commentSearch.isEmpty) return true;
      final q = _commentSearch.toLowerCase();
      return c.message.toLowerCase().contains(q) || c.fromName.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commentaires pour la publication',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _selectedPost!.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Filtrer les commentaires…',
                      ),
                      onChanged: (v) => setState(() => _commentSearch = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_loadingComments) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Recharger les commentaires',
                    onPressed: _loadingComments ? null : _loadCommentsForSelected,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _processingBatch ? null : () => _runBatchProcessing(autoReply: false),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analyser les commentaires'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _processingBatch ? null : () => _runBatchProcessing(autoReply: true),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Auto-réponse IA'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredComments.isEmpty
              ? const Center(child: Text('Aucun commentaire pour cette publication.'))
              : ListView.separated(
                  itemCount: filteredComments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = filteredComments[index];
                    return ListTile(
                      title: Text(c.message),
                      subtitle: Text(
                        '${c.fromName} • ${c.createdTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.likeCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.thumb_up_alt_outlined, size: 16),
                                  const SizedBox(width: 2),
                                  Text(c.likeCount.toString()),
                                ],
                              ),
                            ),
                          IconButton(
                            tooltip: 'Répondre',
                            icon: const Icon(Icons.reply),
                            onPressed: c.canReply ? () => _openReplyDialog(c) : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
