import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generator/services/media_upload_service.dart';
import '../../generator/services/openrouter_service.dart';
import '../services/visual_documents_service.dart';

class VisualEditorPage extends StatefulWidget {
  final String? initialDocumentId;

  const VisualEditorPage({super.key, this.initialDocumentId});

  @override
  State<VisualEditorPage> createState() => _VisualEditorPageState();
}

class _VisualEditorPageState extends State<VisualEditorPage> {
  final _service = VisualDocumentsService.instance();
  final _uploadService = MediaUploadService.instance();
  final _openRouterService = OpenRouterService.instance();

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _document;
  Map<String, dynamic>? _currentVersion;
  String? _baseImagePath;
  String? _baseImageFileName;
  String? _maskPath;
  String? _maskFileName;
  int? _selectedLayerIndex;
  String _selectionType = 'object';
  String? _selectionMaskUrl;
  String? _hoverMaskUrl;
  bool _hoverSegmentationInProgress = false;
  DateTime? _lastHoverSegmentationAt;
  double _eraseStrength = 0.7;
  String? _magicErasePreviewUrl;
  bool _showMagicErasePreview = false;
  String _outpaintAspectRatio = '16:9';
  final TextEditingController _backgroundPromptController =
      TextEditingController();
  final TextEditingController _localFillPromptController =
      TextEditingController();
  String _maskEditMode = 'ai';
  String _maskBrushMode = 'add';
  double _maskBrushSize = 24.0;
  final List<_MaskStroke> _maskStrokes = <_MaskStroke>[];
  _MaskStroke? _currentMaskStroke;
  String? _backgroundImagePath;
  String? _backgroundImageFileName;
  List<Map<String, dynamic>> _projects = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _documentsLibrary =
      const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    final initialId = widget.initialDocumentId?.trim();
    if (initialId != null && initialId.isNotEmpty) {
      _loadDocument(initialId);
    } else {
      _loadLibrary();
    }
  }

  Future<void> _loadLibrary() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final projects = await _service.listProjects();
      final documents = await _service.listDocuments();
      setState(() {
        _projects = projects;
        _documentsLibrary = documents;
      });
    } catch (_) {
      setState(() {
        _projects = const <Map<String, dynamic>>[];
        _documentsLibrary = const <Map<String, dynamic>>[];
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openCreateVisualDialog() async {
    String format = 'square';
    bool confirmed = false;
    final nameController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Créer un nouveau visuel'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du visuel (optionnel)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Format'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Carré'),
                        selected: format == 'square',
                        onSelected: (_) {
                          setStateDialog(() {
                            format = 'square';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Story'),
                        selected: format == 'story',
                        onSelected: (_) {
                          setStateDialog(() {
                            format = 'story';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Paysage'),
                        selected: format == 'landscape',
                        onSelected: (_) {
                          setStateDialog(() {
                            format = 'landscape';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    confirmed = true;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!confirmed || !mounted) {
      return;
    }

    final title = nameController.text.trim().isEmpty
        ? null
        : nameController.text.trim();

    await _createNewVisual(title, format);
  }

  Future<void> _bootstrapDefaultDocumentIfNeeded() async {
    if (_document != null || _loading) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> projects = const <Map<String, dynamic>>[];
      try {
        projects = await _service.listProjects();
      } catch (_) {
        projects = const <Map<String, dynamic>>[];
      }

      Map<String, dynamic> project;
      if (projects.isNotEmpty) {
        project = projects.first;
      } else {
        project = await _service.createProject(name: 'Mes visuels');
      }

      final projectId = project['id'] as String?;
      if (projectId == null || projectId.isEmpty) {
        throw Exception('missing project id');
      }

      final doc = await _service.createDocument(
        projectId: projectId,
        title: 'Nouvelle affiche',
        width: 1080,
        height: 1080,
        dpi: 300,
        backgroundColor: '#0F172A',
      );

      final documentId = doc['id'] as String?;
      if (documentId == null || documentId.isEmpty) {
        throw Exception('missing document id');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final canvasState = <String, dynamic>{
        'canvas': {
          'width': 1080,
          'height': 1080,
          'background': {
            'type': 'color',
            'value': '#0F172A',
          },
        },
        'layers': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'title-$now',
            'type': 'text',
            'name': 'Titre',
            'zIndex': 0,
            'visible': true,
            'locked': false,
            'opacity': 1.0,
            'transform': {
              'x': 0.0,
              'y': 0.0,
              'scaleX': 1.0,
              'scaleY': 1.0,
              'rotation': 0.0,
            },
            'text': {
              'content': 'Titre principal',
              'fontFamily': 'Inter',
              'fontSize': 64.0,
              'color': '#FFFFFF',
              'align': 'center',
              'shadow': null,
            },
          },
        ],
      };

      final version = await _service.saveVersion(
        documentId: documentId,
        canvasState: canvasState,
      );

      setState(() {
        _document = doc;
        _currentVersion = version;
        _selectedLayerIndex = 0;
      });
    } catch (e) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fallbackCanvasState = <String, dynamic>{
        'canvas': {
          'width': 1080,
          'height': 1080,
          'background': {
            'type': 'color',
            'value': '#0F172A',
          },
        },
        'layers': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'title-$now',
            'type': 'text',
            'name': 'Titre',
            'zIndex': 0,
            'visible': true,
            'locked': false,
            'opacity': 1.0,
            'transform': {
              'x': 0.0,
              'y': 0.0,
              'scaleX': 1.0,
              'scaleY': 1.0,
              'rotation': 0.0,
            },
            'text': {
              'content': 'Titre principal',
              'fontFamily': 'Inter',
              'fontSize': 64.0,
              'color': '#FFFFFF',
              'align': 'center',
              'shadow': null,
            },
          },
        ],
      };

      final fallbackDoc = <String, dynamic>{
        'id': null,
        'title': 'Nouvelle affiche',
        'width': 1080,
        'height': 1080,
        'dpi': 300,
        'background_color': '#0F172A',
      };

      setState(() {
        _document = fallbackDoc;
        _currentVersion = <String, dynamic>{
          'id': 'local-initial-version-$now',
          'canvas_state': fallbackCanvasState,
        };
        _selectedLayerIndex = 0;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _createNewVisual(String? title, String format) async {
    int width = 1080;
    int height = 1080;
    switch (format) {
      case 'story':
        width = 1080;
        height = 1920;
        break;
      case 'landscape':
        width = 1920;
        height = 1080;
        break;
      case 'square':
      default:
        width = 1080;
        height = 1080;
        break;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> project;
      if (_projects.isNotEmpty) {
        project = _projects.first;
      } else {
        project = await _service.createProject(name: 'Mes visuels');
      }

      final projectId = project['id'] as String?;
      if (projectId == null || projectId.isEmpty) {
        throw Exception('missing project id');
      }

      final doc = await _service.createDocument(
        projectId: projectId,
        title: title ?? 'Nouveau visuel',
        width: width,
        height: height,
        dpi: 300,
        backgroundColor: '#0F172A',
      );

      final documentId = doc['id'] as String?;
      if (documentId == null || documentId.isEmpty) {
        throw Exception('missing document id');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final canvasState = <String, dynamic>{
        'canvas': {
          'width': width,
          'height': height,
          'background': {
            'type': 'color',
            'value': '#0F172A',
          },
        },
        'layers': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'title-$now',
            'type': 'text',
            'name': 'Titre',
            'zIndex': 0,
            'visible': true,
            'locked': false,
            'opacity': 1.0,
            'transform': {
              'x': 0.0,
              'y': 0.0,
              'scaleX': 1.0,
              'scaleY': 1.0,
              'rotation': 0.0,
            },
            'text': {
              'content': 'Titre principal',
              'fontFamily': 'Inter',
              'fontSize': 64.0,
              'color': '#FFFFFF',
              'align': 'center',
              'shadow': null,
            },
          },
        ],
      };

      final version = await _service.saveVersion(
        documentId: documentId,
        canvasState: canvasState,
      );

      if (!mounted) return;

      setState(() {
        _document = doc;
        _currentVersion = version;
        _selectedLayerIndex = 0;
        _documentsLibrary = <Map<String, dynamic>>[
          doc,
          ..._documentsLibrary,
        ];
      });
    } catch (e) {
      // En cas d'erreur (ex: backend indisponible), on crée tout de même
      // un document local avec un canvas par défaut pour garantir l'UX.
      final now = DateTime.now().millisecondsSinceEpoch;
      final fallbackCanvasState = <String, dynamic>{
        'canvas': {
          'width': width,
          'height': height,
          'background': {
            'type': 'color',
            'value': '#0F172A',
          },
        },
        'layers': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'title-$now',
            'type': 'text',
            'name': 'Titre',
            'zIndex': 0,
            'visible': true,
            'locked': false,
            'opacity': 1.0,
            'transform': {
              'x': 0.0,
              'y': 0.0,
              'scaleX': 1.0,
              'scaleY': 1.0,
              'rotation': 0.0,
            },
            'text': {
              'content': 'Titre principal',
              'fontFamily': 'Inter',
              'fontSize': 64.0,
              'color': '#FFFFFF',
              'align': 'center',
              'shadow': null,
            },
          },
        ],
      };

      final fallbackDoc = <String, dynamic>{
        'id': null,
        'title': title ?? 'Nouveau visuel',
        'width': width,
        'height': height,
        'dpi': 300,
        'background_color': '#0F172A',
      };

      if (!mounted) return;

      setState(() {
        _document = fallbackDoc;
        _currentVersion = <String, dynamic>{
          'id': 'local-initial-version-$now',
          'canvas_state': fallbackCanvasState,
        };
        _selectedLayerIndex = 0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _startMaskStroke(Offset localPosition, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (width <= 0 || height <= 0) {
      return;
    }

    final normalized = Offset(
      (localPosition.dx / width).clamp(0.0, 1.0),
      (localPosition.dy / height).clamp(0.0, 1.0),
    );

    final baseSize = width < height ? width : height;
    final normalizedSize = (baseSize <= 0)
        ? 0.05
        : (_maskBrushSize / baseSize).clamp(0.005, 0.25);

    _currentMaskStroke = _MaskStroke(
      points: <Offset>[normalized],
      mode: _maskBrushMode,
      size: normalizedSize,
    );
    _maskStrokes.add(_currentMaskStroke!);
  }

  void _updateMaskStroke(Offset localPosition, BoxConstraints constraints) {
    final current = _currentMaskStroke;
    if (current == null) {
      return;
    }

    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    if (width <= 0 || height <= 0) {
      return;
    }

    final normalized = Offset(
      (localPosition.dx / width).clamp(0.0, 1.0),
      (localPosition.dy / height).clamp(0.0, 1.0),
    );

    current.points.add(normalized);
  }

  void _endMaskStroke() {
    _currentMaskStroke = null;
  }

  Future<void> _applyMaskBrushEdits() async {
    if (_maskStrokes.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doc = _document;
      final int width =
          doc != null && doc['width'] is num ? (doc['width'] as num).toInt() : 1024;
      final int height =
          doc != null && doc['height'] is num ? (doc['height'] as num).toInt() : 1024;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      );

      final paintBackground = Paint()..color = const Color(0xFF000000);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        paintBackground,
      );

      final paintAdd = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill;
      final paintRemove = Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.fill;

      final minSide = width < height ? width.toDouble() : height.toDouble();

      for (final stroke in _maskStrokes) {
        final paint = stroke.mode == 'add' ? paintAdd : paintRemove;
        final radius = (stroke.size * minSide).clamp(1.0, minSide / 2);
        for (final p in stroke.points) {
          final dx = (p.dx.clamp(0.0, 1.0)) * width;
          final dy = (p.dy.clamp(0.0, 1.0)) * height;
          canvas.drawCircle(Offset(dx, dy), radius, paint);
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode mask image');
      }
      final bytes = byteData.buffer.asUint8List();

      final path = await _uploadService.uploadBinaryData(
        bytes,
        prefix: 'visual_mask_brush',
      );

      String? publicUrl;
      try {
        publicUrl = _uploadService.getPublicUrl(path);
      } catch (_) {
        publicUrl = null;
      }

      setState(() {
        _maskPath = path;
        _maskFileName = 'Masque édité (pinceau)';
        if (publicUrl != null && publicUrl.isNotEmpty) {
          _selectionMaskUrl = publicUrl;
        }
        _magicErasePreviewUrl = null;
        _showMagicErasePreview = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la sauvegarde du masque édité: $e';
      });
    } finally {
      setState(() {
        _loading = false;
        _maskStrokes.clear();
        _currentMaskStroke = null;
      });
    }
  }

  @override
  void dispose() {
    _backgroundPromptController.dispose();
    _localFillPromptController.dispose();
    super.dispose();
  }

  Future<void> _pickBaseImage() async {
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
          await _uploadService.uploadReferenceMedia(file, prefix: 'visual_base');
      setState(() {
        _baseImagePath = path;
        _baseImageFileName = file.name;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'upload de l\'image de base: $e';
      });
    }
  }

  Future<void> _openVersionsDialog() async {
    final doc = _document;
    if (doc == null) return;
    final documentId = doc['id'] as String?;
    if (documentId == null) return;

    setState(() {
      _error = null;
    });

    List<Map<String, dynamic>> versions = const <Map<String, dynamic>>[];
    try {
      versions = await _service.listVersions(documentId: documentId);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des versions: $e';
      });
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Historique des versions'),
          content: SizedBox(
            width: 420,
            height: 320,
            child: versions.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune version enregistrée pour ce document.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: versions.length,
                    itemBuilder: (context, index) {
                      final v = versions[index];
                      final versionIndex = v['version_index'];
                      final isCurrent = v['is_current'] == true;
                      final createdAt = v['created_at'] as String?;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isCurrent
                              ? Icons.check_circle_outline
                              : Icons.history,
                          color: isCurrent ? Colors.lightGreenAccent : Colors.white70,
                        ),
                        title: Text('Version $versionIndex'),
                        subtitle: createdAt != null
                            ? Text(
                                createdAt,
                                style: const TextStyle(fontSize: 11),
                              )
                            : null,
                        trailing: TextButton(
                          onPressed: () async {
                            try {
                              final restored = await _service.restoreVersion(
                                versionId: v['id'] as String,
                              );
                              if (!mounted) return;
                              setState(() {
                                _currentVersion = restored;
                              });
                              Navigator.of(dialogContext).pop();
                            } catch (e) {
                              if (!mounted) return;
                              setState(() {
                                _error = 'Erreur lors de la restauration: $e';
                              });
                            }
                          },
                          child: const Text('Restaurer'),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
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
          await _uploadService.uploadReferenceMedia(file, prefix: 'visual_mask');
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

  Future<void> _pickBackgroundImage() async {
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
        prefix: 'visual_background',
      );
      setState(() {
        _backgroundImagePath = path;
        _backgroundImageFileName = file.name;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'upload de l\'image de fond: $e';
      });
    }
  }

  Map<String, dynamic> _ensureCanvasStateInitialized() {
    final doc = _document;
    if (doc == null) {
      return <String, dynamic>{
        'canvas': {
          'width': null,
          'height': null,
          'background': {
            'type': 'color',
            'value': '#0F172A',
          },
        },
        'layers': <Map<String, dynamic>>[],
      };
    }

    if (_currentVersion != null &&
        _currentVersion!['canvas_state'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(
        _currentVersion!['canvas_state'] as Map<String, dynamic>,
      );
    }

    return <String, dynamic>{
      'canvas': {
        'width': doc['width'],
        'height': doc['height'],
        'background': {
          'type': 'color',
          'value': doc['background_color'] ?? '#0F172A',
        },
      },
      'layers': <Map<String, dynamic>>[],
    };
  }

  Future<void> _saveCanvasState(Map<String, dynamic> canvasState) async {
    final doc = _document;
    if (doc == null) return;
    final documentId = doc['id'] as String?;
    if (documentId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final version = await _service.saveVersion(
        documentId: documentId,
        canvasState: canvasState,
      );
      setState(() {
        _currentVersion = version;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la sauvegarde: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _applyLocalFillAi() async {
    final basePath = _baseImagePath;
    final maskPath = _maskPath;
    final prompt = _localFillPromptController.text.trim();

    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }

    if (maskPath == null || maskPath.trim().isEmpty) {
      setState(() {
        _error =
            'Veuillez fournir un masque pour la zone à remplir (sélection IA ou pinceau).';
      });
      return;
    }

    if (prompt.isEmpty) {
      setState(() {
        _error =
            'Veuillez décrire ce que vous souhaitez générer dans la zone masquée.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _openRouterService.generateImage(
        prompt:
            'Inside the masked area of the reference image, generate the following content: $prompt. Keep all unmasked areas as close as possible to the original image, without altering faces or the global composition.',
        referenceMediaPath: basePath,
        mode: 'inpaint',
        maskPath: maskPath,
        negativePrompt:
            'artifacts, obvious seams, duplicated limbs, deformed faces, unnatural textures, low resolution, heavy compression',
      );

      final canvasState = _ensureCanvasStateInitialized();
      final layers = (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];

      if (layers.isEmpty) {
        layers.add({
          'id': 'background-local-fill',
          'type': 'image',
          'name': 'Remplissage local (IA)',
          'zIndex': 0,
          'visible': true,
          'locked': false,
          'opacity': 1.0,
          'storagePath': basePath,
          'maskPath': maskPath,
          'outputUrl': res.url,
        });
      } else {
        layers[0]['type'] = 'image';
        layers[0]['name'] =
            (layers[0]['name'] as String?) ?? 'Remplissage local (IA)';
        layers[0]['storagePath'] = basePath;
        layers[0]['maskPath'] = maskPath;
        layers[0]['outputUrl'] = res.url;
      }

      canvasState['layers'] = layers;
      await _saveCanvasState(canvasState);

      setState(() {
        _magicErasePreviewUrl = null;
        _showMagicErasePreview = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du remplissage local IA: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _applyFaceEnhanceAi() async {
    final basePath = _baseImagePath;
    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _openRouterService.generateImage(
        prompt:
            'Gently enhance the faces in the image: correct skin tone, reduce small blemishes and noise, and improve clarity of eyes and mouth, while strictly preserving the person\'s identity, proportions and expression. Do not modify the background or overall composition.',
        referenceMediaPath: basePath,
        mode: 'img2img',
        negativePrompt:
            'distorted faces, plastic skin, over-smoothed skin, double eyes, double mouth, extra limbs, caricature style, low resolution',
      );

      final canvasState = _ensureCanvasStateInitialized();
      final layers =
          (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];

      if (layers.isEmpty) {
        layers.add({
          'id': 'background-face-enhanced',
          'type': 'image',
          'name': 'Visage amélioré (IA)',
          'zIndex': 0,
          'visible': true,
          'locked': false,
          'opacity': 1.0,
          'storagePath': basePath,
          'outputUrl': res.url,
        });
      } else {
        layers[0]['type'] = 'image';
        layers[0]['name'] =
            (layers[0]['name'] as String?) ?? 'Visage amélioré (IA)';
        layers[0]['storagePath'] = basePath;
        layers[0]['outputUrl'] = res.url;
      }

      canvasState['layers'] = layers;
      await _saveCanvasState(canvasState);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'amélioration visage IA: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _addTextLayer() async {
    final canvasState = _ensureCanvasStateInitialized();
    final layers = (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];

    final now = DateTime.now().millisecondsSinceEpoch;
    final newLayerId = 'text-$now';

    final newLayer = <String, dynamic>{
      'id': newLayerId,
      'type': 'text',
      'name': 'Texte',
      'zIndex': layers.length,
      'visible': true,
      'locked': false,
      'opacity': 1.0,
      'transform': {
        'x': 0.0,
        'y': 0.0,
        'scaleX': 1.0,
        'scaleY': 1.0,
        'rotation': 0.0,
      },
      'text': {
        'content': 'Nexiom group',
        'fontFamily': 'Inter',
        'fontSize': 32.0,
        'color': '#FFFFFF',
        'align': 'center',
        'shadow': null,
      },
    };

    layers.add(newLayer);
    for (var i = 0; i < layers.length; i++) {
      layers[i]['zIndex'] = i;
    }

    canvasState['layers'] = layers;
    await _saveCanvasState(canvasState);

    setState(() {
      _selectedLayerIndex = layers.length - 1;
    });
  }

  Future<void> _deleteSelectedLayer() async {
    final index = _selectedLayerIndex;
    if (index == null || index < 0) {
      return;
    }

    final canvasState = _ensureCanvasStateInitialized();
    final layers = (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    if (index >= layers.length) {
      return;
    }

    layers.removeAt(index);
    for (var i = 0; i < layers.length; i++) {
      layers[i]['zIndex'] = i;
    }
    canvasState['layers'] = layers;
    await _saveCanvasState(canvasState);

    setState(() {
      if (layers.isEmpty) {
        _selectedLayerIndex = null;
      } else {
        _selectedLayerIndex = (index - 1).clamp(0, layers.length - 1);
      }
    });
  }

  Future<void> _moveSelectedLayer(int delta) async {
    final currentIndex = _selectedLayerIndex;
    if (currentIndex == null) return;

    final canvasState = _ensureCanvasStateInitialized();
    final layers = (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    if (currentIndex < 0 || currentIndex >= layers.length) return;

    final newIndex = currentIndex + delta;
    if (newIndex < 0 || newIndex >= layers.length) return;

    final layer = layers.removeAt(currentIndex);
    layers.insert(newIndex, layer);
    for (var i = 0; i < layers.length; i++) {
      layers[i]['zIndex'] = i;
    }

    canvasState['layers'] = layers;
    await _saveCanvasState(canvasState);

    setState(() {
      _selectedLayerIndex = newIndex;
    });
  }

  Future<void> _editSelectedTextLayer() async {
    final index = _selectedLayerIndex;
    if (index == null || index < 0) {
      setState(() {
        _error = 'Aucun calque sélectionné.';
      });
      return;
    }

    final canvasState = _ensureCanvasStateInitialized();
    final layers = (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    if (index >= layers.length) {
      return;
    }

    final layer = layers[index];
    if (layer['type'] != 'text') {
      setState(() {
        _error = 'Le calque sélectionné n\'est pas un calque texte.';
      });
      return;
    }

    final existingText =
        (layer['text'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final contentController =
        TextEditingController(text: existingText['content'] as String? ?? '');
    final fontSizeController = TextEditingController(
      text: (existingText['fontSize']?.toString() ?? '32'),
    );
    final colorController = TextEditingController(
      text: existingText['color'] as String? ?? '#FFFFFF',
    );

    String align = existingText['align'] as String? ?? 'center';
    String fontFamily = existingText['fontFamily'] as String? ?? 'Inter';
    bool isBold = (existingText['fontWeight'] as String?) == 'bold';
    bool isItalic = (existingText['fontStyle'] as String?) == 'italic';
    double letterSpacing =
        (existingText['letterSpacing'] as num?)?.toDouble() ?? 0.0;
    double lineHeight =
        (existingText['lineHeight'] as num?)?.toDouble() ?? 1.0;

    final shouldApply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Éditer le texte du calque'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Texte'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: fontSizeController,
                      decoration:
                          const InputDecoration(labelText: 'Taille (px)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: colorController,
                      decoration: const InputDecoration(
                        labelText: 'Couleur (#RRGGBB)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Alignement:'),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Gauche'),
                          selected: align == 'left',
                          onSelected: (_) {
                            setStateDialog(() {
                              align = 'left';
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('Centre'),
                          selected: align == 'center',
                          onSelected: (_) {
                            setStateDialog(() {
                              align = 'center';
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('Droite'),
                          selected: align == 'right',
                          onSelected: (_) {
                            setStateDialog(() {
                              align = 'right';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: fontFamily,
                      decoration: const InputDecoration(
                        labelText: 'Police',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Inter',
                          child: Text('Inter'),
                        ),
                        DropdownMenuItem(
                          value: 'Roboto',
                          child: Text('Roboto'),
                        ),
                        DropdownMenuItem(
                          value: 'Montserrat',
                          child: Text('Montserrat'),
                        ),
                        DropdownMenuItem(
                          value: 'Playfair Display',
                          child: Text('Playfair Display'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setStateDialog(() {
                          fontFamily = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Style :'),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Gras'),
                          selected: isBold,
                          onSelected: (selected) {
                            setStateDialog(() {
                              isBold = selected;
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        FilterChip(
                          label: const Text('Italique'),
                          selected: isItalic,
                          onSelected: (selected) {
                            setStateDialog(() {
                              isItalic = selected;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Espacement des lettres'),
                        Slider(
                          value: letterSpacing.clamp(0.0, 0.5),
                          min: 0.0,
                          max: 0.5,
                          divisions: 10,
                          label: letterSpacing.toStringAsFixed(2),
                          onChanged: (value) {
                            setStateDialog(() {
                              letterSpacing = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hauteur de ligne'),
                        Slider(
                          value: lineHeight.clamp(0.8, 2.0),
                          min: 0.8,
                          max: 2.0,
                          divisions: 12,
                          label: lineHeight.toStringAsFixed(2),
                          onChanged: (value) {
                            setStateDialog(() {
                              lineHeight = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Appliquer'),
            ),
          ],
        );
      },
    );

    if (shouldApply != true) {
      contentController.dispose();
      fontSizeController.dispose();
      colorController.dispose();
      return;
    }

    final fontSize =
        double.tryParse(fontSizeController.text.trim()) ?? 32.0;

    final updatedText = Map<String, dynamic>.from(existingText);
    updatedText['content'] = contentController.text;
    updatedText['fontSize'] = fontSize;
    final colorText = colorController.text.trim();
    updatedText['color'] = colorText.isEmpty ? '#FFFFFF' : colorText;
    updatedText['align'] = align;
    updatedText['fontFamily'] = fontFamily;
    updatedText['fontWeight'] = isBold ? 'bold' : 'normal';
    updatedText['fontStyle'] = isItalic ? 'italic' : 'normal';
    updatedText['letterSpacing'] = letterSpacing;
    updatedText['lineHeight'] = lineHeight;

    final updatedLayer = Map<String, dynamic>.from(layer);
    updatedLayer['text'] = updatedText;
    layers[index] = updatedLayer;
    canvasState['layers'] = layers;
    await _saveCanvasState(canvasState);

    contentController.dispose();
    fontSizeController.dispose();
    colorController.dispose();
  }

  Future<void> _applyBrandPreset() async {
    final canvasState = _ensureCanvasStateInitialized();

    final canvas =
        (canvasState['canvas'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final background =
        (canvas['background'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    background['type'] = 'color';
    background['value'] = background['value'] ?? '#0F172A';
    canvas['background'] = background;
    canvasState['canvas'] = canvas;

    final layers = (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    for (final layer in layers) {
      if (layer['type'] == 'text') {
        final text =
            (layer['text'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        text['fontFamily'] = text['fontFamily'] ?? 'Inter';
        text['color'] = text['color'] ?? '#FFFFFF';
        layer['text'] = text;
      }
    }
    canvasState['layers'] = layers;

    await _saveCanvasState(canvasState);
  }

  Future<void> _exportCanvasState() async {
    final canvasState = _ensureCanvasStateInitialized();
    final formatted = const JsonEncoder.withIndent('  ').convert(canvasState);

    await Clipboard.setData(ClipboardData(text: formatted));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Canvas JSON copié dans le presse-papier'),
      ),
    );
  }

  Future<void> _exportSmartRenditions() async {
    final doc = _document;
    if (doc == null) {
      return;
    }

    final canvasState = _ensureCanvasStateInitialized();

    final exportPayload = <String, dynamic>{
      'documentId': doc['id'],
      'title': doc['title'],
      'baseImagePath': _baseImagePath,
      'currentOutpaintAspectRatio': _outpaintAspectRatio,
      'canvasState': canvasState,
      'renditions': [
        {
          'id': 'instagram_story',
          'label': 'Story verticale',
          'aspectRatio': '9:16',
        },
        {
          'id': 'instagram_post',
          'label': 'Post carré',
          'aspectRatio': '1:1',
        },
        {
          'id': 'tiktok_vertical',
          'label': 'Vidéo verticale / TikTok',
          'aspectRatio': '9:16',
        },
        {
          'id': 'youtube_thumbnail',
          'label': 'Miniature YouTube',
          'aspectRatio': '16:9',
        },
      ],
    };

    final formatted = const JsonEncoder.withIndent('  ').convert(exportPayload);
    await Clipboard.setData(ClipboardData(text: formatted));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exports intelligents copiés dans le presse-papier'),
      ),
    );
  }

  Future<void> _openTemplatesDialog() async {
    final selectedPreset = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Templates & presets'),
          children: [
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(dialogContext).pop('instagram_square'),
              child: const Text('Post Instagram carré (1080x1080)'),
            ),
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(dialogContext).pop('story_vertical'),
              child: const Text('Story verticale (1080x1920)'),
            ),
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(dialogContext).pop('youtube_thumbnail'),
              child: const Text('Miniature YouTube (1280x720)'),
            ),
          ],
        );
      },
    );

    if (selectedPreset == null) {
      return;
    }

    await _applyTemplatePreset(selectedPreset);
  }

  Future<void> _applyTemplatePreset(String presetId) async {
    final doc = _document;
    if (doc == null) {
      setState(() {
        _error = 'Aucun document chargé pour appliquer un template.';
      });
      return;
    }

    final canvasState = _ensureCanvasStateInitialized();
    final canvas =
        (canvasState['canvas'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    int width =
        canvas['width'] is num ? (canvas['width'] as num).toInt() : 1080;
    int height =
        canvas['height'] is num ? (canvas['height'] as num).toInt() : 1080;

    String backgroundColor =
        ((canvas['background'] as Map?)?.cast<String, dynamic>() ??
                    <String, dynamic>{})['value'] as String? ??
            '#0F172A';

    final layers = <Map<String, dynamic>>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    if (presetId == 'instagram_square') {
      width = 1080;
      height = 1080;
      backgroundColor = '#0F172A';

      layers.add({
        'id': 'title-$now',
        'type': 'text',
        'name': 'Titre',
        'zIndex': 0,
        'visible': true,
        'locked': false,
        'opacity': 1.0,
        'transform': {
          'x': 0.0,
          'y': 0.0,
          'scaleX': 1.0,
          'scaleY': 1.0,
          'rotation': 0.0,
        },
        'text': {
          'content': 'Titre principal',
          'fontFamily': 'Inter',
          'fontSize': 64.0,
          'color': '#FFFFFF',
          'align': 'center',
          'shadow': null,
        },
      });
    } else if (presetId == 'story_vertical') {
      width = 1080;
      height = 1920;
      backgroundColor = '#020617';

      layers.add({
        'id': 'story-title-$now',
        'type': 'text',
        'name': 'Titre story',
        'zIndex': 0,
        'visible': true,
        'locked': false,
        'opacity': 1.0,
        'transform': {
          'x': 0.0,
          'y': 0.0,
          'scaleX': 1.0,
          'scaleY': 1.0,
          'rotation': 0.0,
        },
        'text': {
          'content': 'Story Nexiom',
          'fontFamily': 'Inter',
          'fontSize': 56.0,
          'color': '#FFFFFF',
          'align': 'center',
          'shadow': null,
        },
      });
      layers.add({
        'id': 'story-subtitle-$now',
        'type': 'text',
        'name': 'Sous-titre',
        'zIndex': 1,
        'visible': true,
        'locked': false,
        'opacity': 1.0,
        'transform': {
          'x': 0.0,
          'y': 0.0,
          'scaleX': 1.0,
          'scaleY': 1.0,
          'rotation': 0.0,
        },
        'text': {
          'content': 'Texte d\'accroche en 2 lignes',
          'fontFamily': 'Inter',
          'fontSize': 32.0,
          'color': '#E5E5E5',
          'align': 'center',
          'shadow': null,
        },
      });
    } else if (presetId == 'youtube_thumbnail') {
      width = 1280;
      height = 720;
      backgroundColor = '#111827';

      layers.add({
        'id': 'yt-title-$now',
        'type': 'text',
        'name': 'Titre YouTube',
        'zIndex': 0,
        'visible': true,
        'locked': false,
        'opacity': 1.0,
        'transform': {
          'x': 0.0,
          'y': 0.0,
          'scaleX': 1.0,
          'scaleY': 1.0,
          'rotation': 0.0,
        },
        'text': {
          'content': 'Titre vidéo percutant',
          'fontFamily': 'Inter',
          'fontSize': 72.0,
          'color': '#FFFFFF',
          'align': 'center',
          'shadow': null,
        },
      });
    }

    for (var i = 0; i < layers.length; i++) {
      layers[i]['zIndex'] = i;
    }

    canvas['width'] = width;
    canvas['height'] = height;
    canvas['background'] = <String, dynamic>{
      'type': 'color',
      'value': backgroundColor,
    };
    canvasState['canvas'] = canvas;
    canvasState['layers'] = layers;

    await _saveCanvasState(canvasState);
  }

  Future<void> _openLibraryDialog() async {
    setState(() {
      _error = null;
    });

    List<Map<String, dynamic>> projects =
        const <Map<String, dynamic>>[];
    List<Map<String, dynamic>> documents =
        const <Map<String, dynamic>>[];

    try {
      projects = await _service.listProjects();
      documents = await _service.listDocuments();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement de la bibliothèque: $e';
      });
      return;
    }

    if (!mounted) return;

    final doc = _document;
    String? selectedProjectId =
        doc != null ? doc['project_id'] as String? : null;
    String? chosenDocumentId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filteredDocs = documents.where((d) {
              if (selectedProjectId == null) return true;
              return d['project_id'] == selectedProjectId;
            }).toList();

            String projectNameFor(String? projectId) {
              if (projectId == null) return '';
              final match = projects.firstWhere(
                (p) => p['id'] == projectId,
                orElse: () => <String, dynamic>{},
              );
              final name = match['name'] as String?;
              return name ?? '';
            }

            return AlertDialog(
              title: const Text('Bibliothèque de documents'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String?>(
                      value: selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Projet',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tous les projets'),
                        ),
                        ...projects.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p['id'] as String?,
                            child: Text(
                              p['name'] as String? ?? 'Projet sans nom',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedProjectId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: filteredDocs.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun document disponible.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                final d = filteredDocs[index];
                                final title =
                                    d['title'] as String? ?? 'Document sans titre';
                                final width = d['width'];
                                final height = d['height'];
                                final projectName =
                                    projectNameFor(d['project_id'] as String?);
                                final subtitleParts = <String>[];
                                if (width != null && height != null) {
                                  subtitleParts.add('${width}x$height');
                                }
                                if (projectName.isNotEmpty) {
                                  subtitleParts.add(projectName);
                                }
                                return ListTile(
                                  title: Text(title),
                                  subtitle: subtitleParts.isEmpty
                                      ? null
                                      : Text(
                                          subtitleParts.join(' • '),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                  onTap: () {
                                    chosenDocumentId = d['id'] as String?;
                                    Navigator.of(dialogContext).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (chosenDocumentId != null) {
      await _loadDocument(chosenDocumentId!);
    }
  }

  Future<void> _applyBackgroundRemoval() async {
    final basePath = _baseImagePath;
    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _openRouterService.generateImage(
        prompt:
            'Remove the background of the reference image, keep the main subject sharp and clean, and return a high quality result suitable for compositing.',
        referenceMediaPath: basePath,
        mode: 'background_removal',
        negativePrompt:
            'artifacts, halos, unnatural edges, missing parts of the subject, low resolution, heavy compression',
      );

      final canvasState = _ensureCanvasStateInitialized();
      final layers = (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];

      if (layers.isEmpty) {
        layers.add({
          'id': 'background',
          'type': 'image',
          'name': 'Image (fond supprimé)',
          'zIndex': 0,
          'visible': true,
          'locked': false,
          'opacity': 1.0,
          'storagePath': basePath,
          'outputUrl': res.url,
        });
      } else {
        layers[0]['type'] = 'image';
        layers[0]['name'] = layers[0]['name'] ?? 'Image (fond supprimé)';
        layers[0]['storagePath'] = basePath;
        layers[0]['outputUrl'] = res.url;
      }

      canvasState['layers'] = layers;
      await _saveCanvasState(canvasState);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la suppression du fond: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _applyInpaintRemove() async {
    final basePath = _baseImagePath;
    final maskPath = _maskPath;
    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }
    if (maskPath == null || maskPath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez fournir un masque pour la zone à supprimer.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _openRouterService.generateImage(
        prompt:
            'Remove the object or person inside the masked area and reconstruct the background in a natural and coherent way with the rest of the image.',
        referenceMediaPath: basePath,
        mode: 'inpaint',
        maskPath: maskPath,
        negativePrompt:
            'artifacts, obvious seams, duplicated limbs, deformed faces, unnatural textures, low resolution',
      );

      final canvasState = _ensureCanvasStateInitialized();
      final layers = (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];

      if (layers.isEmpty) {
        layers.add({
          'id': 'background',
          'type': 'image',
          'name': 'Image retouchée (gomme IA)',
          'zIndex': 0,
          'visible': true,
          'locked': false,
          'opacity': 1.0,
          'storagePath': basePath,
          'maskPath': maskPath,
          'outputUrl': res.url,
        });
      } else {
        layers[0]['type'] = 'image';
        layers[0]['name'] = layers[0]['name'] ?? 'Image retouchée (gomme IA)';
        layers[0]['storagePath'] = basePath;
        layers[0]['maskPath'] = maskPath;
        layers[0]['outputUrl'] = res.url;
      }

      canvasState['layers'] = layers;
      await _saveCanvasState(canvasState);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la retouche (gomme IA): $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _applyBackgroundReplaceAi() async {
    final basePath = _baseImagePath;
    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }

    final prompt = _backgroundPromptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _error = 'Veuillez décrire le nouveau fond (texte).';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<String>? environmentRefs;
      double? environmentStrength;
      if (_backgroundImagePath != null &&
          _backgroundImagePath!.trim().isNotEmpty) {
        environmentRefs = <String>[_backgroundImagePath!];
        environmentStrength = 0.7;
      }

      final res = await _openRouterService.generateImage(
        prompt:
            'Generate a high quality photographic background only (no main subject or person) that matches this description: $prompt. The background must be coherent with the original subject in terms of lighting, perspective and color palette.',
        referenceMediaPath: basePath,
        mode: 'img2img',
        negativePrompt:
            'people, person, face, main subject, portraits, foreground subject, duplicated characters',
        environmentReferencePaths: environmentRefs,
        environmentStrength: environmentStrength,
      );

      final canvasState = _ensureCanvasStateInitialized();
      final layers =
          (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];

      final now = DateTime.now().millisecondsSinceEpoch;
      final bgLayer = <String, dynamic>{
        'id': 'bg-$now',
        'type': 'image',
        'name': 'Fond IA',
        'zIndex': 0,
        'visible': true,
        'locked': false,
        'opacity': 1.0,
        'storagePath': res.url,
        'outputUrl': res.url,
      };

      for (var i = 0; i < layers.length; i++) {
        final currentZ = (layers[i]['zIndex'] as num?) ?? i;
        layers[i]['zIndex'] = currentZ + 1;
      }
      layers.insert(0, bgLayer);

      canvasState['layers'] = layers;
      await _saveCanvasState(canvasState);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du remplacement de fond IA: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _applyOutpaintAi() async {
    final basePath = _baseImagePath;
    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _openRouterService.generateImage(
        prompt:
            'Using the reference image, perform outpainting to extend the scene to a $_outpaintAspectRatio composition while keeping the main subject intact and centered. Preserve the existing style, lighting and overall quality while filling the newly exposed areas with coherent background content.',
        referenceMediaPath: basePath,
        mode: 'outpaint',
        negativePrompt:
            'cropped faces, cut limbs, duplicated heads, unnatural borders, noisy background, low resolution',
        aspectRatio: _outpaintAspectRatio,
      );

      final canvasState = _ensureCanvasStateInitialized();
      final layers =
          (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];

      final canvas =
          (canvasState['canvas'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};

      int targetWidth =
          canvas['width'] is num ? (canvas['width'] as num).toInt() : 1920;
      int targetHeight =
          canvas['height'] is num ? (canvas['height'] as num).toInt() : 1080;

      if (_outpaintAspectRatio == '9:16') {
        targetWidth = 1080;
        targetHeight = 1920;
      } else if (_outpaintAspectRatio == '1:1') {
        targetWidth = 1500;
        targetHeight = 1500;
      } else if (_outpaintAspectRatio == '4:5') {
        targetWidth = 1600;
        targetHeight = 2000;
      } else {
        targetWidth = 1920;
        targetHeight = 1080;
      }

      canvas['width'] = targetWidth;
      canvas['height'] = targetHeight;
      canvasState['canvas'] = canvas;

      if (layers.isEmpty) {
        layers.add({
          'id': 'background-outpaint',
          'type': 'image',
          'name': 'Image étendue (outpainting)',
          'zIndex': 0,
          'visible': true,
          'locked': false,
          'opacity': 1.0,
          'storagePath': basePath,
          'outputUrl': res.url,
        });
      } else {
        layers[0]['type'] = 'image';
        layers[0]['name'] =
            (layers[0]['name'] as String?) ?? 'Image étendue (outpainting)';
        layers[0]['storagePath'] = basePath;
        layers[0]['outputUrl'] = res.url;
      }

      canvasState['layers'] = layers;
      await _saveCanvasState(canvasState);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'outpainting IA: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _applyGlobalHarmonizeAi() async {
    final basePath = _baseImagePath;
    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _openRouterService.generateImage(
        prompt:
            'Globally harmonize the colors, contrast, lighting and style of the image so that it looks coherent, cinematic and professional, while strictly preserving the content, composition and faces.',
        referenceMediaPath: basePath,
        mode: 'img2img',
        negativePrompt:
            'over-saturated colors, extreme filters, washed out image, banding, low resolution, exaggerated skin smoothing',
      );

      final canvasState = _ensureCanvasStateInitialized();
      final layers =
          (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];

      if (layers.isEmpty) {
        layers.add({
          'id': 'background-harmonized',
          'type': 'image',
          'name': 'Image harmonisée (IA)',
          'zIndex': 0,
          'visible': true,
          'locked': false,
          'opacity': 1.0,
          'storagePath': basePath,
          'outputUrl': res.url,
        });
      } else {
        layers[0]['type'] = 'image';
        layers[0]['name'] =
            (layers[0]['name'] as String?) ?? 'Image harmonisée (IA)';
        layers[0]['storagePath'] = basePath;
        layers[0]['outputUrl'] = res.url;
      }

      canvasState['layers'] = layers;
      await _saveCanvasState(canvasState);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'harmonisation globale IA: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _runMagicEraserGeneration() async {
    final basePath = _baseImagePath;
    final maskPath = _maskPath;

    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }

    if (maskPath == null || maskPath.trim().isEmpty) {
      setState(() {
        _error = 'Aucune sélection IA n\'est disponible pour la gomme magique.';
      });
      return;
    }

    String strengthLabel;
    if (_eraseStrength < 0.33) {
      strengthLabel = 'soft';
    } else if (_eraseStrength < 0.66) {
      strengthLabel = 'medium';
    } else {
      strengthLabel = 'strong';
    }

    try {
      final res = await _openRouterService.generateImage(
        prompt:
            'Using the provided black and white mask, remove the selected object or person from the image with a $strengthLabel cleanup and reconstruct the background so that it looks natural and coherent with the rest of the scene. Avoid artifacts, seams or obvious retouching.',
        referenceMediaPath: basePath,
        mode: 'inpaint',
        maskPath: maskPath,
        negativePrompt:
            'artifacts, obvious seams, duplicated limbs, deformed faces, unnatural textures, low resolution, heavy compression',
      );

      setState(() {
        _magicErasePreviewUrl = res.url;
        _showMagicErasePreview = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la gomme magique: $e';
      });
    }
  }

  Offset _normalizeImagePosition(Offset localPosition, BoxConstraints constraints) {
    final doc = _document;
    final double? docWidth =
        doc != null && doc['width'] is num ? (doc['width'] as num).toDouble() : null;
    final double? docHeight =
        doc != null && doc['height'] is num ? (doc['height'] as num).toDouble() : null;

    final containerWidth = constraints.maxWidth;
    final containerHeight = constraints.maxHeight;

    double xNorm;
    double yNorm;

    if (docWidth != null &&
        docWidth > 0 &&
        docHeight != null &&
        docHeight > 0 &&
        containerWidth > 0 &&
        containerHeight > 0) {
      final imageRatio = docWidth / docHeight;
      final containerRatio = containerWidth / containerHeight;

      double displayWidth;
      double displayHeight;
      double offsetX;
      double offsetY;

      if (containerRatio > imageRatio) {
        displayHeight = containerHeight;
        displayWidth = displayHeight * imageRatio;
        offsetX = (containerWidth - displayWidth) / 2;
        offsetY = 0;
      } else {
        displayWidth = containerWidth;
        displayHeight = displayWidth / imageRatio;
        offsetX = 0;
        offsetY = (containerHeight - displayHeight) / 2;
      }

      final dx = localPosition.dx;
      final dy = localPosition.dy;

      if (dx < offsetX || dx > offsetX + displayWidth || dy < offsetY || dy > offsetY + displayHeight) {
        return const Offset(-1, -1);
      }

      xNorm = (dx - offsetX) / displayWidth;
      yNorm = (dy - offsetY) / displayHeight;
    } else {
      xNorm = containerWidth > 0 ? localPosition.dx / containerWidth : 0.5;
      yNorm = containerHeight > 0 ? localPosition.dy / containerHeight : 0.5;
    }

    xNorm = xNorm.clamp(0.0, 1.0);
    yNorm = yNorm.clamp(0.0, 1.0);
    return Offset(xNorm, yNorm);
  }

  Future<void> _handleImageTap(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    final basePath = _baseImagePath;
    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }

    final norm = _normalizeImagePosition(details.localPosition, constraints);
    if (norm.dx < 0 || norm.dy < 0) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _openRouterService.segmentImage(
        referenceMediaPath: basePath,
        x: norm.dx,
        y: norm.dy,
        selectionType: _selectionType,
      );

      final maskPath = data['maskPath'] as String?;
      final maskUrl = data['maskUrl'] as String?;

      if (maskPath == null || maskPath.trim().isEmpty) {
        setState(() {
          _error = 'La sélection IA n\'a pas renvoyé de masque exploitable.';
        });
        return;
      }

      setState(() {
        _maskPath = maskPath;
        _maskFileName = 'Masque IA ($_selectionType)';
        _selectionMaskUrl = maskUrl;
        _hoverMaskUrl = null;
      });

      await _runMagicEraserGeneration();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la sélection intelligente: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleImageHover(
    PointerHoverEvent event,
    BoxConstraints constraints,
  ) async {
    final basePath = _baseImagePath;
    if (basePath == null || basePath.trim().isEmpty) {
      return;
    }

    final now = DateTime.now();
    if (_hoverSegmentationInProgress) {
      return;
    }
    if (_lastHoverSegmentationAt != null &&
        now.difference(_lastHoverSegmentationAt!).inMilliseconds < 400) {
      return;
    }

    final norm = _normalizeImagePosition(event.localPosition, constraints);
    if (norm.dx < 0 || norm.dy < 0) {
      return;
    }

    _hoverSegmentationInProgress = true;
    _lastHoverSegmentationAt = now;

    try {
      final data = await _openRouterService.segmentImage(
        referenceMediaPath: basePath,
        x: norm.dx,
        y: norm.dy,
        selectionType: _selectionType,
      );

      final maskPath = data['maskPath'] as String?;
      final maskUrl = data['maskUrl'] as String?;

      if (maskPath == null || maskPath.trim().isEmpty) {
        return;
      }

      setState(() {
        _hoverMaskUrl = maskUrl;
      });
    } catch (_) {
      // On ignore les erreurs de survol pour ne pas gêner l'utilisateur.
    } finally {
      _hoverSegmentationInProgress = false;
    }
  }

  Widget _buildSelectionPreview(Map<String, dynamic>? canvasState) {
    final noImageWidget = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Aucune image disponible pour la sélection IA.\nImportez une image et appliquez un outil IA pour lancer la sélection.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54),
      ),
    );

    // Si un aperçu de gomme magique est actif, on le montre en priorité
    if (_showMagicErasePreview && _magicErasePreviewUrl != null) {
      final previewUrl = _magicErasePreviewUrl!.trim();
      if (previewUrl.isEmpty) {
        return noImageWidget;
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          return MouseRegion(
            onHover: (event) {
              if (_maskEditMode == 'ai') {
                _handleImageHover(event, constraints);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (_maskEditMode == 'ai') {
                  _handleImageTap(details, constraints);
                }
              },
              onPanStart: (details) {
                if (_maskEditMode == 'brush') {
                  setState(() {
                    _startMaskStroke(details.localPosition, constraints);
                  });
                }
              },
              onPanUpdate: (details) {
                if (_maskEditMode == 'brush') {
                  setState(() {
                    _updateMaskStroke(details.localPosition, constraints);
                  });
                }
              },
              onPanEnd: (details) {
                if (_maskEditMode == 'brush') {
                  setState(() {
                    _endMaskStroke();
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: const Color(0xFF020617),
                      ),
                      Image.network(
                        previewUrl,
                        fit: BoxFit.contain,
                      ),
                      if (_selectionMaskUrl != null)
                        Opacity(
                          opacity: 0.4,
                          child: Image.network(
                            _selectionMaskUrl!,
                            fit: BoxFit.contain,
                            color: Colors.lightBlueAccent.withOpacity(0.7),
                            colorBlendMode: BlendMode.srcATop,
                          ),
                        ),
                      if (_hoverMaskUrl != null)
                        Opacity(
                          opacity: 0.35,
                          child: Image.network(
                            _hoverMaskUrl!,
                            fit: BoxFit.contain,
                            color: Colors.amberAccent.withOpacity(0.8),
                            colorBlendMode: BlendMode.srcATop,
                          ),
                        ),
                      if (_maskEditMode == 'brush')
                        CustomPaint(
                          painter: _MaskBrushPainter(_maskStrokes),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    final layers = (canvasState?['layers'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    final imageLayers = layers
        .where((layer) => layer['type'] == 'image')
        .where((layer) {
          final url = (layer['outputUrl'] as String?)?.trim();
          return url != null && url.isNotEmpty;
        }).toList();

    if (imageLayers.isEmpty) {
      return noImageWidget;
    }

    imageLayers.sort((a, b) {
      final za = (a['zIndex'] as num?) ?? 0;
      final zb = (b['zIndex'] as num?) ?? 0;
      return za.compareTo(zb);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) {
            if (_maskEditMode == 'ai') {
              _handleImageHover(event, constraints);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              if (_maskEditMode == 'ai') {
                _handleImageTap(details, constraints);
              }
            },
            onPanStart: (details) {
              if (_maskEditMode == 'brush') {
                setState(() {
                  _startMaskStroke(details.localPosition, constraints);
                });
              }
            },
            onPanUpdate: (details) {
              if (_maskEditMode == 'brush') {
                setState(() {
                  _updateMaskStroke(details.localPosition, constraints);
                });
              }
            },
            onPanEnd: (details) {
              if (_maskEditMode == 'brush') {
                setState(() {
                  _endMaskStroke();
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFF020617),
                    ),
                    for (final layer in imageLayers)
                      Image.network(
                        (layer['outputUrl'] as String).trim(),
                        fit: BoxFit.contain,
                      ),
                    if (_selectionMaskUrl != null)
                      Opacity(
                        opacity: 0.4,
                        child: Image.network(
                          _selectionMaskUrl!,
                          fit: BoxFit.contain,
                          color: Colors.lightBlueAccent.withOpacity(0.7),
                          colorBlendMode: BlendMode.srcATop,
                        ),
                      ),
                    if (_hoverMaskUrl != null)
                      Opacity(
                        opacity: 0.35,
                        child: Image.network(
                          _hoverMaskUrl!,
                          fit: BoxFit.contain,
                          color: Colors.amberAccent.withOpacity(0.8),
                          colorBlendMode: BlendMode.srcATop,
                        ),
                      ),
                    if (_maskEditMode == 'brush')
                      CustomPaint(
                        painter: _MaskBrushPainter(_maskStrokes),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyMagicEraserPreview() async {
    final previewUrl = _magicErasePreviewUrl;
    final basePath = _baseImagePath;
    final maskPath = _maskPath;

    if (previewUrl == null || previewUrl.trim().isEmpty) {
      setState(() {
        _error =
            'Aucun aperçu de gomme magique à appliquer. Cliquez d\'abord sur l\'image pour générer un aperçu.';
      });
      return;
    }

    if (basePath == null || basePath.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez d\'abord importer une image de base.';
      });
      return;
    }

    if (maskPath == null || maskPath.trim().isEmpty) {
      setState(() {
        _error = 'Aucune sélection IA n\'est disponible pour la gomme magique.';
      });
      return;
    }

    final canvasState = _ensureCanvasStateInitialized();
    final layers = (canvasState['layers'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];

    if (layers.isEmpty) {
      layers.add({
        'id': 'background',
        'type': 'image',
        'name': 'Image retouchée (gomme magique)',
        'zIndex': 0,
        'visible': true,
        'locked': false,
        'opacity': 1.0,
        'storagePath': basePath,
        'maskPath': maskPath,
        'outputUrl': previewUrl,
      });
    } else {
      layers[0]['type'] = 'image';
      layers[0]['name'] =
          (layers[0]['name'] as String?) ?? 'Image retouchée (gomme magique)';
      layers[0]['storagePath'] = basePath;
      layers[0]['maskPath'] = maskPath;
      layers[0]['outputUrl'] = previewUrl;
    }

    canvasState['layers'] = layers;
    await _saveCanvasState(canvasState);

    setState(() {
      _magicErasePreviewUrl = null;
      _showMagicErasePreview = false;
    });
  }

  Future<void> _loadDocument(String documentId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getDocumentWithCurrentVersion(
        documentId: documentId,
      );
      setState(() {
        _document = (data['document'] as Map?)?.cast<String, dynamic>();
        _currentVersion = (data['version'] as Map?)?.cast<String, dynamic>();
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement du document: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveVersion() async {
    final doc = _document;
    if (doc == null) return;
    final documentId = doc['id'] as String?;
    if (documentId == null) return;

    final canvasState = _currentVersion != null
        ? Map<String, dynamic>.from(_currentVersion!['canvas_state'] as Map? ?? const {})
        : <String, dynamic>{
            'canvas': {
              'width': doc['width'],
              'height': doc['height'],
              'background': {
                'type': 'color',
                'value': doc['background_color'] ?? '#0F172A',
              },
            },
            'layers': <Map<String, dynamic>>[],
          };

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final version = await _service.saveVersion(
        documentId: documentId,
        canvasState: canvasState,
      );
      setState(() {
        _currentVersion = version;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la sauvegarde: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _document;
    final version = _currentVersion;
    final canvasState = version != null
        ? (version['canvas_state'] as Map?)?.cast<String, dynamic>()
        : null;

    final previewCanvas = doc != null
        ? (canvasState ?? _ensureCanvasStateInitialized())
        : null;
    final previewCanvasMeta = (previewCanvas != null
            ? (previewCanvas['canvas'] as Map?)?.cast<String, dynamic>()
            : null) ??
        <String, dynamic>{};
    final previewWidth = previewCanvasMeta['width'];
    final previewHeight = previewCanvasMeta['height'];
    double previewAspectRatio = 1.0;
    if (previewWidth is num && previewHeight is num && previewHeight > 0) {
      previewAspectRatio =
          previewWidth.toDouble() / previewHeight.toDouble();
    }
    final previewBackground =
        (previewCanvasMeta['background'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final previewBgColor =
        _parseHexColor(previewBackground['value'] as String?);
    final previewLayers = (previewCanvas != null
            ? (previewCanvas['layers'] as List?)
            : null)
            ?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    String? previewText;
    for (final layer in previewLayers) {
      if (layer['type'] == 'text') {
        final text =
            (layer['text'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        final content = text['content'] as String?;
        if (content != null && content.trim().isNotEmpty) {
          previewText = content.trim();
          break;
        }
      }
    }

    final Widget mainContent;
    if (doc == null) {
      mainContent = Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes visuels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _openCreateVisualDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau visuel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _documentsLibrary.isEmpty
                  ? const Center(
                      child: Text(
                        'Vous n\'avez encore aucun visuel.\nCliquez sur "Nouveau visuel" pour commencer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _documentsLibrary.length,
                      itemBuilder: (context, index) {
                        final d = _documentsLibrary[index];
                        final title =
                            d['title'] as String? ?? 'Document sans titre';
                        final width = d['width'];
                        final height = d['height'];
                        final createdAt = d['created_at']?.toString();
                        final subtitleParts = <String>[];
                        if (width != null && height != null) {
                          subtitleParts.add('${width}x$height');
                        }
                        if (createdAt != null) {
                          subtitleParts.add(createdAt);
                        }
                        return Card(
                          color: const Color(0xFF020617),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.insert_photo_outlined,
                                color: Colors.white70,
                              ),
                            ),
                            title: Text(title),
                            subtitle: subtitleParts.isEmpty
                                ? null
                                : Text(
                                    subtitleParts.join(' • '),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                            trailing: TextButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      final id = d['id'] as String?;
                                      if (id != null) {
                                        _loadDocument(id);
                                      }
                                    },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Ouvrir'),
                            ),
                            onTap: _loading
                                ? null
                                : () {
                                    final id = d['id'] as String?;
                                    if (id != null) {
                                      _loadDocument(id);
                                    }
                                  },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    } else {
      mainContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doc['title'] as String? ?? 'Document sans titre',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Taille: ${doc['width'] ?? '-'} x ${doc['height'] ?? '-'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Panel gauche : gestion des calques et texte
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calques',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: Builder(
                            builder: (context) {
                              final layers =
                                  (canvasState?['layers'] as List?)
                                          ?.cast<Map<String, dynamic>>() ??
                                      <Map<String, dynamic>>[];
                              if (layers.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Aucun calque',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                );
                              }
                              return ListView.builder(
                                itemCount: layers.length,
                                itemBuilder: (context, index) {
                                  final layer = layers[index];
                                  final type = layer['type'] as String? ?? 'unknown';
                                  final name = layer['name'] as String? ?? type;
                                  final selected = _selectedLayerIndex == index;
                                  return ListTile(
                                    dense: true,
                                    selected: selected,
                                    selectedTileColor:
                                        Colors.blueGrey.withOpacity(0.4),
                                    title: Text(
                                      name,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                    ),
                                    subtitle: Text(
                                      type,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedLayerIndex = index;
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _addTextLayer,
                            icon: const Icon(Icons.title),
                            label: const Text('Ajouter texte'),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : () => _moveSelectedLayer(1),
                            icon: const Icon(Icons.arrow_downward),
                            label: const Text('Descendre'),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : () => _moveSelectedLayer(-1),
                            icon: const Icon(Icons.arrow_upward),
                            label: const Text('Monter'),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _deleteSelectedLayer,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Supprimer'),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _editSelectedTextLayer,
                            icon: const Icon(Icons.edit),
                            label: const Text('Éditer texte'),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _applyBrandPreset,
                            icon: const Icon(Icons.palette_outlined),
                            label: const Text('Preset Nexiom'),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _openTemplatesDialog,
                            icon: const Icon(Icons.view_quilt_outlined),
                            label: const Text('Templates & presets'),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _exportCanvasState,
                            icon: const Icon(Icons.ios_share_outlined),
                            label: const Text('Exporter JSON'),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _openLibraryDialog,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Bibliothèque'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Panel central : outils IA
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barre IA simple – fond, gomme, fond IA, outpainting',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _pickBaseImage,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Image de base'),
                          ),
                          const SizedBox(width: 12),
                          if (_baseImageFileName != null)
                            Expanded(
                              child: Text(
                                _baseImageFileName!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _pickMaskImage,
                            icon: const Icon(Icons.brush_outlined),
                            label:
                                const Text('Masque (optionnel / gomme)'),
                          ),
                          const SizedBox(width: 12),
                          if (_maskFileName != null)
                            Expanded(
                              child: Text(
                                _maskFileName!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélection intelligente (cliquez sur l\'image pour créer une sélection IA)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Objet'),
                            selected: _selectionType == 'object',
                            onSelected: (_) {
                              setState(() {
                                _selectionType = 'object';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Personne'),
                            selected: _selectionType == 'person',
                            onSelected: (_) {
                              setState(() {
                                _selectionType = 'person';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Arrière-plan'),
                            selected: _selectionType == 'background',
                            onSelected: (_) {
                              setState(() {
                                _selectionType = 'background';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Mode IA'),
                            selected: _maskEditMode == 'ai',
                            onSelected: (_) {
                              setState(() {
                                _maskEditMode = 'ai';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Mode pinceau'),
                            selected: _maskEditMode == 'brush',
                            onSelected: (_) {
                              setState(() {
                                _maskEditMode = 'brush';
                              });
                            },
                          ),
                        ],
                      ),
                      if (_maskEditMode == 'brush') ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Ajouter à la sélection'),
                              selected: _maskBrushMode == 'add',
                              onSelected: (_) {
                                setState(() {
                                  _maskBrushMode = 'add';
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Retirer de la sélection'),
                              selected: _maskBrushMode == 'remove',
                              onSelected: (_) {
                                setState(() {
                                  _maskBrushMode = 'remove';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Taille du pinceau'),
                            Slider(
                              value: _maskBrushSize.clamp(4.0, 96.0),
                              min: 4.0,
                              max: 96.0,
                              divisions: 8,
                              label: _maskBrushSize.toStringAsFixed(0),
                              onChanged: (value) {
                                setState(() {
                                  _maskBrushSize = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _applyMaskBrushEdits,
                            icon: const Icon(Icons.brush),
                            label: const Text(
                                'Appliquer le pinceau sur le masque'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final label = _eraseStrength < 0.33
                              ? 'doux'
                              : (_eraseStrength < 0.66
                                  ? 'moyen'
                                  : 'fort');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Intensité de la gomme (gomme magique)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              Slider(
                                value: _eraseStrength,
                                min: 0.0,
                                max: 1.0,
                                divisions: 4,
                                label: label,
                                onChanged: (value) {
                                  setState(() {
                                    _eraseStrength = value;
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _applyBackgroundRemoval,
                            icon: const Icon(Icons.layers_clear_outlined),
                            label: const Text('Supprimer le fond'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _applyInpaintRemove,
                            icon: const Icon(
                                Icons.cleaning_services_outlined),
                            label:
                                const Text('Gommer la zone masquée'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Remplissage local de la zone masquée (IA)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _localFillPromptController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText:
                              'Description du contenu à générer dans la zone masquée',
                          hintText:
                              'Ex: remplacer l\'objet par une plante verte, remplir avec un ciel bleu...',
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _applyLocalFillAi,
                          icon: const Icon(Icons.auto_fix_high_outlined),
                          label: const Text('Remplir la zone masquée (IA)'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Outpainting & harmonisation globale',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _outpaintAspectRatio,
                              decoration: const InputDecoration(
                                labelText: 'Format cible (outpainting)',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: '16:9',
                                  child: Text('16:9 – Paysage'),
                                ),
                                DropdownMenuItem(
                                  value: '9:16',
                                  child: Text('9:16 – Vertical'),
                                ),
                                DropdownMenuItem(
                                  value: '1:1',
                                  child: Text('1:1 – Carré'),
                                ),
                                DropdownMenuItem(
                                  value: '4:5',
                                  child: Text('4:5 – Portrait'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _outpaintAspectRatio = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _applyOutpaintAi,
                            icon: const Icon(Icons.open_in_full),
                            label:
                                const Text('Étendre l\'image (outpainting)'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _applyGlobalHarmonizeAi,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Harmoniser globalement (IA)'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _applyFaceEnhanceAi,
                            icon: const Icon(Icons.face),
                            label: const Text('Améliorer le visage (IA)'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Remplacement de fond (IA)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _backgroundPromptController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description du nouveau fond',
                          hintText:
                              'Ex: bureau moderne lumineux, fond flou, couleurs pastel',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Bureau moderne'),
                            onPressed: _loading
                                ? null
                                : () {
                                    setState(() {
                                      _backgroundPromptController.text =
                                          'bureau moderne lumineux, mobilier contemporain, ambiance professionnelle, profondeur de champ légère';
                                    });
                                  },
                          ),
                          ActionChip(
                            label: const Text('Campus lumineux'),
                            onPressed: _loading
                                ? null
                                : () {
                                    setState(() {
                                      _backgroundPromptController.text =
                                          'campus universitaire lumineux, couloirs vitrés, étudiants flous en arrière-plan, tons chaleureux';
                                    });
                                  },
                          ),
                          ActionChip(
                            label: const Text('Fond pastel minimaliste'),
                            onPressed: _loading
                                ? null
                                : () {
                                    setState(() {
                                      _backgroundPromptController.text =
                                          'fond pastel dégradé doux, formes géométriques légères, style minimaliste';
                                    });
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _pickBackgroundImage,
                            icon: const Icon(
                                Icons.photo_library_outlined),
                            label: const Text('Image de fond (importée)'),
                          ),
                          const SizedBox(width: 12),
                          if (_backgroundImageFileName != null)
                            Expanded(
                              child: Text(
                                _backgroundImageFileName!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _loading ? null : _applyBackgroundReplaceAi,
                          icon: const Icon(Icons.image),
                          label: const Text('Générer et appliquer le fond IA'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 260,
                        child: _buildSelectionPreview(canvasState),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Avant'),
                            selected: !_showMagicErasePreview ||
                                _magicErasePreviewUrl == null,
                            onSelected: (_) {
                              setState(() {
                                _showMagicErasePreview = false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Après (aperçu gomme)'),
                            selected: _showMagicErasePreview &&
                                _magicErasePreviewUrl != null,
                            onSelected: (_) {
                              if (_magicErasePreviewUrl != null) {
                                setState(() {
                                  _showMagicErasePreview = true;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _magicErasePreviewUrl == null
                              ? null
                              : _applyMagicEraserPreview,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                              'Appliquer la retouche (gomme magique)'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.grey.shade700),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            child: Text(
                              const JsonEncoder.withIndent('  ').convert(
                                canvasState ?? const <String, dynamic>{},
                              ),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _saveVersion,
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder la version'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loading ? null : _exportSmartRenditions,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Exports intelligents'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loading ? null : _openVersionsDialog,
                icon: const Icon(Icons.history),
                label: const Text('Historique des versions'),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditeur visuel (fondations)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 8),
            mainContent,
          ],
        ),
      ),
    );
  }
}

class _MaskStroke {
  final List<Offset> points;
  final String mode;
  final double size;

  _MaskStroke({
    required this.points,
    required this.mode,
    required this.size,
  });
}

class _MaskBrushPainter extends CustomPainter {
  final List<_MaskStroke> strokes;

  _MaskBrushPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) {
      return;
    }

    final paintAdd = Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.fill;
    final paintRemove = Paint()
      ..color = const Color(0x80FF0000)
      ..style = PaintingStyle.fill;

    final minSide = size.width < size.height ? size.width : size.height;

    for (final stroke in strokes) {
      final paint = stroke.mode == 'add' ? paintAdd : paintRemove;
      final radius = (stroke.size * minSide).clamp(1.0, minSide / 2);
      for (final p in stroke.points) {
        final dx = (p.dx.clamp(0.0, 1.0)) * size.width;
        final dy = (p.dy.clamp(0.0, 1.0)) * size.height;
        canvas.drawCircle(Offset(dx, dy), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MaskBrushPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}

Color _parseHexColor(String? hex, {Color fallback = const Color(0xFF0F172A)}) {
  if (hex == null) return fallback;
  var value = hex.trim();
  if (value.isEmpty) return fallback;
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 6) {
    value = 'FF$value';
  }
  try {
    final intColor = int.parse(value, radix: 16);
    return Color(intColor);
  } catch (_) {
    return fallback;
  }
}
