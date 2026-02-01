import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexiom_ai_studio/routes/app_routes.dart';
import '../../publishing/services/social_posts_service.dart';
import '../services/marketing_service.dart';
import '../services/marketing_assistant_service.dart';
import '../widgets/marketing_validation_widget.dart';

class MarketingDecisionDashboard extends StatefulWidget {
  const MarketingDecisionDashboard({super.key});

  @override
  State<MarketingDecisionDashboard> createState() => _MarketingDecisionDashboardState();
}

class _MarketingDecisionDashboardState extends State<MarketingDecisionDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MarketingService _marketingService = MarketingService.instance();
  final MarketingAssistantService _assistantService = MarketingAssistantService.instance();

  // États
  bool _isLoading = false;
  List<MarketingRecommendation> _pendingRecommendations = [];
  List<MarketingObjective> _objectives = [];
  List<MarketingMission> _missions = [];
  Map<String, dynamic>? _patternsAnalysis;
  Map<String, dynamic>? _objectiveState;
  List<Map<String, dynamic>> _strategyLessons = [];
  Map<String, dynamic>? _studioMemory;
  List<Map<String, dynamic>> _analysisRuns = [];
  bool _refreshKnowledgeForOrchestration = false;
  String? _error;
  String _selectedObjective = 'engagement';
  Future<AssistantReport?>? _assistantReportFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _assistantReportFuture = _assistantService.getAssistantReport(
      objective: _selectedObjective,
    );
    _loadData();
  }

  Future<void> _generateMissionMedia(MarketingMission mission) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic>? result;
    String? error;

    try {
      result = await _marketingService.generateMissionMedia(
        missionId: mission.id,
        channel: mission.channel,
        mediaType: 'image',
        limit: 20,
      );
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _error = error;
    });

    await showDialog(
      context: context,
      builder: (context) {
        final total = (result?['totalCandidates'] ?? result?['total_candidates'] ?? 0).toString();
        final generated = (result?['generated'] ?? result?['generated_count'] ?? 0).toString();

        return AlertDialog(
          backgroundColor: const Color(0xFF020617),
          title: Text(
            'Génération des médias',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mission : ${mission.id}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              if (error != null)
                Text(
                  'Erreur : $error',
                  style: const TextStyle(color: Colors.redAccent),
                )
              else ...[
                Text(
                  'Posts candidats : $total',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Médias générés : $generated',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudioMemoryBanner() {
    final contextMap = _studioMemory?['context'] as Map<String, dynamic>?;
    final label = contextMap?['label']?.toString();

    if (label == null || label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.memory, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contexte actuel Nexiom',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les recommandations en attente
      final recommendations = await _marketingService.getPendingRecommendations();
      
      // Charger les objectifs
      final objectives = await _marketingService.getMarketingObjectives();
      // Charger les missions
      final missions = await _marketingService.getMarketingMissions();
      
      // Analyser les patterns
      final patterns = await _marketingService.analyzePerformancePatterns();

      // État marketing global (M1)
      final objectiveState = await _marketingService.getMarketingObjectiveState();

      // Charger les leçons stratégiques (mémoire) pour l'objectif sélectionné
      final lessonsPayload = await _marketingService.listPostStrategyLessons(
        objective: _selectedObjective,
        limit: 20,
      );
      final lessonsList = (lessonsPayload['lessons'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);

      // Charger la mémoire consolidée du Studio (cerveau Nexiom)
      final studioMemory = await _marketingService.getStudioMemory();

      // Récupérer l'historique récent des exécutions du cerveau marketing
      final analysisRuns = await _marketingService.getRecentStudioAnalysisRuns(limit: 5);

      setState(() {
        _pendingRecommendations = recommendations;
        _objectives = objectives;
        _missions = missions;
        _patternsAnalysis = patterns;
        _objectiveState = objectiveState;
        _strategyLessons = lessonsList;
        _studioMemory = studioMemory;
        _analysisRuns = analysisRuns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportMarketingKnowledge() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final export = await _marketingService.exportMarketingKnowledge(
        objective: _selectedObjective,
        channel: 'facebook',
        periodDays: 30,
        locale: 'fr',
      );

      if (!mounted) return;

      if (export == null || export.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun export marketing disponible pour le moment.'),
          ),
        );
        return;
      }

      final markdown = export['markdown']?.toString() ?? '';
      if (markdown.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export vide (aucun contenu markdown renvoyé).'),
          ),
        );
        return;
      }

      await Clipboard.setData(ClipboardData(text: markdown));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Export marketing copié dans le presse-papiers (Markdown). Collez-le dans un document ou un email.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'export marketing: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _autoPlanMission(MarketingMission mission) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1) Générer les content_jobs pour la mission (séquence intro / nurture / closing)
      await _marketingService.createContentJobsFromMission(
        missionId: mission.id,
        timezone: 'Africa/Ouagadougou',
      );

      // 2) Planifier automatiquement ces content_jobs en respectant la limite par jour
      final scheduleResult = await _marketingService.scheduleContentJobsForMission(
        missionId: mission.id,
        timezone: 'Africa/Ouagadougou',
        maxPostsPerDay: 3,
      );

      if (!mounted) return;

      await _loadData();

      int jobsScheduled = 0;
      try {
        final any = scheduleResult['jobs_scheduled'];
        if (any is int) {
          jobsScheduled = any;
        } else if (any is num) {
          jobsScheduled = any.toInt();
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            jobsScheduled > 0
                ? '$jobsScheduled contenus planifiés automatiquement pour la mission.'
                : 'Aucun contenu n\'a pu être planifié automatiquement pour cette mission.',
          ),
        ),
      );

      // Basculer sur l'onglet Calendrier pour visualiser la planification
      _tabController.animateTo(7);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur lors de la planification automatique de la mission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showMissionPlanning(
    MarketingMission mission,
    MarketingObjective objective,
  ) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobs = await _marketingService.listContentJobsForMission(
        missionId: mission.id,
        limit: 200,
      );

      final calendar = await _marketingService.listMissionCalendar(
        missionId: mission.id,
        startDate: mission.startDate ?? DateTime.now(),
        days: 30,
      );

      if (!mounted) return;

      final statusCounts = <String, int>{};
      final phaseCounts = <String, int>{};
      for (final j in jobs.whereType<Map>()) {
        final job = j.cast<String, dynamic>();
        final status = (job['status'] ?? '').toString();
        if (status.isNotEmpty) {
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
        final phase = (job['phase'] ?? '').toString();
        if (phase.isNotEmpty) {
          phaseCounts[phase] = (phaseCounts[phase] ?? 0) + 1;
        }
      }

      final days = calendar.whereType<Map>().toList(growable: false);

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              'Planning mission – ${objective.objective} · ${mission.channel}',
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Résumé des contenus (${jobs.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (statusCounts.isEmpty)
                    const Text('Aucun content_job pour cette mission.'),
                  if (statusCounts.isNotEmpty) ...[
                    ...statusCounts.entries
                        .map((e) => Text('${e.key}: ${e.value}'))
                        .toList(),
                  ],
                  if (phaseCounts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Par phase :',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    ...phaseCounts.entries
                        .map((e) => Text('${e.key}: ${e.value}'))
                        .toList(),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Calendrier (30 jours)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (days.isEmpty)
                    const Text('Aucun élément planifié pour cette période.'),
                  if (days.isNotEmpty)
                    ...days.map((day) {
                      final d = day as Map;
                      final dateStr = d['date']?.toString() ?? '';
                      final items = (d['items'] as List?) ?? const [];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ExpansionTile(
                          title: Text(dateStr),
                          children: items.map((it) {
                            final m = (it as Map).cast<String, dynamic>();
                            final time = (m['time'] ?? '').toString();
                            final status = (m['status'] ?? '').toString();
                            final channels = (m['channels'] as List?)
                                    ?.map((e) => e.toString())
                                    .join(', ') ??
                                '';
                            final content = (m['content'] ?? '').toString();
                            final phase = (m['phase'] ?? '').toString();
                            return ListTile(
                              leading: Text(time),
                              title: Text(
                                '[$status] $channels${phase.isNotEmpty ? ' · $phase' : ''}',
                              ),
                              subtitle: Text(
                                content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur lors du chargement du planning de mission: $e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showMissionIntelligenceReport(
    MarketingMission mission,
    MarketingObjective objective,
  ) async {
    try {
      final report =
          await _marketingService.getLatestMissionIntelligenceReport(mission.id);

      if (!mounted) return;

      if (report == null || report.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Aucun rapport d'intelligence IA complète n'est disponible pour cette mission.",
            ),
          ),
        );
        return;
      }

      final internal =
          (report['internal_analysis'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final external =
          (report['external_analysis'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final insights = (report['insights_for_recommendation_engine']
              as Map<String, dynamic>?) ??
          <String, dynamic>{};

      final recommendedFormats = (insights['recommended_formats'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      final recommendedHashtags = (insights['recommended_hashtags'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      final recommendedAngles = (insights['recommended_angles'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];

      final topFormats = (internal['top_formats'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final topHashtags = (internal['top_hashtags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Intelligence IA complète – Mission'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Objectif: ${objective.objective} · Canal: ${mission.channel}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (topFormats.isNotEmpty) ...[
                    const Text(
                      'Formats internes qui marchent le mieux:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(topFormats.join(', ')),
                    const SizedBox(height: 8),
                  ],
                  if (topHashtags.isNotEmpty) ...[
                    const Text(
                      'Hashtags internes performants:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(topHashtags.join(' ')),
                    const SizedBox(height: 8),
                  ],
                  if (recommendedFormats.isNotEmpty) ...[
                    const Text(
                      'Formats recommandés pour les recos finales:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(recommendedFormats.join(', ')),
                    const SizedBox(height: 8),
                  ],
                  if (recommendedHashtags.isNotEmpty) ...[
                    const Text(
                      'Hashtags recommandés par l\'intelligence IA:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(recommendedHashtags.join(' ')),
                    const SizedBox(height: 8),
                  ],
                  if (recommendedAngles.isNotEmpty) ...[
                    const Text(
                      'Angles de contenu recommandés:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(recommendedAngles.join(', ')),
                    const SizedBox(height: 8),
                  ],
                  if (external.isNotEmpty) ...[
                    const Text(
                      'Analyse externe disponible (Meta / sources pro / autres).',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur lors du chargement du rapport d'intelligence pour la mission: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _runObjectiveIntelligence() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _marketingService.runMissionIntelligence(
        missionId: null,
        objective: _selectedObjective,
        channel: 'facebook',
        periodDays: 30,
        locale: 'fr',
        refreshKnowledge: _refreshKnowledgeForOrchestration,
      );

      if (!mounted) return;

      await _loadData();

      if (result == null || result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Orchestration IA globale terminée mais aucun résultat détaillé n'a été renvoyé.",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Intelligence marketing complète exécutée pour l’objectif courant. Vérifiez les recommandations et le diagnostic.',
            ),
          ),
        );
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'orchestration IA globale: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runMissionIntelligenceForMission(
    MarketingMission mission,
    MarketingObjective objective,
  ) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _marketingService.runMissionIntelligence(
        missionId: mission.id,
        objective: objective.objective,
        channel: mission.channel,
        periodDays: 30,
        locale: 'fr',
        refreshKnowledge: _refreshKnowledgeForOrchestration,
      );

      if (!mounted) return;

      await _loadData();

      if (result == null || result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Orchestration IA terminée mais aucun résultat détaillé n'a été renvoyé.",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Intelligence marketing complète exécutée pour la mission. Vérifiez les recommandations et le diagnostic.',
            ),
          ),
        );
        // Basculer sur l'onglet Recommandations pour voir les nouveaux posts
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'orchestration IA pour la mission: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Marketing Décisionnel'),
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.recommend), text: 'Recommandations'),
            Tab(icon: Icon(Icons.analytics), text: 'Patterns'),
            Tab(icon: Icon(Icons.track_changes), text: 'Objectifs'),
            Tab(icon: Icon(Icons.flag), text: 'Missions'),
            Tab(icon: Icon(Icons.notifications), text: 'Alertes'),
            Tab(icon: Icon(Icons.history_edu), text: 'Leçons'),
            Tab(icon: Icon(Icons.support_agent), text: 'Intelligence marketing avancée'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Calendrier'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedObjective,
                dropdownColor: const Color(0xFF020617),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'notoriety',
                    child: Text(
                      'Notoriété',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const DropdownMenuItem(
                    value: 'engagement',
                    child: Text(
                      'Engagement',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const DropdownMenuItem(
                    value: 'conversion',
                    child: Text(
                      'Conversion',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedObjective = value;
                    _assistantReportFuture = _assistantService.getAssistantReport(
                      objective: _selectedObjective,
                    );
                  });
                  _loadData();
                },
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _refreshKnowledgeForOrchestration = !_refreshKnowledgeForOrchestration;
              });
            },
            icon: Icon(
              Icons.public,
              color:
                  _refreshKnowledgeForOrchestration ? Colors.cyanAccent : Colors.white70,
            ),
            tooltip:
                'Rafraîchir la connaissance web (SerpAPI) lors de la prochaine orchestration IA',
          ),
          IconButton(
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Aide sur le cerveau marketing',
          ),
          IconButton(
            onPressed: _isLoading ? null : _exportMarketingKnowledge,
            icon: const Icon(Icons.file_download),
            tooltip: 'Exporter la synthèse marketing (stats + knowledge)',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.studioMemoryContext),
            icon: const Icon(Icons.memory),
            tooltip: 'Contexte du Studio',
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _isLoading ? null : _askCommittee,
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'Demander au comité',
          ),
          IconButton(
            onPressed: _isLoading ? null : _runObjectiveIntelligence,
            icon: const Icon(Icons.psychology_alt),
            tooltip: 'Intelligence IA complète sur l’objectif courant',
          ),
          IconButton(
            onPressed: _isLoading ? null : _createEditorialPlan,
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Créer un plan éditorial auto',
          ),
          IconButton(
            onPressed: _generateNewRecommendations,
            icon: const Icon(Icons.add),
            tooltip: 'Générer des recommandations IA',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecommendationsTab(),
          _buildPatternsTab(),
          _buildObjectivesTab(),
          _buildMissionsTab(),
          _buildAlertsTab(),
          _buildLessonsTab(),
          _buildAssistantTab(),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  Future<void> _createEditorialPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final objective = _objectives.isNotEmpty
          ? _objectives.first.objective
          : _selectedObjective;

      await _marketingService.createContentJobsFromObjective(
        objective: objective,
        startDate: DateTime.now(),
        days: 7,
        channels: const ['facebook'],
      );

      if (!mounted) return;

      // Naviguer vers la page d'administration des content_jobs
      Navigator.of(context).pushNamed(AppRoutes.contentJobsAdmin);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRecommendationsTab() {
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
              onPressed: _loadData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_pendingRecommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Aucune recommandation en attente',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateNewRecommendations,
              icon: const Icon(Icons.add),
              label: const Text('Générer des recommandations'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRecommendations.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Boucle d’apprentissage',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _tabController.animateTo(4),
                        icon: const Icon(Icons.history_edu, size: 16),
                        label: const Text('Voir les leçons stratégiques'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_studioMemory != null)
                    _buildStudioMemoryBanner(),
                ],
              ),
            );
          }

          final recommendation = _pendingRecommendations[index - 1];
          return MarketingValidationWidget(
            recommendation: recommendation,
            onApproved: () {
              setState(() {
                _pendingRecommendations.removeAt(index - 1);
              });
            },
            onRejected: () {
              setState(() {
                _pendingRecommendations.removeAt(index - 1);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildPatternsTab() {
    if (_isLoading && _patternsAnalysis == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_patternsAnalysis == null || _patternsAnalysis!.isEmpty) {
      return Center(
        child: Text(
          'Aucune analyse de patterns disponible pour le moment.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final entries = _patternsAnalysis!.entries.toList(growable: false);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final key = entry.key;
        final value = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(value.toString()),
          ),
        );
      },
    );
  }

  Widget _buildCalendarTab() {
    final svc = SocialPostsService.instance();

    return FutureBuilder<List<dynamic>>(
      future: svc.listCalendar(days: 30),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Erreur lors du chargement du calendrier éditorial : ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final calendar = snapshot.data ?? const [];
        if (calendar.isEmpty) {
          return const Center(
            child: Text('Aucun post planifié ou publié pour la période.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: calendar.length,
          itemBuilder: (context, index) {
            final day = calendar[index] as Map;
            final dateStr = day['date']?.toString() ?? '';
            final items = (day['items'] as List?) ?? const [];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(dateStr),
                children: items.map((it) {
                  final m = it as Map;
                  final time = m['time']?.toString() ?? '';
                  final status = m['status']?.toString() ?? '';
                  final channels = ((m['channels'] as List?)?.join(', ')) ?? '';
                  final content = m['content']?.toString() ?? '';
                  return ListTile(
                    leading: Text(time),
                    title: Text('[$status] $channels'),
                    subtitle: Text(
                      content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAssistantTab() {
    return FutureBuilder<AssistantReport?>(
      future: _assistantReportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Erreur lors du chargement de l\'assistant marketing : ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final report = snapshot.data;
        if (report == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucun diagnostic n\'a encore été produit par l\'assistant marketing.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report.diagnostic != null) ...[
                Text(
                  'Diagnostic global',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  report.diagnostic!.summary,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                if (report.diagnostic!.whatWorks.isNotEmpty) ...[
                  Text(
                    'Ce qui marche',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  ...report.diagnostic!.whatWorks
                      .map((t) => _buildBullet(t, color: Colors.white70))
                      .toList(),
                  const SizedBox(height: 12),
                ],
                if (report.diagnostic!.whatTires.isNotEmpty) ...[
                  Text(
                    'Ce qui fatigue',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  ...report.diagnostic!.whatTires
                      .map((t) => _buildBullet(t, color: Colors.white70))
                      .toList(),
                  const SizedBox(height: 12),
                ],
                if (report.diagnostic!.whatIsMissing.isNotEmpty) ...[
                  Text(
                    'Ce qui manque',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  ...report.diagnostic!.whatIsMissing
                      .map((t) => _buildBullet(t, color: Colors.white70))
                      .toList(),
                  const SizedBox(height: 24),
                ],
              ],
              Text(
                'Recommandations (3 actions)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (report.recommendations.isEmpty)
                const Text('Aucune recommandation n\'a été renvoyée.'),
              ...report.recommendations
                  .map((rec) => _buildAssistantRecommendationCard(rec))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBullet(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(color: color),
          ),
          Expanded(
            child: Text(
              text,
              style: color != null ? TextStyle(color: color) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantRecommendationCard(AssistantRecommendation rec) {
    final objectiveCode =
        rec.objective.isNotEmpty ? rec.objective : _selectedObjective;
    final objectiveLabel = _getObjectiveLabel(objectiveCode);
    final objectiveColor = _getObjectiveColor(objectiveCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support_agent, color: objectiveColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(rec.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rec.priority.toUpperCase(),
                    style: TextStyle(
                      color: _getPriorityColor(rec.priority),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Objectif : $objectiveLabel',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(rec.explanation),
            const SizedBox(height: 8),
            if (rec.actions.isNotEmpty) ...[
              const Text('Actions proposées :'),
              const SizedBox(height: 4),
              ...rec.actions.map(_buildBullet).toList(),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final code =
                        rec.objective.isNotEmpty ? rec.objective : _selectedObjective;
                    setState(() {
                      _selectedObjective = code;
                      _assistantReportFuture = _assistantService.getAssistantReport(
                        objective: _selectedObjective,
                      );
                    });
                    _loadData();
                    _tabController.animateTo(2);
                  },
                  icon: const Icon(Icons.track_changes),
                  label: const Text('Relier à l\'objectif'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final buffer = StringBuffer();
                    buffer.writeln(rec.title);
                    buffer.writeln();
                    buffer.writeln(rec.explanation);
                    if (rec.actions.isNotEmpty) {
                      buffer.writeln();
                      buffer.writeln('Actions recommandées :');
                      for (final action in rec.actions) {
                        buffer.writeln('- $action');
                      }
                    }

                    await Clipboard.setData(
                      ClipboardData(text: buffer.toString()),
                    );

                    if (!mounted) return;

                    Navigator.of(context).pushNamed(AppRoutes.contentJobsAdmin);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Recommandation copiée. Collez-la comme brief dans la page de validation / planification.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ouvrir pour publier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateRecommendationsForMission(
    MarketingMission mission,
    MarketingObjective objective,
  ) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hasReport =
          await _marketingService.hasMissionIntelligenceReport(mission.id);
      if (!hasReport) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Aucun rapport d'intelligence IA complète n'est disponible pour cette mission. Lance d'abord l'Intelligence IA complète.",
              ),
            ),
          );
        }
        return;
      }

      final recs = await _marketingService.generateRecommendations(
        objective: objective.objective,
        count: 3,
        missionId: mission.id,
      );

      await _loadData();

      if (mounted) {
        if (recs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${recs.length} recommandations générées pour la mission.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Basculer sur l'onglet Recommandations pour visualiser les nouveaux posts
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération de recommandations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _proposeAIMissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activityContext = _pendingRecommendations.isNotEmpty
          ? _pendingRecommendations.first.recommendationSummary
          : null;

      await _marketingService.proposeAIMissions(
        objective: _selectedObjective,
        activityRef: activityContext,
        preferredChannels: const ['facebook'],
        maxMissions: 3,
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missions IA proposées avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la proposition de missions IA: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMissionsTab() {
    if (_isLoading && _missions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, color: Colors.grey[600], size: 48),
            const SizedBox(height: 16),
            Text(
              'Aucune mission marketing définie pour le moment.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showCreateMissionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une mission'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _proposeAIMissions,
                  icon: const Icon(Icons.psychology),
                  label: const Text('Proposer des missions IA'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Missions marketing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _proposeAIMissions,
                    icon: const Icon(Icons.psychology),
                    label: const Text('Proposer des missions IA'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showCreateMissionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle mission'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _missions.length,
              itemBuilder: (context, index) {
                final mission = _missions[index];
                final objective = _objectives.firstWhere(
                  (o) => o.id == mission.objectiveId,
                  orElse: () => MarketingObjective(
                    id: '',
                    objective: mission.metric,
                    targetValue: 0,
                    currentValue: 0,
                    progressPercentage: 0,
                    status: '',
                  ),
                );
                return _buildMissionCard(mission, objective);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard(MarketingMission mission, MarketingObjective objective) {
    Color statusColor;
    switch (mission.status) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'paused':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getObjectiveLabel(objective.objective),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${mission.channel} · ${mission.metric}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mission.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cible: ${mission.targetValue.toStringAsFixed(1)} ${mission.unit} · Base: ${mission.currentBaseline.toStringAsFixed(1)}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (mission.activityRef != null && mission.activityRef!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                mission.activityRef!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _generateRecommendationsForMission(mission, objective),
                  icon: const Icon(Icons.recommend),
                  label: const Text('Générer des recommandations'),
                ),
                TextButton.icon(
                  onPressed: () => _runMissionIntelligenceForMission(mission, objective),
                  icon: const Icon(Icons.psychology_alt),
                  label: const Text('Intelligence IA complète'),
                ),
                TextButton.icon(
                  onPressed: () => _showMissionIntelligenceReport(mission, objective),
                  icon: const Icon(Icons.insights),
                  label: const Text('Voir intelligence IA'),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'auto_plan') {
                      await _autoPlanMission(mission);
                    } else if (value == 'mission_calendar') {
                      await _showMissionPlanning(mission, objective);
                    } else if (value == 'generate_media') {
                      await _generateMissionMedia(mission);
                    } else {
                      await _changeMissionStatus(mission.id, value);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'active',
                      child: Text('Activer'),
                    ),
                    const PopupMenuItem(
                      value: 'paused',
                      child: Text('Mettre en pause'),
                    ),
                    const PopupMenuItem(
                      value: 'completed',
                      child: Text('Marquer comme terminée'),
                    ),
                    const PopupMenuItem(
                      value: 'cancelled',
                      child: Text('Annuler'),
                    ),
                    const PopupMenuItem(
                      value: 'mission_calendar',
                      child: Text('Voir calendrier mission'),
                    ),
                    const PopupMenuItem(
                      value: 'auto_plan',
                      child: Text('Planification automatique'),
                    ),
                    const PopupMenuItem(
                      value: 'generate_media',
                      child: Text('Générer les médias de la mission'),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeMissionStatus(String missionId, String status) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final ok = await _marketingService.updateMarketingMissionStatus(
        missionId: missionId,
        status: status,
      );
      if (ok) {
        await _loadData();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCreateMissionDialog() {
    if (_objectives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun objectif marketing défini. Créez d’abord un objectif.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final objective = _objectives.first;
    final objectiveId = objective.id;
    final targetController = TextEditingController();
    final baselineController = TextEditingController();
    final activityController = TextEditingController();
    String channel = 'facebook';
    String metric = 'followers';

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nouvelle mission marketing'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: channel,
                  decoration: const InputDecoration(labelText: 'Canal'),
                  items: const [
                    DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                    DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
                    DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      channel = value;
                    }
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: metric,
                  decoration: const InputDecoration(labelText: 'Métrique'),
                  items: const [
                    DropdownMenuItem(value: 'followers', child: Text('Abonnés')),
                    DropdownMenuItem(value: 'views', child: Text('Vues')),
                    DropdownMenuItem(value: 'clicks', child: Text('Clics')),
                    DropdownMenuItem(value: 'leads', child: Text('Prospects')),
                    DropdownMenuItem(value: 'conversions', child: Text('Conversions')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      metric = value;
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cible (valeur numérique)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: baselineController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Baseline actuelle (optionnel)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: activityController,
                  decoration: const InputDecoration(
                    labelText: 'Référence activité (ex: cours d’appui maths Terminale)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final target = double.tryParse(targetController.text.trim());
                final baseline = baselineController.text.trim().isNotEmpty
                    ? double.tryParse(baselineController.text.trim())
                    : null;

                if (target == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir une cible numérique valide.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();

                setState(() {
                  _isLoading = true;
                });

                try {
                  await _marketingService.createMarketingMission(
                    objectiveId: objectiveId,
                    channel: channel,
                    metric: metric,
                    targetValue: target,
                    currentBaseline: baseline,
                    activityRef: activityController.text.trim().isNotEmpty
                        ? activityController.text.trim()
                        : null,
                  );
                  await _loadData();
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildObjectivesTab() {
    if (_isLoading && _objectives.isEmpty && _objectiveState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_objectives.isEmpty) {
      return Center(
        child: Text(
          'Aucun objectif marketing configuré.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _objectives.length,
      itemBuilder: (context, index) {
        final obj = _objectives[index];
        final progress = obj.progressPercentage / 100.0;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getObjectiveIcon(obj.objective),
                      color: _getObjectiveColor(obj.objective),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getObjectiveLabel(obj.objective),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Cible: ${obj.targetValue.toStringAsFixed(1)} – Actuel: ${obj.currentValue.toStringAsFixed(1)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.isNaN ? 0 : progress,
                  backgroundColor: Colors.grey[200],
                  color: _getObjectiveColor(obj.objective),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${obj.progressPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    if (_isLoading && _analysisRuns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analysisRuns.isEmpty) {
      return Center(
        child: Text(
          'Les alertes marketing seront affichées ici à partir des signaux générés.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _analysisRuns.length,
      itemBuilder: (context, index) {
        final run = _analysisRuns[index];
        final source = run['source']?.toString() ?? 'marketing_brain';
        final createdAtStr = run['created_at']?.toString() ?? '';
        Map<String, dynamic>? inputMetrics;
        try {
          inputMetrics = (run['input_metrics'] as Map?)?.cast<String, dynamic>();
        } catch (_) {
          inputMetrics = null;
        }
        Map<String, dynamic>? outputSummary;
        try {
          outputSummary = (run['output_summary'] as Map?)?.cast<String, dynamic>();
        } catch (_) {
          outputSummary = null;
        }
        final objective = inputMetrics?['objective']?.toString();
        final market = inputMetrics?['market']?.toString();
        final diagnosticSummary =
            outputSummary?['assistant_diagnostic_summary']?.toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.psychology_alt),
            title: Text(source),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (objective != null && objective.isNotEmpty)
                  Text('Objectif: ${_getObjectiveLabel(objective)}'),
                if (market != null && market.isNotEmpty)
                  Text('Marché: $market'),
                if (createdAtStr.isNotEmpty)
                  Text(
                    'Analyse: $createdAtStr',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                if (diagnosticSummary != null && diagnosticSummary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      diagnosticSummary,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonsTab() {
    if (_isLoading && _strategyLessons.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_strategyLessons.isEmpty) {
      return Center(
        child: Text(
          'Aucune leçon stratégique enregistrée pour l\'objectif sélectionné.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _strategyLessons.length,
      itemBuilder: (context, index) {
        final lesson = _strategyLessons[index];
        final objective = lesson['objective_at_publication']?.toString() ?? '';
        final role = lesson['strategic_role']?.toString() ?? '';
        final verdict = lesson['verdict']?.toString() ?? '';
        final notes = lesson['context_notes']?.toString() ?? '';

        Color verdictColor;
        switch (verdict) {
          case 'success':
            verdictColor = Colors.green;
            break;
          case 'failure':
            verdictColor = Colors.red;
            break;
          default:
            verdictColor = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_edu,
                      color: _getObjectiveColor(
                        objective.isNotEmpty ? objective : _selectedObjective,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        role.isNotEmpty ? role : 'Leçon stratégique',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      verdict.toUpperCase(),
                      style: TextStyle(
                        color: verdictColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (notes.isNotEmpty)
                  Text(
                    notes,
                    style: const TextStyle(fontSize: 14),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateNewRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final recommendations = await _marketingService.generateRecommendations(
        objective: _selectedObjective,
        count: 3,
      );

      if (recommendations.isNotEmpty) {
        // Créer une alerte pour les nouvelles recommandations
        await _marketingService.createMarketingAlert(
          alertType: 'new_recommendations',
          message: '${recommendations.length} nouvelles recommandations générées',
        );

        // Recharger les données
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${recommendations.length} recommandations générées !'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  Future<void> _askCommittee() async {
    setState(() => _isLoading = true);
    try {
      final res = await _marketingService.generateCommitteeRecommendation(
        objective: _selectedObjective,
        persist: true,
      );
      if (!mounted) return;
      final summary = res['recommendation_summary']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            summary.isNotEmpty
                ? 'Comité marketing: $summary'
                : 'Recommandation du comité générée',
          ),
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur comité: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Comment utiliser le Studio Marketing ?'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ce module regroupe le cerveau marketing Nexiom en plusieurs volets :',
                ),
                SizedBox(height: 8),
                Text('• M1 — Objectifs : vue d’ensemble des objectifs marketing et de leur progression.'),
                SizedBox(height: 4),
                Text('• M2 — Comité marketing : génération de recommandations stratégiques persistées.'),
                SizedBox(height: 4),
                Text('• M3 — Décision → Publication : l’onglet Recommandations permet d’approuver puis publier en 1 clic.'),
                SizedBox(height: 4),
                Text('• M4 — Analyse algorithmique : utilisée côté Analytics pour expliquer la performance des posts.'),
                SizedBox(height: 4),
                Text('• M5 — Mémoire stratégique : l’onglet Leçons synthétise les outcomes par post et par objectif.'),
                SizedBox(height: 12),
                Text(
                  'Pour un PM/CMO : commencez par vérifier vos objectifs, interrogez le comité, puis validez ou ajustez les recommandations en vous appuyant sur les leçons apprises.',
                ),
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
  }

  IconData _getObjectiveIcon(String objective) {
    switch (objective) {
      case 'notoriety':
        return Icons.trending_up;
      case 'engagement':
        return Icons.favorite;
      case 'conversion':
        return Icons.transform;
      default:
        return Icons.campaign;
    }
  }

  Color _getObjectiveColor(String objective) {
    switch (objective) {
      case 'notoriety':
        return Colors.purple;
      case 'engagement':
        return Colors.orange;
      case 'conversion':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  String _getObjectiveLabel(String objective) {
    switch (objective) {
      case 'notoriety':
        return 'Notoriété';
      case 'engagement':
        return 'Engagement';
      case 'conversion':
        return 'Conversion';
      default:
        return 'Marketing';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
