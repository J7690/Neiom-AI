import 'package:flutter/material.dart';

import '../services/content_job_service.dart';
import '../../generator/services/openrouter_service.dart';

class ContentJobsAdminPage extends StatefulWidget {
  const ContentJobsAdminPage({super.key});

  @override
  State<ContentJobsAdminPage> createState() => _ContentJobsAdminPageState();
}

class _ContentJobsAdminPageState extends State<ContentJobsAdminPage> {
  final _service = ContentJobService.instance();
  final _openRouterService = OpenRouterService.instance();

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _jobs = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _service.listContentJobs(limit: 200);
      final list = res
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);
      // Filtrer principalement les jobs qui nécessitent une validation
      final filtered = list.where((job) {
        final status = (job['status'] ?? '').toString();
        return status == 'generated' || status == 'pending_validation' || status == 'approved';
      }).toList(growable: false);
      setState(() {
        _jobs = filtered;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des content_jobs: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _generateAssetsForJob(Map<String, dynamic> job) async {
    final id = (job['id'] ?? '').toString();
    if (id.isEmpty) return;

    final objective = (job['objective'] ?? 'marketing').toString();
    final format = (job['format'] ?? 'post').toString();

    final prompt =
        'Créer un visuel attractif pour une publication $format sur Facebook, '
        'aligné avec l’objectif marketing "$objective" pour Nexiom/Academia, '
        'destiné à un public africain francophone. Style professionnel, positif, '
        'mettant en valeur les étudiants et la réussite académique.';

    try {
      setState(() => _loading = true);

      final result = await _openRouterService.generateImage(
        prompt: prompt,
        useBrandLogo: true,
      );

      final existingMetadata = (job['metadata'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final updatedMetadata = Map<String, dynamic>.from(existingMetadata);
      updatedMetadata['asset_url'] = result.url;
      updatedMetadata['asset_type'] = 'image';

      await _service.upsertContentJob(
        id: id,
        generationJobId: result.jobId,
        metadata: updatedMetadata,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Média IA généré et lié au content_job'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadJobs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur génération média IA: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runStep(Map<String, dynamic> job, String step) async {
    final id = (job['id'] ?? '').toString();
    if (id.isEmpty) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('orchestrate_content_job_step($step) en cours...')),
    );

    try {
      await _service.orchestrateContentJobStep(contentJobId: id, step: step);
      await _loadJobs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Étape "$step" appliquée au job $id')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec orchestrate_content_job_step($step): $e')),
      );
    }
  }

  Future<void> _inspectJob(Map<String, dynamic> job) async {
    final id = (job['id'] ?? '').toString();
    if (id.isEmpty) return;

    try {
      final res = await _service.orchestrateContentJobStep(
        contentJobId: id,
        step: 'inspect',
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Inspecter le content_job'),
            content: SingleChildScrollView(
              child: Text(
                res.toString(),
                style: const TextStyle(fontSize: 12),
              ),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inspect échec: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_validation':
        return Colors.amber;
      case 'approved':
        return Colors.greenAccent;
      case 'generated':
        return Colors.blueAccent;
      case 'scheduled':
        return Colors.lightBlueAccent;
      case 'published':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _scheduleJob(Map<String, dynamic> job) async {
    final id = job['id'] as String;
    
    // Sélectionner la date de planification
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (!mounted || selectedDate == null) return;
    
    // Sélectionner l'heure
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    
    if (!mounted || selectedTime == null) return;
    
    final scheduleAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    
    try {
      setState(() => _loading = true);
      
      await _service.scheduleContentJob(
        contentJobId: id,
        scheduleAt: scheduleAt,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contenu planifié pour ${scheduleAt.toLocal()}'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadJobs(); // Recharger pour voir le nouveau statut
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur planification: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation contenus (admin)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadJobs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                : _jobs.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun content_job à valider pour le moment.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _jobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final job = _jobs[index];
                          final id = (job['id'] ?? '').toString();
                          final status = (job['status'] ?? '').toString();
                          final format = (job['format'] ?? '').toString();
                          final origin = (job['origin_ui'] ?? '').toString();
                          final createdAt = (job['created_at'] ?? '').toString();
                          final objective = (job['objective'] ?? '').toString();
                          final generationJobId = (job['generation_job_id'] ?? '').toString();
                          final socialPostId = (job['social_post_id'] ?? '').toString();
                          final metadata =
                              (job['metadata'] as Map?)?.cast<String, dynamic>() ??
                                  <String, dynamic>{};
                          final assetUrl = (metadata['asset_url'] ?? '').toString();

                          return Card(
                            color: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        format.isEmpty ? 'format inconnu' : format,
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () => _inspectJob(job),
                                        icon: const Icon(Icons.search, size: 18, color: Colors.white70),
                                        tooltip: 'Inspecter (RPC)',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    objective.isEmpty ? '(Sans objectif explicite)' : objective,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'id=$id',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'origin=$origin | created=$createdAt',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  if (assetUrl.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        assetUrl,
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Text(
                                            'Média IA: $assetUrl',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'generation_job=${generationJobId.isEmpty ? '-' : generationJobId} | post=${socialPostId.isEmpty ? '-' : socialPostId}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: generationJobId.isNotEmpty || _loading
                                            ? null
                                            : () => _generateAssetsForJob(job),
                                        icon: const Icon(Icons.auto_awesome, size: 16),
                                        label: const Text('Générer média IA'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: status == 'approved'
                                            ? null
                                            : () => _runStep(job, 'mark_pending_validation'),
                                        icon: const Icon(Icons.flag_outlined, size: 16),
                                        label: const Text('Marquer à valider'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.icon(
                                        onPressed: status == 'approved'
                                            ? null
                                            : () => _runStep(job, 'mark_approved'),
                                        icon: const Icon(Icons.check_circle_outline, size: 16),
                                        label: const Text('Approuver'),
                                      ),
                                      const SizedBox(width: 8),
                                      if (status == 'approved' && socialPostId.isEmpty)
                                        FilledButton.icon(
                                          onPressed: () => _scheduleJob(job),
                                          icon: const Icon(Icons.schedule, size: 16),
                                          label: const Text('Planifier'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
