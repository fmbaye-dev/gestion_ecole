// lib/view_model/absence_view_model.dart
// MODIFIÉ : streamFiltrees avec type, compterAbsencesEtRetards pour bulletin

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_ecole/models/absence_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class AbsenceViewModel extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  bool _isLoading = false;
  String? _erreur;

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  Stream<List<AbsenceModel>> get streamAbsences =>
      _service.streamAbsences().map(_parse);

  Stream<List<AbsenceModel>> streamEleve(String idEleve) =>
      _service.streamAbsencesEleve(idEleve).map(_parse);

  Stream<List<AbsenceModel>> streamEnseignant(String idEnseignant) =>
      _service.streamAbsencesEnseignant(idEnseignant).map(_parse);

  Stream<List<AbsenceModel>> streamFiltrees({
    String? idEleve,
    String? type,
    String? matiere,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) => _service
      .streamAbsencesFiltrees(
        idEleve: idEleve,
        type: type,
        matiere: matiere,
        dateDebut: dateDebut,
        dateFin: dateFin,
      )
      .map(_parse);

  List<AbsenceModel> _parse(QuerySnapshot s) {
    final list = s.docs.map((d) => AbsenceModel.fromFirestore(d)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<Map<String, int>> compterAbsencesEtRetards({
    required String idEleve,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    Query q = FirebaseFirestore.instance
        .collection('absence')
        .where('idEleve', isEqualTo: idEleve);
    if (dateDebut != null)
      q = q.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut),
      );
    if (dateFin != null)
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateFin));
    final snap = await q.get();
    int nbAbsences = 0, nbRetards = 0;
    for (final doc in snap.docs) {
      final type = (doc.data() as Map<String, dynamic>)['type'] as String?;
      if (type == 'retard')
        nbRetards++;
      else
        nbAbsences++;
    }
    return {'absences': nbAbsences, 'retards': nbRetards};
  }

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
