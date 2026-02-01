import 'package:flutter/material.dart';

import '../../analytics/services/analytics_service.dart';

class FacebookAnalyticsSection extends StatefulWidget {
  const FacebookAnalyticsSection({super.key});

  @override
  State<FacebookAnalyticsSection> createState() => _FacebookAnalyticsSectionState();
}

class _FacebookAnalyticsSectionState extends State<FacebookAnalyticsSection> {
  final AnalyticsService _svc = AnalyticsService.instance();

  bool _loading = false;
  Map<String, dynamic>? _weekly;
  List<dynamic> _topFacebookPosts = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final weekly = await _svc.getReportWeekly();
      final top = (weekly['top_posts'] as List?) ?? const [];
      final fbTop = top.where((e) {
        final m = (e as Map).cast<String, dynamic>();
        final channels = (m['channels'] as List?) ?? const [];
        return channels
            .whereType<dynamic>()
            .map((c) => c.toString().toLowerCase())
            .any((c) => c.contains('facebook'));
      }).toList();

      setState(() {
        _weekly = (weekly as Map).cast<String, dynamic>();
        _topFacebookPosts = fbTop;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _weekly == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
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
                  'Analytics Facebook (7 derniers jours)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'Rafraîchir',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_weekly == null)
              const Text('Pas de données disponibles pour le moment.')
            else ...[
              _buildKpis(theme),
              const SizedBox(height: 16),
              const Text(
                'Top posts Facebook',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_topFacebookPosts.isEmpty)
                const Text('Aucun post Facebook dans le top des 7 derniers jours.')
              else
                _buildTopFacebookPostsList(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpis(ThemeData theme) {
    final summary = (_weekly?['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final fbCount = _topFacebookPosts.length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _kpiCard(
          theme,
          label: 'Messages IN',
          value: '${summary['messages_in'] ?? 0}',
          icon: Icons.inbox_outlined,
        ),
        _kpiCard(
          theme,
          label: 'Posts créés',
          value: '${summary['posts_created'] ?? 0}',
          icon: Icons.post_add_outlined,
        ),
        _kpiCard(
          theme,
          label: 'Leads',
          value: '${summary['leads'] ?? 0}',
          icon: Icons.person_add_alt_1_outlined,
        ),
        _kpiCard(
          theme,
          label: 'Top posts Facebook',
          value: '$fbCount',
          icon: Icons.facebook,
        ),
      ],
    );
  }

  Widget _kpiCard(ThemeData theme,
      {required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70)),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFacebookPostsList(ThemeData theme) {
    return Column(
      children: _topFacebookPosts.map((e) {
        final m = (e as Map).cast<String, dynamic>();
        final content = (m['content'] ?? '').toString();
        final score = (m['score'] ?? '0').toString();
        final channels = ((m['channels'] as List?) ?? const [])
            .whereType<dynamic>()
            .map((c) => c.toString())
            .toList();
        final postId = m['post_id']?.toString();

        return Card(
          child: ListTile(
            title: Text(
              content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Score: $score • Canaux: ${channels.join(', ')}'),
            trailing: postId == null || postId.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.insights_outlined),
                    tooltip: 'Expliquer la performance',
                    onPressed: () => _explainPost(postId),
                  ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _explainPost(String postId) async {
    try {
      final res = await _svc.explainPostAlgorithmicStatus(postId: postId);
      if (!mounted) return;

      final status = res['status']?.toString() ?? '-';
      final reason = res['reason']?.toString() ?? '';
      final metrics = (res['metrics'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Performance du post Facebook'),
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
                    ...metrics.entries.map(
                      (entry) => Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
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
  }
}
