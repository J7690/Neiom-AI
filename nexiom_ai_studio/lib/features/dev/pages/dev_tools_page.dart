import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';
import '../../messaging/services/messaging_service.dart';
import '../../publishing/services/social_posts_service.dart';
import '../../publishing/services/content_job_service.dart';
import '../../analytics/services/analytics_service.dart';
import '../../marketing/services/marketing_service.dart';

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  final _msg = MessagingService.instance();
  final _posts = SocialPostsService.instance();
  final _contentJobsService = ContentJobService.instance();
  final _marketingService = MarketingService.instance();

  final _seedCountCtrl = TextEditingController(text: '20');
  final _autoSinceCtrl = TextEditingController(text: '1 hour');
  final _autoLimitCtrl = TextEditingController(text: '50');
  final _routeChannelCtrl = TextEditingController();
  final _routeLimitCtrl = TextEditingController(text: '100');

  final _simChannel = ValueNotifier<String>('whatsapp');
  final _simAuthorIdCtrl = TextEditingController(text: 'wa_demo');
  final _simAuthorNameCtrl = TextEditingController(text: 'Demo User');
  final _simContentCtrl = TextEditingController(text: 'Bonjour, ceci est un test.');

  final _simCommentChannel = ValueNotifier<String>('facebook');
  final _simCommentAuthorIdCtrl = TextEditingController(text: 'fb_user');
  final _simCommentAuthorNameCtrl = TextEditingController(text: 'Alice FB');
  final _simCommentContentCtrl = TextEditingController(text: 'Un commentaire test');

  final _objectiveCtrl = TextEditingController(text: "Annonce Nexiom: nouvelle fonctionnalité RPC-only");
  final _authorAgentCtrl = TextEditingController(text: 'rpc_dev');
  final _timezoneCtrl = TextEditingController(text: 'UTC');
  final _length = ValueNotifier<double>(120);
  final _tone = ValueNotifier<String>('neutre');
  final _genPreview = ValueNotifier<String>('');
  final _scheduleMinutesCtrl = TextEditingController(text: '1');
  final _pipelineSinceCtrl = TextEditingController(text: '1 hour');
  final _pipelineLimitCtrl = TextEditingController(text: '100');
  final _planDaysCtrl = TextEditingController(text: '7');
  final _activityLimitCtrl = TextEditingController(text: '50');
  final _timeseriesDaysCtrl = TextEditingController(text: '7');
  final _settingKeyCtrl = TextEditingController();
  final _settingValueCtrl = TextEditingController();
  final _alertEmailsCtrl = TextEditingController(text: 'ops@nexiom.local');
  final _advisorEmailsCtrl = TextEditingController(text: 'ops@nexiom.local, marketing@nexiom.local');
  final _postIdCtrl = TextEditingController();
  final _queueLimitCtrl = TextEditingController(text: '10');
  final _contentJobIdCtrl = TextEditingController();
  final _orchestratorChannelCtrl = TextEditingController(text: 'facebook');
  final _orchestratorMaxPerDayCtrl = TextEditingController(text: '5');
  final _orchestratorDateCtrl = TextEditingController();
  final _orchestratorTimezoneCtrl = TextEditingController(text: 'UTC');

  final Set<String> _seedChannels = {'whatsapp','facebook','instagram','tiktok','youtube'};
  final Set<String> _postChannels = {'facebook','instagram'};

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _pipeline;
  Map<String, dynamic>? _settings;
  Map<String, dynamic>? _plan;
  Map<String, dynamic>? _activity;
  List<dynamic>? _timeseries;
  String? _status;

  bool _busySeed = false;
  bool _busyAuto = false;
  bool _busyRoute = false;
  bool _busySim = false;
  bool _busySimComment = false;
  bool _busySuggest = false;
  bool _busyCreateSchedule = false;
  bool _busyRunSchedules = false;
  bool _busyMetrics = false;
  bool _busyStats = false;
  bool _busyPipeline = false;
  bool _busySettings = false;
  bool _busyPlan = false;
  bool _busyActivity = false;
  bool _busyTimeseries = false;
  bool _busyUpsert = false;
  bool _busyPublishPost = false;
  bool _busyEnqueue = false;
  bool _busyRunQueue = false;
  bool _busyAlertRules = false;
  bool _busyNotifyAlerts = false;
  bool _busyAdvisorGenerate = false;
  bool _busyAdvisorSend = false;
  bool _busyContentJobs = false;
   bool _busyGlobalOrchestrator = false;
  String _advisorPreview = '';

  List<Map<String, dynamic>>? _contentJobs;
  String? _contentJobOrchestratorOutput;
  String? _globalOrchestratorOutput;

  List<String> get allChannels => const ['whatsapp','facebook','instagram','tiktok','youtube'];
  List<String> get tones => const ['neutre','enthousiaste','professionnel','convivial'];

  void _setStatus(String s) { setState(() { _status = s; }); }

  Future<void> _doLoadContentJobs() async {
    setState(() { _busyContentJobs = true; });
    try {
      final res = await _contentJobsService.listContentJobs(limit: 100);
      final list = res
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);
      setState(() {
        _contentJobs = list;
      });
      _setStatus('Content jobs chargés (${list.length})');
    } catch (e) {
      _setStatus('Chargement content_jobs échec: $e');
    } finally {
      if (mounted) {
        setState(() { _busyContentJobs = false; });
      }
    }
  }

  Future<void> _doRunGlobalOrchestrator() async {
    setState(() {
      _busyGlobalOrchestrator = true;
      _globalOrchestratorOutput = null;
    });
    try {
      final channel = _orchestratorChannelCtrl.text.trim().isEmpty
          ? 'facebook'
          : _orchestratorChannelCtrl.text.trim();
      final maxPerDay = int.tryParse(_orchestratorMaxPerDayCtrl.text.trim()) ?? 5;
      final rawDate = _orchestratorDateCtrl.text.trim();
      DateTime? date;
      if (rawDate.isNotEmpty) {
        date = DateTime.tryParse(rawDate);
      }
      final timezone = _orchestratorTimezoneCtrl.text.trim().isEmpty
          ? 'UTC'
          : _orchestratorTimezoneCtrl.text.trim();

      final res = await _marketingService.orchestrateGlobalPublishing(
        channel: channel,
        date: date,
        maxPostsPerDay: maxPerDay,
        timezone: timezone,
      );

      setState(() {
        _globalOrchestratorOutput = res.toString();
      });

      final jobs = res['jobs_scheduled'];
      _setStatus('orchestrate_global_publishing OK (${jobs ?? 0} jobs)');
    } catch (e) {
      _setStatus('orchestrate_global_publishing chec: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busyGlobalOrchestrator = false;
        });
      }
    }
  }

  Future<void> _doOrchestrateContentJobStep(String step) async {
    final id = _contentJobIdCtrl.text.trim();
    if (id.isEmpty) {
      _setStatus('ContentJobId requis pour l\'orchestration');
      return;
    }

    setState(() { _busyContentJobs = true; });
    try {
      final res = await _contentJobsService.orchestrateContentJobStep(
        contentJobId: id,
        step: step,
      );
      setState(() {
        _contentJobOrchestratorOutput = res.toString();
      });
      _setStatus('orchestrate_content_job_step($step) OK');
    } catch (e) {
      _setStatus('orchestrate_content_job_step($step) échec: $e');
    } finally {
      if (mounted) {
        setState(() { _busyContentJobs = false; });
      }
    }
  }

  Future<void> _doSeed() async {
    setState(() { _busySeed = true; });
    try {
      final count = int.tryParse(_seedCountCtrl.text.trim()) ?? 10;
      final n = await _msg.seedRandomMessages(channels: _seedChannels.toList(), count: count);
      _setStatus('Seed: $n messages injectés');
    } catch (e) {
      _setStatus('Seed échec: $e');
    } finally { if (mounted) setState(() { _busySeed = false; }); }
  }

  Future<void> _doGenerateAdvisorReport() async {
    setState(() { _busyAdvisorGenerate = true; _advisorPreview = ''; });
    try {
      final weekly = await AnalyticsService.instance().getReportWeekly();
      final period = (weekly['period'] as Map?)?.cast<String, dynamic>() ?? {};
      final summary = (weekly['summary'] as Map?)?.cast<String, dynamic>() ?? {};
      final topPosts = (weekly['top_posts'] as List?) ?? const [];
      final bestHours = (weekly['best_hours'] as List?) ?? const [];

      final buf = StringBuffer();
      buf.writeln('Rapport hebdomadaire Nexiom — Période: ${period.toString()}');
      buf.writeln('KPI: IN=${summary['messages_in'] ?? 0}, OUT=${summary['messages_out'] ?? 0}, Posts=${summary['posts_created'] ?? 0}, Leads=${summary['leads'] ?? 0}');
      buf.writeln('Top posts:');
      for (final e in topPosts.take(5)) {
        final m = (e as Map).cast<String, dynamic>();
        buf.writeln('- Score ${m['score'] ?? 0}: ${(m['content'] ?? '').toString()}');
      }
      buf.writeln('Meilleures heures (planning):');
      for (final e in bestHours.take(8)) {
        final m = (e as Map).cast<String, dynamic>();
        buf.writeln('- Heure ${m['hour'] ?? ''}: ${m['count'] ?? 0}');
      }
      buf.writeln('Recommandations:');
      buf.writeln('- Booster les contenus top 3 sur Facebook/Instagram dès réception des clés.');
      buf.writeln('- Planifier +2 posts sur les plages horaires top.');
      buf.writeln('- Mettre en avant les programmes les plus demandés en WhatsApp.');

      setState(() { _advisorPreview = buf.toString(); });
      _setStatus('Rapport hebdo généré');
    } catch (e) {
      _setStatus('Génération rapport hebdo échec: $e');
    } finally { if (mounted) setState(() { _busyAdvisorGenerate = false; }); }
  }

  Future<void> _doSendAdvisorReport() async {
    if (_advisorPreview.trim().isEmpty) { _setStatus('Générer le rapport avant envoi'); return; }
    setState(() { _busyAdvisorSend = true; });
    try {
      final emails = _advisorEmailsCtrl.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
      final weekly = await AnalyticsService.instance().getReportWeekly();
      final period = (weekly['period'] as Map?)?.cast<String, dynamic>() ?? {};
      final n = await AnalyticsService.instance().notifyWeeklyReport(emails: emails, body: _advisorPreview, period: period);
      _setStatus('Rapport hebdo envoyé (stub): $n destinataires');
    } catch (e) {
      _setStatus('Envoi rapport hebdo échec: $e');
    } finally { if (mounted) setState(() { _busyAdvisorSend = false; }); }
  }

  Future<void> _doRunAlertRules() async {
    setState(() { _busyAlertRules = true; });
    try {
      final n = await AnalyticsService.instance().runAlertRules();
      _setStatus('Alert rules exécutées: $n alertes générées');
    } catch (e) {
      _setStatus('Alert rules échec: $e');
    } finally { if (mounted) setState(() { _busyAlertRules = false; }); }
  }

  Future<void> _doNotifyAlerts() async {
    setState(() { _busyNotifyAlerts = true; });
    try {
      final emails = _alertEmailsCtrl.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
      final n = await AnalyticsService.instance().notifyRecentAlerts(emails: emails);
      _setStatus('Notifications envoyées (stub): $n alertes');
    } catch (e) {
      _setStatus('Notify alerts échec: $e');
    } finally { if (mounted) setState(() { _busyNotifyAlerts = false; }); }
  }

  Future<void> _doPublishPost() async {
    setState(() { _busyPublishPost = true; });
    try {
      final id = _postIdCtrl.text.trim();
      if (id.isEmpty) { _setStatus('PostId requis'); return; }
      final res = await _posts.publishPost(postId: id);
      _setStatus('publish_post: $res');
    } catch (e) {
      _setStatus('publish_post échec: $e');
    } finally { if (mounted) setState(() { _busyPublishPost = false; }); }
  }

  Future<void> _doEnqueuePost() async {
    setState(() { _busyEnqueue = true; });
    try {
      final id = _postIdCtrl.text.trim();
      if (id.isEmpty) { _setStatus('PostId requis'); return; }
      final n = await _posts.enqueuePublishForPost(postId: id);
      _setStatus('enqueue: $n entrées');
    } catch (e) {
      _setStatus('enqueue échec: $e');
    } finally { if (mounted) setState(() { _busyEnqueue = false; }); }
  }

  Future<void> _doRunQueue() async {
    setState(() { _busyRunQueue = true; });
    try {
      final limit = int.tryParse(_queueLimitCtrl.text.trim()) ?? 10;
      final n = await _posts.runPublishQueueOnce(limit: limit);
      _setStatus('run_queue: $n items traités');
    } catch (e) {
      _setStatus('run_queue échec: $e');
    } finally { if (mounted) setState(() { _busyRunQueue = false; }); }
  }

  Future<void> _doAutoReply() async {
    setState(() { _busyAuto = true; });
    try {
      final limit = int.tryParse(_autoLimitCtrl.text.trim()) ?? 50;
      final n = await _msg.autoReplyRecentInbound(since: _autoSinceCtrl.text.trim().isEmpty ? null : _autoSinceCtrl.text.trim(), limit: limit);
      _setStatus('Auto-reply: $n réponses envoyées');
    } catch (e) {
      _setStatus('Auto-reply échec: $e');
    } finally { if (mounted) setState(() { _busyAuto = false; }); }
  }

  Future<void> _doRoute() async {
    setState(() { _busyRoute = true; });
    try {
      final limit = int.tryParse(_routeLimitCtrl.text.trim()) ?? 100;
      final ch = _routeChannelCtrl.text.trim().isEmpty ? null : _routeChannelCtrl.text.trim();
      final n = await _msg.routeUnroutedEvents(channel: ch, limit: limit);
      _setStatus('Routage: $n événements traités');
    } catch (e) {
      _setStatus('Routage échec: $e');
    } finally { if (mounted) setState(() { _busyRoute = false; }); }
  }

  Future<void> _doSimMessage() async {
    setState(() { _busySim = true; });
    try {
      final res = await _msg.simulateMessage(
        channel: _simChannel.value,
        authorId: _simAuthorIdCtrl.text.trim(),
        authorName: _simAuthorNameCtrl.text.trim(),
        content: _simContentCtrl.text.trim(),
      );
      _setStatus('Simulation message OK: ${res.toString()}');
    } catch (e) {
      _setStatus('Simulation message échec: $e');
    } finally { if (mounted) setState(() { _busySim = false; }); }
  }

  Future<void> _doSimComment() async {
    setState(() { _busySimComment = true; });
    try {
      final res = await Supabase.instance.client.rpc('simulate_comment', params: {
        'p_channel': _simCommentChannel.value,
        'p_author_id': _simCommentAuthorIdCtrl.text.trim(),
        'p_author_name': _simCommentAuthorNameCtrl.text.trim(),
        'p_content': _simCommentContentCtrl.text.trim(),
      });
      _setStatus('Simulation commentaire OK: ${res.toString()}');
    } catch (e) {
      _setStatus('Simulation commentaire échec: $e');
    } finally { if (mounted) setState(() { _busySimComment = false; }); }
  }

  Future<void> _doSuggest() async {
    setState(() { _busySuggest = true; });
    try {
      final txt = await _posts.suggestContentStub(
        objective: _objectiveCtrl.text.trim(),
        tone: _tone.value,
        length: _length.value.toInt(),
      );
      _genPreview.value = txt;
      _setStatus('Suggestion générée');
    } catch (e) {
      _setStatus('Suggestion échec: $e');
    } finally { if (mounted) setState(() { _busySuggest = false; }); }
  }

  Future<void> _doCreateAndSchedule() async {
    setState(() { _busyCreateSchedule = true; });
    try {
      final mins = int.tryParse(_scheduleMinutesCtrl.text.trim()) ?? 1;
      final when = DateTime.now().toUtc().add(Duration(minutes: mins));
      final res = await _posts.createAndSchedulePostStub(
        authorAgent: _authorAgentCtrl.text.trim(),
        objective: _objectiveCtrl.text.trim(),
        targetChannels: _postChannels.toList(),
        scheduleAt: when,
        timezone: _timezoneCtrl.text.trim(),
        tone: _tone.value,
        length: _length.value.toInt(),
      );
      _setStatus('Créé et planifié: ${res.toString()}');
    } catch (e) {
      _setStatus('Création/planification échec: $e');
    } finally { if (mounted) setState(() { _busyCreateSchedule = false; }); }
  }

  Future<void> _doRunSchedules() async {
    setState(() { _busyRunSchedules = true; });
    try {
      final n = await _msg.runSchedulesOnce();
      _setStatus('Planifications exécutées: $n');
    } catch (e) {
      _setStatus('Exécution planifications échec: $e');
    } finally { if (mounted) setState(() { _busyRunSchedules = false; }); }
  }

  Future<void> _doCollectMetrics() async {
    setState(() { _busyMetrics = true; });
    try {
      final n = await _msg.collectMetricsStub();
      _setStatus('Collecte métriques: $n');
    } catch (e) {
      _setStatus('Collecte métriques échec: $e');
    } finally { if (mounted) setState(() { _busyMetrics = false; }); }
  }

  Future<void> _doStats() async {
    setState(() { _busyStats = true; });
    try {
      final res = await _msg.getPipelineStats();
      setState(() { _stats = res; });
      _setStatus('Stats mises à jour');
    } catch (e) {
      _setStatus('Stats échec: $e');
    } finally { if (mounted) setState(() { _busyStats = false; }); }
  }

  Future<void> _doRunPipeline() async {
    setState(() { _busyPipeline = true; });
    try {
      final limit = int.tryParse(_pipelineLimitCtrl.text.trim()) ?? 100;
      final res = await _msg.runPipelineOnce(
        since: _pipelineSinceCtrl.text.trim().isEmpty ? null : _pipelineSinceCtrl.text.trim(),
        limit: limit,
      );
      setState(() { _pipeline = res; });
      _setStatus('Pipeline exécuté');
    } catch (e) {
      _setStatus('Pipeline échec: $e');
    } finally { if (mounted) setState(() { _busyPipeline = false; }); }
  }

  Future<void> _doSettings() async {
    setState(() { _busySettings = true; });
    try {
      final res = await _msg.settingsOverview();
      setState(() { _settings = res; });
      _setStatus('Réglages récupérés');
    } catch (e) {
      _setStatus('Réglages échec: $e');
    } finally { if (mounted) setState(() { _busySettings = false; }); }
  }

  Future<void> _doPlan() async {
    setState(() { _busyPlan = true; });
    try {
      final days = int.tryParse(_planDaysCtrl.text.trim()) ?? 7;
      final res = await _posts.createEditorialPlanStub(
        authorAgent: _authorAgentCtrl.text.trim(),
        objective: _objectiveCtrl.text.trim(),
        startDate: DateTime.now().toUtc(),
        days: days,
        channels: _postChannels.toList(),
        timezone: _timezoneCtrl.text.trim(),
        tone: _tone.value,
        length: _length.value.toInt(),
      );
      setState(() { _plan = res; });
      _setStatus('Plan éditorial généré');
    } catch (e) {
      _setStatus('Plan éditorial échec: $e');
    } finally { if (mounted) setState(() { _busyPlan = false; }); }
  }

  Future<void> _doActivity() async {
    setState(() { _busyActivity = true; });
    try {
      final limit = int.tryParse(_activityLimitCtrl.text.trim()) ?? 50;
      final res = await _msg.getRecentActivity(limit: limit);
      setState(() { _activity = res; });
      _setStatus('Activité récente mise à jour');
    } catch (e) {
      _setStatus('Activité récente échec: $e');
    } finally { if (mounted) setState(() { _busyActivity = false; }); }
  }

  Future<void> _doTimeseries() async {
    setState(() { _busyTimeseries = true; });
    try {
      final days = int.tryParse(_timeseriesDaysCtrl.text.trim()) ?? 7;
      final res = await _msg.getMetricsTimeseries(days: days);
      setState(() { _timeseries = res; });
      _setStatus('Timeseries mises à jour');
    } catch (e) {
      _setStatus('Timeseries échec: $e');
    } finally { if (mounted) setState(() { _busyTimeseries = false; }); }
  }

  Future<void> _doUpsertSetting() async {
    setState(() { _busyUpsert = true; });
    try {
      final ok = await _msg.upsertSetting(key: _settingKeyCtrl.text.trim(), value: _settingValueCtrl.text.trim());
      if (ok) {
        await _doSettings();
        _setStatus('Réglage enregistré');
      } else {
        _setStatus('Échec enregistrement réglage');
      }
    } catch (e) {
      _setStatus('Upsert réglage échec: $e');
    } finally { if (mounted) setState(() { _busyUpsert = false; }); }
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _channelsChips(Set<String> set, void Function(String, bool) onSel) {
    return Wrap(
      spacing: 8,
      children: allChannels.map((ch) {
        final selected = set.contains(ch);
        return FilterChip(
          label: Text(ch, style: TextStyle(color: selected ? Colors.black : Colors.white)),
          selected: selected,
          onSelected: (v) => setState(() => onSel(ch, v)),
          selectedColor: Colors.cyanAccent,
          backgroundColor: const Color(0xFF1E293B),
        );
      }).toList(),
    );
  }

  Widget _tonesChips() {
    return Wrap(
      spacing: 8,
      children: tones.map((t) {
        return ValueListenableBuilder<String>(
          valueListenable: _tone,
          builder: (_, val, __) {
            final selected = val == t;
            return ChoiceChip(
              label: Text(t, style: TextStyle(color: selected ? Colors.black : Colors.white)),
              selected: selected,
              onSelected: (_) => _tone.value = t,
              selectedColor: Colors.cyanAccent,
              backgroundColor: const Color(0xFF1E293B),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outils Dev – Pipeline RPC'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text(_status!, style: const TextStyle(color: Colors.white70))),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Seed & Auto-réponse'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Canaux à peupler', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              _channelsChips(_seedChannels, (ch, v) { v ? _seedChannels.add(ch) : _seedChannels.remove(ch); }),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _seedCountCtrl, decoration: const InputDecoration(hintText: 'Nombre de messages'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busySeed ? null : _doSeed, child: _busySeed ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Seed')),
              ]),
              const Divider(),
              Row(children: [
                Expanded(child: TextField(controller: _autoSinceCtrl, decoration: const InputDecoration(hintText: "Fenêtre ex: '1 hour'"), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _autoLimitCtrl, decoration: const InputDecoration(hintText: 'Limite'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyAuto ? null : _doAutoReply, child: _busyAuto ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Auto-reply')),
              ]),
            ])),

            _sectionTitle('Publication (queue)'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: TextField(controller: _postIdCtrl, decoration: const InputDecoration(hintText: 'Post ID'), style: const TextStyle(color: Colors.white)) ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyPublishPost ? null : _doPublishPost, child: _busyPublishPost ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('publish_post')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _queueLimitCtrl, decoration: const InputDecoration(hintText: 'Limite run queue'), style: const TextStyle(color: Colors.white)) ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyEnqueue ? null : _doEnqueuePost, child: _busyEnqueue ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('enqueue')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyRunQueue ? null : _doRunQueue, child: _busyRunQueue ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('run_queue')),
              ]),
            ])),

            _sectionTitle('Pipeline (1 clic)'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: TextField(controller: _pipelineSinceCtrl, decoration: const InputDecoration(hintText: "Fenêtre ex: '1 hour'"), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _pipelineLimitCtrl, decoration: const InputDecoration(hintText: 'Limite'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyPipeline ? null : _doRunPipeline, child: _busyPipeline ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Exécuter pipeline')),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Text((_pipeline ?? {}).toString(), style: const TextStyle(color: Colors.white70)),
              ),
            ])),

            _sectionTitle('Content jobs (lecture seule)'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ElevatedButton(
                  onPressed: _busyContentJobs ? null : _doLoadContentJobs,
                  child: _busyContentJobs
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Rafraîchir content_jobs'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _contentJobIdCtrl,
                    decoration: const InputDecoration(
                      hintText: 'ContentJob ID pour orchestration',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton(
                  onPressed: _busyContentJobs ? null : () => _doOrchestrateContentJobStep('inspect'),
                  child: const Text('Inspect'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _busyContentJobs
                      ? null
                      : () => _doOrchestrateContentJobStep('mark_pending_validation'),
                  child: const Text('Mark pending_validation'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _busyContentJobs
                      ? null
                      : () => _doOrchestrateContentJobStep('mark_approved'),
                  child: const Text('Mark approved'),
                ),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_contentJobs == null)
                      const Text('Aucune donnée chargée', style: TextStyle(color: Colors.white70))
                    else if (_contentJobs!.isEmpty)
                      const Text('Aucun content_job trouvé', style: TextStyle(color: Colors.white70))
                    else
                      ..._contentJobs!.take(50).map((job) {
                        final id = (job['id'] ?? '').toString();
                        final status = (job['status'] ?? '').toString();
                        final format = (job['format'] ?? '').toString();
                        final origin = (job['origin_ui'] ?? '').toString();
                        final createdAt = (job['created_at'] ?? '').toString();
                        final objective = (job['objective'] ?? '').toString();
                        final generationJobId = (job['generation_job_id'] ?? '').toString();
                        final socialPostId = (job['social_post_id'] ?? '').toString();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${id.substring(0, id.length > 8 ? 8 : id.length)} | '
                            '$status | $format | origin=$origin | created=$createdAt\n'
                            '  objective=${objective.isEmpty ? '-' : objective}\n'
                            '  genJob=${generationJobId.isEmpty ? '-' : generationJobId} | post=${socialPostId.isEmpty ? '-' : socialPostId}',
                            style: const TextStyle(color: Colors.white70, height: 1.3),
                          ),
                        );
                      }).toList(),
                    if (_contentJobOrchestratorOutput != null) ...[
                      const SizedBox(height: 12),
                      const Text('Dernier résultat orchestrateur:', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(
                        _contentJobOrchestratorOutput!,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ])),

            _sectionTitle('Orchestrateur global (missions)'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _orchestratorChannelCtrl,
                    decoration: const InputDecoration(hintText: 'Canal (ex: facebook)'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _orchestratorMaxPerDayCtrl,
                    decoration: const InputDecoration(hintText: 'Max posts / jour'),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _orchestratorDateCtrl,
                    decoration: const InputDecoration(hintText: 'Date (YYYY-MM-DD, optionnel)'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _orchestratorTimezoneCtrl,
                    decoration: const InputDecoration(hintText: 'Timezone (ex: Africa/Ouagadougou)'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _busyGlobalOrchestrator ? null : _doRunGlobalOrchestrator,
                  child: _busyGlobalOrchestrator
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Orchestrer'),
                ),
              ]),
              const SizedBox(height: 8),
              if (_globalOrchestratorOutput != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _globalOrchestratorOutput!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ])),

            _sectionTitle('Plan éditorial (stub)'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: TextField(controller: _planDaysCtrl, decoration: const InputDecoration(hintText: 'Nombre de jours'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyPlan ? null : _doPlan, child: _busyPlan ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Générer plan')),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Text((_plan ?? {}).toString(), style: const TextStyle(color: Colors.white70)),
              ),
            ])),

            _sectionTitle('Activité récente'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: TextField(controller: _activityLimitCtrl, decoration: const InputDecoration(hintText: 'Limite'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyActivity ? null : _doActivity, child: _busyActivity ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Rafraîchir')),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Text((_activity ?? {}).toString(), style: const TextStyle(color: Colors.white70)),
              ),
            ])),

            _sectionTitle('Métriques – timeseries (jours)'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: TextField(controller: _timeseriesDaysCtrl, decoration: const InputDecoration(hintText: 'Jours'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyTimeseries ? null : _doTimeseries, child: _busyTimeseries ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Rafraîchir')),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Text(((_timeseries ?? [])).toString(), style: const TextStyle(color: Colors.white70)),
              ),
            ])),

            _sectionTitle('Routage des événements'),
            _card(Row(children: [
              Expanded(child: TextField(controller: _routeChannelCtrl, decoration: const InputDecoration(hintText: 'Canal (optionnel)'), style: const TextStyle(color: Colors.white))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _routeLimitCtrl, decoration: const InputDecoration(hintText: 'Limite'), style: const TextStyle(color: Colors.white))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _busyRoute ? null : _doRoute, child: _busyRoute ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Router')),
            ])),

            _sectionTitle('Simulation ciblée'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                DropdownButton<String>(
                  value: _simChannel.value,
                  dropdownColor: const Color(0xFF1E293B),
                  items: allChannels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) { if (v!=null) setState(() { _simChannel.value = v; }); },
                ),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _simAuthorIdCtrl, decoration: const InputDecoration(hintText: 'Auteur ID'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _simAuthorNameCtrl, decoration: const InputDecoration(hintText: 'Auteur nom'), style: const TextStyle(color: Colors.white))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _simContentCtrl, decoration: const InputDecoration(hintText: 'Contenu'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busySim ? null : _doSimMessage, child: _busySim ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Simuler message')),
              ]),
              const Divider(),
              Row(children: [
                DropdownButton<String>(
                  value: _simCommentChannel.value,
                  dropdownColor: const Color(0xFF1E293B),
                  items: allChannels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) { if (v!=null) setState(() { _simCommentChannel.value = v; }); },
                ),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _simCommentAuthorIdCtrl, decoration: const InputDecoration(hintText: 'Auteur ID'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _simCommentAuthorNameCtrl, decoration: const InputDecoration(hintText: 'Auteur nom'), style: const TextStyle(color: Colors.white))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _simCommentContentCtrl, decoration: const InputDecoration(hintText: 'Contenu'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busySimComment ? null : _doSimComment, child: _busySimComment ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Simuler commentaire')),
              ]),
            ])),

            _sectionTitle('Publication stub'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Canaux du post', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              _channelsChips(_postChannels, (ch, v) { v ? _postChannels.add(ch) : _postChannels.remove(ch); }),
              const SizedBox(height: 8),
              _tonesChips(),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _objectiveCtrl, decoration: const InputDecoration(hintText: 'Objectif'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: ValueListenableBuilder<double>(
                  valueListenable: _length,
                  builder: (_, val, __) {
                    return Row(children: [
                      const Text('Longueur', style: TextStyle(color: Colors.white70)),
                      Expanded(child: Slider(value: val, min: 60, max: 240, divisions: 18, label: '${val.toInt()}', onChanged: (v) => setState(() { _length.value = v; })))
                    ]);
                  },
                )),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _authorAgentCtrl, decoration: const InputDecoration(hintText: 'Auteur agent'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _scheduleMinutesCtrl, decoration: const InputDecoration(hintText: 'Planifier dans (minutes)'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _timezoneCtrl, decoration: const InputDecoration(hintText: 'Timezone'), style: const TextStyle(color: Colors.white))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton(onPressed: _busySuggest ? null : _doSuggest, child: _busySuggest ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Suggérer')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyCreateSchedule ? null : _doCreateAndSchedule, child: _busyCreateSchedule ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Créer + Planifier')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyRunSchedules ? null : _doRunSchedules, child: _busyRunSchedules ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Exécuter planifs')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyMetrics ? null : _doCollectMetrics, child: _busyMetrics ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Collecter métriques')),
              ]),
              const SizedBox(height: 8),
              ValueListenableBuilder<String>(
                valueListenable: _genPreview,
                builder: (_, val, __) {
                  if (val.isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: Text(val, style: const TextStyle(color: Colors.white)),
                  );
                },
              ),
            ])),

            _sectionTitle('Observabilité'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ElevatedButton(onPressed: _busyStats ? null : _doStats, child: _busyStats ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Rafraîchir stats')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.messaging), child: const Text('Voir conversations')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busySettings ? null : _doSettings, child: _busySettings ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Réglages')),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Text(_stats?.toString() ?? '{}', style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Text(_settings?.toString() ?? '{}', style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _settingKeyCtrl, decoration: const InputDecoration(hintText: 'Clé'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _settingValueCtrl, decoration: const InputDecoration(hintText: 'Valeur'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyUpsert ? null : _doUpsertSetting, child: _busyUpsert ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Enregistrer réglage')),
              ]),
            ])),

            _sectionTitle('Alertes (règles & notifications)'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ElevatedButton(onPressed: _busyAlertRules ? null : _doRunAlertRules, child: _busyAlertRules ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Exécuter règles')),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _alertEmailsCtrl, decoration: const InputDecoration(hintText: 'Emails (comma)'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyNotifyAlerts ? null : _doNotifyAlerts, child: _busyNotifyAlerts ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Notifier (stub)')),
              ]),
            ])),

            _sectionTitle('Advisor (rapport hebdo IA)'),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ElevatedButton(onPressed: _busyAdvisorGenerate ? null : _doGenerateAdvisorReport, child: _busyAdvisorGenerate ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Générer')),                
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _advisorEmailsCtrl, decoration: const InputDecoration(hintText: 'Destinataires (comma)'), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _busyAdvisorSend ? null : _doSendAdvisorReport, child: _busyAdvisorSend ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Envoyer (stub)')),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                child: Text(_advisorPreview.isEmpty ? 'Aucun rapport généré pour l’instant.' : _advisorPreview, style: const TextStyle(color: Colors.white70)),
              )
            ])),
          ],
        ),
      ),
    );
  }
}
