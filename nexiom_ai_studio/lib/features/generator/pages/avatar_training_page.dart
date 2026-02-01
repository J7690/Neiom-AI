import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../models/avatar_profile.dart';
import '../models/avatar_preview.dart';
import '../models/image_agent.dart';
import '../services/avatar_preview_service.dart';
import '../services/avatar_profile_service.dart';
import '../services/image_agent_service.dart';
import '../services/media_upload_service.dart';

class AvatarTrainingPage extends StatefulWidget {
  const AvatarTrainingPage({super.key});

  @override
  State<AvatarTrainingPage> createState() => _AvatarTrainingPageState();
}

class _AvatarTrainingPageState extends State<AvatarTrainingPage> {
  final _service = AvatarProfileService.instance();
  final _uploadService = MediaUploadService.instance();
  final _imageAgentService = ImageAgentService.instance();
  final _previewService = AvatarPreviewService.instance();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingAgents = false;
  List<AvatarProfile> _profiles = [];
  List<ImageAgent> _agents = [];
  ImageAgent? _selectedAgent;
  String? _error;

  // Creation form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyTypeController = TextEditingController();
  final _complexionController = TextEditingController();
  final _ageRangeController = TextEditingController();
  final _genderController = TextEditingController();
  final _hairController = TextEditingController();
  final _clothingController = TextEditingController();

  final List<String> _faceReferencePaths = [];
  final List<String> _faceReferenceNames = [];
  final List<String> _environmentReferencePaths = [];
  final List<String> _environmentReferenceNames = [];
  double _faceStrength = 0.7;
  double _environmentStrength = 0.35;

  @override
  void initState() {
    super.initState();
    _load();
    _loadAgents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _heightController.dispose();
    _bodyTypeController.dispose();
    _complexionController.dispose();
    _ageRangeController.dispose();
    _genderController.dispose();
    _hairController.dispose();
    _clothingController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _service.listProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du chargement des avatars: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _renameAvatar(AvatarProfile profile) async {
    final controller = TextEditingController(text: profile.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renommer l\'avatar'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nouveau nom',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
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
      final newName = controller.text.trim();
      if (newName.isEmpty) return;

      try {
        await _service.renameProfile(profile.id, newName);
        await _load();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = 'Erreur lors du renommage de l\'avatar: $e';
        });
      }
    }
  }

  Future<void> _loadAgents() async {
    setState(() {
      _isLoadingAgents = true;
    });

    try {
      final list = await _imageAgentService.listAvatarAgents();
      if (!mounted) return;
      setState(() {
        _agents = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error ??= 'Erreur lors du chargement des modèles d\'avatar: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingAgents = false;
      });
    }
  }

  Future<void> _pickFaceReferences() async {
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

  Future<void> _pickEnvironmentReferences() async {
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

  Future<void> _saveAvatar() async {
    if (_faceReferencePaths.isEmpty) {
      setState(() {
        _error =
            'Ajoutez au moins une image de référence visage avant de créer un avatar.';
      });
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = 'Donnez un nom à votre avatar.';
      });
      return;
    }

    int? heightCm;
    final heightText = _heightController.text.trim();
    if (heightText.isNotEmpty) {
      heightCm = int.tryParse(heightText);
    }

    final bodyType = _bodyTypeController.text.trim().isEmpty
        ? null
        : _bodyTypeController.text.trim();
    final complexion = _complexionController.text.trim().isEmpty
        ? null
        : _complexionController.text.trim();
    final ageRange = _ageRangeController.text.trim().isEmpty
        ? null
        : _ageRangeController.text.trim();
    final gender =
        _genderController.text.trim().isEmpty ? null : _genderController.text.trim();
    final hairDescription = _hairController.text.trim().isEmpty
        ? null
        : _hairController.text.trim();
    final clothingStyle = _clothingController.text.trim().isEmpty
        ? null
        : _clothingController.text.trim();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await _service.createProfile(
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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

      _nameController.clear();
      _descriptionController.clear();
      _heightController.clear();
      _bodyTypeController.clear();
      _complexionController.clear();
      _ageRangeController.clear();
      _genderController.clear();
      _hairController.clear();
      _clothingController.clear();
      _faceReferencePaths.clear();
      _faceReferenceNames.clear();
      _environmentReferencePaths.clear();
      _environmentReferenceNames.clear();
      _faceStrength = 0.7;
      _environmentStrength = 0.35;
      _selectedAgent = null;

      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de la création du profil d\'avatar: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _setPrimary(AvatarProfile profile) async {
    try {
      await _service.setPrimary(profile.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de la mise à jour de l\'avatar principal: $e';
      });
    }
  }

  Future<void> _openMultiAgentDialog(AvatarProfile profile) async {
    if (_agents.isEmpty && !_isLoadingAgents) {
      await _loadAgents();
    }

    if (!mounted) return;

    if (_agents.isEmpty) {
      setState(() {
        _error ??=
            'Aucun modèle d\'avatar n\'est disponible pour le moment. Configurez au moins un agent dans image_agents.';
      });
      return;
    }

    String? selectedAgentId = profile.preferredAgentId ??
        (_agents.isNotEmpty ? _agents.first.id : null);
    List<AvatarPreview> previews = [];
    bool isGenerating = false;
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Prévisualiser l\'avatar (multi-agents)',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 640,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sélectionnez plusieurs modèles d\'image, puis générez des prévisualisations pour choisir la version la plus fidèle.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    if (localError != null) ...[
                      Text(
                        localError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Modèles disponibles',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _agents.length,
                        itemBuilder: (context, index) {
                          final agent = _agents[index];
                          return RadioListTile<String>(
                            value: agent.id,
                            groupValue: selectedAgentId,
                            onChanged: isGenerating
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setStateDialog(() {
                                      selectedAgentId = value;
                                    });
                                  },
                            title: Text(
                              agent.displayName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: agent.qualityScore != null
                                ? Text(
                                    'Score qualité: ${agent.qualityScore!.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  )
                                : null,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: isGenerating
                            ? null
                            : () async {
                                if (selectedAgentId == null) {
                                  setStateDialog(() {
                                    localError =
                                        'Sélectionnez un modèle avant de lancer la génération.';
                                  });
                                  return;
                                }

                                setStateDialog(() {
                                  isGenerating = true;
                                  localError = null;
                                });

                                try {
                                  final result = await _previewService.generatePreviews(
                                    avatarProfileId: profile.id,
                                    agentIds: [selectedAgentId!],
                                  );
                                  setStateDialog(() {
                                    previews = result;
                                  });
                                } catch (e) {
                                  setStateDialog(() {
                                    localError =
                                        'Erreur lors de la génération des prévisualisations: $e';
                                  });
                                } finally {
                                  setStateDialog(() {
                                    isGenerating = false;
                                  });
                                }
                              },
                        icon: isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome_outlined),
                        label: Text(
                          isGenerating
                              ? 'Génération en cours...'
                              : 'Générer les prévisualisations',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (previews.isNotEmpty) ...[
                      Text(
                        'Prévisualisations générées',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 260,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: previews.length,
                          itemBuilder: (context, index) {
                            final preview = previews[index];
                            return _AvatarPreviewTile(
                              preview: preview,
                              onSelect: isGenerating
                                  ? () {}
                                  : () async {
                                      setStateDialog(() {
                                        isGenerating = true;
                                        localError = null;
                                      });
                                      try {
                                        await _previewService.selectPreview(
                                          preview: preview,
                                        );
                                        await _load();
                                        if (!mounted) return;
                                        Navigator.of(dialogContext).pop();
                                      } catch (e) {
                                        if (!mounted) return;
                                        setStateDialog(() {
                                          isGenerating = false;
                                          localError =
                                              'Erreur lors de la sélection de cette version: $e';
                                        });
                                      }
                                    },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isGenerating
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _goToImageWithAvatar(AvatarProfile profile) {
    Navigator.pushNamed(
      context,
      AppRoutes.image,
      arguments: profile.id,
    );
  }

  void _goToVideoWithAvatar(AvatarProfile profile) {
    Navigator.pushNamed(
      context,
      AppRoutes.video,
      arguments: profile.id,
    );
  }

  Widget _buildAvatarThumbnail(AvatarProfile profile) {
    String? url = profile.previewImageUrl;
    if (url == null || url.isEmpty) {
      if (profile.faceReferencePaths.isNotEmpty) {
        final path = profile.faceReferencePaths.first;
        url = _uploadService.getPublicUrl(path);
      }
    }

    if (url == null || url.isEmpty) {
      return const Icon(
        Icons.person_outline,
        color: Colors.cyanAccent,
        size: 40,
      );
    }

    // Use a fixed, bounded size to avoid "RenderAspectRatio has unbounded constraints"
    // when the thumbnail is placed inside a Row / ListView.
    return SizedBox(
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF111827),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_outline,
                color: Colors.cyanAccent,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes avatars visage'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entraînez un personnage principal à partir de vos photos de référence.',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez un avatar visage réutilisable dans vos images et vidéos (même personne, même style).',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: creation form
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Créer un nouvel avatar visage',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Nom de l\'avatar',
                              labelStyle: TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description générale (optionnel)',
                              labelStyle: TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Taille (cm, optionnel)',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Color(0xFF0F172A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(16)),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _bodyTypeController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Corpulence / morphologie',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Color(0xFF0F172A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(16)),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _complexionController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Teint / couleur de peau',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Color(0xFF0F172A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(16)),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _ageRangeController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Tranche d\'âge',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Color(0xFF0F172A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(16)),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _genderController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Genre (optionnel)',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Color(0xFF0F172A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(16)),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _hairController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Cheveux (type, longueur, style)',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Color(0xFF0F172A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(16)),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _clothingController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Style vestimentaire habituel',
                              labelStyle: TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Modèle d\'avatar (OpenRouter)',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          if (_isLoadingAgents)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_agents.isEmpty)
                            const Text(
                              'Aucun modèle n\'est encore configuré. Ajoutez des agents recommandés dans image_agents.',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final agent in _agents)
                                  ChoiceChip(
                                    label: Text(agent.displayName),
                                    selected: _selectedAgent?.id == agent.id,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedAgent = selected ? agent : null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Références visage',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              FilledButton.icon(
                                onPressed: _pickFaceReferences,
                                icon: const Icon(Icons.face_retouching_natural_outlined),
                                label: const Text('Ajouter des photos de visage'),
                              ),
                              if (_faceReferenceNames.isNotEmpty)
                                Text(
                                  '${_faceReferenceNames.length} fichier(s) sélectionné(s)',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_faceReferencePaths.isNotEmpty)
                            SizedBox(
                              height: 88,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _faceReferencePaths.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final path = _faceReferencePaths[index];
                                  final url = _uploadService.getPublicUrl(path);
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: const Color(0xFF111827),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.white38,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _faceReferencePaths.removeAt(index);
                                              if (index < _faceReferenceNames.length) {
                                                _faceReferenceNames.removeAt(index);
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Force visage',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _faceStrength,
                                  min: 0.1,
                                  max: 1.0,
                                  divisions: 9,
                                  label: _faceStrength.toStringAsFixed(2),
                                  onChanged: (v) {
                                    setState(() {
                                      _faceStrength = v;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Références environnement (optionnel)',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              FilledButton.icon(
                                onPressed: _pickEnvironmentReferences,
                                icon: const Icon(Icons.landscape_outlined),
                                label: const Text('Ajouter des photos de décor'),
                              ),
                              if (_environmentReferenceNames.isNotEmpty)
                                Text(
                                  '${_environmentReferenceNames.length} fichier(s) sélectionné(s)',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_environmentReferencePaths.isNotEmpty)
                            SizedBox(
                              height: 88,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _environmentReferencePaths.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final path = _environmentReferencePaths[index];
                                  final url = _uploadService.getPublicUrl(path);
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: const Color(0xFF111827),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.white38,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _environmentReferencePaths.removeAt(index);
                                              if (index < _environmentReferenceNames.length) {
                                                _environmentReferenceNames.removeAt(index);
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Force environnement',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _environmentStrength,
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 10,
                                  label: _environmentStrength.toStringAsFixed(2),
                                  onChanged: (v) {
                                    setState(() {
                                      _environmentStrength = v;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _saveAvatar,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _isSaving
                                    ? 'Enregistrement du profil...'
                                    : 'Créer le profil d\'avatar',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right: existing avatars
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mes avatars existants',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _isLoading ? null : _load,
                              icon: const Icon(Icons.refresh, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else if (_profiles.isEmpty)
                          const Text(
                            'Aucun avatar enregistré pour le moment. Ajoutez un avatar à gauche avec des photos de référence.',
                            style: TextStyle(color: Colors.white70),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              itemCount: _profiles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final profile = _profiles[index];
                                final hasPreview = profile.previewImageUrl != null &&
                                    profile.previewImageUrl!.isNotEmpty;
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: const Color(0xFF0F172A),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      _buildAvatarThumbnail(profile),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  profile.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (profile.isPrimary) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                      color: Colors.cyanAccent.withOpacity(0.15),
                                                    ),
                                                    child: const Text(
                                                      'Principal',
                                                      style: TextStyle(
                                                        color: Colors.cyanAccent,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (profile.description != null &&
                                                profile.description!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                profile.description!,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                            if (hasPreview) ...[
                                              const Text(
                                                'Avatar généré',
                                                style: TextStyle(
                                                  color: Colors.cyanAccent,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ] else ...[
                                              const Text(
                                                'Profil sans avatar généré',
                                                style: TextStyle(
                                                  color: Colors.orangeAccent,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          FilledButton.icon(
                                            onPressed: () => _goToImageWithAvatar(profile),
                                            icon: const Icon(Icons.image_outlined, size: 18),
                                            label: const Text('Image'),
                                          ),
                                          const SizedBox(height: 8),
                                          FilledButton.icon(
                                            onPressed: () => _goToVideoWithAvatar(profile),
                                            icon:
                                                const Icon(Icons.movie_creation_outlined, size: 18),
                                            label: const Text('Vidéo'),
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton.icon(
                                            onPressed: () => _openMultiAgentDialog(profile),
                                            icon: const Icon(
                                              Icons.auto_awesome_outlined,
                                              size: 18,
                                              color: Colors.cyanAccent,
                                            ),
                                            label: Text(
                                              hasPreview
                                                  ? 'Re-générer l\'avatar (multi-agents)'
                                                  : 'Générer l\'avatar (multi-agents)',
                                              style: const TextStyle(
                                                color: Colors.cyanAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton.icon(
                                            onPressed: profile.isPrimary
                                                ? null
                                                : () => _setPrimary(profile),
                                            icon: const Icon(Icons.star_outline,
                                                size: 18, color: Colors.amber),
                                            label: Text(
                                              profile.isPrimary
                                                  ? 'Avatar principal'
                                                  : 'Définir comme principal',
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextButton.icon(
                                            onPressed: () => _renameAvatar(profile),
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 18,
                                              color: Colors.white70,
                                            ),
                                            label: const Text(
                                              'Renommer',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPreviewTile extends StatelessWidget {
  final AvatarPreview preview;
  final VoidCallback onSelect;

  const _AvatarPreviewTile({
    required this.preview,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0B1220),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      preview.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF111827),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white38,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: InkWell(
                    onTap: () {
                      final fileName =
                          'avatar_${preview.id}_${DateTime.now().millisecondsSinceEpoch}.png';
                      final anchor = html.AnchorElement(href: preview.imageUrl)
                        ..download = fileName
                        ..target = '_blank';
                      html.document.body?.append(anchor);
                      anchor.click();
                      anchor.remove();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.download,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (preview.agentDisplayName != null)
            Text(
              preview.agentDisplayName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          const SizedBox(height: 4),
          FilledButton.tonal(
            onPressed: onSelect,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
            child: const Text(
              'Choisir cette version',
              style: TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
