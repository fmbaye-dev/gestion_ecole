// lib/config/routeur.dart

// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:gestion_ecole/views/page_absences.dart';
import 'package:gestion_ecole/views/page_accueil.dart';
import 'package:gestion_ecole/views/page_accueil_enseignant.dart';
import 'package:gestion_ecole/views/page_accueil_eleve.dart';
import 'package:gestion_ecole/views/page_classes.dart';
import 'package:gestion_ecole/views/page_matieres.dart';
import 'package:gestion_ecole/views/page_enseignants.dart';
import 'package:gestion_ecole/views/page_eleves.dart';
import 'package:gestion_ecole/views/page_login.dart';
import 'package:gestion_ecole/views/page_mon_profil.dart';
import 'package:gestion_ecole/views/page_notes.dart';
import 'package:gestion_ecole/views/page_route_inconnue.dart';

abstract class Routeur {
  static const String routeInitial = '/login';
  static const String routeAccueil = '/accueil';
  static const String routeAccueilEnseignant = '/accueil-enseignant';
  static const String routeAccueilEleve = '/accueil-eleve';
  static const String routeProfil = '/profil';
  static const String routeEleves = '/eleves';
  static const String routeEnseignants = '/enseignants';
  static const String routeClasses = '/classes';
  static const String routeMatieres = '/matieres';
  static const String routeNotes = '/notes';
  static const String routeAbsences = '/absences';

  static Route<dynamic> lesRoutesGenerees(RouteSettings settings) {
    switch (settings.name) {
      case routeInitial:
        return _page(const PageLogin());
      case routeAccueil:
        return _page(const PageAccueil());
      case routeAccueilEnseignant:
        return _page(const PageAccueilEnseignant());
      case routeAccueilEleve:
        return _page(const PageAccueilEleve());
      case routeProfil:
        return _page(const PageMonProfil());
      case routeEleves:
        return _page(const PageEleves());
      case routeEnseignants:
        return _page(const PageEnseignants());
      case routeClasses:
        return _page(const PageClasses());
      case routeMatieres:
        return _page(const PageMatieres());
      case routeNotes:
        return _page(const PageNotes());
      case routeAbsences:
        return _page(const PageAbsences());
      default:
        return _page(
          PageRouteInconnue(
            message: settings.arguments as String? ?? 'Page introuvable',
          ),
        );
    }
  }

  static Route<dynamic> siLaRouteEstInconnue(RouteSettings settings) => _page(
    PageRouteInconnue(
      message: settings.arguments as String? ?? 'Page introuvable',
    ),
  );

  static PageRouteBuilder _page(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 220),
  );
}
