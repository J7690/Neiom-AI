import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexiom AI Studio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Studio de création IA',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Générez vidéos, images et voix off à partir de prompts, avec médias de référence.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureCard(
                              icon: Icons.person_pin_outlined,
                              title: 'Entraîner mon avatar',
                              description:
                                  'Créez un personnage principal réutilisable pour vos images et vidéos.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.avatars),
                            ),
                            _FeatureCard(
                              icon: Icons.movie_creation_outlined,
                              title: 'Générer une vidéo',
                              description:
                                  'Créez des vidéos de 10 à 60 secondes, avec environnement de référence.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.video),
                            ),
                            _FeatureCard(
                              icon: Icons.image_outlined,
                              title: 'Générer une image',
                              description:
                                  'Images haute qualité guidées par texte et photos de référence.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.image),
                            ),
                            _FeatureCard(
                              icon: Icons.graphic_eq,
                              title: 'Voix off / clonage',
                              description:
                                  'Générez des voix off et clonez une voix à partir d’un échantillon.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.audio),
                            ),
                            _FeatureCard(
                              icon: Icons.brush_outlined,
                              title: 'Éditeur visuel',
                              description:
                                  'Composez des visuels multi-calques avec outils IA et historique.',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.visualEditor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureCard(
                              icon: Icons.build_circle_outlined,
                              title: 'Outils Dev',
                              description:
                                  'Simuler, router, publier (stub), observabilité RPC.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.devTools),
                            ),
                            _FeatureCard(
                              icon: Icons.flag_outlined,
                              title: 'Stratégie',
                              description:
                                  'Plans marketing IA, validation, règles de marque.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.strategy),
                            ),
                            _FeatureCard(
                              icon: Icons.policy,
                              title: 'Règles de marque',
                              description:
                                  'CRUD par locale: interdits, mentions et escalade.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.brandRules),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureCard(
                              icon: Icons.menu_book_outlined,
                              title: 'Connaissances',
                              description:
                                  'Indexer des documents et rechercher (RAG).',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.knowledge),
                            ),
                            _FeatureCard(
                              icon: Icons.science_outlined,
                              title: 'A/B Tests',
                              description:
                                  'Créer des expériences, générer et planifier des variantes.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.experiments),
                            ),
                            _FeatureCard(
                              icon: Icons.calendar_month_outlined,
                              title: 'Calendrier',
                              description:
                                  'Voir les posts planifiés (semaine/mois).',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.calendar),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureCard(
                              icon: Icons.dashboard_customize_outlined,
                              title: 'Studio Marketing',
                              description:
                                  'Décisions IA, recommandations et mémoire stratégique.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.marketingStudio),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureCard(
                              icon: Icons.link_outlined,
                              title: 'Connexions',
                              description:
                                  'Pages/Comptes & statut des connexions (Meta/IG/WhatsApp).',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.connections),
                            ),
                            _FeatureCard(
                              icon: Icons.insights_outlined,
                              title: 'Analytics',
                              description:
                                  'Rapports hebdo/mensuels, KPIs et top posts.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.analytics),
                            ),
                            _FeatureCard(
                              icon: Icons.campaign_outlined,
                              title: 'Ads (Reco)',
                              description:
                                  'Propositions campagnes selon perfs organiques.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.adsReco),
                            ),
                            _FeatureCard(
                              icon: Icons.campaign,
                              title: 'Campagnes Ads',
                              description:
                                  'Lister, rechercher et changer le statut des campagnes.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.adsCampaigns),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureCard(
                              icon: Icons.description,
                              title: 'Modèles campagne',
                              description: 'Templates + brief + garde-fous policy.',
                              onTap: () => Navigator.pushNamed(context, AppRoutes.campaignTemplates),
                            ),
                            _FeatureCard(
                              icon: Icons.person_outline,
                              title: 'Mes voix',
                              description:
                                  'Consultez et réutilisez vos profils de voix clonées.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.voices),
                            ),
                            _FeatureCard(
                              icon: Icons.description_outlined,
                              title: 'Mes templates',
                              description:
                                  'Scripts vidéo et textes marketing réutilisables.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.templates),
                            ),
                            _FeatureCard(
                              icon: Icons.settings,
                              title: 'Réglages',
                              description: 'Secrets/connexions (staging)',
                              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                            ),
                            _FeatureCard(
                              icon: Icons.forum_outlined,
                              title: 'Conversations',
                              description:
                                  'Consultez les conversations multicanal (WhatsApp, etc.).',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.messaging),
                            ),
                            _FeatureCard(
                              icon: Icons.people_outline,
                              title: 'Leads',
                              description:
                                  'Visualisez les leads multicanal et leurs statuts.',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.leads),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FeatureCard(
                              icon: Icons.verified_outlined,
                              title: 'Validation contenus',
                              description:
                                  'Valider les contenus générés (jobs, posts, médias).',
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.contentJobsAdmin),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: Colors.cyanAccent),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
