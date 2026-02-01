import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../settings/services/settings_service.dart';
import '../../publishing/services/content_job_service.dart';
import '../models/generation_result.dart';
import '../models/text_template.dart';
import '../models/avatar_profile.dart';
import '../services/file_download_helper.dart';
import '../services/media_upload_service.dart';
import '../services/openrouter_service.dart';
import '../services/avatar_profile_service.dart';
import '../widgets/loader.dart';
import '../widgets/prompt_input.dart';
import '../widgets/result_viewer.dart';
import 'text_templates_page.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({super.key});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  final _promptController = TextEditingController();
  final _overlayTextController = TextEditingController();
  final _negativePromptController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _seedController = TextEditingController();
  final _service = OpenRouterService.instance();
  final _uploadService = MediaUploadService.instance();
  final _settingsService = SettingsService.instance();
  final _avatarService = AvatarProfileService.instance();

  bool _isGenerating = false;
  GenerationResult? _result;
  String? _error;
  String? _referenceMediaPath;
  String? _referenceFileName;
  String? _maskPath;
  String? _maskFileName;
  final List<String> _faceReferencePaths = [];
  final List<String> _faceReferenceNames = [];
  final List<String> _environmentReferencePaths = [];
  final List<String> _environmentReferenceNames = [];
  double _faceStrength = 0.3;
  double _environmentStrength = 0.35;
  List<AvatarProfile> _avatarProfiles = [];
  bool _isLoadingAvatars = false;
  String? _selectedAvatarId;
  String? _selectedImageModel;
  String _mode = 'text2img';
  String? _aspectRatio;
  String? _lastJobId;
  final List<GenerationResult> _history = [];
  bool _didInitFromArgs = false;

  String? _brandLogoPath;
  String? _brandLogoUrl;
  bool _isLoadingBrandLogo = false;
  bool _isSavingBrandLogo = false;
  bool _useBrandLogo = false;

  final _contentJobService = ContentJobService.instance();

  @override
  void initState() {
    super.initState();
    _loadBrandLogo();
    _loadAvatarProfiles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromArgs) return;
    _didInitFromArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      setState(() {
        _selectedAvatarId = args;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _overlayTextController.dispose();
    _negativePromptController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  Future<void> _loadBrandLogo() async {
    setState(() {
      _isLoadingBrandLogo = true;
    });

    try {
      final path = await _settingsService.getSetting('NEXIOM_BRAND_LOGO_PATH');
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

  Future<void> _saveCurrentAsAvatarProfile() async {
    if (_faceReferencePaths.isEmpty) {
      setState(() {
        _error =
            'Ajoutez au moins une image de référence visage avant de créer un avatar.';
      });
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final heightController = TextEditingController();
    final bodyTypeController = TextEditingController();
    final complexionController = TextEditingController();
    final ageRangeController = TextEditingController();
    final genderController = TextEditingController();
    final hairController = TextEditingController();
    final clothingController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enregistrer un avatar visage'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'avatar',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description générale (optionnel)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Taille approximative (cm, optionnel)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bodyTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Corpulence / morphologie (mince, moyenne, robuste...)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: complexionController,
                  decoration: const InputDecoration(
                    labelText: 'Teint / couleur de peau (ex: ébène, caramel...)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ageRangeController,
                  decoration: const InputDecoration(
                    labelText: 'Tranche d\'âge approximative (ex: 25-35 ans)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: genderController,
                  decoration: const InputDecoration(
                    labelText: 'Genre (optionnel)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: hairController,
                  decoration: const InputDecoration(
                    labelText: 'Cheveux (type, longueur, style – ex: crépus courts)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: clothingController,
                  decoration: const InputDecoration(
                    labelText:
                        'Style vestimentaire habituel (ex: professionnel, casual...)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      int? heightCm;
      final heightText = heightController.text.trim();
      if (heightText.isNotEmpty) {
        heightCm = int.tryParse(heightText);
      }

      final bodyType = bodyTypeController.text.trim().isEmpty
          ? null
          : bodyTypeController.text.trim();
      final complexion = complexionController.text.trim().isEmpty
          ? null
          : complexionController.text.trim();
      final ageRange = ageRangeController.text.trim().isEmpty
          ? null
          : ageRangeController.text.trim();
      final gender =
          genderController.text.trim().isEmpty ? null : genderController.text.trim();
      final hairDescription = hairController.text.trim().isEmpty
          ? null
          : hairController.text.trim();
      final clothingStyle = clothingController.text.trim().isEmpty
          ? null
          : clothingController.text.trim();

      try {
        await _avatarService.createProfile(
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          faceReferencePaths: List<String>.from(_faceReferencePaths),
          environmentReferencePaths: _environmentReferencePaths.isNotEmpty
              ? List<String>.from(_environmentReferencePaths)
              : null,
          faceStrength: _faceStrength,
          environmentStrength: _environmentStrength,
          heightCm: heightCm,
          bodyType: bodyType,
          complexion: complexion,
          ageRange: ageRange,
          gender: gender,
          hairDescription: hairDescription,
          clothingStyle: clothingStyle,
        );
        await _loadAvatarProfiles();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = 'Erreur lors de la création de l\'avatar: $e';
        });
      }
    }

    nameController.dispose();
    descriptionController.dispose();
    heightController.dispose();
    bodyTypeController.dispose();
    complexionController.dispose();
    ageRangeController.dispose();
    genderController.dispose();
    hairController.dispose();
    clothingController.dispose();
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

  Future<void> _pickReferenceImage() async {
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
      final path =
          await _uploadService.uploadReferenceMedia(file, prefix: 'image_reference');
      setState(() {
        _referenceMediaPath = path;
        _referenceFileName = file.name;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'upload de l\'image de référence: $e';
      });
    }
  }

  Future<void> _pickMaskImage() async {
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
      final path =
          await _uploadService.uploadReferenceMedia(file, prefix: 'image_mask');
      setState(() {
        _maskPath = path;
        _maskFileName = file.name;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'upload du masque: $e';
      });
    }
  }

  Future<void> _pickFaceReferenceImages() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    final files = result?.files;
    if (files == null || files.isEmpty) return;

    try {
      final newPaths = <String>[];
      final newNames = <String>[];
      for (final file in files) {
        if (file.bytes == null) continue;
        final path = await _uploadService.uploadReferenceMedia(
          file,
          prefix: 'image_face_reference',
        );
        newPaths.add(path);
        newNames.add(file.name);
      }
      if (newPaths.isEmpty) return;
      setState(() {
        _faceReferencePaths.addAll(newPaths);
        _faceReferenceNames.addAll(newNames);
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'upload des références visage: $e';
      });
    }
  }

  Future<void> _pickEnvironmentReferenceImages() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    final files = result?.files;
    if (files == null || files.isEmpty) return;

    try {
      final newPaths = <String>[];
      final newNames = <String>[];
      for (final file in files) {
        if (file.bytes == null) continue;
        final path = await _uploadService.uploadReferenceMedia(
          file,
          prefix: 'image_environment_reference',
        );
        newPaths.add(path);
        newNames.add(file.name);
      }
      if (newPaths.isEmpty) return;
      setState(() {
        _environmentReferencePaths.addAll(newPaths);
        _environmentReferenceNames.addAll(newNames);
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'upload des références environnement: $e';
      });
    }
  }

  Future<void> _pickOverlayTemplate() async {
    final template = await Navigator.push<TextTemplate>(
      context,
      MaterialPageRoute(
        builder: (_) => const TextTemplatesPage(
          pickMode: true,
          categoryFilter: 'image_overlay',
        ),
      ),
    );

    if (template == null) return;

    setState(() {
      if (_overlayTextController.text.isEmpty) {
        _overlayTextController.text = template.content;
      } else {
        _overlayTextController.text =
            '${_overlayTextController.text.trim()}\n${template.content.trim()}';
      }
    });
  }

  Future<void> _registerImageContentJob(
    GenerationResult res,
    String prompt,
    String? overlayText,
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
        format: 'image',
        channels: const <String>[],
        originUi: 'image_page',
        status: 'generated',
        generationJobId: jobId,
        metadata: <String, dynamic>{
          'prompt': prompt,
          if (overlayText != null && overlayText.isNotEmpty)
            'overlay_text': overlayText,
          'mode': _mode,
          if (_selectedImageModel != null) 'model': _selectedImageModel,
          if (_aspectRatio != null) 'aspect_ratio': _aspectRatio,
          'use_brand_logo': _useBrandLogo && _brandLogoPath != null,
        },
      );
    } catch (_) {
      // Best-effort: ne jamais bloquer l'UI si la création du content_job échoue.
    }
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _error = 'Veuillez saisir un prompt.';
      });
      return;
    }

    final overlayText = _overlayTextController.text.trim();
    final negativePrompt = _negativePromptController.text.trim();
    final widthText = _widthController.text.trim();
    final heightText = _heightController.text.trim();
    final seedText = _seedController.text.trim();

    int? width;
    int? height;
    int? seed;

    if (widthText.isNotEmpty) {
      width = int.tryParse(widthText);
      if (width == null || width <= 0) {
        setState(() {
          _error = 'Largeur invalide.';
        });
        return;
      }
    }

    if (heightText.isNotEmpty) {
      height = int.tryParse(heightText);
      if (height == null || height <= 0) {
        setState(() {
          _error = 'Hauteur invalide.';
        });
        return;
      }
    }

    if (seedText.isNotEmpty) {
      seed = int.tryParse(seedText);
      if (seed == null) {
        setState(() {
          _error = 'Seed invalide.';
        });
        return;
      }
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await _service.generateImage(
        prompt: prompt,
        referenceMediaPath: _referenceMediaPath,
        model: _selectedImageModel,
        overlayText: overlayText.isEmpty ? null : overlayText,
        mode: _mode,
        negativePrompt: negativePrompt.isEmpty ? null : negativePrompt,
        seed: seed,
        width: width,
        height: height,
        aspectRatio: _aspectRatio,
        maskPath: _maskPath,
        parentJobId: _lastJobId,
        parentAssetId: null,
        faceReferencePaths:
            _faceReferencePaths.isNotEmpty ? List<String>.from(_faceReferencePaths) : null,
        faceStrength:
            _faceReferencePaths.isNotEmpty ? _faceStrength : null,
        environmentReferencePaths: _environmentReferencePaths.isNotEmpty
            ? List<String>.from(_environmentReferencePaths)
            : null,
        environmentStrength:
            _environmentReferencePaths.isNotEmpty ? _environmentStrength : null,
        useBrandLogo: _useBrandLogo && _brandLogoPath != null,
        avatarProfileId: _selectedAvatarId,
      );
      await _registerImageContentJob(res, prompt, overlayText.isEmpty ? null : overlayText);
      setState(() {
        _result = res;
        _lastJobId = res.jobId;
        _history.insert(0, res);
        if (_history.length > 10) {
          _history.removeLast();
        }
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
      'image_${res.jobId ?? DateTime.now().millisecondsSinceEpoch}.png',
      res.url,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Génération d\'image'),
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
                      'Image haute qualité',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Définissez un style, un environnement, un cadrage. Ajoutez une photo de référence si besoin.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    PromptInput(
                      controller: _promptController,
                      hint:
                          'Par exemple: "Portrait cinématique d\'une personne dans un bureau moderne, lumière néon bleue"',
                    ),
                    const SizedBox(height: 16),
                    PromptInput(
                      controller: _overlayTextController,
                      hint:
                          'Texte à afficher sur l\'image (numéro, slogan, CTA...)',
                      maxLines: 3,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _pickOverlayTemplate,
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Insérer depuis mes templates'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mode de génération',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _mode,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'text2img',
                          child: Text(
                            'Texte → image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'img2img',
                          child: Text(
                            'Image → image (style)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'inpaint',
                          child: Text(
                            'Retouche partielle (inpainting)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'outpaint',
                          child: Text(
                            'Extension de cadre (outpainting)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'background_removal',
                          child: Text(
                            'Détourage / fond transparent',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'upscale',
                          child: Text(
                            'Upscale / super résolution',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _mode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Modèle image (avancé)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedImageModel,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: Text(
                        'Modèle par défaut (configuration serveur)',
                        style:
                            TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'black-forest-labs/flux.2-pro',
                          child: Text(
                            'black-forest-labs/flux.2-pro',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'black-forest-labs/flux.2-flex',
                          child: Text(
                            'black-forest-labs/flux.2-flex',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'openai/gpt-5-image',
                          child: Text(
                            'openai/gpt-5-image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedImageModel = value;
                        });
                      },
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
                            'Par exemple: artefacts, flou, doigts déformés, visages tordus...',
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
                      'Paramètres avancés',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _widthController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Largeur (px)',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Hauteur (px)',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
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
                              value: _useBrandLogo && _brandLogoPath != null,
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
                                'Utiliser le logo Nexiom Group dans cette image (coin bas droit après génération).',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Lorsque vous mentionnez le logo Nexiom Group dans le prompt, cela fait référence à ce fichier officiel. L’IA ne redessine pas le logo : il sera ajouté par Nexiom en surimpression à partir de ce fichier.',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _aspectRatio,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Ratio (optionnel)',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '1:1',
                                child: Text(
                                  '1:1 (carré)',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DropdownMenuItem(
                                value: '16:9',
                                child: Text(
                                  '16:9 (paysage)',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DropdownMenuItem(
                                value: '9:16',
                                child: Text(
                                  '9:16 (vertical)',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DropdownMenuItem(
                                value: '4:5',
                                child: Text(
                                  '4:5 (portrait)',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _aspectRatio = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _seedController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Seed (optionnel)',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickReferenceImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Image de référence'),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickMaskImage,
                          icon: const Icon(Icons.brush_outlined),
                          label: const Text('Masque (zones à modifier)'),
                        ),
                        const SizedBox(width: 12),
                        if (_maskFileName != null)
                          Flexible(
                            child: Text(
                              _maskFileName!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Images de référence – visage',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickFaceReferenceImages,
                              icon:
                                  const Icon(Icons.face_retouching_natural_outlined),
                              label: const Text('Ajouter des portraits'),
                            ),
                            const SizedBox(width: 12),
                            if (_faceReferenceNames.isNotEmpty)
                              Expanded(
                                child: Text(
                                  _faceReferenceNames.join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(color: Colors.white70),
                                ),
                              ),
                              if (_faceReferenceNames.isEmpty)
                                const Expanded(
                                  child: Text(
                                    'Ajoutez plusieurs portraits nets de la même personne (face, 3/4, profil, différents éclairages) pour renforcer l\'avatar.',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (_isLoadingAvatars)
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_avatarProfiles.isNotEmpty)
                              Expanded(
                                child: Wrap(
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
                                            _faceReferencePaths
                                              ..clear()
                                              ..addAll(avatar.faceReferencePaths);
                                            _faceReferenceNames
                                              ..clear()
                                              ..addAll(avatar.faceReferencePaths);
                                            _environmentReferencePaths
                                              ..clear()
                                              ..addAll(
                                                  avatar.environmentReferencePaths,
                                                );
                                            _environmentReferenceNames
                                              ..clear()
                                              ..addAll(
                                                  avatar.environmentReferencePaths,
                                                );
                                            _faceStrength = avatar.faceStrength;
                                            _environmentStrength =
                                                avatar.environmentStrength;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.avatars);
                              },
                              icon: const Icon(Icons.person_pin_outlined),
                              label: const Text('Gérer mes avatars'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Fidélité du visage',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        Slider(
                          value: _faceStrength,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          label: _faceStrength.toStringAsFixed(2),
                          onChanged: (value) {
                            setState(() {
                              _faceStrength = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Images de référence – environnement / décor',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickEnvironmentReferenceImages,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Ajouter des décors'),
                            ),
                            const SizedBox(width: 12),
                            if (_environmentReferenceNames.isNotEmpty)
                              Expanded(
                                child: Text(
                                  _environmentReferenceNames.join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Fidélité de l\'environnement',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        Slider(
                          value: _environmentStrength,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          label: _environmentStrength.toStringAsFixed(2),
                          onChanged: (value) {
                            setState(() {
                              _environmentStrength = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isGenerating ? null : _generate,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          _isGenerating ? 'Génération en cours...' : 'Générer l\'image',
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
                    if (_result != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _download,
                              icon: const Icon(Icons.download),
                              label: const Text(
                                'Télécharger l\'image générée (avec logo Nexiom si activé)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_history.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Historique de cette session',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _history.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _result = item;
                                });
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.url,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
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
                              'Génération en cours... Les images complexes peuvent prendre quelques instants.',
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
