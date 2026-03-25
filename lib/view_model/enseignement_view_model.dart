// lib/view_model/enseignement_view_model.dart

import 'package:flutter/material.dart';
import 'package:gestion_ecole/models/enseignement_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class EnseignementViewModel extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  bool _isLoading = false;
  String? _erreur;

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  // Tous les enseignements
  Stream<List<EnseignementModel>> get streamEnseignements =>
      _service.streamEnseignements().map(
        (s) => s.docs.map((d) => EnseignementModel.fromFirestore(d)).toList(),
      );

  // Par classe
  Stream<List<EnseignementModel>> streamParClasse(String idClasse) => _service
      .streamEnseignementsParClasse(idClasse)
      .map(
        (s) => s.docs.map((d) => EnseignementModel.fromFirestore(d)).toList(),
      );

  // Par enseignant
  Stream<List<EnseignementModel>> streamParEnseignant(String idEnseignant) =>
      _service
          .streamEnseignementsParEnseignant(idEnseignant)
          .map(
            (s) =>
                s.docs.map((d) => EnseignementModel.fromFirestore(d)).toList(),
          );

  Future<bool> ajouter(EnseignementModel e) async {
    _setLoading(true);
    try {
      await _service.ajouterEnseignement(e.toMap());
      _erreur = null;
      return true;
    } catch (ex) {
      _erreur = ex.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> modifier(String id, EnseignementModel e) async {
    _setLoading(true);
    try {
      await _service.modifierEnseignement(id, e.toMap());
      _erreur = null;
      return true;
    } catch (ex) {
      _erreur = ex.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> supprimer(String id) async {
    _setLoading(true);
    try {
      await _service.supprimerEnseignement(id);
      _erreur = null;
      return true;
    } catch (ex) {
      _erreur = ex.toString();
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

