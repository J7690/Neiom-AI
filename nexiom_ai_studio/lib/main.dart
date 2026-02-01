import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'features/generator/pages/audio_page.dart';
import 'features/generator/pages/home_page.dart';
import 'features/generator/pages/image_page.dart';
import 'features/generator/pages/text_templates_page.dart';
import 'features/generator/pages/video_page.dart';
import 'features/generator/pages/voice_profiles_page.dart';
import 'features/generator/pages/avatar_training_page.dart';
import 'features/messaging/pages/conversations_page.dart';
import 'features/messaging/pages/leads_page.dart';
import 'features/editor/pages/visual_editor_page.dart';
import 'features/dev/pages/dev_tools_page.dart';
import 'features/strategy/pages/strategy_page.dart';
import 'features/strategy/pages/brand_rules_page.dart';
import 'features/knowledge/pages/knowledge_page.dart';
import 'features/experiments/pages/experiments_page.dart';
import 'features/publishing/pages/calendar_page.dart';
import 'features/publishing/pages/content_jobs_admin_page.dart';
import 'features/channels/pages/connections_page.dart';
import 'features/analytics/pages/analytics_page.dart';
import 'features/ads/pages/ads_reco_page.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'features/ads/pages/campaigns_page.dart';
import 'features/ads/pages/campaign_templates_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/marketing/pages/marketing_decision_dashboard.dart';
import 'features/marketing/pages/studio_memory_context_page.dart';
import 'features/marketing/pages/facebook_knowledge_page.dart';
import 'features/marketing/pages/studio_brain_insights_page.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexiom AI Studio',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFF020617),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => const HomePage(),
        AppRoutes.video: (context) => const VideoPage(),
        AppRoutes.image: (context) => const ImagePage(),
        AppRoutes.audio: (context) => const AudioPage(),
        AppRoutes.voices: (context) => const VoiceProfilesPage(),
        AppRoutes.avatars: (context) => const AvatarTrainingPage(),
        AppRoutes.templates: (context) => const TextTemplatesPage(),
        AppRoutes.messaging: (context) => const ConversationsPage(),
        AppRoutes.leads: (context) => const LeadsPage(),
        AppRoutes.visualEditor: (context) => const VisualEditorPage(),
        AppRoutes.devTools: (context) => const DevToolsPage(),
        AppRoutes.strategy: (context) => const StrategyPage(),
        AppRoutes.brandRules: (context) => const BrandRulesPage(),
        AppRoutes.knowledge: (context) => const KnowledgePage(),
        AppRoutes.experiments: (context) => const ExperimentsPage(),
        AppRoutes.calendar: (context) => const CalendarPage(),
        AppRoutes.connections: (context) => const ConnectionsPage(),
        AppRoutes.analytics: (context) => const AnalyticsPage(),
        AppRoutes.adsReco: (context) => const AdsRecoPage(),
        AppRoutes.dashboard: (context) => const DashboardPage(),
        AppRoutes.adsCampaigns: (context) => const CampaignsPage(),
        AppRoutes.campaignTemplates: (context) => const CampaignTemplatesPage(),
        AppRoutes.settings: (context) => const SettingsPage(),
        AppRoutes.marketingStudio: (context) => const MarketingDecisionDashboard(),
        AppRoutes.contentJobsAdmin: (context) => const ContentJobsAdminPage(),
        AppRoutes.studioMemoryContext: (context) => const StudioMemoryContextPage(),
        AppRoutes.facebookKnowledge: (context) => const FacebookKnowledgePage(),
        AppRoutes.studioBrainInsights: (context) => const StudioBrainInsightsPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
