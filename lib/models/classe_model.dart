// lib/models/classe_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ClasseModel {
  final String? id;
  final String nomClasse;

  ClasseModel({this.id, required this.nomClasse});

  factory ClasseModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClasseModel(id: doc.id, nomClasse: d['nomClasse'] ?? '');
  }

  factory ClasseModel.fromMap(String id, Map<String, dynamic> d) =>
      ClasseModel(id: id, nomClasse: d['nomClasse'] ?? '');

  Map<String, dynamic> toMap() => {'nomClasse': nomClasse};
}
