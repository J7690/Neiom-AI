-- Seed v1.0 – Base de bonnes pratiques d’engagement organique pour le Studio Marketing Nexiom
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-31_seed_facebook_engagement_best_practices.sql
-- Non destructif : insère des entrées de connaissance dans studio_facebook_knowledge

insert into public.studio_facebook_knowledge (category, objective, payload, source)
values
  -- 1) Principes universels d'engagement + accroches + dwell time + questions de fin
  (
    'engagement_universal',
    'global',
    $$
    {
      "version": "v1.0",
      "scope": [
        "principes_algorithmiques_facebook",
        "bonnes_pratiques_universelles",
        "accroches",
        "dwell_time",
        "questions_fin_de_post"
      ],
      "core_principle": "Facebook ne pousse pas un post parce qu’il est “bon”, mais parce que les premières personnes exposées réagissent vite et humainement.",
      "evaluation_rule": "Chaque recommandation doit être évaluée selon sa capacité à déclencher une réaction humaine rapide (dwell time + interactions).",
      "hooks": {
        "description": "Première ligne extrêmement critique : doit créer une tension ou une curiosité immédiate.",
        "rules": [
          "Si la première ligne peut être supprimée sans perte de sens ni perte d’attention, elle est considérée comme mauvaise.",
          "Éviter les phrases descriptives neutres ou institutionnelles.",
          "Privilégier des formulations qui interpellent directement l’étudiant, le parent ou l’enseignant."
        ],
        "patterns": [
          {
            "id": "hook_phrase_incomplete",
            "label": "Phrase incomplète",
            "examples": [
              "Beaucoup de parents font cette erreur avant la rentrée…",
              "Ce détail peut te coûter une année entière…"
            ]
          },
          {
            "id": "hook_alerte_douce",
            "label": "Alerte douce",
            "examples": [
              "Si tu es étudiant ou parent, lis ceci jusqu’au bout.",
              "Avant de choisir une formation, prends 2 minutes pour lire ça." ]
          },
          {
            "id": "hook_promesse_realiste",
            "label": "Promesse réaliste",
            "examples": [
              "Ce post peut t’éviter une perte de temps et d’argent.",
              "Quelques lignes pour t’éviter une grosse erreur de choix d’école." ]
          }
        ]
      },
      "dwell_time": {
        "target_seconds": 10,
        "rules": [
          "Favoriser des paragraphes courts et aérés.",
          "Rythme narratif : alterner faits, exemples concrets et mini-pauses visuelles.",
          "Lister clairement les points importants (listes à puces naturelles)."
        ],
        "preferred_styles": [
          "storytelling court basé sur une situation vécue par un étudiant ou un parent",
          "projection : 'Imagine que…' appliqué au contexte académique africain"
        ]
      },
      "end_of_post_triggers": {
        "goal": "maximiser les commentaires organiques utiles",
        "rules": [
          "Clore chaque post par une question simple ou une invitation à réagir.",
          "Éviter les questions trop techniques ou abstraites qui bloquent la réponse."
        ],
        "examples": [
          "Tu es d’accord ou pas ?",
          "Qu’en penses-tu ?",
          "Est-ce que ça t’est déjà arrivé ?",
          "Tu ferais quoi à leur place ?"
        ]
      }
    }
    $$::jsonb,
    'seed_engagement_best_practices_v1'
  ),

  -- 2) Bonnes pratiques par type d’engagement (likes, commentaires, partages)
  (
    'engagement_by_goal',
    'visibility',
    $$
    {
      "version": "v1.0",
      "goals": {
        "likes": {
          "description": "Maximiser les réactions rapides (likes et réactions).",
          "content_types": ["positif", "identitaire", "valorisant"],
          "tone": ["accessible", "chaleureux", "non agressif"],
          "patterns": [
            {
              "id": "likes_reconnaissance",
              "label": "Reconnaissance",
              "examples": [
                "Beaucoup d’étudiants ne se rendent pas compte de leur vrai potentiel…",
                "On ne le dit pas assez aux parents qui se battent pour la scolarité de leurs enfants…"
              ]
            },
            {
              "id": "likes_reussite",
              "label": "Mettre en avant la réussite",
              "examples": [
                "Ceux qui préparent leur orientation à l’avance réussissent mieux que les autres…",
                "Les étudiants qui posent ces 3 questions avant de s’inscrire évitent la plupart des mauvaises surprises."
              ]
            }
          ]
        },
        "comments": {
          "description": "Maximiser les commentaires (clé de la portée).",
          "rules": [
            "Poser des questions faciles à répondre.",
            "Éviter les questions trop techniques ou intimidantes.",
            "Favoriser les questions de positionnement ou de vécu personnel."
          ],
          "bad_examples": [
            "Quelle est votre analyse stratégique détaillée de ce dispositif ?"
          ],
          "good_examples": [
            "Tu ferais quoi à leur place ?",
            "Est-ce que tu t’es déjà retrouvé dans cette situation ?",
            "Si tu devais choisir, tu prendrais quelle option ?"
          ]
        },
        "shares": {
          "description": "Maximiser les partages utiles.",
          "content_types": ["utile", "éducatif", "protecteur"],
          "target_audiences": ["parents", "étudiants", "jeunes travailleurs"],
          "angles": [
            "Ce conseil peut vraiment aider quelqu’un autour de toi.",
            "Ce post peut éviter une erreur coûteuse.",
            "Partage à un ami qui prépare aussi son orientation."
          ],
          "cta_examples": [
            "Partage à quelqu’un qui en a besoin.",
            "Envoie ce post à un ami qui prépare aussi sa rentrée.",
            "Garde ce post et partage-le à un proche qui est concerné."
          ]
        }
      }
    }
    $$::jsonb,
    'seed_engagement_best_practices_v1'
  ),

  -- 3) Bonnes pratiques de formulation (ton, longueur, hashtags)
  (
    'copywriting_tone_and_length',
    'global',
    $$
    {
      "version": "v1.0",
      "tone": {
        "recommended": ["humain", "conversationnel", "pédagogique"],
        "rules": [
          "Parler comme un conseiller humain, pas comme un dépliant institutionnel.",
          "Éviter le jargon administratif et les phrases longues.",
          "Toujours contextualiser pour l’Afrique de l’Ouest / Burkina Faso (réalités locales)."
        ],
        "to_avoid": [
          "langage trop institutionnel",
          "jargon technique non expliqué",
          "pavés de texte sans respiration"
        ]
      },
      "length": {
        "recommended_structure": {
          "blocks": "3 à 6 blocs courts",
          "main_idea": "1 idée principale par post",
          "notes": [
            "Éviter le pavé unique",
            "Chaque bloc doit pouvoir être lu en 2 à 3 secondes"
          ]
        }
      },
      "hashtags": {
        "max_per_post": 5,
        "rules": [
          "Utiliser peu de hashtags (3 à 5).",
          "Privilégier les hashtags contextuels (ville, thème, type de formation).",
          "Éviter de n’utiliser que des hashtags génériques (#success, #motivation…)."
        ],
        "constraints": [
          "Si le rapport d’intelligence (mission_intelligence_report) a déjà identifié des hashtags performants, l’IA doit les privilégier.",
          "L’IA ne doit pas inventer des hashtags par défaut si aucune donnée n’est disponible : elle doit rester prudente."
        ]
      }
    }
    $$::jsonb,
    'seed_engagement_best_practices_v1'
  ),

  -- 4) Bonnes pratiques de timing & diffusion (côté règles, complémentaires aux analytics)
  (
    'timing_and_diffusion',
    'visibility',
    $$
    {
      "version": "v1.0",
      "principles": [
        "Pas de règle universelle fixe sur les horaires.",
        "Toujours prioriser l’historique réel de la page vs. les moyennes globales.",
        "Chercher des fenêtres où l’audience cible est disponible mais la concurrence plus faible."
      ],
      "internal_signals": [
        "Slots horaires extraits de get_best_facebook_time_for_topic / best_time_slots.",
        "Performance par type de post via get_facebook_post_performance_overview.",
        "Objectifs et verdicts via get_objective_performance_summary / post_strategy_outcomes."
      ],
      "rules_for_ai": [
        "Toujours proposer des créneaux horaires spécifiques à la page (données internes).",
        "N’utiliser les benchmarks externes (Meta, Hootsuite…) que pour ajuster ou compléter, jamais pour contredire frontalement l’historique Nexiom.",
        "Si les données internes sont trop faibles, le modèle doit l’indiquer explicitement (faible confiance)."
      ]
    }
    $$::jsonb,
    'seed_engagement_best_practices_v1'
  ),

  -- 5) Anti-patterns explicites (ce qui pénalise la portée)
  (
    'anti_patterns',
    'global',
    $$
    {
      "version": "v1.0",
      "anti_patterns": [
        {
          "id": "promo_directe",
          "label": "Texte trop promotionnel direct",
          "description": "Post centré uniquement sur la vente ou la promotion sans valeur ajoutée pour l’audience.",
          "risks": [
            "baisse de portée",
            "fatigue de l’audience",
            "perception opportuniste"
          ]
        },
        {
          "id": "liens_sortants_excessifs",
          "label": "Trop de liens sortants",
          "description": "Post qui renvoie systématiquement hors de Facebook sans créer d’engagement sur place.",
          "risks": ["diminution du dwell time", "moins de commentaires / réactions"]
        },
        {
          "id": "hashtags_excessifs",
          "label": "Hashtags en trop grand nombre",
          "description": "Utilisation massive de hashtags non pertinents ou génériques.",
          "risks": ["post perçu comme spam", "baisse de crédibilité"]
        },
        {
          "id": "copie_non_adaptee",
          "label": "Copier-coller de posts viraux sans adaptation",
          "description": "Reprise brute de contenus d’autres pages sans contextualisation pour Nexiom / Afrique de l’Ouest.",
          "risks": ["incohérence avec la marque", "risque de signalement", "perte de confiance"]
        },
        {
          "id": "publication_sans_suivi",
          "label": "Publication sans interaction après coup",
          "description": "Post publié puis laissé sans réponses aux commentaires ou sans like de la page.",
          "risks": ["signal négatif à l’algorithme", "perception de distance avec l’audience"]
        }
      ],
      "rules_for_ai": [
        "Signaler explicitement les anti-patterns détectés dans chaque recommandation.",
        "Proposer une alternative plus saine quand un anti-pattern est identifié dans un brief ou dans un exemple fourni.",
        "Ne jamais recommander un plan qui repose principalement sur ces anti-patterns."
      ]
    }
    $$::jsonb,
    'seed_engagement_best_practices_v1'
  ),

  -- 6) Règle d’or finale
  (
    'engagement_rule_of_thumb',
    'global',
    $$
    {
      "version": "v1.0",
      "golden_rule": "Le Studio ne doit jamais chercher à faire plaisir à Facebook, mais à provoquer une réaction humaine mesurable. Facebook ne fait que suivre.",
      "implications": [
        "Prioriser la clarté du bénéfice pour l’étudiant / le parent / le partenaire plutôt que les astuces algorithmique.",
        "Toujours tester la recommandation en se demandant : est-ce qu’un humain précis va réellement réagir à ce message ?",
        "Préférer une conversation honnête avec l’audience à une optimisation artificielle des signaux."
      ]
    }
    $$::jsonb,
    'seed_engagement_best_practices_v1'
  );
