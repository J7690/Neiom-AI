import 'package:flutter/material.dart';

import '../services/social_posts_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _svc = SocialPostsService.instance();

  DateTime _startDate = DateTime.now();
  int _days = 14;
  bool _loading = false;
  List<dynamic> _calendar = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _svc.listCalendar(startDate: _startDate, days: _days);
      setState(() => _calendar = res);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelSchedule(String scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Annuler la planification'),
          content: const Text(
              'Voulez-vous vraiment annuler cette planification Facebook ? Elle ne sera plus publiée automatiquement.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Oui, annuler'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await _svc.cancelSocialSchedule(scheduleId: scheduleId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planification annulée.')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Erreur lors de l\'annulation de la planification: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier éditorial'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: _loading ? null : _pickDate,
                  icon: const Icon(Icons.date_range),
                  label: Text('${_startDate.toLocal()}'.split(' ')[0]),
                ),
                const SizedBox(width: 12),
                const Text('Jours:'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onSubmitted: (v) async {
                      final n = int.tryParse(v);
                      if (n != null && n > 0 && n <= 90) {
                        setState(() => _days = n);
                        await _load();
                      }
                    },
                    controller: TextEditingController(text: _days.toString()),
                  ),
                ),
                const Spacer(),
                IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _calendar.isEmpty
                      ? const Center(child: Text('Aucun élément planifié'))
                      : ListView.builder(
                          itemCount: _calendar.length,
                          itemBuilder: (context, index) {
                            final day = _calendar[index] as Map;
                            final dateStr = day['date']?.toString() ?? '';
                            final items = (day['items'] as List?) ?? const [];
                            return Card(
                              child: ExpansionTile(
                                title: Text(dateStr),
                                children: items.map((it) {
                                  final m = it as Map;
                                  final time = m['time']?.toString() ?? '';
                                  final status = m['status']?.toString() ?? '';
                                  final channels = ((m['channels'] as List?)?.join(', ')) ?? '';
                                  final content = m['content']?.toString() ?? '';
                                  final scheduleId = m['schedule_id']?.toString();
                                  final canCancel = status == 'scheduled' &&
                                      scheduleId != null && scheduleId.isNotEmpty;

                                  return ListTile(
                                    leading: Text(time),
                                    title: Text('[$status] $channels'),
                                    subtitle: Text(
                                      content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.cancel),
                                      tooltip: 'Annuler cette planification',
                                      onPressed: (!_loading && canCancel)
                                          ? () => _cancelSchedule(scheduleId!)
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
