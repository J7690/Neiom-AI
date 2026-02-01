import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _svc = SettingsService.instance();

  bool _loading = true;
  Map<String, dynamic> _overview = const {};

  final _openrouterCtrl = TextEditingController();
  final _metaSecretCtrl = TextEditingController();
  final _waVerifyCtrl = TextEditingController();
  final _waPhoneIdCtrl = TextEditingController();
  final _waAccessCtrl = TextEditingController();
  final _waApiBaseCtrl = TextEditingController(text: 'https://graph.facebook.com');
  final _chatModelCtrl = TextEditingController(text: 'openrouter/anthropic/claude-3.5-sonnet');

  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final ov = await _svc.overview();
      final keys = [
        'OPENROUTER_API_KEY', 'META_APP_SECRET', 'WHATSAPP_VERIFY_TOKEN',
        'WHATSAPP_PHONE_NUMBER_ID', 'WHATSAPP_ACCESS_TOKEN', 'WHATSAPP_API_BASE_URL',
        'NEXIOM_DEFAULT_CHAT_MODEL',
      ];
      final values = <String, String?>{};
      for (final k in keys) {
        final v = await _svc.getSetting(k);
        values[k] = v;
      }
      setState(() {
        _overview = ov;
        _openrouterCtrl.text = values['OPENROUTER_API_KEY'] ?? _openrouterCtrl.text;
        _metaSecretCtrl.text = values['META_APP_SECRET'] ?? _metaSecretCtrl.text;
        _waVerifyCtrl.text = values['WHATSAPP_VERIFY_TOKEN'] ?? _waVerifyCtrl.text;
        _waPhoneIdCtrl.text = values['WHATSAPP_PHONE_NUMBER_ID'] ?? _waPhoneIdCtrl.text;
        _waAccessCtrl.text = values['WHATSAPP_ACCESS_TOKEN'] ?? _waAccessCtrl.text;
        _waApiBaseCtrl.text = values['WHATSAPP_API_BASE_URL'] ?? _waApiBaseCtrl.text;
        _chatModelCtrl.text = values['NEXIOM_DEFAULT_CHAT_MODEL'] ?? _chatModelCtrl.text;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAll() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modification des secrets désactivée dans cet environnement sécurisé.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages & Secrets (staging)'),
        actions: [
          IconButton(onPressed: _loading ? null : _loadAll, icon: const Icon(Icons.refresh)),
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
                    const Text('Aperçu des réglages'),
                    const SizedBox(height: 8),
                    Wrap(spacing: 16, runSpacing: 8, children: _overview.entries.map((e) {
                      final ok = e.value == true;
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(ok ? Icons.check_circle : Icons.error, color: ok ? Colors.green : Colors.orange),
                        const SizedBox(width: 6),
                        Text(e.key),
                      ]);
                    }).toList()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Secrets & paramètres'),
                    Row(children: [
                      ElevatedButton(onPressed: _loading ? null : _saveAll, child: const Text('Enregistrer')),
                      const SizedBox(width: 12),
                      TextButton(onPressed: () => setState(() => _obscure = !_obscure), child: Text(_obscure ? 'Afficher' : 'Masquer')),
                    ]),
                    const SizedBox(height: 8),
                    TextField(controller: _openrouterCtrl, obscureText: _obscure, decoration: const InputDecoration(labelText: 'OPENROUTER_API_KEY')),
                    const SizedBox(height: 8),
                    TextField(controller: _metaSecretCtrl, obscureText: _obscure, decoration: const InputDecoration(labelText: 'META_APP_SECRET')),
                    const SizedBox(height: 8),
                    TextField(controller: _waVerifyCtrl, obscureText: _obscure, decoration: const InputDecoration(labelText: 'WHATSAPP_VERIFY_TOKEN')),
                    const SizedBox(height: 8),
                    TextField(controller: _waPhoneIdCtrl, decoration: const InputDecoration(labelText: 'WHATSAPP_PHONE_NUMBER_ID')),
                    const SizedBox(height: 8),
                    TextField(controller: _waAccessCtrl, obscureText: _obscure, decoration: const InputDecoration(labelText: 'WHATSAPP_ACCESS_TOKEN')),
                    const SizedBox(height: 8),
                    TextField(controller: _waApiBaseCtrl, decoration: const InputDecoration(labelText: 'WHATSAPP_API_BASE_URL')),
                    const SizedBox(height: 8),
                    TextField(controller: _chatModelCtrl, decoration: const InputDecoration(labelText: 'NEXIOM_DEFAULT_CHAT_MODEL')),
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
    _openrouterCtrl.dispose();
    _metaSecretCtrl.dispose();
    _waVerifyCtrl.dispose();
    _waPhoneIdCtrl.dispose();
    _waAccessCtrl.dispose();
    _waApiBaseCtrl.dispose();
    _chatModelCtrl.dispose();
    super.dispose();
  }
}
