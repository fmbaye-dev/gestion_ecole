// lib/dto/eleve_dto.dart

import 'package:gestion_ecole/models/eleve_model.dart';

class EleveDto {
  final String nomComplet;
  final String email;
  final String telephone;
  final String adresse;
  final String idClasse;
  final String nomClasse;
  final String anneeScolaire;

  EleveDto({
    required this.nomComplet,
    required this.email,
    required this.telephone,
    required this.adresse,
    required this.idClasse,
    this.nomClasse = '',
    this.anneeScolaire = '',
  });

  factory EleveDto.fromModel(EleveModel m) => EleveDto(
    nomComplet: m.nomComplet,
    email: m.email,
    telephone: m.telephone,
    adresse: m.adresse,
    idClasse: m.idClasse,
    nomClasse: m.nomClasse,
    anneeScolaire: m.anneeScolaire,
  );

  EleveModel toModel() => EleveModel(
    nomComplet: nomComplet,
    email: email,
    telephone: telephone,
    adresse: adresse,
    idClasse: idClasse,
    nomClasse: nomClasse,
    anneeScolaire: anneeScolaire,
  );

  Map<String, dynamic> toMap() => {
    'nomComplet': nomComplet,
    'email': email,
    'telephone': telephone,
    'adresse': adresse,
    'idClasse': idClasse,
    'nomClasse': nomClasse,
    'anneeScolaire': anneeScolaire,
    'role': 'eleve',
  };
}
