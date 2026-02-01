import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../publishing/services/content_job_service.dart';
import '../models/generation_result.dart';
import '../models/text_template.dart';
import '../services/file_download_helper.dart';
import '../services/media_upload_service.dart';
import '../services/openrouter_service.dart';
import '../services/speech_capture_service.dart';
import '../services/voice_profile_service.dart';
import '../widgets/loader.dart';
import '../widgets/prompt_input.dart';
import '../widgets/result_viewer.dart';
import 'text_templates_page.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final _promptController = TextEditingController();
  final _service = OpenRouterService.instance();
  final _uploadService = MediaUploadService.instance();
  final _voiceProfileService = VoiceProfileService.instance();
  final _speechService = SpeechCaptureService.instance();
  final _contentJobService = ContentJobService.instance();

  bool _isGenerating = false;
  GenerationResult? _result;
  String? _error;
  String? _referenceVoicePath;
  String? _referenceFileName;
  final List<String> _referenceVoicePaths = [];

  bool _isRecording = false;
  bool _isUploadingRecording = false;

   String? _selectedAudioModel;

  static const List<String> _trainingScripts = [
    'Bonjour, je m\'appelle __NOM__ et je représente Nexiom Group. Aujourd\'hui, je vais vous présenter rapidement notre solution pour accompagner les entreprises au Burkina Faso dans leur communication digitale. Nous travaillons avec des équipes locales pour créer des contenus ancrés dans la réalité de Ouagadougou et des grandes villes du pays.',
    'Chez Nexiom Group, notre objectif est de rendre la technologie accessible aux PME, aux écoles et aux organisations publiques. Nous aidons nos clients à produire des vidéos, des visuels et des messages audio professionnels, adaptés au terrain, aux marchés locaux et aux habitudes de consommation au Burkina Faso.',
    'Merci d\'avoir pris le temps d\'écouter ce message. Pour plus d\'informations, vous pouvez nous contacter, réserver une démonstration ou passer dans nos bureaux à Ouagadougou. Nexiom Group, votre partenaire pour une communication moderne, efficace et proche de vos réalités au quotidien.',
    'Vous écoutez un exemple de voix Nexiom Group. Imaginez cette voix utilisée pour vos campagnes radio, vos vidéos explicatives ou vos messages WhatsApp professionnels. Notre technologie vous permet de garder une identité vocale cohérente, tout en adaptant le ton au message, du plus institutionnel au plus convivial.',
    'Dans les rues de Ouagadougou, les entreprises ont besoin de se démarquer avec des messages clairs, chaleureux et crédibles. Grâce au clonage vocal, vous pouvez confier la voix de votre marque à une identité vocale stable, qui respecte les accents, le rythme de parole et les expressions naturelles de vos équipes.',
    'Nexiom Group vous accompagne de bout en bout : rédaction des scripts, enregistrement de la voix de référence, clonage vocal, puis génération automatique de contenus audio pour vos campagnes. Vous pouvez ainsi adapter rapidement un même message à plusieurs langues, plusieurs canaux et plusieurs contextes de diffusion.',
    'Ce message est un exemple de texte d\'entraînement pour le clonage vocal. Pendant l\'enregistrement, parlez naturellement, articulez chaque mot, variez légèrement le ton et le rythme, comme si vous expliquiez une offre importante à un client réel. Plus la diction est claire, plus le modèle pourra reproduire fidèlement votre voix.',
    'Pour tester la stabilité de la voix clonée, nous vous recommandons d\'enregistrer plusieurs scripts, avec des phrases courtes et longues, des chiffres, des dates et des noms propres. Par exemple : "Nexiom Group, 2025, Ouagadougou, Burkina Faso" ou encore "Appelez-nous au zéro-un, zéro-deux, zéro-trois, pour planifier votre démonstration".',
    'Enfin, souvenez-vous que la voix est un élément fort de votre identité de marque. En travaillant avec Nexiom Group, vous gardez le contrôle sur votre tonalité, votre accent et votre manière de vous adresser à vos clients, tout en bénéficiant de la puissance de l\'intelligence artificielle pour automatiser la production de contenus audio.',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _startRecordingReference() async {
    setState(() {
      _error = null;
      _isUploadingRecording = false;
    });

    try {
      await _speechService.startRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _error = 'Impossible de démarrer l\'enregistrement micro: $e';
      });
    }
  }

  Future<void> _registerAudioContentJob(GenerationResult res, String prompt) async {
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
        format: 'audio',
        channels: const <String>[],
        originUi: 'audio_page',
        status: 'generated',
        generationJobId: jobId,
        metadata: <String, dynamic>{
          'prompt': prompt,
          if (_selectedAudioModel != null) 'model': _selectedAudioModel,
        },
      );
    } catch (_) {
      // Best-effort: ne pas bloquer l'UI si la création du content_job échoue.
    }
  }

  Future<void> _stopRecordingReference() async {
    if (!_isRecording) return;

    setState(() {
      _isUploadingRecording = true;
    });

    try {
      final wavBytes = await _speechService.stopAndGetWavBytes();
      final path = await _uploadService.uploadBinaryData(
        wavBytes,
        prefix: 'voice_reference',
      );

      setState(() {
        _isRecording = false;
        _isUploadingRecording = false;
        _referenceVoicePath = path;
        _referenceFileName =
            'Enregistrement Nexiom ${DateTime.now().toLocal().toIso8601String()}';
        _referenceVoicePaths.add(path);
      });
    } catch (e) {
      await _speechService.cancel();
      setState(() {
        _isRecording = false;
        _isUploadingRecording = false;
        _error = 'Erreur lors de l\'enregistrement de la voix: $e';
      });
    }
  }

  Future<void> _pickReferenceVoice() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
      allowMultiple: false,
      withData: true,
    );

    final file = result?.files.first;
    if (file == null) return;

    try {
      final path = await _uploadService.uploadReferenceMedia(
        file,
        prefix: 'voice_reference',
      );
      setState(() {
        _referenceVoicePath = path;
        _referenceFileName = file.name;
        _referenceVoicePaths.add(path);
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'upload de la voix de référence: $e';
      });
    }
  }

  Future<void> _pickAudioScriptTemplate() async {
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
      if (_promptController.text.isEmpty) {
        _promptController.text = template.content;
      } else {
        _promptController.text =
            '${_promptController.text.trim()}\n\n${template.content.trim()}';
      }
    });
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _error = 'Veuillez saisir un texte pour la voix off.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await _service.generateAudio(
        prompt: prompt,
        referenceVoicePath: _referenceVoicePath,
        referenceVoicePaths:
            _referenceVoicePaths.isNotEmpty ? List<String>.from(_referenceVoicePaths) : null,
        model: _selectedAudioModel,
      );
      await _registerAudioContentJob(res, prompt);
      setState(() {
        _result = res;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la génération audio: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveAsVoiceProfile() async {
    final res = _result;
    if (res == null) return;

    final controller = TextEditingController(
      text: 'Voix ${DateTime.now().millisecondsSinceEpoch}',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nom du profil de voix'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nom de la voix (ex: Voix Pub TV)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) {
      return;
    }

    try {
      setState(() {
        _error = null;
      });
      final profile = await _voiceProfileService.createProfile(
        name: name,
        sampleUrl: res.url,
        referenceMediaPath: _referenceVoicePath,
        audioJobId: res.jobId,
        allReferenceMediaPaths:
            _referenceVoicePaths.isNotEmpty ? List<String>.from(_referenceVoicePaths) : null,
      );
      await _voiceProfileService.setPrimary(profile.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil de voix enregistré.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de l\'enregistrement du profil de voix: $e';
      });
    }
  }

  void _download() {
    final res = _result;
    if (res == null) return;
    FileDownloadHelper.downloadFromUrl(
      'audio_${res.jobId ?? DateTime.now().millisecondsSinceEpoch}.mp3',
      res.url,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voix off / clonage vocal'),
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
                      'Voix off & clonage vocal',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Étape 1 : enregistrez votre vraie voix (micro ou fichier). Étape 2 : saisissez un texte à lire et générez un exemple de voix clonée. Étape 3 : enregistrez le résultat comme profil de voix.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Étape 1 – Enregistrer votre voix Nexiom',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploadingRecording
                              ? null
                              : (_isRecording
                                  ? _stopRecordingReference
                                  : _startRecordingReference),
                          icon: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                          ),
                          label: Text(
                            _isRecording
                                ? 'Arrêter l\'enregistrement'
                                : 'Enregistrer ma voix (micro)',
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_isUploadingRecording)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PromptInput(
                      controller: _promptController,
                      hint:
                          'Par exemple: script de vidéo, texte de présentation, call-to-action marketing...',
                      maxLines: 6,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedAudioModel,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Modèle audio OpenRouter (optionnel, par défaut: configuration serveur)',
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
                          value: 'openai/gpt-4o-mini-tts',
                          child: Text(
                            'openai/gpt-4o-mini-tts',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'google/gemini-2.0-flash-tts',
                          child: Text(
                            'google/gemini-2.0-flash-tts',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAudioModel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Textes d\'entraînement suggérés (lisez-les à voix haute pendant l\'enregistrement) :',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (int i = 0; i < _trainingScripts.length; i++)
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _promptController.text = _trainingScripts[i];
                              });
                            },
                            child: Text('Script ${i + 1}'),
                          ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _pickAudioScriptTemplate,
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Insérer depuis mes templates'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickReferenceVoice,
                          icon: const Icon(Icons.mic),
                          label: const Text('Importer un fichier voix (optionnel)'),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isGenerating ? null : _generate,
                        icon: const Icon(Icons.graphic_eq),
                        label: Text(
                          _isGenerating ? 'Génération en cours...' : 'Générer la voix off',
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
                          children: [
                            OutlinedButton.icon(
                              onPressed: _download,
                              icon: const Icon(Icons.download),
                              label: const Text('Télécharger l\'audio'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _saveAsVoiceProfile,
                              icon: const Icon(Icons.person),
                              label: const Text('Enregistrer comme profil de voix'),
                            ),
                          ],
                        ),
                      ),
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
                              'Génération en cours... La synthèse et le clonage vocal peuvent prendre quelques instants.',
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
