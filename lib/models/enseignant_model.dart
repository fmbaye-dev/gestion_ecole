// lib/models/enseignant_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class EnseignantModel {
  final String? id;
  final String  nomComplet;
  final String  email;
  final String  motPasse;
  final String  telephone;
  final String  adresse;

  EnseignantModel({
    this.id,
    required this.nomComplet,
    required this.email,
    this.motPasse  = '',
    required this.telephone,
    required this.adresse,
  });

  factory EnseignantModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EnseignantModel(
      id:         doc.id,
      nomComplet: d['nomComplet'] ?? '',
      email:      d['email']      ?? '',
      telephone:  d['telephone']  ?? '',
      adresse:    d['adresse']    ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'nomComplet': nomComplet,
    'email':      email,
    'telephone':  telephone,
    'adresse':    adresse,
    'role':       'enseignant',
  };

  String get initiales {
    final p = nomComplet.trim().split(' ');
    if (p.length >= 2 && p[0].isNotEmpty && p[1].isNotEmpty) {
      return '${p[0][0]}${p[1][0]}'.toUpperCase();
    }
    return nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : 'P';
  }
}