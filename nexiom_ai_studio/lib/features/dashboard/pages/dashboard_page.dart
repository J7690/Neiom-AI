import 'package:flutter/material.dart';

import '../../analytics/services/analytics_service.dart';
import '../../messaging/services/messaging_service.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _analytics = AnalyticsService.instance();
  final _msg = MessagingService.instance();

  bool _loading = true;
  Map<String, dynamic>? _overview;
  List<dynamic> _ts = const [];
  List<dynamic> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ov = await _analytics.getDashboardOverview(days: 7);
      final ts = await _msg.getMetricsTimeseries(days: 7);
      final alerts = await _analytics.listAlerts(limit: 20);
      setState(() {
        _overview = ov;
        _ts = ts;
        _alerts = alerts;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _kpi(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: Colors.cyanAccent),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ])),
      ]),
    );
  }

  Widget _timeseries(List<dynamic> series) {
    if (series.isEmpty) return const Text('N/A');
    // Prepare grouped bar data: one group per day, four bars: IN/OUT/POSTS/LEADS
    final groups = <BarChartGroupData>[];
    double maxVal = 0;
    for (int i = 0; i < series.length; i++) {
      final m = (series[i] as Map).cast<String, dynamic>();
      final mi = (m['messages_in'] as num?)?.toDouble() ?? 0;
      final mo = (m['messages_out'] as num?)?.toDouble() ?? 0;
      final sp = (m['social_posts'] as num?)?.toDouble() ?? 0;
      final ld = (m['leads'] as num?)?.toDouble() ?? 0;
      maxVal = [maxVal, mi, mo, sp, ld].reduce((a, b) => a > b ? a : b);
    }
    if (maxVal <= 0) maxVal = 1;

    const miColor = Colors.cyanAccent;
    const moColor = Colors.purpleAccent;
    const spColor = Colors.orangeAccent;
    const ldColor = Colors.limeAccent;

    for (int i = 0; i < series.length; i++) {
      final m = (series[i] as Map).cast<String, dynamic>();
      final mi = (m['messages_in'] as num?)?.toDouble() ?? 0;
      final mo = (m['messages_out'] as num?)?.toDouble() ?? 0;
      final sp = (m['social_posts'] as num?)?.toDouble() ?? 0;
      final ld = (m['leads'] as num?)?.toDouble() ?? 0;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: mi, width: 6, color: miColor),
            BarChartRodData(toY: mo, width: 6, color: moColor),
            BarChartRodData(toY: sp, width: 6, color: spColor),
            BarChartRodData(toY: ld, width: 6, color: ldColor),
          ],
          barsSpace: 3,
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: groups,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= series.length) return const SizedBox.shrink();
                final m = (series[idx] as Map).cast<String, dynamic>();
                final lbl = (m['date'] ?? '').toString().substring(5);
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text(lbl, style: const TextStyle(fontSize: 10)),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _alertsList(List<dynamic> items) {
    if (items.isEmpty) return const Text('Aucune alerte');
    return Column(children: items.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      final id = (m['id'] ?? '').toString();
      final sev = (m['severity'] ?? '').toString();
      final title = (m['alert_type'] ?? '').toString();
      final msg = (m['message'] ?? '').toString();
      final ack = (m['acknowledged'] == true);
      return Card(
        child: ListTile(
          leading: Icon(Icons.report_problem, color: sev == 'error' ? Colors.redAccent : Colors.orangeAccent),
          title: Text('$title — $sev'),
          subtitle: Text(msg),
          trailing: ack
              ? const Icon(Icons.check, color: Colors.greenAccent)
              : TextButton(onPressed: () async {
                  final ok = await _analytics.ackAlert(id: id);
                  if (ok) await _load();
                }, child: const Text('Ack')),
        ),
      );
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _kpi('Messages IN', '${_overview?['messages_in'] ?? 0}', Icons.inbox_outlined),
                  _kpi('Messages OUT', '${_overview?['messages_out'] ?? 0}', Icons.outbox_outlined),
                  _kpi('Posts créés', '${_overview?['posts_created'] ?? 0}', Icons.post_add_outlined),
                  _kpi('Leads', '${_overview?['leads'] ?? 0}', Icons.person_add_alt_1_outlined),
                  _kpi('Conversations ouvertes', '${_overview?['open_conversations'] ?? 0}', Icons.chat_bubble_outline),
                  _kpi('Planifs à venir', '${_overview?['scheduled_upcoming'] ?? 0}', Icons.schedule_outlined),
                ]),
                const SizedBox(height: 16),
                const Text('Tendance (7 jours)'),
                _timeseries(_ts),
                const SizedBox(height: 16),
                const Text('Alertes'),
                _alertsList(_alerts),
              ]),
            ),
    );
  }
}
