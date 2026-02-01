import 'package:flutter/material.dart';

import '../services/ads_service.dart';

class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> {
  final _svc = AdsService.instance();
  final _status = ValueNotifier<String?>('draft');
  final List<String?> _statuses = const [null, 'draft', 'active', 'paused', 'completed'];
  final _searchCtrl = TextEditingController();
  final _sort = ValueNotifier<String>('created_at_desc');
  int _page = 0;
  static const _pageSize = 20;

  bool _loading = true;
  List<dynamic> _items = const [];
  final Map<String, bool> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.listAdCampaigns(
        status: _status.value,
        limit: _pageSize,
        offset: _page * _pageSize,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _sort.value,
      );
      setState(() => _items = items);
    } finally { setState(() => _loading = false); }
  }

  Future<void> _updateStatus(String id, String status) async {
    setState(() => _busy[id] = true);
    try {
      final ok = await _svc.updateAdCampaignStatus(id: id, status: status);
      if (ok) await _load();
    } finally { setState(() => _busy[id] = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campagnes Ads'),
        actions: [
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(hintText: 'Recherche', isDense: true),
              onSubmitted: (_) { _page = 0; _load(); },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String?>(
            value: _status.value,
            underline: const SizedBox.shrink(),
            items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s ?? 'Toutes'))).toList(),
            onChanged: (v) { setState(() { _status.value = v; }); _load(); },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sort.value,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'created_at_desc', child: Text('Date desc')),
              DropdownMenuItem(value: 'created_at_asc', child: Text('Date asc')),
              DropdownMenuItem(value: 'name_asc', child: Text('Nom A→Z')),
              DropdownMenuItem(value: 'name_desc', child: Text('Nom Z→A')),
              DropdownMenuItem(value: 'status_asc', child: Text('Statut')),
            ],
            onChanged: (v) { if (v!=null) setState(() { _sort.value = v; _page = 0; }); _load(); },
          ),
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final m = (_items[i] as Map).cast<String, dynamic>();
                      final id = (m['id'] ?? '').toString();
                      final name = (m['name'] ?? '').toString();
                      final obj = (m['objective'] ?? '').toString();
                      final st = (m['status'] ?? '').toString();
                      final db = (m['daily_budget']?.toString() ?? '');
                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('objectif: $obj • statut: $st • budget: $db'),
                          trailing: Wrap(spacing: 6, children: [
                            _actionBtn(id, 'draft', st),
                            _actionBtn(id, 'active', st),
                            _actionBtn(id, 'paused', st),
                            _actionBtn(id, 'completed', st),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _page>0 && !_loading ? () { setState(() { _page -= 1; }); _load(); } : null,
                      child: const Text('Précédent'),
                    ),
                    const SizedBox(width: 8),
                    Text('Page ${_page+1}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _items.length==_pageSize && !_loading ? () { setState(() { _page += 1; }); _load(); } : null,
                      child: const Text('Suivant'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _actionBtn(String id, String target, String current) {
    final busy = _busy[id] == true;
    final enabled = target != current && !busy;
    return ElevatedButton(
      onPressed: enabled ? () => _updateStatus(id, target) : null,
      child: busy ? const SizedBox(height:16,width:16,child: CircularProgressIndicator(strokeWidth:2)) : Text(target),
    );
  }
}
