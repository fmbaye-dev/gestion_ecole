// lib/dto/absence_dto.dart
// Selon diagramme : idEleve, nomEleve, matiere, date, justifiee, idEnseignant
// Pas d'idClasse ni nomClasse dans Absence

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_ecole/models/absence_model.dart';

class AbsenceDto {
  final String   idEleve;
  final String   nomEleve;
  final String   matiere;
  final DateTime date;
  final bool     justifiee;
  final String   idEnseignant;

  AbsenceDto({
    required this.idEleve,
    this.nomEleve  = '',
    required this.matiere,
    required this.date,
    required this.justifiee,
    this.idEnseignant = '',
  });

  factory AbsenceDto.fromModel(AbsenceModel m) => AbsenceDto(
    idEleve:   m.idEleve,
    nomEleve:  m.nomEleve,
    matiere:      m.matiere,
    date:         m.date,
    justifiee:    m.justifiee,
    idEnseignant: m.idEnseignant,
  );

  AbsenceModel toModel() => AbsenceModel(
    idEleve:   idEleve,
    nomEleve:  nomEleve,
    matiere:      matiere,
    date:         date,
    justifiee:    justifiee,
    idEnseignant: idEnseignant,
  );

  Map<String, dynamic> toMap() => {
    'idEleve':   idEleve,
    'nomEleve':  nomEleve,
    'matiere':      matiere,
    'date':         Timestamp.fromDate(date),
    'justifiee':    justifiee,
    'idEnseignant': idEnseignant,
  };
}