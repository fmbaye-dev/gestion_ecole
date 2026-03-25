// lib/models/eleve_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class EleveModel {
  final String? id;
  final String nomComplet;
  final String email;
  final String motPasse;
  final String telephone;
  final String adresse;
  final String idClasse;
  final String nomClasse;

  EleveModel({
    this.id,
    required this.nomComplet,
    required this.email,
    this.motPasse = '',
    required this.telephone,
    required this.adresse,
    required this.idClasse,
    this.nomClasse = '',
  });

  factory EleveModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EleveModel(
      id: doc.id,
      nomComplet: d['nomComplet'] ?? '',
      email: d['email'] ?? '',
      telephone: d['telephone'] ?? '',
      adresse: d['adresse'] ?? '',
      idClasse: d['idClasse'] ?? '',
      nomClasse: d['nomClasse'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'nomComplet': nomComplet,
    'email': email,
    'telephone': telephone,
    'adresse': adresse,
    'idClasse': idClasse,
    'nomClasse': nomClasse,
    'role': 'eleve',
  };

  String get initiales {
    final p = nomComplet.trim().split(' ');
    if (p.length >= 2 && p[0].isNotEmpty && p[1].isNotEmpty) {
      return '${p[0][0]}${p[1][0]}'.toUpperCase();
    }
    return nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : 'E';
  }
}
