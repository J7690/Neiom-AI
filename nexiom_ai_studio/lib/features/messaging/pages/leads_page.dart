import 'package:flutter/material.dart';

import '../models/lead.dart';
import '../services/messaging_service.dart';
import 'lead_detail_page.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  final _service = MessagingService.instance();

  bool _isLoading = false;
  String? _error;
  List<Lead> _leads = [];
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _service.listLeads(status: _selectedStatus);
      if (!mounted) return;
      setState(() {
        _leads = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du chargement des leads: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads multicanal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leads',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Leads collectés via WhatsApp et les autres canaux, avec leur statut et leur intérêt programme.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                DropdownButton<String?>(
                  dropdownColor: const Color(0xFF020617),
                  value: _selectedStatus,
                  hint: const Text(
                    'Filtrer par statut',
                    style: TextStyle(color: Colors.white70),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Tous les statuts'),
                    ),
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
                    setState(() {
                      _selectedStatus = value;
                    });
                    _loadLeads();
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _loadLeads,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              )
            else if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_leads.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Aucun lead pour le moment.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    itemCount: _leads.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final lead = _leads[index];
                      return ListTile(
                        onTap: () async {
                          final updated = await Navigator.of(context).push<Lead>(
                            MaterialPageRoute(
                              builder: (_) => LeadDetailPage(lead: lead),
                            ),
                          );
                          if (updated != null) {
                            setState(() {
                              _leads[index] = updated;
                            });
                          }
                        },
                        title: Text(
                          lead.programInterest ?? 'Sans programme précisé',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${lead.sourceChannel} • ${lead.status}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (lead.firstContactAt != null)
                              Text(
                                '1er contact: ${lead.firstContactAt}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            if (lead.lastContactAt != null)
                              Text(
                                'Dernier: ${lead.lastContactAt}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
