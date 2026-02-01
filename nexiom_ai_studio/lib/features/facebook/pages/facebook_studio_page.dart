import 'package:flutter/material.dart';
import 'dart:convert';

import '../services/facebook_service.dart';
import '../widgets/facebook_post_composer.dart';
import '../widgets/facebook_comments_section.dart';
import '../widgets/facebook_analytics_section.dart';
import '../../publishing/services/content_job_service.dart';

class FacebookStudioPage extends StatefulWidget {
  const FacebookStudioPage({super.key});

  @override
  State<FacebookStudioPage> createState() => _FacebookStudioPageState();
}

class _FacebookStudioPageState extends State<FacebookStudioPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FacebookService _facebookService = FacebookService.instance();
  final ContentJobService _contentJobService = ContentJobService.instance();

  bool _isLoading = false;
  FacebookDashboardMetrics? _dashboardMetrics;
  List<FacebookPost> _recentPosts = const [];
  Map<String, dynamic>? _pageInsights;
  Map<String, dynamic>? _trends;
  String? _error;
  List<Map<String, dynamic>> _bestTimeSlots = const [];
  List<Map<String, dynamic>> _scheduledFacebookJobs = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final metrics = await _facebookService.getDashboardMetrics();
      final posts = await _facebookService.listPosts(limit: 10);

      Map<String, dynamic>? insights;
      Map<String, dynamic>? trends;
      List<Map<String, dynamic>> bestSlots = const [];
      List<Map<String, dynamic>> scheduledFacebookJobs = const [];

      try {
        final rawInsights = await _facebookService.getPageInsights(period: 'week');
        insights = rawInsights;
      } catch (_) {}

      try {
        final rawTrends = await _facebookService.getPerformanceTrends(days: 30);
        trends = rawTrends;
      } catch (_) {}

      try {
        bestSlots = await _facebookService.getBestPostingTimeSummary(days: 90);
      } catch (_) {}

      // Charger les content_jobs planifiés pour Facebook (statut = scheduled)
      try {
        final rawJobs =
            await _contentJobService.listContentJobs(status: 'scheduled', limit: 50);
        final filteredJobs = rawJobs
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .where((job) {
          final channels = job['channels'];
          if (channels is List) {
            return channels.contains('facebook');
          }
          return false;
        }).toList(growable: false);
        scheduledFacebookJobs = filteredJobs;
      } catch (_) {}

      setState(() {
        _dashboardMetrics = metrics;
        _recentPosts = posts;
        _pageInsights = insights;
        _trends = trends;
        _bestTimeSlots = bestSlots;
        _scheduledFacebookJobs = scheduledFacebookJobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Facebook'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.post_add), text: 'Publier'),
            Tab(icon: Icon(Icons.comment), text: 'Commentaires'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDashboardData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          FacebookPostComposer(onPostPublished: _loadDashboardData),
          FacebookCommentsSection(),
          FacebookAnalyticsSection(),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    final entries = _pageInsights?.entries.toList(growable: false) ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insights de la page',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Text('Aucun insight disponible pour le moment.')
            else
              ...entries.take(5).map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          e.value.toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_trends != null && _trends!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Tendances récentes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ..._trends!.entries.take(3).map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key.toString(),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              e.value.toString(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPostsCard() {
    final posts = _recentPosts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dernières publications Facebook',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (posts.isEmpty)
              const Text('Aucune publication récente.')
            else
              Column(
                children: posts.take(5).map((p) {
                  final subtitleParts = <String>[];
                  if (p.status != null) {
                    subtitleParts.add(p.status!);
                  }
                  if (p.createdAt != null) {
                    subtitleParts.add(p.createdAt!.toLocal().toString());
                  }

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      p.type == 'image'
                          ? Icons.image
                          : p.type == 'video'
                              ? Icons.videocam
                              : Icons.text_snippet,
                    ),
                    title: Text(
                      p.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: subtitleParts.isEmpty
                        ? null
                        : Text(subtitleParts.join(' • ')),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// Sous-onglet regroupant les publications Facebook publiées et planifiées.
  Widget _buildPostsAndSchedulesCard() {
    final posts = _recentPosts;
    final scheduled = _scheduledFacebookJobs;

    return DefaultTabController(
      length: 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Publications Facebook',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Publiées'),
                  Tab(text: 'Planifiées'),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: TabBarView(
                  children: [
                    _buildPublishedPostsList(posts),
                    _buildScheduledPostsList(scheduled),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishedPostsList(List<FacebookPost> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Text('Aucune publication Facebook publiée.'),
      );
    }

    return ListView(
      children: posts.take(20).map((p) {
        final subtitleParts = <String>[];
        if (p.status != null) {
          subtitleParts.add(p.status!);
        }
        if (p.createdAt != null) {
          subtitleParts.add(p.createdAt!.toLocal().toString());
        }

        return ListTile(
          dense: true,
          leading: Icon(
            p.type == 'image'
                ? Icons.image
                : p.type == 'video'
                    ? Icons.videocam
                    : Icons.text_snippet,
          ),
          title: Text(
            p.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle:
              subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
        );
      }).toList(),
    );
  }

  Widget _buildScheduledPostsList(List<Map<String, dynamic>> jobs) {
    if (jobs.isEmpty) {
      return const Center(
        child: Text('Aucune publication Facebook planifiée en attente.'),
      );
    }

    return ListView(
      children: jobs.map((job) {
        final title = (job['title'] ?? job['objective'] ?? '').toString();
        final status = (job['status'] ?? 'scheduled').toString();
        DateTime? scheduledAt;
        String? timezone;

        final metadata = job['metadata'];
        if (metadata is Map) {
          final rawScheduled = metadata['scheduled_at'];
          if (rawScheduled is String) {
            try {
              scheduledAt = DateTime.parse(rawScheduled).toLocal();
            } catch (_) {}
          }
          final tz = metadata['timezone'];
          if (tz != null) {
            timezone = tz.toString();
          }
        }

        final subtitleParts = <String>[];
        subtitleParts.add(status);
        if (scheduledAt != null) {
          final base = 'Prévu le ${scheduledAt.toString()}';
          subtitleParts.add(
            timezone != null ? '$base ($timezone)' : base,
          );
        } else if (timezone != null) {
          subtitleParts.add('Heure $timezone');
        }

        return ListTile(
          dense: true,
          leading: const Icon(Icons.schedule),
          title: Text(
            title.isEmpty ? 'Publication Facebook planifiée' : title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle:
              subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
        );
      }).toList(),
    );
  }

  Widget _buildBestTimesCard() {
    final slots = _bestTimeSlots;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meilleures heures pour publier (Africa/Ouagadougou)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (slots.isEmpty)
              const Text('Pas encore assez de données pour recommander des horaires optimaux.')
            else
              Column(
                children: slots.take(8).map((slot) {
                  final weekday = slot['weekday'] as int? ?? 0;
                  final hour = slot['hour'] as int? ?? 0;
                  final postsCount = slot['posts_count'] as int? ?? 0;
                  final label = _weekdayLabel(weekday);
                  final hourLabel = '${hour.toString().padLeft(2, '0')}h00';
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.schedule),
                    title: Text('$label – $hourLabel'),
                    subtitle: Text('Basé sur $postsCount publication(s) performante(s)'),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case 0:
        return 'Dimanche';
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      default:
        return 'Jour $weekday';
    }
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_dashboardMetrics == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartes de métriques principales
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Abonnés',
                  _dashboardMetrics!.totalFollowers.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Impressions',
                  '${(_dashboardMetrics!.weeklyImpressions / 1000).toStringAsFixed(1)}K',
                  Icons.visibility,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Engagements',
                  _dashboardMetrics!.weeklyEngagements.toString(),
                  Icons.thumb_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Taux engagement',
                  '${_dashboardMetrics!.engagementRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions rapides
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions rapides',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(1),
                          icon: const Icon(Icons.post_add),
                          label: const Text('Nouvelle publication'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(2),
                          icon: const Icon(Icons.comment),
                          label: const Text('Gérer commentaires'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_pageInsights != null && _pageInsights!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildInsightsCard(),
          ],
          if (_recentPosts.isNotEmpty || _scheduledFacebookJobs.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildPostsAndSchedulesCard(),
          ],
          if (_bestTimeSlots.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildBestTimesCard(),
          ],
          const SizedBox(height: 24),

          // Statut du service
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  const Text('Service Facebook opérationnel'),
                  const Spacer(),
                  TextButton(
                    onPressed: _checkServiceHealth,
                    child: const Text('Vérifier'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkServiceHealth() async {
    setState(() => _isLoading = true);
    
    try {
      final isHealthy = await _facebookService.checkHealth();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHealthy ? 'Service OK' : 'Service indisponible'),
            backgroundColor: isHealthy ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
