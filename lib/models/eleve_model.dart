// lib/models/eleve_model.dart
// MODIFIÉ : ajout tuteur (nomTuteur, contactTuteur, emailTuteur)
//           ajout santé (maladies, handicaps, observationsMedicales)

import 'package:cloud_firestore/cloud_firestore.dart';

class EleveModel {
  final String? id;
  final String  nomComplet;
  final String  email;
  final String  motPasse;
  final String  telephone;
  final String  adresse;
  final String  idClasse;
  final String  nomClasse;
  final String  anneeScolaire;

  // ── Tuteur ────────────────────────────────────────────────────────────────
  final String nomTuteur;       // ← NOUVEAU
  final String contactTuteur;   // ← NOUVEAU
  final String emailTuteur;     // ← NOUVEAU

  // ── Santé ─────────────────────────────────────────────────────────────────
  final String maladies;              // ← NOUVEAU
  final String handicaps;             // ← NOUVEAU
  final String observationsMedicales; // ← NOUVEAU

  EleveModel({
    this.id,
    required this.nomComplet,
    required this.email,
    this.motPasse              = '',
    required this.telephone,
    required this.adresse,
    required this.idClasse,
    this.nomClasse             = '',
    this.anneeScolaire         = '',
    this.nomTuteur             = '',
    this.contactTuteur         = '',
    this.emailTuteur           = '',
    this.maladies              = '',
    this.handicaps             = '',
    this.observationsMedicales = '',
  });

  factory EleveModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EleveModel(
      id:                    doc.id,
      nomComplet:            d['nomComplet']            ?? '',
      email:                 d['email']                 ?? '',
      telephone:             d['telephone']             ?? '',
      adresse:               d['adresse']               ?? '',
      idClasse:              d['idClasse']              ?? '',
      nomClasse:             d['nomClasse']             ?? '',
      anneeScolaire:         d['anneeScolaire']         ?? '',
      nomTuteur:             d['nomTuteur']             ?? '',
      contactTuteur:         d['contactTuteur']         ?? '',
      emailTuteur:           d['emailTuteur']           ?? '',
      maladies:              d['maladies']              ?? '',
      handicaps:             d['handicaps']             ?? '',
      observationsMedicales: d['observationsMedicales'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'nomComplet':            nomComplet,
    'email':                 email,
    'telephone':             telephone,
    'adresse':               adresse,
    'idClasse':              idClasse,
    'nomClasse':             nomClasse,
    'anneeScolaire':         anneeScolaire,
    'role':                  'eleve',
    'nomTuteur':             nomTuteur,
    'contactTuteur':         contactTuteur,
    'emailTuteur':           emailTuteur,
    'maladies':              maladies,
    'handicaps':             handicaps,
    'observationsMedicales': observationsMedicales,
  };

  String get initiales {
    final p = nomComplet.trim().split(' ');
    if (p.length >= 2 && p[0].isNotEmpty && p[1].isNotEmpty)
      return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : 'E';
  }

  static String anneeCourante() {
    final now = DateTime.now();
    final debut = now.month >= 9 ? now.year : now.year - 1;
    return '$debut-${debut + 1}';
  }
}