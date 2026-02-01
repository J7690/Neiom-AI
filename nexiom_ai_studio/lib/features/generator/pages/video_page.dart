import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../settings/services/settings_service.dart';
import '../../publishing/services/content_job_service.dart';
import '../models/generation_result.dart';
import '../models/text_template.dart';
import '../models/voice_profile.dart';
import '../models/avatar_profile.dart';
import '../services/ffmpeg_wasm_service_web.dart';
import '../services/file_download_helper.dart';
import '../services/media_upload_service.dart';
import '../services/openrouter_service.dart';
import '../services/orchestrated_video_service.dart';
import '../services/video_brief_service.dart';
import '../services/voice_profile_service.dart';
import '../services/avatar_profile_service.dart';
import '../widgets/loader.dart';
import '../widgets/prompt_input.dart';
import '../widgets/result_viewer.dart';
import 'text_templates_page.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final _promptController = TextEditingController();
  final _voiceScriptController = TextEditingController();
  final _negativePromptController = TextEditingController();
  final _storyboardController = TextEditingController();
  final _shotListController = TextEditingController();
  final _dialoguesController = TextEditingController();
  final _locationController = TextEditingController();
  final _environmentController = TextEditingController();
  final _charactersController = TextEditingController();
  final _cameraController = TextEditingController();
  final _lightingController = TextEditingController();
  final _actionController = TextEditingController();
  final _styleController = TextEditingController();
  final _service = OpenRouterService.instance();
  final _orchestratedService = OrchestratedVideoService.instance();
  final _uploadService = MediaUploadService.instance();
  final _voiceProfileService = VoiceProfileService.instance();
  final _videoBriefService = VideoBriefService.instance();
  final _ffmpegService = FfmpegWasmServiceWeb.instance();
  final _settingsService = SettingsService.instance();
  final _avatarService = AvatarProfileService.instance();
  final _contentJobService = ContentJobService.instance();

  bool _isGenerating = false;
  bool _isMergingFinal = false;
  GenerationResult? _result;
  Uint8List? _finalMp4Bytes;
  bool _hasFinalMp4 = false;
  String? _error;
  int _duration = 20;
  bool _adaptDurationToVoiceScript = false;
  int? _estimatedVoiceDurationSeconds;
  String _qualityTier = 'standard';
  String _provider = 'auto';
  bool _useOrchestrator = false;
  String? _selectedVideoModel;
  String? _referenceMediaPath;
  String? _referenceFileName;
  String? _faceReferencePath;
  String? _faceReferenceFileName;
  bool _enableFaceLock = false;
  List<VoiceProfile> _voiceProfiles = [];
  String? _selectedVoiceProfileId;
  bool _isLoadingVoices = false;
  List<AvatarProfile> _avatarProfiles = [];
  bool _isLoadingAvatars = false;
  String? _selectedAvatarId;
  bool _didInitFromArgs = false;
  String? _lastJobId;

  String? _brandLogoPath;
  String? _brandLogoUrl;
  bool _isLoadingBrandLogo = false;
  bool _isSavingBrandLogo = false;
  bool _useBrandLogo = false;

  String _brandLogoPosition = 'bottom_right';
  double _brandLogoSize = 0.2; // proportion of video width
  double _brandLogoOpacity = 1.0; // 0.1 – 1.0

  @override
  void initState() {
    super.initState();
    _loadVoiceProfiles();
    _loadAvatarProfiles();
    _loadBrandLogo();
    _voiceScriptController.addListener(_updateEstimatedVoiceDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromArgs) return;
    _didInitFromArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is VoiceProfile) {
      _selectedVoiceProfileId = args.id;
    } else if (args is String) {
      _selectedAvatarId = args;
      _enableFaceLock = true;
    }
  }

  Future<void> _generateFinalVideo() async {
    final res = _result;
    if (res == null) {
      setState(() {
        _error = 'Aucune vidéo à fusionner pour le moment.';
      });
      return;
    }

    final mode = res.metadata != null ? res.metadata!['mode'] as String? : null;
    final isScriptedSlideshow = mode == 'scripted_slideshow';

    if (!isScriptedSlideshow && res.type != GenerationType.video) {
      setState(() {
        _error = 'Aucune vidéo à fusionner pour le moment.';
      });
      return;
    }

    final audioUrl = res.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) {
      setState(() {
        _error =
            'Aucune piste audio clonée associée à cette vidéo. Générez une vidéo orchestrée avec script voix et profil de voix.';
      });
      return;
    }

    setState(() {
      _isMergingFinal = true;
      _error = null;
      _finalMp4Bytes = null;
      _hasFinalMp4 = false;
    });

    try {
      final audioBytes = await FileDownloadHelper.fetchBytes(audioUrl);
      Uint8List videoBytes;

      if (isScriptedSlideshow) {
        final metadata = res.metadata ?? const <String, dynamic>{};
        final rawSegments = metadata['segments'];

        if (rawSegments is! List || rawSegments.isEmpty) {
          setState(() {
            _error = 'Aucun segment d\'images trouvé pour ce diaporama.';
          });
          return;
        }

        final imageUrls = <String>[];
        final durations = <int>[];
        for (final raw in rawSegments) {
          if (raw is Map) {
            final map = raw.cast<String, dynamic>();
            final imageUrl = map['imageUrl'] as String?;
            final durationValue = map['duration'];
            final duration = durationValue is num
                ? durationValue.toInt().clamp(1, 60)
                : 1;

            if (imageUrl != null && imageUrl.isNotEmpty) {
              imageUrls.add(imageUrl);
              durations.add(duration);
            }
          }
        }

        if (imageUrls.isEmpty) {
          setState(() {
            _error = 'Aucun segment avec image valide pour ce diaporama.';
          });
          return;
        }

        final imageBytes = <Uint8List>[];
        for (final url in imageUrls) {
          final bytes = await FileDownloadHelper.fetchBytes(url);
          imageBytes.add(bytes);
        }

        videoBytes = await _ffmpegService.composeSlideshow(
          imageBytes: imageBytes,
          durationsSeconds: durations,
          audioBytes: audioBytes,
        );
      } else {
        videoBytes = await FileDownloadHelper.fetchBytes(res.url);
      }
      Uint8List merged;

      if (_useBrandLogo && _brandLogoPath != null && _brandLogoUrl != null) {
        final logoBytes = await FileDownloadHelper.fetchBytes(_brandLogoUrl!);
        merged = await _ffmpegService.mergeVideoAndAudioWithLogo(
          videoBytes: videoBytes,
          audioBytes: audioBytes,
          logoBytes: logoBytes,
          position: _brandLogoPosition,
          size: _brandLogoSize,
          opacity: _brandLogoOpacity,
        );
      } else {
        merged = await _ffmpegService.mergeVideoAndAudio(
          videoBytes: videoBytes,
          audioBytes: audioBytes,
        );
      }

      if (!mounted) return;
      setState(() {
        _finalMp4Bytes = merged;
        _hasFinalMp4 = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de la fusion audio/vidéo: $e';
        _finalMp4Bytes = null;
        _hasFinalMp4 = false;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isMergingFinal = false;
      });
    }
  }

  Future<void> _registerVideoContentJob(
    GenerationResult res,
    String prompt,
    String? voiceScript,
    bool useOrchestrator,
  ) async {
    final jobId = res.jobId;
    if (jobId == null || jobId.isEmpty) {
      return;
    }

    try {
      String objective = prompt;
      if (objective.length > 160) {
        objective = '${objective.substring(0, 157)}...';
      }

      await _contentJobService.upsertContentJob(
        objective: objective,
        format: 'video',
        channels: const <String>[],
        originUi: 'video_page',
        status: 'generated',
        generationJobId: jobId,
        metadata: <String, dynamic>{
          'prompt': prompt,
          if (voiceScript != null && voiceScript.isNotEmpty)
            'voice_script': voiceScript,
          'use_orchestrator': useOrchestrator,
          'quality_tier': _qualityTier,
          if (_selectedVideoModel != null) 'model': _selectedVideoModel,
          if (_provider != 'auto') 'provider': _provider,
        },
      );
    } catch (_) {
      // Best-effort: ne jamais bloquer l'UI si la création du content_job échoue.
    }
  }

  Future<void> _saveBrandLogoPreferences() async {
    try {
      await _settingsService.setSetting('NEXIOM_BRAND_LOGO_POSITION', _brandLogoPosition);
      await _settingsService.setSetting(
        'NEXIOM_BRAND_LOGO_SIZE',
        _brandLogoSize.toString(),
      );
      await _settingsService.setSetting(
        'NEXIOM_BRAND_LOGO_OPACITY',
        _brandLogoOpacity.toString(),
      );
    } catch (_) {
      // silent: preferences are optional, no blocking behavior
    }
  }

  void _updateEstimatedVoiceDuration() {
    final text = _voiceScriptController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _estimatedVoiceDurationSeconds = null;
      });
      return;
    }

    final wordMatches = RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ0-9']+").allMatches(text);
    final wordCount = wordMatches.length;
    if (wordCount == 0) {
      setState(() {
        _estimatedVoiceDurationSeconds = null;
      });
      return;
    }

    const wordsPerMinute = 150; // lecture posée
    final seconds = (wordCount / wordsPerMinute * 60).ceil();
    final clamped = seconds.clamp(10, 60);

    setState(() {
      _estimatedVoiceDurationSeconds = clamped;
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _voiceScriptController.dispose();
    _negativePromptController.dispose();
    _storyboardController.dispose();
    _shotListController.dispose();
    _dialoguesController.dispose();
    _locationController.dispose();
    _environmentController.dispose();
    _charactersController.dispose();
    _cameraController.dispose();
    _lightingController.dispose();
    _actionController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  Future<void> _loadVoiceProfiles() async {
    setState(() {
      _isLoadingVoices = true;
    });

    try {
      final profiles = await _voiceProfileService.listProfiles();
      if (!mounted) return;
      setState(() {
        _voiceProfiles = profiles;
        if (_selectedVoiceProfileId == null && profiles.isNotEmpty) {
          final primary = profiles.firstWhere(
            (p) => p.isPrimary,
            orElse: () => profiles.first,
          );
          _selectedVoiceProfileId = primary.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _voiceProfiles = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingVoices = false;
      });
    }
  }

  Future<void> _loadAvatarProfiles() async {
    setState(() {
      _isLoadingAvatars = true;
    });

    try {
      final profiles = await _avatarService.listProfiles();
      if (!mounted) return;
      setState(() {
        _avatarProfiles = profiles;
        if (_selectedAvatarId == null && profiles.isNotEmpty) {
          final primary = profiles.firstWhere(
            (p) => p.isPrimary,
            orElse: () => profiles.first,
          );
          _selectedAvatarId = primary.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _avatarProfiles = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingAvatars = false;
      });
    }
  }

  Future<void> _loadBrandLogo() async {
    setState(() {
      _isLoadingBrandLogo = true;
    });

    try {
      final path = await _settingsService.getSetting('NEXIOM_BRAND_LOGO_PATH');
      final position = await _settingsService.getSetting('NEXIOM_BRAND_LOGO_POSITION');
      final sizeStr = await _settingsService.getSetting('NEXIOM_BRAND_LOGO_SIZE');
      final opacityStr = await _settingsService.getSetting('NEXIOM_BRAND_LOGO_OPACITY');
      if (!mounted) return;

      if (path != null && path.isNotEmpty) {
        final url = _uploadService.getPublicUrl(path);
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

      if (position != null && position.isNotEmpty) {
        _brandLogoPosition = position;
      }

      if (sizeStr != null && sizeStr.isNotEmpty) {
        final parsed = double.tryParse(sizeStr);
        if (parsed != null && parsed > 0 && parsed <= 0.5) {
          _brandLogoSize = parsed;
        }
      }

      if (opacityStr != null && opacityStr.isNotEmpty) {
        final parsed = double.tryParse(opacityStr);
        if (parsed != null && parsed > 0 && parsed <= 1.0) {
          _brandLogoOpacity = parsed;
        }
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

  Future<void> _pickBrandLogo() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    final file = result?.files.first;
    if (file == null) return;

    setState(() {
      _isSavingBrandLogo = true;
    });

    try {
      final path = await _uploadService.uploadReferenceMedia(
        file,
        prefix: 'brand_logo',
      );
      final url = _uploadService.getPublicUrl(path);

      await _settingsService.setSetting('NEXIOM_BRAND_LOGO_PATH', path);

      if (!mounted) return;
      setState(() {
        _brandLogoPath = path;
        _brandLogoUrl = url;
        _useBrandLogo = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de l\'upload du logo Nexiom: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSavingBrandLogo = false;
      });
    }
  }

  Future<void> _pickVoiceScriptTemplate() async {
    final template = await Navigator.push<TextTemplate>(
      context,
      MaterialPageRoute(
        builder: (_) => const TextTemplatesPage(
          pickMode: true,
          categoryFilter: 'video_script',
        ),
      ),
    );

    if (template == null) return;

    setState(() {
      if (_voiceScriptController.text.isEmpty) {
        _voiceScriptController.text = template.content;
      } else {
        _voiceScriptController.text =
            '${_voiceScriptController.text.trim()}\n\n${template.content.trim()}';
      }
    });
  }

  Future<void> _pickReferenceMedia() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
      withData: true,
    );

    final file = result?.files.first;
    if (file == null) return;

    try {
      final path = await _uploadService.uploadReferenceMedia(file,
          prefix: 'video_reference');
      setState(() {
        _referenceMediaPath = path;
        _referenceFileName = file.name;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'upload du média de référence: $e';
      });
    }
  }

  Future<void> _pickFaceReference() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    final file = result?.files.first;
    if (file == null) return;

    try {
      final path = await _uploadService.uploadReferenceMedia(
        file,
        prefix: 'video_face_reference',
      );
      setState(() {
        _faceReferencePath = path;
        _faceReferenceFileName = file.name;
        _selectedAvatarId = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'upload de la référence visage: $e';
      });
    }
  }

  Future<void> _generate() async {
    final basePrompt = _promptController.text.trim();
    final location = _locationController.text.trim();
    final environment = _environmentController.text.trim();
    final characters = _charactersController.text.trim();
    final camera = _cameraController.text.trim();
    final lighting = _lightingController.text.trim();
    final action = _actionController.text.trim();
    final style = _styleController.text.trim();

    final buffer = StringBuffer();
    if (basePrompt.isNotEmpty) {
      buffer.writeln(basePrompt);
    }
    if (location.isNotEmpty) {
      buffer.writeln('\n[Lieu & contexte]');
      buffer.writeln(location);
    }
    if (environment.isNotEmpty) {
      buffer.writeln('\n[Décor & ambiance]');
      buffer.writeln(environment);
    }
    if (characters.isNotEmpty) {
      buffer.writeln('\n[Personnages]');
      buffer.writeln(characters);
    }
    if (camera.isNotEmpty) {
      buffer.writeln('\n[Caméra & cadrage]');
      buffer.writeln(camera);
    }
    if (lighting.isNotEmpty) {
      buffer.writeln('\n[Lumière & couleurs]');
      buffer.writeln(lighting);
    }
    if (action.isNotEmpty) {
      buffer.writeln('\n[Action principale]');
      buffer.writeln(action);
    }
    if (style.isNotEmpty) {
      buffer.writeln('\n[Style & niveau de réalisme]');
      buffer.writeln(style);
    }

    final dialoguesRaw = _dialoguesController.text.trim();
    if (dialoguesRaw.isNotEmpty) {
      buffer.writeln('\n[Dialogues à l\'écran]');
      buffer.writeln(
        'Les lignes suivantes décrivent ce que les personnages disent à l\'image, avec un ton réaliste et des mouvements de bouche cohérents :',
      );
      buffer.writeln(dialoguesRaw);
    }

    final prompt = buffer.toString().trim();
    if (prompt.isEmpty) {
      setState(() {
        _error = 'Veuillez saisir un prompt ou remplir le brief structuré.';
      });
      return;
    }

    final voiceScript = _voiceScriptController.text.trim();
    final negativePrompt = _negativePromptController.text.trim();
    final storyboard = _storyboardController.text.trim();
    final shotListRaw = _shotListController.text.trim();

    List<String>? shotDescriptions;
    if (shotListRaw.isNotEmpty) {
      final lines = shotListRaw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) {
        shotDescriptions = lines;
      }
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _result = null;
      _isMergingFinal = false;
      _finalMp4Bytes = null;
      _hasFinalMp4 = false;
    });

    try {
      var effectiveDuration = _duration;
      if (_adaptDurationToVoiceScript && voiceScript.isNotEmpty) {
        final est = _estimatedVoiceDurationSeconds ??
            (() {
              final text = voiceScript.trim();
              if (text.isEmpty) return _duration;
              final wordMatches =
                  RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ0-9']+").allMatches(text);
              final wordCount = wordMatches.length;
              if (wordCount == 0) return _duration;
              const wordsPerMinute = 150;
              final seconds = (wordCount / wordsPerMinute * 60).ceil();
              return seconds.clamp(10, 60) as int;
            })();
        effectiveDuration = est is int ? est : _duration;
      }

      String? videoBriefId;
      try {
        videoBriefId = await _videoBriefService.createBriefFromVideoForm(
          prompt: prompt,
          durationSeconds: effectiveDuration,
          qualityTier: _qualityTier,
          location: location.isEmpty ? null : location,
          environment: environment.isEmpty ? null : environment,
          characters: characters.isEmpty ? null : characters,
          camera: camera.isEmpty ? null : camera,
          lighting: lighting.isEmpty ? null : lighting,
          action: action.isEmpty ? null : action,
          style: style.isEmpty ? null : style,
        );
      } catch (_) {
        videoBriefId = null;
      }

      final selectedAvatarId = _selectedAvatarId;

      final res = _useOrchestrator
          ? await _orchestratedService.orchestrateVideo(
              prompt: prompt,
              durationSeconds: effectiveDuration,
              model: _selectedVideoModel,
              referenceMediaPath: _referenceMediaPath,
              qualityTier: _qualityTier,
              provider: _provider == 'auto' ? null : _provider,
              voiceProfileId: _selectedVoiceProfileId,
              voiceScript: voiceScript.isEmpty ? null : voiceScript,
              negativePrompt: negativePrompt.isEmpty ? null : negativePrompt,
              storyboard: storyboard.isEmpty ? null : storyboard,
              shotDescriptions: shotDescriptions,
              faceReferencePath: _faceReferencePath,
              enableFaceLock: _enableFaceLock,
              aspectRatio: null,
              seed: null,
              width: null,
              height: null,
              parentJobId: _lastJobId,
              videoBriefId: videoBriefId,
              useLibrary: true,
              libraryLocation: location.isEmpty ? null : location,
              libraryShotType: null,
              useBrandLogo: _useBrandLogo && _brandLogoPath != null,
              avatarProfileId: selectedAvatarId,
              orchestrationMode: 'scripted_slideshow',
            )
          : await _service.generateVideo(
              prompt: prompt,
              durationSeconds: effectiveDuration,
              model: _selectedVideoModel,
              referenceMediaPath: _referenceMediaPath,
              qualityTier: _qualityTier,
              provider: _provider == 'auto' ? null : _provider,
              voiceProfileId: _selectedVoiceProfileId,
              voiceScript: voiceScript.isEmpty ? null : voiceScript,
              negativePrompt: negativePrompt.isEmpty ? null : negativePrompt,
              storyboard: storyboard.isEmpty ? null : storyboard,
              shotDescriptions: shotDescriptions,
              faceReferencePath: _faceReferencePath,
              enableFaceLock: _enableFaceLock,
              parentJobId: _lastJobId,
              videoBriefId: videoBriefId,
              useBrandLogo: _useBrandLogo && _brandLogoPath != null,
              avatarProfileId: selectedAvatarId,
            );
      await _registerVideoContentJob(
        res,
        prompt,
        voiceScript.isEmpty ? null : voiceScript,
        _useOrchestrator,
      );
      setState(() {
        _result = res;
        _lastJobId = res.jobId;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la génération: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _download() {
    final res = _result;
    if (res == null) return;
    FileDownloadHelper.downloadFromUrl(
      'video_${res.jobId ?? DateTime.now().millisecondsSinceEpoch}.mp4',
      res.url,
    );
  }

  void _downloadFinal() {
    final bytes = _finalMp4Bytes;
    final res = _result;
    if (bytes == null || res == null) return;

    final fileName =
        'video_finale_${res.jobId ?? DateTime.now().millisecondsSinceEpoch}.mp4';
    FileDownloadHelper.downloadBytes(fileName, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Génération de vidéo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vidéo 10–60 secondes',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choisissez une durée et, si possible, une photo ou vidéo réelle de votre environnement (bureaux, salle de réunion, rue à Ouagadougou / au Burkina) pour guider la scène.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    PromptInput(
                      controller: _promptController,
                      hint:
                          'Décrivez la scène, le style, le mouvement... Par exemple: "Vue drone nocturne d\'une ville futuriste avec néons bleus"',
                    ),
                    const SizedBox(height: 16),
                    PromptInput(
                      controller: _voiceScriptController,
                      hint:
                          'Texte que la voix va prononcer (script voix off, optionnel)',
                      maxLines: 4,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _pickVoiceScriptTemplate,
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Insérer depuis mes templates'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _estimatedVoiceDurationSeconds == null
                                ? 'Saisissez un texte de voix off pour estimer sa durée de lecture.'
                                : 'Durée estimée de la voix off : ~${_estimatedVoiceDurationSeconds}s (lecture posée).',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white60),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _adaptDurationToVoiceScript,
                              onChanged: (value) {
                                setState(() {
                                  _adaptDurationToVoiceScript = value ?? false;
                                });
                              },
                            ),
                            const Text(
                              'Adapter la durée',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Brief structuré (optionnel)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Précisez le décor, les personnages, la caméra, la lumière et l\'action pour une vidéo très réaliste (ex: bureau à Ouagadougou, environnement d\'entreprise au Burkina).',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Lieu / contexte (ex: Ouagadougou, Burkina Faso, quartier d\'affaires, intérieur d\'entreprise...)',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _environmentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Décor & ambiance (ex: open space moderne à Ouagadougou, salle de réunion, rue animée...)',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _charactersController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Personnages (nombre, rôles, style vestimentaire, ex: commercial et client dans une PME à Ouagadougou)',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cameraController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Caméra & cadrage (plans larges, plans serrés, mouvements: travelling, caméra fixe, vue drone...)',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lightingController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Lumière & couleurs (ex: lumière naturelle chaude, néons bleus, style corporate propre et réaliste)',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _actionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Action principale (ex: le commercial explique une offre à la caméra, puis montre un écran à un client)',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _styleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Style & réalisme (ex: vidéo ultra-réaliste, corporate, tournée comme avec une caméra cinéma 4K, sans style cartoon)',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Negative prompt (éléments à éviter)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _negativePromptController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Par exemple: artefacts, glitchs, flou, visages déformés...',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Storyboard (optionnel)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _storyboardController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Décrivez rapidement le déroulé (début, milieu, fin, type de plans...)',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Découpage en plans (1 plan par ligne, optionnel)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _shotListController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Ex:\n1. Plan large de la ville\n2. Gros plan sur le visage du personnage... ',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final d in [10, 20, 30, 60])
                          ChoiceChip(
                            label: Text('$d s'),
                            selected: _duration == d,
                            onSelected: (_) {
                              setState(() {
                                _duration = d;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Mode simple'),
                          selected: !_useOrchestrator,
                          onSelected: (_) {
                            setState(() {
                              _useOrchestrator = false;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Mode production (orchestré)'),
                          selected: _useOrchestrator,
                          onSelected: (_) {
                            setState(() {
                              _useOrchestrator = true;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Standard'),
                          selected: _qualityTier == 'standard',
                          onSelected: (_) {
                            setState(() {
                              _qualityTier = 'standard';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Cinématique'),
                          selected: _qualityTier == 'cinematic',
                          onSelected: (_) {
                            setState(() {
                              _qualityTier = 'cinematic';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Ultra‑réaliste'),
                          selected: _qualityTier == 'ultra_realistic',
                          onSelected: (_) {
                            setState(() {
                              _qualityTier = 'ultra_realistic';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Provider automatique'),
                          selected: _provider == 'auto',
                          onSelected: (_) {
                            setState(() {
                              _provider = 'auto';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Forcer OpenRouter'),
                          selected: _provider == 'openrouter',
                          onSelected: (_) {
                            setState(() {
                              _provider = 'openrouter';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Modèle vidéo (avancé)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedVideoModel,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Modèle par défaut (configuration serveur)',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Auto (OpenRouter choisit / défaut)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'google/gemini-2.0-flash-lite-001',
                          child: Text(
                            'Gemini 2.0 Flash Lite (Google)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedVideoModel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickReferenceMedia,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Média de référence (photo/vidéo)'),
                            ),
                            const SizedBox(width: 12),
                            if (_referenceFileName != null)
                              Flexible(
                                child: Text(
                                  _referenceFileName!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Astuce : importez une photo ou vidéo réelle de vos bureaux ou d’une rue d’Ouagadougou pour obtenir une vidéo encore plus réaliste.',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickFaceReference,
                              icon: const Icon(Icons.face_retouching_natural_outlined),
                              label: const Text('Référence visage (portrait) '),
                            ),
                            const SizedBox(width: 12),
                            if (_faceReferenceFileName != null)
                              Flexible(
                                child: Text(
                                  _faceReferenceFileName!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingAvatars)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_avatarProfiles.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Avatar visage (personnage principal)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Aucun avatar'),
                                selected: _selectedAvatarId == null,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedAvatarId = null;
                                  });
                                },
                              ),
                              for (final avatar in _avatarProfiles)
                                ChoiceChip(
                                  label: Text(avatar.name),
                                  selected: _selectedAvatarId == avatar.id,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedAvatarId = avatar.id;
                                      _enableFaceLock = true;
                                      if (avatar.faceReferencePaths.isNotEmpty) {
                                        _faceReferencePath =
                                            avatar.faceReferencePaths.first;
                                        _faceReferenceFileName =
                                            avatar.faceReferencePaths.first
                                                .split('/')
                                                .last;
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.avatars);
                              },
                              icon: const Icon(Icons.person_pin_outlined, size: 18),
                              label: const Text('Gérer mes avatars'),
                            ),
                          ),
                        ],
                        Row(
                          children: [
                            Checkbox(
                              value: _enableFaceLock,
                              onChanged: (value) {
                                setState(() {
                                  _enableFaceLock = value ?? false;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Verrouiller le visage principal (cohérence d\'identité entre les plans)',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voix clonée (optionnel)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              if (_isLoadingVoices)
                                const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else if (_voiceProfiles.isEmpty)
                                const Text(
                                  'Aucun profil de voix pour le moment. Générez une voix dans l\'onglet "Voix off".',
                                  style: TextStyle(color: Colors.white54),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Aucune'),
                                      selected: _selectedVoiceProfileId == null,
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedVoiceProfileId = null;
                                        });
                                      },
                                    ),
                                    for (final profile in _voiceProfiles)
                                      ChoiceChip(
                                        label: Text(profile.name),
                                        selected: _selectedVoiceProfileId == profile.id,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedVoiceProfileId = profile.id;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Logo Nexiom Group',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              if (_isLoadingBrandLogo)
                                const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed:
                                          _isSavingBrandLogo ? null : _pickBrandLogo,
                                      icon: const Icon(Icons.image_outlined),
                                      label: Text(
                                        _brandLogoPath == null
                                            ? 'Importer le logo Nexiom'
                                            : 'Mettre à jour le logo Nexiom',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (_brandLogoUrl != null)
                                      Container(
                                        width: 80,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.white,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Image.network(
                                          _brandLogoUrl!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Switch(
                                    value:
                                        _useBrandLogo && _brandLogoPath != null,
                                    onChanged: _brandLogoPath == null
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _useBrandLogo = value;
                                            });
                                          },
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Utiliser le logo Nexiom Group dans cette vidéo (coin bas droit après génération).',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Lorsque vous mentionnez le logo Nexiom Group dans le scénario ou le prompt, cela fait référence à ce fichier officiel. L’IA ne redessine pas le logo : il sera ajouté par Nexiom en surimpression à partir de ce fichier.',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isGenerating ? null : _generate,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          _isGenerating ? 'Génération en cours...' : 'Générer la vidéo',
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_result != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (_result!.type == GenerationType.video)
                              OutlinedButton.icon(
                                onPressed: _download,
                                icon: const Icon(Icons.download),
                                label: const Text('Télécharger la vidéo brute'),
                              ),
                            FilledButton.icon(
                              onPressed:
                                  _isMergingFinal ? null : _generateFinalVideo,
                              icon: const Icon(Icons.movie_creation_outlined),
                              label: Text(
                                _isMergingFinal
                                    ? 'Fusion en cours...'
                                    : 'Générer la vidéo finale (MP4)',
                              ),
                            ),
                            if (_hasFinalMp4)
                              OutlinedButton.icon(
                                onPressed: _downloadFinal,
                                icon: const Icon(Icons.download_done),
                                label:
                                    const Text('Télécharger la vidéo finale'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: _isGenerating
                      ? const Loader(
                          message:
                              'Génération en cours... Cela peut prendre jusqu’à une minute pour 60 secondes de vidéo.',
                        )
                      : ResultViewer(result: _result),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
