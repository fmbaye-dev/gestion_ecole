// lib/models/absence_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AbsenceModel {
  final String?  id;
  final String   idEleve;
  final String   nomEleve;
  final String   matiere;
  final DateTime date;
  final bool     justifiee;
  final String   idEnseignant;

  AbsenceModel({
    this.id,
    required this.idEleve,
    this.nomEleve     = '',
    required this.matiere,
    required this.date,
    required this.justifiee,
    this.idEnseignant = '',
  });

  factory AbsenceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AbsenceModel(
      id:           doc.id,
      idEleve:      d['idEleve']      ?? '',
      nomEleve:     d['nomEleve']     ?? '',
      matiere:      d['matiere']      ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      justifiee:    d['justifiee']    ?? false,
      idEnseignant: d['idEnseignant'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'idEleve':      idEleve,
    'nomEleve':     nomEleve,
    'matiere':      matiere,
    'date':         Timestamp.fromDate(date),
    'justifiee':    justifiee,
    'idEnseignant': idEnseignant,
  };

  String get dateFormatee =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}