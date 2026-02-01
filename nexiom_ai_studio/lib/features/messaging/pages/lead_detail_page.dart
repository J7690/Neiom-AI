import 'package:flutter/material.dart';

import '../models/lead.dart';
import '../services/messaging_service.dart';
import '../../../routes/app_routes.dart';

class LeadDetailPage extends StatefulWidget {
  final Lead lead;

  const LeadDetailPage({super.key, required this.lead});

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  final _service = MessagingService.instance();

  late String _status;
  late TextEditingController _notesController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.lead.status;
    _notesController = TextEditingController(text: widget.lead.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updated = await _service.updateLead(
        id: widget.lead.id,
        status: _status,
        notes: _notesController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop<Lead>(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de la mise à jour du lead: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _openConversation() {
    final conversationId = widget.lead.sourceConversationId;
    if (conversationId == null) {
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.messaging,
      arguments: conversationId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du lead'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lead.programInterest ?? 'Sans programme précisé',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.lead.sourceChannel} • ${widget.lead.status}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            DropdownButton<String>(
              value: _status,
              dropdownColor: const Color(0xFF020617),
              items: const [
                DropdownMenuItem(
                  value: 'new',
                  child: Text('Nouveau'),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('En cours'),
                ),
                DropdownMenuItem(
                  value: 'converted',
                  child: Text('Converti'),
                ),
                DropdownMenuItem(
                  value: 'lost',
                  child: Text('Perdu'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _status = value;
                });
              },
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF020617),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.lead.sourceConversationId != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _openConversation,
                  child: const Text('Voir la conversation'),
                ),
              ),
            if (widget.lead.sourceConversationId != null)
              const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
