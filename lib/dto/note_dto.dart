// lib/dto/note_dto.dart

import 'package:gestion_ecole/models/note_model.dart';

class NoteDto {
  final String idEleve;
  final String nomEleve;
  final String matiere;
  final String idEnseignant;
  final String semestre;
  final double? devoir1;
  final double? devoir2;
  final double? devoir3;
  final double? compo1;
  final double? compo2;

  NoteDto({
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

  factory NoteDto.fromModel(NoteModel m) => NoteDto(
    idEleve: m.idEleve,
    nomEleve: m.nomEleve,
    matiere: m.matiere,
    idEnseignant: m.idEnseignant,
    semestre: m.semestre,
    devoir1: m.devoir1,
    devoir2: m.devoir2,
    devoir3: m.devoir3,
    compo1: m.compo1,
    compo2: m.compo2,
  );

  NoteModel toModel() => NoteModel(
    idEleve: idEleve,
    nomEleve: nomEleve,
    matiere: matiere,
    idEnseignant: idEnseignant,
    semestre: semestre,
    devoir1: devoir1,
    devoir2: devoir2,
    devoir3: devoir3,
    compo1: compo1,
    compo2: compo2,
  );

  Map<String, dynamic> toMap() => toModel().toMap();
}
