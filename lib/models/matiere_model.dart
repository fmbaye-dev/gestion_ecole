// lib/models/matiere_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MatiereModel {
  final String? id;
  final String nom;

  MatiereModel({this.id, required this.nom});

  factory MatiereModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MatiereModel(id: doc.id, nom: d['nom'] ?? '');
  }

  Map<String, dynamic> toMap() => {'nom': nom};
}
