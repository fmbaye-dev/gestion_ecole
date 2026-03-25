// lib/dto/eleve_dto.dart

import 'package:gestion_ecole/models/eleve_model.dart';

class EleveDto {
  final String nomComplet;
  final String email;
  final String telephone;
  final String adresse;
  final String idClasse;
  final String nomClasse;

  EleveDto({
    required this.nomComplet,
    required this.email,
    required this.telephone,
    required this.adresse,
    required this.idClasse,
    this.nomClasse = '',
  });

  factory EleveDto.fromModel(EleveModel m) => EleveDto(
    nomComplet: m.nomComplet, email: m.email,
    telephone: m.telephone,  adresse: m.adresse,
    idClasse: m.idClasse,    nomClasse: m.nomClasse,
  );

  EleveModel toModel() => EleveModel(
    nomComplet: nomComplet, email: email,
    telephone: telephone,   adresse: adresse,
    idClasse: idClasse,     nomClasse: nomClasse,
  );

  Map<String, dynamic> toMap() => {
    'nomComplet': nomComplet, 'email': email,
    'telephone':  telephone,  'adresse': adresse,
    'idClasse':   idClasse,   'nomClasse': nomClasse,
    'role':       'eleve',
  };
}