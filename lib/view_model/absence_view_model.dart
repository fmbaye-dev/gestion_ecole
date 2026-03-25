// lib/view_model/absence_view_model.dart

import 'package:flutter/material.dart';
import 'package:gestion_ecole/models/absence_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class AbsenceViewModel extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  bool _isLoading = false;
  String? _erreur;

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  // Toutes les absences (admin)
  Stream<List<AbsenceModel>> get streamAbsences =>
      _service.streamAbsences().map((s) {
        final list = s.docs.map((d) => AbsenceModel.fromFirestore(d)).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });

  // Absences d'un élève
  Stream<List<AbsenceModel>> streamEleve(String idEleve) =>
      _service.streamAbsencesEleve(idEleve).map((s) {
        final list = s.docs.map((d) => AbsenceModel.fromFirestore(d)).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });

  // Absences saisies par un enseignant
  Stream<List<AbsenceModel>> streamEnseignant(String idEnseignant) =>
      _service.streamAbsencesEnseignant(idEnseignant).map((s) {
        final list = s.docs.map((d) => AbsenceModel.fromFirestore(d)).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });

  Future<bool> ajouter(AbsenceModel absence) async {
    _setLoading(true);
    try {
      await _service.ajouterAbsence(absence.toMap());
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> modifier(String id, AbsenceModel absence) async {
    _setLoading(true);
    try {
      await _service.modifierAbsence(id, absence.toMap());
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> supprimer(String id) async {
    _setLoading(true);
    try {
      await _service.supprimerAbsence(id);
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
