// lib/main.dart

import 'package:flutter/material.dart';
import 'package:gestion_ecole/core/app_state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/core/constants/app_constants.dart';
import 'package:gestion_ecole/core/theme/theme_perso.dart';
import 'package:gestion_ecole/view_model/user_view_model.dart';
import 'package:gestion_ecole/view_model/eleve_view_model.dart';
import 'package:gestion_ecole/view_model/enseignant_view_model.dart';
import 'package:gestion_ecole/view_model/enseignement_view_model.dart';
import 'package:gestion_ecole/view_model/matiere_view_model.dart';
import 'package:gestion_ecole/view_model/note_view_model.dart';
import 'package:gestion_ecole/view_model/absence_view_model.dart';
import 'package:gestion_ecole/view_model/classe_view_model.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppState().initialiser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => EleveViewModel()),
        ChangeNotifierProvider(create: (_) => EnseignantViewModel()),
        ChangeNotifierProvider(create: (_) => EnseignementViewModel()),
        ChangeNotifierProvider(create: (_) => MatiereViewModel()),
        ChangeNotifierProvider(create: (_) => NoteViewModel()),
        ChangeNotifierProvider(create: (_) => AbsenceViewModel()),
        ChangeNotifierProvider(
          create: (_) => ClasseViewModel()..chargerClasses(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return MaterialApp(
          title: AppConstants.titreApplication,
          debugShowCheckedModeBanner: false,

          //! gestion des routes
          initialRoute: Routeur.routeInitial,
          onGenerateRoute: Routeur.lesRoutesGenerees,
          onUnknownRoute: Routeur.siLaRouteEstInconnue,

          locale: const Locale('fr', 'FR'),
          supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          //! gestion du thème dynamique
          theme: ThemePerso.modeClair,
          darkTheme: ThemePerso.modeSombre,
          themeMode: appState.themeMode ?? ThemeMode.system,
        );
      },
    );
  }
}
