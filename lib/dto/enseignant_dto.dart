// lib/dto/enseignant_dto.dart
// Selon diagramme : nomComplet, email, telephone, adresse
// La matière et la classe sont dans la table Enseignement

import 'package:gestion_ecole/models/enseignant_model.dart';

class EnseignantDto {
  final String nomComplet;
  final String email;
  final String telephone;
  final String adresse;

  EnseignantDto({
    required this.nomComplet,
    required this.email,
    required this.telephone,
    required this.adresse,
  });

  factory EnseignantDto.fromModel(EnseignantModel m) => EnseignantDto(
    nomComplet: m.nomComplet,
    email: m.email,
    telephone: m.telephone,
    adresse: m.adresse,
  );

  EnseignantModel toModel() => EnseignantModel(
    nomComplet: nomComplet,
    email: email,
    telephone: telephone,
    adresse: adresse,
  );

  Map<String, dynamic> toMap() => {
    'nomComplet': nomComplet,
    'email': email,
    'telephone': telephone,
    'adresse': adresse,
    'role': 'enseignant',
  };
}
