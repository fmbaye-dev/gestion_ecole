// lib/dto/classe_dto.dart
// Selon diagramme : nomClasse seulement (pas de niveau)

import 'package:gestion_ecole/models/classe_model.dart';

class ClasseDto {
  final String nomClasse;

  ClasseDto({required this.nomClasse});

  factory ClasseDto.fromModel(ClasseModel m) =>
      ClasseDto(nomClasse: m.nomClasse);

  ClasseModel toModel() => ClasseModel(nomClasse: nomClasse);

  Map<String, dynamic> toMap() => {'nomClasse': nomClasse};
}
