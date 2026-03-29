// lib/models/coefficient_model.dart
//
// Stocke le coefficient d'une matière pour une classe donnée.
// Collection Firestore : 'coefficient'
// {
//   idClasse, nomClasse, matiere, valeur (double)
// }

import 'package:cloud_firestore/cloud_firestore.dart';

class CoefficientModel {
  final String? id;
  final String idClasse;
  final String nomClasse;
  final String matiere;
  final double valeur;

  CoefficientModel({
    this.id,
    required this.idClasse,
    required this.nomClasse,
    required this.matiere,
    required this.valeur,
  });

  factory CoefficientModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CoefficientModel(
      id: doc.id,
      idClasse: d['idClasse'] ?? '',
      nomClasse: d['nomClasse'] ?? '',
      matiere: d['matiere'] ?? '',
      valeur: (d['valeur'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'idClasse': idClasse,
        'nomClasse': nomClasse,
        'matiere': matiere,
        'valeur': valeur,
      };
}