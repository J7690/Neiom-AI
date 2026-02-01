import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../models/voice_profile.dart';
import '../services/voice_profile_service.dart';

class VoiceProfilesPage extends StatefulWidget {
  const VoiceProfilesPage({super.key});

  @override
  State<VoiceProfilesPage> createState() => _VoiceProfilesPageState();
}

class _VoiceProfilesPageState extends State<VoiceProfilesPage> {
  final _service = VoiceProfileService.instance();

  bool _isLoading = false;
  List<VoiceProfile> _profiles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
        _error = 'Erreur lors du chargement des voix: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToVideoWithProfile(VoiceProfile profile) {
    Navigator.pushNamed(
      context,
      AppRoutes.video,
      arguments: profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes voix clonées'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profils de voix',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Retrouvez ici les voix enregistrées depuis l\'onglet "Voix off". Vous pouvez les réutiliser pour de nouvelles vidéos.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              )
            else if (_profiles.isEmpty)
              const Text(
                'Aucune voix enregistrée pour le moment. Générez une voix dans l\'onglet "Voix off" puis enregistrez-la comme profil.',
                style: TextStyle(color: Colors.white70),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _profiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF0F172A),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.cyanAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.sampleUrl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => _goToVideoWithProfile(profile),
                            icon: const Icon(Icons.movie_creation_outlined),
                            label: const Text('Nouvelle vidéo'),
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
    );
  }
}
