// lib/models/note_model.dart
//
// Structure Firestore d'une note :
// {
//   idEleve, nomEleve, matiere, idEnseignant, semestre,
//   devoir1, devoir2,   // double? nullable
//   compo               // double? nullable
//   coefficient         // double  (1 à 6 selon la matière/classe)
// }
//
// Formules (conformes au bulletin physique) :
//   Moy. Devoirs     = (D1 + D2) / 2
//   Moy. Matière/20  = (Moy.Devoirs + Compo) / 2
//   Moy. Pondérée    = Moy.Matière × Coeff
//   Moy. Générale    = Σ(Moy.Pondérée) / Σ(Coeff)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteModel {
  final String? id;
  final String idEleve;
  final String nomEleve;
  final String matiere;
  final String idEnseignant;
  final String semestre; // 'S1' ou 'S2'

  // 2 Devoirs
  final double? devoir1;
  final double? devoir2;

  // 1 Composition
  final double? compo;

  // Coefficient de la matière pour cette classe (1 à 6)
  final double coefficient;

  NoteModel({
    this.id,
    required this.idEleve,
    this.nomEleve = '',
    required this.matiere,
    this.idEnseignant = '',
    this.semestre = 'S1',
    this.devoir1,
    this.devoir2,
    this.compo,
    this.coefficient = 1.0,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      idEleve: d['idEleve'] ?? '',
      nomEleve: d['nomEleve'] ?? '',
      matiere: d['matiere'] ?? '',
      idEnseignant: d['idEnseignant'] ?? '',
      semestre: d['semestre'] ?? 'S1',
      devoir1: (d['devoir1'] as num?)?.toDouble(),
      devoir2: (d['devoir2'] as num?)?.toDouble(),
      compo: (d['compo'] as num?)?.toDouble(),
      coefficient: (d['coefficient'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'idEleve': idEleve,
      'nomEleve': nomEleve,
      'matiere': matiere,
      'idEnseignant': idEnseignant,
      'semestre': semestre,
      'coefficient': coefficient,
    };
    if (devoir1 != null) m['devoir1'] = devoir1;
    if (devoir2 != null) m['devoir2'] = devoir2;
    if (compo != null) m['compo'] = compo;
    return m;
  }

  // ── Calculs ──────────────────────────────────────────────────────────────

  /// Moy. Devoirs = (D1 + D2) / 2
  /// Si un seul devoir renseigné, on prend sa valeur directement.
  double? get moyenneDevoirs {
    final vals = [devoir1, devoir2].whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  /// Moy. Matière /20 = (Moy.Devoirs + Compo) / 2
  /// Si seulement devoirs → moy devoirs.
  /// Si seulement compo   → compo.
  double? get moyenneMatiere {
    final md = moyenneDevoirs;
    final mc = compo;
    if (md == null && mc == null) return null;
    if (md == null) return mc;
    if (mc == null) return md;
    return (md + mc) / 2;
  }

  /// Moy. Pondérée = Moy.Matière × Coefficient
  double? get moyennePonderee {
    final m = moyenneMatiere;
    if (m == null) return null;
    return m * coefficient;
  }

  // ── Appréciation ─────────────────────────────────────────────────────────

  String get appreciation {
    final m = moyenneMatiere;
    if (m == null) return '—';
    if (m >= 18) return 'Excellent travail';
    if (m >= 16) return 'Très Bon Travail';
    if (m >= 14) return 'Bon Travail';
    if (m >= 12) return 'A. Bien';
    if (m >= 10) return 'Passable';
    if (m >= 8) return 'Insuffisant';
    return 'Très Insuffisant';
  }

  String get mention => appreciation;

  Color get mentionColor {
    final m = moyenneMatiere;
    if (m == null) return Colors.grey;
    if (m >= 16) return const Color(0xFF2A8A5C);
    if (m >= 12) return const Color(0xFF1A3A8F);
    if (m >= 8) return const Color(0xFFC0692A);
    return const Color(0xFFD32F2F);
  }

  // ── Formatage ─────────────────────────────────────────────────────────────

  /// Affiche avec max 2 décimales, sans zéros inutiles (ex: 13.50 → 13,5)
  static String fmt(double? v) {
    if (v == null) return '—';
    final rounded = (v * 100).round() / 100;
    if (rounded % 1 == 0) return '${rounded.toInt()}';
    final s = rounded.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}
