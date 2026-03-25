// lib/models/note_model.dart
//
// Structure Firestore d'une note :
// {
//   idEleve, nomEleve, matiere, idEnseignant, semestre,
//   devoir1, devoir2, devoir3,   // double? nullable
//   compo1, compo2               // double? nullable
// }
//
// Moyenne matière = (moy_devoirs * 1 + moy_compos * 2) / 3
// Coefficients fixes : devoir=1, compo=2

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteModel {
  final String? id;
  final String idEleve;
  final String nomEleve;
  final String matiere;
  final String idEnseignant;
  final String semestre; // 'S1' ou 'S2'

  // Devoirs (coefficient 1 chacun)
  final double? devoir1;
  final double? devoir2;
  final double? devoir3;

  // Compositions (coefficient 2 chacune)
  final double? compo1;
  final double? compo2;

  NoteModel({
    this.id,
    required this.idEleve,
    this.nomEleve = '',
    required this.matiere,
    this.idEnseignant = '',
    this.semestre = 'S1',
    this.devoir1,
    this.devoir2,
    this.devoir3,
    this.compo1,
    this.compo2,
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
      devoir3: (d['devoir3'] as num?)?.toDouble(),
      compo1: (d['compo1'] as num?)?.toDouble(),
      compo2: (d['compo2'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'idEleve': idEleve,
      'nomEleve': nomEleve,
      'matiere': matiere,
      'idEnseignant': idEnseignant,
      'semestre': semestre,
    };
    if (devoir1 != null) m['devoir1'] = devoir1;
    if (devoir2 != null) m['devoir2'] = devoir2;
    if (devoir3 != null) m['devoir3'] = devoir3;
    if (compo1 != null) m['compo1'] = compo1;
    if (compo2 != null) m['compo2'] = compo2;
    return m;
  }

  // ── Calculs ────────────────────────────────────────────────────────────

  /// Moyenne des devoirs (sur les valeurs renseignées)
  double? get moyenneDevoirs {
    final vals = [devoir1, devoir2, devoir3].whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  /// Moyenne des compositions (sur les valeurs renseignées)
  double? get moyenneCompos {
    final vals = [compo1, compo2].whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  /// Moyenne pondérée matière : devoirs coeff 1, compos coeff 2
  double? get moyenneMatiere {
    final md = moyenneDevoirs;
    final mc = moyenneCompos;
    if (md == null && mc == null) return null;
    if (md == null) return mc;
    if (mc == null) return md;
    return (md * 1 + mc * 2) / 3;
  }

  String get mention {
    final m = moyenneMatiere;
    if (m == null) return '—';
    if (m >= 16) return 'Très Bien';
    if (m >= 14) return 'Bien';
    if (m >= 12) return 'Assez Bien';
    if (m >= 10) return 'Passable';
    return 'Insuffisant';
  }

  Color get mentionColor {
    final m = moyenneMatiere;
    if (m == null) return Colors.grey;
    if (m >= 16) return const Color(0xFF2A8A5C);
    if (m >= 12) return const Color(0xFF1A3A8F);
    if (m >= 8) return const Color(0xFFC0692A);
    return const Color(0xFFD32F2F);
  }

  static String fmt(double? v) =>
      v == null ? '—' : (v % 1 == 0 ? '${v.toInt()}' : v.toStringAsFixed(1));
}
