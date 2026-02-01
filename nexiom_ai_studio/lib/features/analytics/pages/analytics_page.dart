import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../services/analytics_service.dart';
import '../../messaging/services/messaging_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _svc = AnalyticsService.instance();
  final _msg = MessagingService.instance();

  bool _loadingW = false;
  bool _loadingM = false;
  bool _loadingTS = false;
  Map<String, dynamic>? _weekly;
  Map<String, dynamic>? _monthly;
  List<dynamic> _series = const [];
  bool _loadingIa = false;
  List<dynamic> _ai2h = const [];
  List<dynamic> _aiDaily = const [];
  List<dynamic> _aiWeekly = const [];
  List<dynamic> _jobsWithoutGen = const [];
  List<dynamic> _jobsApprovedUnscheduled = const [];
  List<dynamic> _messagesNeedsHuman = const [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadWeekly();
    _loadMonthly();
    _loadTimeseries();
    _loadIaSupervision();
  }

  Future<void> _exportPdf({required bool monthly}) async {
    final data = monthly ? _monthly : _weekly;
    if (data == null) return;
    final doc = pw.Document();

    Map<String, dynamic> summary = (data['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final topPosts = (data['top_posts'] as List?) ?? const [];
    final best = monthly ? ((data['best_days'] as List?) ?? const []) : ((data['best_hours'] as List?) ?? const []);

    doc.addPage(
      pw.Page(
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rapport ${monthly ? 'Mensuel' : 'Hebdo'}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Période: ${(data['period'] ?? {}).toString()}'),
              pw.SizedBox(height: 12),
              pw.Text('KPIs', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Messages IN: ${summary['messages_in'] ?? 0}'),
              pw.Bullet(text: 'Messages OUT: ${summary['messages_out'] ?? 0}'),
              pw.Bullet(text: 'Posts: ${summary['posts_created'] ?? 0}'),
              pw.Bullet(text: 'Leads: ${summary['leads'] ?? 0}'),
              pw.SizedBox(height: 12),
              pw.Text('Top posts', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ...topPosts.take(10).map<pw.Widget>((e) {
                final m = (e as Map).cast<String, dynamic>();
                return pw.Bullet(text: '${(m['score'] ?? '0')} — ${(m['content'] ?? '').toString()}');
              }).toList(),
              pw.SizedBox(height: 12),
              pw.Text(monthly ? 'Meilleurs jours' : 'Meilleures heures', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ...best.take(24).map<pw.Widget>((e) {
                final m = (e as Map).cast<String, dynamic>();
                final label = monthly ? (m['date']?.toString() ?? '') : 'Heure ${m['hour'] ?? ''}';
                return pw.Bullet(text: '$label — ${m['count'] ?? 0}');
              }).toList(),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Nexiom AI Studio', style: pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => await doc.save());
  }

  Future<void> _loadWeekly() async {
    setState(() => _loadingW = true);
    try {
      final res = await _svc.getReportWeekly();
      setState(() => _weekly = res);
    } finally { setState(() => _loadingW = false); }
  }

  Future<void> _loadMonthly() async {
    setState(() => _loadingM = true);
    try {
      final res = await _svc.getReportMonthly();
      setState(() => _monthly = res);
    } finally { setState(() => _loadingM = false); }
  }

  Future<void> _loadTimeseries({int days = 7}) async {
    setState(() => _loadingTS = true);
    try {
      final res = await _msg.getMetricsTimeseries(days: days);
      setState(() => _series = res);
    } finally { setState(() => _loadingTS = false); }
  }

  Future<void> _loadIaSupervision() async {
    setState(() => _loadingIa = true);
    try {
      final since2h = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final a2h = await _svc.getAiActivity2h(since: since2h);
      final aDaily = await _svc.getAiActivityDaily(days: 7);
      final aWeekly = await _svc.getAiActivityWeekly(weeks: 4);
      final jobsNoGen = await _svc.getContentJobsWithoutGenerationJob();
      final jobsApprovedUnsched = await _svc.getContentJobsApprovedUnscheduled();
      final msgsNeedsHuman = await _svc.getMessagesNeedsHumanOlderThan(24);

      setState(() {
        _ai2h = a2h;
        _aiDaily = aDaily;
        _aiWeekly = aWeekly;
        _jobsWithoutGen = jobsNoGen;
        _jobsApprovedUnscheduled = jobsApprovedUnsched;
        _messagesNeedsHuman = msgsNeedsHuman;
      });
    } finally {
      setState(() => _loadingIa = false);
    }
  }

  Future<void> _aggregateIaActivity() async {
    try {
      await _svc.aggregateAiActivity(bucketType: '2h');
      await _svc.aggregateAiActivity(bucketType: 'daily');
      await _svc.aggregateAiActivity(bucketType: 'weekly');
      await _loadIaSupervision();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur agrégation IA: $err'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _summaryView(Map<String, dynamic> m) {
    final s = (m['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _kpi('Msgs IN', s['messages_in']?.toString() ?? '-'),
        _kpi('Msgs OUT', s['messages_out']?.toString() ?? '-'),
        _kpi('Posts', s['posts_created']?.toString() ?? '-'),
        _kpi('Leads', s['leads']?.toString() ?? '-'),
      ],
    );
  }

  Widget _kpi(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _topPosts(List<dynamic> items) {
    if (items.isEmpty) return const Text('Aucun post');
    return Column(
      children: items.map((e) {
        final m = (e as Map).cast<String, dynamic>();
        return Card(
          child: ListTile(
            title: Text(m['content']?.toString() ?? ''),
            subtitle: Text('Score: ${m['score']?.toString() ?? '0'} | Channels: ${(m['channels'] as List?)?.join(', ') ?? ''}'),
            trailing: IconButton(
              icon: const Icon(Icons.insights_outlined),
              tooltip: 'Expliquer la performance',
              onPressed: () async {
                final postId = m['post_id']?.toString();
                if (postId == null || postId.isEmpty) {
                  return;
                }
                try {
                  final res = await _svc.explainPostAlgorithmicStatus(postId: postId);
                  if (!mounted) return;
                  final status = res['status']?.toString() ?? '-';
                  final reason = res['reason']?.toString() ?? '';
                  final metrics = (res['metrics'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

                  // Afficher une boîte de dialogue avec le détail
                  // ignore: use_build_context_synchronously
                  await showDialog<void>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Performance du post'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Statut: $status'),
                              const SizedBox(height: 8),
                              if (reason.isNotEmpty)
                                Text(
                                  reason,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              if (metrics.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Métriques:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                ...metrics.entries.map((entry) => Text(
                                      '${entry.key}: ${entry.value}',
                                      style: const TextStyle(fontSize: 13),
                                    )),
                              ],
                            ],
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
                } catch (err) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur explication post: $err'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bestTimes(List<dynamic> items, {bool byHour = true}) {
    if (items.isEmpty) return const Text('N/A');
    // Simple bar chart without extra dependencies
    final counts = items.map((e) => ((e as Map)['count'] as num?)?.toDouble() ?? 0).toList();
    final maxVal = counts.isEmpty ? 0.0 : counts.reduce((a,b) => a > b ? a : b);
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      return Column(
        children: items.map((e) {
          final m = (e as Map).cast<String, dynamic>();
          final label = byHour ? 'Heure ${m['hour']}' : (m['date']?.toString() ?? '');
          final c = (m['count'] as num?)?.toDouble() ?? 0.0;
          final w = maxVal > 0 ? (c / maxVal) * (maxWidth - 120) : 0.0; // leave room for labels
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 8),
                Container(height: 12, width: w, decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(6))),
                const SizedBox(width: 8),
                SizedBox(width: 32, child: Text(c.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _timeseriesBars(List<dynamic> series) {
    if (series.isEmpty) return const Text('N/A');
    double maxVal = 0;
    for (final e in series) {
      final m = (e as Map).cast<String, dynamic>();
      final mi = (m['messages_in'] as num?)?.toDouble() ?? 0;
      final mo = (m['messages_out'] as num?)?.toDouble() ?? 0;
      final sp = (m['social_posts'] as num?)?.toDouble() ?? 0;
      final ld = (m['leads'] as num?)?.toDouble() ?? 0;
      maxVal = [maxVal, mi, mo, sp, ld].reduce((a,b)=> a>b ? a : b);
    }
    maxVal = maxVal <= 0 ? 1 : maxVal;

    const miColor = Colors.cyanAccent;
    const moColor = Colors.purpleAccent;
    const spColor = Colors.orangeAccent;
    const ldColor = Colors.limeAccent;

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: series.map((e) {
          final m = (e as Map).cast<String, dynamic>();
          final lbl = (m['date'] ?? '').toString().substring(5);
          final mi = (m['messages_in'] as num?)?.toDouble() ?? 0;
          final mo = (m['messages_out'] as num?)?.toDouble() ?? 0;
          final sp = (m['social_posts'] as num?)?.toDouble() ?? 0;
          final ld = (m['leads'] as num?)?.toDouble() ?? 0;
          const barW = 12.0;
          const space = 6.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(width: barW, height: 120*(mi/maxVal), color: miColor),
                    SizedBox(width: space),
                    Container(width: barW, height: 120*(mo/maxVal), color: moColor),
                    SizedBox(width: space),
                    Container(width: barW, height: 120*(sp/maxVal), color: spColor),
                    SizedBox(width: space),
                    Container(width: barW, height: 120*(ld/maxVal), color: ldColor),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(width: 72, child: Text(lbl, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Hebdo'),
            Tab(text: 'Mensuel'),
            Tab(text: 'Supervision IA'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Copier le rapport JSON',
            onPressed: () async {
              final data = _tab.index == 0 ? _weekly : _monthly;
              if (data == null) return;
              await Clipboard.setData(ClipboardData(text: jsonEncode(data)));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapport copié dans le presse-papiers')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exporter en PDF',
            onPressed: () => _exportPdf(monthly: _tab.index == 1),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _loadingW
              ? const Center(child: CircularProgressIndicator())
              : _weekly == null
                  ? const Center(child: Text('Pas de données'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _summaryView(_weekly!),
                        const SizedBox(height: 16),
                        const Text('7 jours — Messages/Posts/Leads'),
                        _loadingTS
                            ? const Center(child: CircularProgressIndicator())
                            : _timeseriesBars(_series),
                        const SizedBox(height: 16),
                        const Text('Top Posts'),
                        _topPosts(((_weekly!['top_posts']) as List?) ?? const []),
                        const SizedBox(height: 16),
                        const Text('Meilleures heures'),
                        _bestTimes(((_weekly!['best_hours']) as List?) ?? const [], byHour: true),
                      ]),
                    ),
          _loadingM
              ? const Center(child: CircularProgressIndicator())
              : _monthly == null
                  ? const Center(child: Text('Pas de données'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _summaryView(_monthly!),
                        const SizedBox(height: 16),
                        const Text('Top Posts'),
                        _topPosts(((_monthly!['top_posts']) as List?) ?? const []),
                        const SizedBox(height: 16),
                        const Text('Meilleurs jours'),
                        _bestTimes(((_monthly!['best_days']) as List?) ?? const [], byHour: false),
                      ]),
                    ),
          _loadingIa
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadIaSupervision,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Activité IA (2h / 24h / 7j)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _loadingIa ? null : _aggregateIaActivity,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Recalculer'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_ai2h.isEmpty && _aiDaily.isEmpty && _aiWeekly.isEmpty)
                          const Text('Aucune donnée IA pour le moment.', style: TextStyle(color: Colors.white70))
                        else ...[
                          if (_ai2h.isNotEmpty) ...[
                            const Text('Dernières 2h', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            _buildAiActivityList(_ai2h),
                            const SizedBox(height: 12),
                          ],
                          if (_aiDaily.isNotEmpty) ...[
                            const Text('7 derniers jours', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            _buildAiActivityList(_aiDaily),
                            const SizedBox(height: 12),
                          ],
                          if (_aiWeekly.isNotEmpty) ...[
                            const Text('Semaines récentes', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            _buildAiActivityList(_aiWeekly),
                          ],
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'Rapports de cohérence',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildConsistencySection(),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
 
  Widget _buildAiActivityList(List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) {
        final m = (e as Map).cast<String, dynamic>();
        final bucket = (m['bucket'] ?? m['bucket_date'] ?? '').toString();
        final rec = (m['messages_received'] ?? 0).toString();
        final ans = (m['messages_answered_by_ai'] ?? 0).toString();
        final skipped = (m['messages_ai_skipped'] ?? 0).toString();
        final needsHuman = (m['messages_needs_human'] ?? 0).toString();
        final alerts = (m['alerts_created'] ?? 0).toString();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '$bucket — in=$rec • ia=$ans • skip=$skipped • human=$needsHuman • alerts=$alerts',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConsistencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Content jobs média sans generation_job_id', style: TextStyle(color: Colors.white70)),
        if (_jobsWithoutGen.isEmpty)
          const Text('RAS', style: TextStyle(color: Colors.white38))
        else
          ..._jobsWithoutGen.map((e) {
            final m = (e as Map).cast<String, dynamic>();
            return Text(
              '- ${(m['id'] ?? '').toString()} • ${(m['objective'] ?? '').toString()}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            );
          }),
        const SizedBox(height: 8),
        const Text('Content jobs approuvés mais non planifiés', style: TextStyle(color: Colors.white70)),
        if (_jobsApprovedUnscheduled.isEmpty)
          const Text('RAS', style: TextStyle(color: Colors.white38))
        else
          ..._jobsApprovedUnscheduled.map((e) {
            final m = (e as Map).cast<String, dynamic>();
            return Text(
              '- ${(m['id'] ?? '').toString()} • ${(m['objective'] ?? '').toString()}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            );
          }),
        const SizedBox(height: 8),
        const Text('Messages needs_human (24h+)', style: TextStyle(color: Colors.white70)),
        if (_messagesNeedsHuman.isEmpty)
          const Text('RAS', style: TextStyle(color: Colors.white38))
        else
          ..._messagesNeedsHuman.map((e) {
            final m = (e as Map).cast<String, dynamic>();
            return Text(
              '- ${(m['id'] ?? '').toString()} • ${(m['channel'] ?? '').toString()} • ${(m['direction'] ?? '').toString()}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            );
          }),
      ],
    );
  }
}
