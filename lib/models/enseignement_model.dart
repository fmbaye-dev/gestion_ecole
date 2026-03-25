// lib/models/enseignement_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class EnseignementModel {
  final String? id;
  final String idClasse;
  final String idEnseignant;
  final String matiere;
  final String anneeScolaire;
  final String nomClasse;
  final String nomEnseignant;

  EnseignementModel({
    this.id,
    required this.idClasse,
    required this.idEnseignant,
    required this.matiere,
    required this.anneeScolaire,
    this.nomClasse = '',
    this.nomEnseignant = '',
  });

  factory EnseignementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EnseignementModel(
      id: doc.id,
      idClasse: d['idClasse'] ?? '',
      idEnseignant: d['idEnseignant'] ?? '',
      matiere: d['matiere'] ?? '',
      anneeScolaire: d['anneeScolaire'] ?? '',
      nomClasse: d['nomClasse'] ?? '',
      nomEnseignant: d['nomEnseignant'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'idClasse': idClasse,
    'idEnseignant': idEnseignant,
    'matiere': matiere,
    'anneeScolaire': anneeScolaire,
    'nomClasse': nomClasse,
    'nomEnseignant': nomEnseignant,
  };
}
