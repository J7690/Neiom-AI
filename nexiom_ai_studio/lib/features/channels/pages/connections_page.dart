import 'package:flutter/material.dart';
import 'dart:convert';

import '../services/channels_service.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final _svc = ChannelsService.instance();

  final _channelType = ValueNotifier<String>('facebook');
  final List<String> _channelTypes = const ['whatsapp', 'facebook', 'instagram', 'tiktok', 'youtube'];
  final _entityCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _status = ValueNotifier<String>('active');
  final List<String> _statuses = const ['active', 'suspended', 'expired'];
  final _metadataCtrl = TextEditingController(text: '{}');

  bool _loading = false;
  List<dynamic> _channels = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.listSocialChannels();
      setState(() => _channels = items);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      Map<String, dynamic> meta = {};
      try { meta = _parseJson(_metadataCtrl.text); } catch (_) {}
      await _svc.upsertSocialChannel(
        channelType: _channelType.value,
        entity: _entityCtrl.text.trim().isEmpty ? null : _entityCtrl.text.trim(),
        displayName: _displayNameCtrl.text.trim().isEmpty ? null : _displayNameCtrl.text.trim(),
        status: _status.value,
        providerMetadata: meta,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connexion enregistrée')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _parseJson(String s) {
    try {
      final obj = jsonDecode(s);
      if (obj is Map<String, dynamic>) return obj;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexions (Meta/IG/WhatsApp)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    const Text('Nouvelle connexion / MAJ'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _channelType.value,
                          items: _channelTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) { if (v != null) setState(() => _channelType.value = v); },
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _entityCtrl, decoration: const InputDecoration(labelText: 'Entity (ex: Page ID, Phone ID)'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _displayNameCtrl, decoration: const InputDecoration(labelText: 'Nom affiché'))),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _status.value,
                          items: _statuses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) { if (v != null) setState(() => _status.value = v); },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _metadataCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Provider metadata (JSON)'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Connexions existantes'),
            const SizedBox(height: 8),
            _loading && _channels.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                : Column(
                    children: _channels.map((e) {
                      final m = (e as Map);
                      final ch = (m['channel_type'] ?? '').toString();
                      final entity = (m['entity'] ?? '').toString();
                      final dn = (m['display_name'] ?? '').toString();
                      final status = (m['status'] ?? '').toString();
                      final meta = m['provider_metadata']?.toString() ?? '{}';
                      return Card(
                        child: ListTile(
                          leading: Icon(_iconFor(ch)),
                          title: Text('$ch — $dn'),
                          subtitle: Text('entity: $entity\nstatus: $status\nmeta: $meta'),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String ch) {
    switch (ch) {
      case 'whatsapp':
        return Icons.chat_bubble_outline;
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'tiktok':
        return Icons.music_note;
      case 'youtube':
        return Icons.ondemand_video;
      default:
        return Icons.link;
    }
  }

  @override
  void dispose() {
    _entityCtrl.dispose();
    _displayNameCtrl.dispose();
    _metadataCtrl.dispose();
    super.dispose();
  }
}
