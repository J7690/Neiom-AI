import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';
import '../../knowledge/services/knowledge_service.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final _service = MessagingService.instance();

  String? _initialConversationId;
  bool _initializedFromRoute = false;

  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  String? _error;
  bool _onlyEscalated = false;

  List<Conversation> _conversations = [];
  Conversation? _selectedConversation;
  List<Message> _messages = [];
  final _replyController = TextEditingController();
  bool _sending = false;
  bool _busyEscalate = false;
  bool _busyCreateLead = false;
  bool _busyAiReply = false;
  bool _busyAddKnowledge = false;
  String _sortKey = 'last_desc';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromRoute) {
      _initializedFromRoute = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _initialConversationId = args;
      }
      _loadConversations();
    }
  }

  Future<void> _toggleEscalation() async {
    final conv = _selectedConversation;
    if (conv == null) return;
    final current = (conv.metadata != null && (conv.metadata!['needs_escalation'] == true));
    setState(() => _busyEscalate = true);
    try {
      await _service.setConversationEscalation(conversationId: conv.id, value: !current);
      if (!mounted) return;
      setState(() {
        final md = Map<String, dynamic>.from(conv.metadata ?? {});
        md['needs_escalation'] = !current;
        final updated = Conversation(
          id: conv.id,
          contactId: conv.contactId,
          channel: conv.channel,
          status: conv.status,
          subject: conv.subject,
          lastMessageAt: conv.lastMessageAt,
          assignedTo: conv.assignedTo,
          metadata: md,
        );
        _selectedConversation = updated;
        // also reflect in list
        _conversations = _conversations.map((c) => c.id == updated.id ? updated : c).toList();
      });
    } catch (e) {
      setState(() => _error = 'Escalade échouée: $e');
    } finally {
      if (mounted) setState(() => _busyEscalate = false);
    }
  }

  Future<void> _createLead() async {
    final conv = _selectedConversation;
    if (conv == null) return;
    setState(() => _busyCreateLead = true);
    try {
      final id = await _service.createLeadFromConversation(conversationId: conv.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lead créé: $id')));
    } catch (e) {
      setState(() => _error = 'Création lead échouée: $e');
    } finally {
      if (mounted) setState(() => _busyCreateLead = false);
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoadingConversations = true;
      _error = null;
    });

    try {
      final list = await _service.listConversations();
      if (!mounted) return;
      Conversation? initial;
      if (list.isNotEmpty) {
        if (_initialConversationId != null) {
          try {
            initial = list.firstWhere(
              (c) => c.id == _initialConversationId,
            );
          } catch (_) {
            initial = list.first;
          }
        } else {
          initial = list.first;
        }
      }
      setState(() {
        _conversations = list;
        _selectedConversation = initial;
      });
      if (_selectedConversation != null) {
        await _loadMessages(_selectedConversation!.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du chargement des conversations: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingConversations = false;
      });
    }
  }

  Future<void> _loadMessages(String conversationId) async {
    setState(() {
      _isLoadingMessages = true;
      _error = null;
    });

    try {
      final list = await _service.listMessagesForConversation(conversationId);
      if (!mounted) return;
      setState(() {
        _messages = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du chargement des messages: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  void _onSelectConversation(Conversation conv) {
    setState(() {
      _selectedConversation = conv;
      _messages = [];
    });
    _loadMessages(conv.id);
  }

  Future<void> _sendStubReply() async {
    if (_selectedConversation == null) return;
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.respondWithStub(conversationId: _selectedConversation!.id, text: text);
      _replyController.clear();
      await _loadMessages(_selectedConversation!.id);
    } catch (e) {
      setState(() => _error = 'Envoi échoué: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _autoReplyLastInbound() async {
    if (_selectedConversation == null || _messages.isEmpty) return;
    final lastInbound = _messages.lastWhere(
      (m) => m.direction == 'inbound',
      orElse: () => _messages.last,
    );
    setState(() => _sending = true);
    try {
      await _service.autoReplyForMessage(lastInbound.id);
      await _loadMessages(_selectedConversation!.id);
    } catch (e) {
      setState(() => _error = 'Auto-réponse échouée: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _runAiReplyForLastInbound() async {
    if (_selectedConversation == null || _messages.isEmpty) return;
    final lastInbound = _messages.lastWhere(
      (m) => m.direction == 'inbound',
      orElse: () => _messages.last,
    );

    setState(() {
      _busyAiReply = true;
      _error = null;
    });

    try {
      await _service.runAiReplyForMessage(lastInbound.id);
      if (_selectedConversation != null) {
        await _loadMessages(_selectedConversation!.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Réponse IA échouée: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busyAiReply = false;
        });
      }
    }
  }

  Future<void> _addMessageToKnowledge(Message msg) async {
    final text = msg.contentText?.trim() ?? '';
    if (text.isEmpty) return;

    setState(() => _busyAddKnowledge = true);
    try {
      await KnowledgeService.instance().ingestDocument(
        source: 'inbox_message',
        title: 'Message ${msg.channel} ${msg.id.substring(0, 8)}',
        locale: 'fr_BF',
        content: text,
        metadata: {
          'message_id': msg.id,
          'conversation_id': msg.conversationId,
          'channel': msg.channel,
          'direction': msg.direction,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message ajouté à la base de connaissances')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ajout knowledge: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busyAddKnowledge = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations multicanal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversations',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Liste des conversations issues de WhatsApp et des autres canaux. Sélectionnez une conversation pour voir les messages.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Switch(
                  value: _onlyEscalated,
                  onChanged: (v) => setState(() => _onlyEscalated = v),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Afficher uniquement les conversations à escalader',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                const Text('Tri:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: _sortKey,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'last_desc', child: Text('Récents')),
                    DropdownMenuItem(value: 'last_asc', child: Text('Anciens')),
                    DropdownMenuItem(value: 'status', child: Text('Statut')),
                    DropdownMenuItem(value: 'channel', child: Text('Canal')),
                  ],
                  onChanged: (v) { if (v!=null) setState(() => _sortKey = v); },
                ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              )
            else if (_isLoadingConversations)
              const Center(child: CircularProgressIndicator())
            else if (_conversations.isEmpty)
              const Text(
                'Aucune conversation pour le moment.',
                style: TextStyle(color: Colors.white70),
              )
            else
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView.separated(
                          itemCount: (_onlyEscalated
                                  ? _conversations.where((c) => (c.metadata != null && (c.metadata!['needs_escalation'] == true))).toList()
                                  : _conversations)
                              .length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final source = _onlyEscalated
                                ? _conversations
                                    .where((c) => (c.metadata != null && (c.metadata!['needs_escalation'] == true)))
                                    .toList()
                                : List<Conversation>.from(_conversations);
                            // apply sorting
                            source.sort((a,b){
                              int cmp;
                              switch(_sortKey){
                                case 'last_asc':
                                  final da = a.lastMessageAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                                  final db = b.lastMessageAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                                  cmp = da.compareTo(db);
                                  break;
                                case 'status':
                                  cmp = (a.status).compareTo(b.status);
                                  break;
                                case 'channel':
                                  cmp = (a.channel).compareTo(b.channel);
                                  break;
                                case 'last_desc':
                                default:
                                  final da2 = a.lastMessageAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                                  final db2 = b.lastMessageAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                                  cmp = db2.compareTo(da2);
                              }
                              return cmp;
                            });
                            final conv = source[index];
                            final isSelected = conv.id == _selectedConversation?.id;
                            return Material(
                              color: isSelected
                                  ? Colors.blueGrey.withOpacity(0.4)
                                  : Colors.transparent,
                              child: ListTile(
                                onTap: () => _onSelectConversation(conv),
                                title: Text(
                                  conv.channel,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  conv.status,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: (conv.metadata != null && (conv.metadata!['needs_escalation'] == true))
                                    ? const Icon(
                                        Icons.flag,
                                        color: Colors.orangeAccent,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF020617),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isLoadingMessages
                            ? const Center(child: CircularProgressIndicator())
                            : _selectedConversation == null
                                ? const Center(
                                    child: Text(
                                      'Sélectionnez une conversation pour voir les messages.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                : _messages.isEmpty
                                    ? Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(children: [
                                              Chip(label: Text(_selectedConversation!.channel)),
                                              const SizedBox(width: 8),
                                              Text('statut: ${_selectedConversation!.status}', style: const TextStyle(color: Colors.white70)),
                                              if ((_selectedConversation!.metadata != null && (_selectedConversation!.metadata!['needs_escalation'] == true))) ...[
                                                const SizedBox(width: 8),
                                                const Icon(Icons.flag, color: Colors.orangeAccent),
                                              ],
                                              if (((_selectedConversation!.subject ?? '').isNotEmpty)) ...[
                                                const SizedBox(width: 12),
                                                Expanded(child: Text(_selectedConversation!.subject!, overflow: TextOverflow.ellipsis)),
                                              ],
                                            ]),
                                          ),
                                          const Expanded(
                                            child: Center(
                                              child: Text(
                                                'Aucun message dans cette conversation.',
                                                style: TextStyle(color: Colors.white70),
                                              ),
                                            ),
                                          ),
                                          const Divider(height: 1),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _replyController,
                                                    style: const TextStyle(color: Colors.white),
                                                    decoration: const InputDecoration(
                                                      hintText: 'Écrire un message (stub)...',
                                                      hintStyle: TextStyle(color: Colors.white54),
                                                      border: OutlineInputBorder(),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: _sending ? null : _sendStubReply,
                                                  child: _sending ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Envoyer (stub)'),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: (_busyEscalate || _selectedConversation == null) ? null : _toggleEscalation,
                                                  child: _busyEscalate
                                                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                                      : Text(((
                                                                _selectedConversation?.metadata != null &&
                                                                (_selectedConversation!.metadata!['needs_escalation'] == true))
                                                            ? 'Désescalader'
                                                            : 'Escalader')),
                                                ),
                                                const SizedBox(width: 8),
                                                FilledButton(
                                                  onPressed: (_busyCreateLead || _selectedConversation == null) ? null : _createLead,
                                                  child: _busyCreateLead
                                                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                                      : const Text('Créer lead'),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(children: [
                                              Chip(label: Text(_selectedConversation!.channel)),
                                              const SizedBox(width: 8),
                                              Text('statut: ${_selectedConversation!.status}', style: const TextStyle(color: Colors.white70)),
                                              if ((_selectedConversation!.metadata != null && (_selectedConversation!.metadata!['needs_escalation'] == true))) ...[
                                                const SizedBox(width: 8),
                                                const Icon(Icons.flag, color: Colors.orangeAccent),
                                              ],
                                              if (((_selectedConversation!.subject ?? '').isNotEmpty)) ...[
                                                const SizedBox(width: 12),
                                                Expanded(child: Text(_selectedConversation!.subject!, overflow: TextOverflow.ellipsis)),
                                              ],
                                            ]),
                                          ),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: _messages.length,
                                              itemBuilder: (context, index) {
                                                final msg = _messages[index];
                                                final isInbound = msg.direction == 'inbound';
                                                final isAiAnswer = msg.answeredByAi;
                                                final needsHuman = msg.needsHuman;
                                                final aiSkipped = msg.aiSkipped;
                                                final hasKnowledge = (msg.knowledgeHitIds ?? []).isNotEmpty;

                                                return Align(
                                                  alignment: isInbound ? Alignment.centerLeft : Alignment.centerRight,
                                                  child: Container(
                                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: () {
                                                        if (needsHuman || aiSkipped) {
                                                          return const Color(0xFF7F1D1D); // rouge sombre pour besoin humain / skip IA
                                                        }
                                                        if (isAiAnswer && !isInbound) {
                                                          return const Color(0xFF064E3B); // vert sombre pour réponse IA
                                                        }
                                                        return isInbound
                                                            ? const Color(0xFF1E293B)
                                                            : const Color(0xFF0F172A);
                                                      }(),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        if (isAiAnswer || needsHuman || aiSkipped || hasKnowledge)
                                                          Padding(
                                                            padding: const EdgeInsets.only(bottom: 4),
                                                            child: Wrap(
                                                              spacing: 4,
                                                              runSpacing: 2,
                                                              children: [
                                                                if (isAiAnswer)
                                                                  const Chip(
                                                                    label: Text(
                                                                      'Réponse IA',
                                                                      style: TextStyle(fontSize: 10),
                                                                    ),
                                                                    visualDensity: VisualDensity.compact,
                                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  ),
                                                                if (needsHuman)
                                                                  const Chip(
                                                                    label: Text(
                                                                      'À traiter humain',
                                                                      style: TextStyle(fontSize: 10),
                                                                    ),
                                                                    backgroundColor: Colors.orangeAccent,
                                                                    visualDensity: VisualDensity.compact,
                                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  ),
                                                                if (aiSkipped)
                                                                  const Chip(
                                                                    label: Text(
                                                                      'IA en silence',
                                                                      style: TextStyle(fontSize: 10),
                                                                    ),
                                                                    backgroundColor: Colors.redAccent,
                                                                    visualDensity: VisualDensity.compact,
                                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  ),
                                                                if (hasKnowledge)
                                                                  Chip(
                                                                    label: Text(
                                                                      'Knowledge x${msg.knowledgeHitIds!.length}',
                                                                      style: const TextStyle(fontSize: 10),
                                                                    ),
                                                                    visualDensity: VisualDensity.compact,
                                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        Text(
                                                          msg.contentText ?? (msg.mediaUrl ?? ''),
                                                          style: const TextStyle(color: Colors.white),
                                                        ),
                                                        if (isInbound && needsHuman)
                                                          Align(
                                                            alignment: Alignment.centerRight,
                                                            child: TextButton.icon(
                                                              onPressed: _busyAddKnowledge
                                                                  ? null
                                                                  : () => _addMessageToKnowledge(msg),
                                                              icon: const Icon(Icons.library_add, size: 14),
                                                              label: const Text(
                                                                'Ajouter à la knowledge',
                                                                style: TextStyle(fontSize: 11),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const Divider(height: 1),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _replyController,
                                                    style: const TextStyle(color: Colors.white),
                                                    decoration: const InputDecoration(
                                                      hintText: 'Écrire un message (stub)...',
                                                      hintStyle: TextStyle(color: Colors.white54),
                                                      border: OutlineInputBorder(),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: _sending ? null : _sendStubReply,
                                                  child: _sending
                                                      ? const SizedBox(
                                                          height: 16,
                                                          width: 16,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        )
                                                      : const Text('Envoyer (stub)'),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: (_sending || _messages.isEmpty) ? null : _autoReplyLastInbound,
                                                  child: const Text('Réponse auto (stub)'),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: (_busyAiReply || _messages.isEmpty) ? null : _runAiReplyForLastInbound,
                                                  child: _busyAiReply
                                                      ? const SizedBox(
                                                          height: 16,
                                                          width: 16,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        )
                                                      : const Text('Réponse IA (règle d\'or)'),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: (_busyEscalate || _selectedConversation == null) ? null : _toggleEscalation,
                                                  child: _busyEscalate
                                                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                                      : Text(((
                                                                _selectedConversation?.metadata != null &&
                                                                (_selectedConversation!.metadata!['needs_escalation'] == true))
                                                            ? 'Désescalader'
                                                            : 'Escalader')),
                                                ),
                                                const SizedBox(width: 8),
                                                FilledButton(
                                                  onPressed: (_busyCreateLead || _selectedConversation == null) ? null : _createLead,
                                                  child: _busyCreateLead
                                                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                                      : const Text('Créer lead'),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
