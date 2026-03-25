// lib/dto/user_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_ecole/models/user_model.dart';

class UserDto {
  final String uid;
  final String nomComplet;
  final String email;
  final String motPasse;
  final String adresse;
  final String telephone;
  final String role;

  UserDto({
    required this.uid,
    required this.nomComplet,
    required this.email,
    this.motPasse = '',
    required this.adresse,
    required this.telephone,
    required this.role,
  });

  factory UserDto.fromModel(UserModel m) => UserDto(
    uid: m.uid,
    nomComplet: m.nomComplet,
    email: m.email,
    motPasse: m.motPasse,
    adresse: m.adresse,
    telephone: m.telephone,
    role: m.role,
  );

  factory UserDto.fromMap(Map<String, dynamic> map) => UserDto(
    uid: map['uid'] ?? '',
    nomComplet: map['nomComplet'] ?? '',
    email: map['email'] ?? '',
    motPasse: '',
    adresse: map['adresse'] ?? '',
    telephone: map['telephone'] ?? '',
    role: map['role'] ?? 'eleve',
  );

  UserModel toModel() => UserModel(
    uid: uid,
    nomComplet: nomComplet,
    email: email,
    motPasse: motPasse,
    adresse: adresse,
    telephone: telephone,
    role: role,
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nomComplet': nomComplet,
    'email': email,
    'adresse': adresse,
    'telephone': telephone,
    'role': role,
    'date_creation': FieldValue.serverTimestamp(),
  };
}
