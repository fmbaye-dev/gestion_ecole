// lib/view_model/matiere_view_model.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_ecole/models/matiere_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class MatiereViewModel extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final _col = FirebaseFirestore.instance.collection('matiere');

  bool _isLoading = false;
  String? _erreur;

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  Stream<List<MatiereModel>> get streamMatieres => _col.snapshots().map((s) {
    final list = s.docs.map((d) => MatiereModel.fromFirestore(d)).toList();
    list.sort((a, b) => a.nom.compareTo(b.nom));
    return list;
  });

  Future<bool> ajouter(String nom) async {
    _setLoading(true);
    try {
      await _col.add({'nom': nom.trim()});
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// UPDATE matière → cascade sur Enseignements + Notes + Absences
  Future<bool> modifier(String id, String ancienNom, String nouveauNom) async {
    _setLoading(true);
    try {
      await _service.modifierMatiere(id, ancienNom, nouveauNom);
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// DELETE matière → cascade sur Enseignements + Notes + Absences
  Future<bool> supprimer(String id, String nomMatiere) async {
    _setLoading(true);
    try {
      await _service.supprimerMatiere(id, nomMatiere);
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}

