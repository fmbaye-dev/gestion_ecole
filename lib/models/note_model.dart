// lib/models/note_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteModel {
  final String? id;
  final String  idEleve;
  final String  nomEleve;
  final String  matiere;
  final double  valeur;
  final String  idEnseignant;

  NoteModel({
    this.id,
    required this.idEleve,
    this.nomEleve     = '',
    required this.matiere,
    required this.valeur,
    this.idEnseignant = '',
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id:           doc.id,
      idEleve:      d['idEleve']      ?? '',
      nomEleve:     d['nomEleve']     ?? '',
      matiere:      d['matiere']      ?? '',
      valeur:       (d['valeur'] as num?)?.toDouble() ?? 0.0,
      idEnseignant: d['idEnseignant'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'idEleve':      idEleve,
    'nomEleve':     nomEleve,
    'matiere':      matiere,
    'valeur':       valeur,
    'idEnseignant': idEnseignant,
  };

  String get mention {
    if (valeur >= 16) return 'Très Bien';
    if (valeur >= 14) return 'Bien';
    if (valeur >= 12) return 'Assez Bien';
    if (valeur >= 10) return 'Passable';
    return 'Insuffisant';
  }

  Color get mentionColor {
    if (valeur >= 16) return const Color(0xFF2A8A5C);
    if (valeur >= 12) return const Color(0xFF1A3A8F);
    if (valeur >= 8)  return const Color(0xFFC0692A);
    return const Color(0xFFD32F2F);
  }

  String get valeurFormatee =>
      valeur % 1 == 0 ? '${valeur.toInt()}' : '$valeur';
}