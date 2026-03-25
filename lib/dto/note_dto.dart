// lib/dto/note_dto.dart
// Selon diagramme : idEleve, nomEleve, matiere, valeur, idEnseignant
// Pas d'idClasse ni nomClasse dans Note

import 'package:gestion_ecole/models/note_model.dart';

class NoteDto {
  final String idEleve;
  final String nomEleve;
  final String matiere;
  final double valeur;
  final String idEnseignant;

  NoteDto({
    required this.idEleve,
    this.nomEleve  = '',
    required this.matiere,
    required this.valeur,
    this.idEnseignant = '',
  });

  factory NoteDto.fromModel(NoteModel m) => NoteDto(
    idEleve:   m.idEleve,
    nomEleve:  m.nomEleve,
    matiere:      m.matiere,
    valeur:       m.valeur,
    idEnseignant: m.idEnseignant,
  );

  NoteModel toModel() => NoteModel(
    idEleve:   idEleve,
    nomEleve:  nomEleve,
    matiere:      matiere,
    valeur:       valeur,
    idEnseignant: idEnseignant,
  );

  Map<String, dynamic> toMap() => {
    'idEleve':   idEleve,
    'nomEleve':  nomEleve,
    'matiere':      matiere,
    'valeur':       valeur,
    'idEnseignant': idEnseignant,
  };
}