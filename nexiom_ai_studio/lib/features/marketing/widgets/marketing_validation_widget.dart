import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/marketing_service.dart';
import '../../generator/services/openrouter_service.dart';
import '../../generator/services/media_upload_service.dart';
import '../../generator/services/file_download_helper.dart';
import '../../facebook/services/facebook_service.dart';
import '../../settings/services/settings_service.dart';

class MarketingValidationWidget extends StatefulWidget {
  final MarketingRecommendation recommendation;
  final VoidCallback? onApproved;
  final VoidCallback? onRejected;

  const MarketingValidationWidget({
    super.key,
    required this.recommendation,
    this.onApproved,
    this.onRejected,
  });

  @override
  State<MarketingValidationWidget> createState() => _MarketingValidationWidgetState();
}

class _MarketingValidationWidgetState extends State<MarketingValidationWidget> {
  final MarketingService _marketingService = MarketingService.instance();
  final OpenRouterService _openRouterService = OpenRouterService.instance();
  final FacebookService _facebookService = FacebookService.instance();
  final MediaUploadService _mediaUploadService = MediaUploadService.instance();
  final SettingsService _settingsService = SettingsService.instance();
  bool _isProcessing = false;
  bool _isGeneratingMedia = false;
  bool _isUploadingMedia = false;
  bool _isDownloadingMedia = false;
  String? _error;
  String? _mediaUrl;
  String? _mediaType;
  String? _brandLogoPath;
  String? _brandLogoUrl;
  bool _useBrandLogo = false;
  bool _isLoadingBrandLogo = false;

  @override
  void initState() {
    super.initState();
    _loadBrandLogo();
  }

  Future<Map<String, dynamic>?> _showMediaGenerationDialog({
    required BuildContext context,
    required String initialPrompt,
    required bool isVideo,
    required bool initialUseBrandLogo,
  }) async {
    final TextEditingController promptController =
        TextEditingController(text: initialPrompt);
    bool useBrandLogo = initialUseBrandLogo;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isVideo
              ? 'Préparer la génération de la vidéo IA'
              : 'Préparer la génération de l\'image IA'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Décrivez précisément la scène que vous voulez voir. '
                  'Le Studio appliquera automatiquement le contexte Afrique de l\'Ouest '
                  '(Burkina Faso), des personnes noires, des environnements modestes et '
                  'un texte uniquement en français.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promptController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description de la scène',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: useBrandLogo,
                  onChanged: (value) {
                    if (value == null) return;
                    useBrandLogo = value;
                    (ctx as Element).markNeedsBuild();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Ajouter automatiquement le logo Nexiom/Academia'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final text = promptController.text.trim();
                if (text.isEmpty) {
                  return;
                }
                Navigator.of(ctx).pop(<String, dynamic>{
                  'prompt': text,
                  'useBrandLogo': useBrandLogo,
                });
              },
              child: const Text('Générer'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _loadBrandLogo() async {
    setState(() {
      _isLoadingBrandLogo = true;
    });

    try {
      final path = await _settingsService.getSetting('NEXIOM_BRAND_LOGO_PATH');
      if (!mounted) return;

      if (path != null && path.isNotEmpty) {
        final url = _mediaUploadService.getPublicUrl(path);
        setState(() {
          _brandLogoPath = path;
          _brandLogoUrl = url;
          _useBrandLogo = true;
        });
      } else {
        setState(() {
          _brandLogoPath = null;
          _brandLogoUrl = null;
          _useBrandLogo = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _brandLogoPath = null;
        _brandLogoUrl = null;
        _useBrandLogo = false;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingBrandLogo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec objectif
            Row(
              children: [
                Icon(
                  _getObjectiveIcon(widget.recommendation.objective),
                  color: _getObjectiveColor(widget.recommendation.objective),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objectif: ${_getObjectiveLabel(widget.recommendation.objective)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.recommendation.recommendationSummary,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(widget.recommendation.confidenceLevel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.recommendation.confidenceLevel.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Proposition IA (marketing-brain) – à valider par un humain avant publication.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),

            // Aperçu du post
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getFormatIcon(widget.recommendation.proposedFormat),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.recommendation.proposedFormat.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.recommendation.proposedMessage,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (widget.recommendation.hashtags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.recommendation.hashtags
                          .map(
                            (h) => Chip(
                              label: Text(h),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_mediaUrl != null && _mediaUrl!.isNotEmpty)
                    _buildMediaPreview(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Justification
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.recommendation.reasoning,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Message d'erreur
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _error = null),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Bouton de génération média IA
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed:
                    (_isProcessing || _isGeneratingMedia) ? null : _handleGenerateMedia,
                icon: _isGeneratingMedia
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGeneratingMedia ? 'Génération média IA…' : 'Générer média IA',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: (_isProcessing || _isGeneratingMedia || _isUploadingMedia)
                    ? null
                    : _handleUploadMedia,
                icon: _isUploadingMedia
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  _isUploadingMedia ? 'Upload image…' : 'Uploader une image',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: (_isProcessing || _isGeneratingMedia || _isUploadingMedia || _isDownloadingMedia)
                        ? null
                        : (_mediaUrl == null || _mediaUrl!.isEmpty)
                            ? null
                            : _handleDownloadGeneratedMedia,
                icon: const Icon(Icons.download),
                label: const Text('Télécharger le média IA'),
              ),
            ),
            const SizedBox(height: 8),

            // Boutons d'action OK / REJETER
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog(
                                  title: const Text('Confirmer la publication'),
                                  content: const Text(
                                    'Vous allez approuver cette recommandation et publier immédiatement sur Facebook. Confirmer ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Confirmer'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed == true) {
                              _handleApprove();
                            }
                          },
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_isProcessing ? 'TRAITEMENT...' : '✅ OK – PUBLIER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _handleReject,
                    icon: const Icon(Icons.cancel),
                    label: const Text('❌ REJETER'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isProcessing ? null : _handleSchedule,
                icon: const Icon(Icons.schedule),
                label: const Text('Planifier la publication'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isProcessing ? null : _handleSmartSchedule,
                icon: const Icon(Icons.schedule),
                label: const Text('Planification intelligente (heure optimale)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleApprove() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await _marketingService.approveRecommendation(widget.recommendation.id);

      if (result != null && result['success'] == true) {
        // Succès approbation -> on publie via l'Edge Function Facebook
        String? preparedId;
        try {
          final anyId = result['prepared_post_id'];
          if (anyId is String && anyId.isNotEmpty) {
            preparedId = anyId;
          }
        } catch (_) {}

        if (preparedId == null || preparedId.isEmpty) {
          final prepared = await _marketingService.ensurePreparedPostForRecommendation(
            widget.recommendation.id,
          );

          if (prepared == null || (prepared['id']?.toString().isEmpty ?? true)) {
            if (mounted) {
              setState(() => _error =
                  'Impossible de retrouver le post préparé pour cette recommandation.');
            }
            return;
          }

          preparedId = prepared['id'].toString();
        }

        // 3) Demander un contexte de publication optionnel avant la publication immédiate
        if (preparedId.isNotEmpty) {
          String publicationContext = '';
          final contextController = TextEditingController();
          final contextResult = await showDialog<String>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Contexte de la publication Facebook'),
                content: TextField(
                  controller: contextController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Ex: campagne de rentrée, cible parents 6e, points sensibles à respecter, ton attendu…',
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(''),
                    child: const Text('Ignorer'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(contextController.text.trim()),
                    child: const Text('Enregistrer le contexte'),
                  ),
                ],
              );
            },
          );

          if (contextResult != null) {
            publicationContext = contextResult.trim();
          }

          if (publicationContext.isNotEmpty) {
            await _marketingService.setPublicationContextForPreparedPost(
              preparedPostId: preparedId,
              publicationContext: publicationContext,
            );
          }
        }

        bool publishOk = false;
        String? publishMessage;

        if (preparedId != null) {
          try {
            final publishRes = await _publishPreparedPostViaEdge(
              recommendationId: widget.recommendation.id,
              preparedPostId: preparedId,
            );
            if (publishRes != null) {
              publishOk = (publishRes['success'] == true);
              publishMessage = publishRes['message']?.toString();
            }
          } catch (e) {
            publishOk = false;
            publishMessage = 'Erreur publication: ${e.toString()}';
          }
        }

        widget.onApproved?.call();

        if (!mounted) return;

        if (publishOk) {
          // Cas succès complet : approbation + publication OK
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recommandation approuvée et publiée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Cas où l'approbation a réussi mais la publication Facebook doit être vérifiée
          final baseMessage = publishMessage ??
              'Recommandation approuvée, mais la publication Facebook n\'a pas pu être confirmée.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(baseMessage),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _error = 'Échec de l\'approbation');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleDownloadGeneratedMedia() async {
    final url = _mediaUrl;
    if (url == null || url.isEmpty) {
      return;
    }

    setState(() {
      _isDownloadingMedia = true;
      _error = null;
    });

    try {
      final type = (_mediaType ?? 'image').toLowerCase();
      final extension = type == 'video' ? 'mp4' : 'png';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final baseId = widget.recommendation.id.isNotEmpty
          ? widget.recommendation.id
          : 'media';
      final fileName = 'nexiom_${baseId}_$ts.$extension';

      FileDownloadHelper.downloadFromUrl(fileName, url);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Média IA téléchargé localement.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du téléchargement du média IA: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isDownloadingMedia = false;
      });
    }
  }

  Future<void> _handleSmartSchedule() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // 1) Approuver la recommandation pour créer/associer le prepared_post
      final approveResult =
          await _marketingService.approveRecommendation(widget.recommendation.id);

      if (approveResult == null || approveResult['success'] != true) {
        if (mounted) {
          setState(() =>
              _error = 'Échec de l\'approbation pour la planification intelligente');
        }
        return;
      }

      String? preparedId;
      try {
        final anyId = approveResult['prepared_post_id'];
        if (anyId is String && anyId.isNotEmpty) {
          preparedId = anyId;
        }
      } catch (_) {}

      // 2) S'assurer qu'un prepared_post existe et récupérer son id
      if (preparedId == null || preparedId.isEmpty) {
        final prepared = await _marketingService.ensurePreparedPostForRecommendation(
          widget.recommendation.id,
        );

        if (prepared == null || (prepared['id']?.toString().isEmpty ?? true)) {
          if (mounted) {
            setState(() => _error =
                'Impossible de retrouver le post préparé pour cette recommandation.');
          }
          return;
        }

        preparedId = prepared['id'].toString();
      }

      // 3) Demander un contexte de publication optionnel
      String publicationContext = '';
      final contextController = TextEditingController();
      final contextResult = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Contexte de la publication Facebook'),
            content: TextField(
              controller: contextController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Ex: campagne de rentrée, cible parents 6e, points sensibles à respecter, ton attendu…',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(''),
                child: const Text('Ignorer'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(contextController.text.trim()),
                child: const Text('Enregistrer le contexte'),
              ),
            ],
          );
        },
      );

      if (contextResult != null) {
        publicationContext = contextResult.trim();
      }

      if (publicationContext.isNotEmpty) {
        await _marketingService.setPublicationContextForPreparedPost(
          preparedPostId: preparedId,
          publicationContext: publicationContext,
        );
      }

      // 4) Planification intelligente via le service Facebook (best slots, Africa/Ouagadougou)
      final result = await _facebookService.scheduleSmartPublication(
        preparedPostId: preparedId,
        timezone: 'Africa/Ouagadougou',
        days: 90,
      );

      widget.onApproved?.call();

      if (!mounted) return;

      String message;
      // Afficher l'heure exacte choisie par la planification intelligente si disponible
      final rawComputed = result['computed_scheduled_at'] ?? result['scheduled_at'];
      if (rawComputed is String && rawComputed.isNotEmpty) {
        try {
          final computedAt = DateTime.parse(rawComputed).toLocal();
          final timezone = (result['timezone'] ?? 'Africa/Ouagadougou').toString();
          message =
              'Recommandation approuvée et planifiée automatiquement pour $computedAt (heure $timezone).';
        } catch (_) {
          message = result['message']?.toString() ??
              'Recommandation approuvée et planifiée automatiquement à l\'heure optimale.';
        }
      } else {
        message = result['message']?.toString() ??
            'Recommandation approuvée et planifiée automatiquement à l\'heure optimale.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = 'Erreur planification intelligente: \'${e.toString()}\'');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<DateTime?> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final initialDate = now;
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 30));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 15))),
    );

    if (time == null) return null;

    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      // Si l'heure choisie est dans le passé, on repousse légèrement dans le futur
      return now.add(const Duration(minutes: 5));
    }

    return scheduled;
  }

  Future<void> _handleSchedule() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // 1) Choisir une date/heure de planification
      final scheduledAt = await _pickScheduleDateTime();
      if (scheduledAt == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        return;
      }

      // 2) Approuver la recommandation (création/liaison du prepared_post)
      final approveResult =
          await _marketingService.approveRecommendation(widget.recommendation.id);

      if (approveResult == null || approveResult['success'] != true) {
        if (mounted) {
          setState(() => _error = 'Échec de l\'approbation pour la planification');
        }
        return;
      }

      String? preparedId;
      try {
        final anyId = approveResult['prepared_post_id'];
        if (anyId is String && anyId.isNotEmpty) {
          preparedId = anyId;
        }
      } catch (_) {}

      // 3) S'assurer qu'un prepared_post existe et récupérer son id
      if (preparedId == null || preparedId.isEmpty) {
        final prepared = await _marketingService.ensurePreparedPostForRecommendation(
          widget.recommendation.id,
        );

        if (prepared == null || (prepared['id']?.toString().isEmpty ?? true)) {
          if (mounted) {
            setState(() => _error =
                'Impossible de retrouver le post préparé pour cette recommandation.');
          }
          return;
        }

        preparedId = prepared['id'].toString();
      }

      // 4) Demander un contexte de publication optionnel
      String publicationContext = '';
      final contextController = TextEditingController();
      final contextResult = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Contexte de la publication Facebook'),
            content: TextField(
              controller: contextController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Ex: campagne de rentrée, cible parents 6e, points sensibles à respecter, ton attendu…',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(''),
                child: const Text('Ignorer'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(contextController.text.trim()),
                child: const Text('Enregistrer le contexte'),
              ),
            ],
          );
        },
      );

      if (contextResult != null) {
        publicationContext = contextResult.trim();
      }

      if (publicationContext.isNotEmpty) {
        await _marketingService.setPublicationContextForPreparedPost(
          preparedPostId: preparedId,
          publicationContext: publicationContext,
        );
      }

      // 5) Appeler le service Facebook pour planifier la publication à la date choisie
      await _facebookService.schedulePublication(
        preparedPostId: preparedId,
        scheduledAt: scheduledAt,
        timezone: 'Africa/Ouagadougou',
      );

      widget.onApproved?.call();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recommandation approuvée et planifiée pour ${scheduledAt.toLocal()}',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erreur planification: \'${e.toString()}\'');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleReject() async {
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _error = null;
      });
    }

    try {
      final success = await _marketingService.rejectRecommendation(widget.recommendation.id);
      
      if (success) {
        widget.onRejected?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recommandation rejetée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _error = 'Échec du rejet');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildMediaPreview() {
    if (_mediaUrl == null || _mediaUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final type = (_mediaType ?? 'image').toLowerCase();

    if (type == 'video') {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vidéo IA générée',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        _mediaUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            height: 160,
            alignment: Alignment.center,
            child: const Text('Impossible d\'afficher le média IA'),
          );
        },
      ),
    );
  }

  void _handleGenerateMedia() async {
    setState(() {
      _isGeneratingMedia = true;
      _error = null;
    });

    try {
      final format = widget.recommendation.proposedFormat.toLowerCase();
      final isVideo = format == 'video';

      // Choisir le prompt le plus riche possible pour le média
      String basePrompt = (widget.recommendation.proposedMediaPrompt ?? '').trim();
      if (basePrompt.isEmpty) {
        basePrompt = [
          widget.recommendation.recommendationSummary,
          widget.recommendation.proposedMessage,
        ].where((e) => e.trim().isNotEmpty).join(" \u2014 ");
      }

      if (basePrompt.isEmpty) {
        throw Exception('Prompt média IA vide. Impossible de générer un média.');
      }

      final bool hasBrandLogoConfigured = _brandLogoPath != null && _brandLogoUrl != null;

      final options = await _showMediaGenerationDialog(
        context: context,
        initialPrompt: basePrompt,
        isVideo: isVideo,
        initialUseBrandLogo: hasBrandLogoConfigured,
      );

      if (options == null) {
        if (mounted) {
          setState(() {
            _isGeneratingMedia = false;
          });
        }
        return;
      }

      final String prompt = options['prompt'] as String;
      final bool effectiveUseBrandLogo =
          (options['useBrandLogo'] as bool? ?? false) && hasBrandLogoConfigured;

      // S'assurer qu'un prepared_post existe pour cette recommandation
      final prepared = await _marketingService.ensurePreparedPostForRecommendation(
        widget.recommendation.id,
      );

      if (prepared == null || (prepared['id']?.toString().isEmpty ?? true)) {
        throw Exception('Impossible de préparer le post Facebook pour cette recommandation.');
      }

      final preparedId = prepared['id'].toString();

      String generatedUrl;
      String mediaType;

      if (isVideo) {
        final result = await _openRouterService.generateVideo(
          prompt: prompt,
          durationSeconds: 15,
          useBrandLogo: effectiveUseBrandLogo,
        );
        generatedUrl = result.url;
        mediaType = 'video';
      } else {
        final result = await _openRouterService.generateImage(
          prompt: prompt,
          useBrandLogo: effectiveUseBrandLogo,
        );

        // 1) Télécharger les octets de l'image générée (depuis l'URL OpenRouter/Supabase)
        final Uint8List baseBytes = await FileDownloadHelper.fetchBytes(result.url);

        // 2) Utiliser l'image finale (le logo Nexiom/Academia est désormais composé côté serveur)
        Uint8List finalBytes = baseBytes;

        // 3) Uploader systématiquement l'image finale dans le stockage Supabase
        final String path = await _mediaUploadService.uploadBinaryData(
          finalBytes,
          prefix: 'marketing_posts',
        );
        final String publicUrl = _mediaUploadService.getPublicUrl(path);

        generatedUrl = publicUrl;
        mediaType = 'image';
      }

      // Attacher le média au prepared_post côté Supabase
      final attached = await _marketingService.attachMediaToPreparedPost(
        preparedPostId: preparedId,
        mediaUrl: generatedUrl,
        mediaType: mediaType,
      );

      if (!attached) {
        throw Exception('Le média IA a été généré mais n\'a pas pu être attaché au post préparé.');
      }

      if (!mounted) return;

      setState(() {
        _mediaUrl = generatedUrl;
        _mediaType = mediaType;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVideo
                ? 'Vidéo IA générée et attachée au post préparé.'
                : 'Image IA générée et attachée au post préparé.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingMedia = false;
        });
      }
    }
  }

  void _handleUploadMedia() async {
    setState(() {
      _isUploadingMedia = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      final file = result?.files.first;
      if (file == null) {
        if (mounted) {
          setState(() {
            _isUploadingMedia = false;
          });
        }
        return;
      }

      final prepared = await _marketingService.ensurePreparedPostForRecommendation(
        widget.recommendation.id,
      );

      if (prepared == null || (prepared['id']?.toString().isEmpty ?? true)) {
        throw Exception(
            'Impossible de préparer le post Facebook pour cette recommandation.');
      }

      final preparedId = prepared['id'].toString();

      final path = await _mediaUploadService.uploadReferenceMedia(
        file,
        prefix: 'marketing_posts',
      );
      final publicUrl = _mediaUploadService.getPublicUrl(path);

      final attached = await _marketingService.attachMediaToPreparedPost(
        preparedPostId: preparedId,
        mediaUrl: publicUrl,
        mediaType: 'image',
      );

      if (!attached) {
        throw Exception(
            'L\'image a été uploadée mais n\'a pas pu être attachée au post préparé.');
      }

      if (!mounted) return;

      setState(() {
        _mediaUrl = publicUrl;
        _mediaType = 'image';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploadée et attachée au post préparé.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _publishPreparedPostViaEdge({
    required String recommendationId,
    required String preparedPostId,
  }) async {
    // S'assurer qu'on a bien le prepared_post complet
    final prepared = await _marketingService.ensurePreparedPostForRecommendation(
      recommendationId,
    );

    if (prepared == null || (prepared['id']?.toString().isEmpty ?? true)) {
      return {
        'success': false,
        'message': 'Impossible de retrouver le post préparé pour cette recommandation.',
      };
    }

    final effectivePreparedId = prepared['id']?.toString() ?? preparedPostId;
    String vFinalMessage = prepared['final_message']?.toString() ?? '';
    final mediaUrl = prepared['media_url']?.toString();
    final mediaType = prepared['media_type']?.toString().toLowerCase() ?? 'text';

    // Injecter les hashtags structurés de la recommandation, comme dans publish_prepared_post
    final recHashtags = widget.recommendation.hashtags;
    if (recHashtags.isNotEmpty) {
      final tags = recHashtags
          .map((h) => h.trim())
          .where((h) => h.isNotEmpty)
          .map((h) => h.startsWith('#') ? h : '#$h')
          .toList(growable: false);

      if (tags.isNotEmpty) {
        final tagsStr = tags.join(' ');
        vFinalMessage = (vFinalMessage.isEmpty ? '' : '$vFinalMessage ') + tagsStr;
      }
    }

    // Ajouter la signature Nexiom AI Studio pour cohérence avec la pipeline SQL
    if (vFinalMessage.isNotEmpty) {
      vFinalMessage = vFinalMessage.trim();
    }
    vFinalMessage = '$vFinalMessage\n\nPost réalisé par le studio Nexiom AI, développé par Nexiom Group.';

    String postType = 'text';
    String? imageUrl;
    String? videoUrl;

    if (mediaType == 'image' && mediaUrl != null && mediaUrl.isNotEmpty) {
      postType = 'image';
      imageUrl = mediaUrl;
    } else if (mediaType == 'video' && mediaUrl != null && mediaUrl.isNotEmpty) {
      postType = 'video';
      videoUrl = mediaUrl;
    }

    // Appel de l'Edge Function Facebook réelle
    final fbResponse = await _facebookService.publishPost(
      FacebookPostRequest(
        type: postType,
        message: vFinalMessage,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      ),
    );

    if (!fbResponse.isSuccess || fbResponse.postId == null || fbResponse.postId!.isEmpty) {
      return {
        'success': false,
        'message': fbResponse.error ?? 'La publication Facebook a échoué.',
      };
    }

    // Enregistrer la publication Facebook dans le pipeline SQL (prepared_post, recommandations, etc.)
    final record = await _marketingService.recordFacebookPublicationForPreparedPost(
      preparedPostId: effectivePreparedId,
      facebookPostId: fbResponse.postId!,
      facebookUrl: fbResponse.url ?? '',
    );

    final recordOk = record != null && record['success'] == true;
    final recordMsg = record?['message']?.toString();

    return {
      'success': recordOk,
      'message': recordMsg ??
          (recordOk
              ? 'Publication Facebook enregistrée avec succès.'
              : 'Publication Facebook envoyée, mais enregistrement en base à vérifier.'),
    };
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

  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'video':
        return Icons.video_file;
      case 'image':
        return Icons.image;
      case 'text':
        return Icons.text_fields;
      default:
        return Icons.article;
    }
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
