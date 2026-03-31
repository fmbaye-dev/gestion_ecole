// lib/models/absence_model.dart
// MODIFIÉ : ajout de `type` (absence|retard), `enseignantNom`, `raison`

import 'package:cloud_firestore/cloud_firestore.dart';

enum TypePresence { absence, retard }

class AbsenceModel {
  final String? id;
  final String idEleve;
  final String nomEleve;
  final String matiere;
  final DateTime date;
  final bool justifiee;
  final String idEnseignant;
  final String enseignantNom; // ← NOUVEAU
  final TypePresence type; // ← NOUVEAU : absence | retard
  final String raison; // ← NOUVEAU : optionnel

  AbsenceModel({
    this.id,
    required this.idEleve,
    this.nomEleve = '',
    required this.matiere,
    required this.date,
    required this.justifiee,
    this.idEnseignant = '',
    this.enseignantNom = '',
    this.type = TypePresence.absence,
    this.raison = '',
  });

  factory AbsenceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AbsenceModel(
      id: doc.id,
      idEleve: d['idEleve'] ?? '',
      nomEleve: d['nomEleve'] ?? '',
      matiere: d['matiere'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      justifiee: d['justifiee'] ?? false,
      idEnseignant: d['idEnseignant'] ?? '',
      enseignantNom: d['enseignantNom'] ?? '',
      type: (d['type'] as String?) == 'retard'
          ? TypePresence.retard
          : TypePresence.absence,
      raison: d['raison'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'idEleve': idEleve,
    'nomEleve': nomEleve,
    'matiere': matiere,
    'date': Timestamp.fromDate(date),
    'justifiee': justifiee,
    'idEnseignant': idEnseignant,
    'enseignantNom': enseignantNom,
    'type': type == TypePresence.retard ? 'retard' : 'absence',
    'raison': raison,
  };

  String get dateFormatee =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String get typeLabel => type == TypePresence.retard ? 'Retard' : 'Absence';
}
