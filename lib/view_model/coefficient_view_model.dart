// lib/view_model/coefficient_view_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gestion_ecole/models/coefficient_model.dart';

class CoefficientViewModel extends ChangeNotifier {
  final _col = FirebaseFirestore.instance.collection('coefficient');

  bool _isLoading = false;
  String? _erreur;

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  /// Stream de tous les coefficients
  Stream<List<CoefficientModel>> get streamCoefficients =>
      _col.snapshots().map((s) =>
          s.docs.map((d) => CoefficientModel.fromFirestore(d)).toList());

  /// Stream des coefficients d'une classe
  Stream<List<CoefficientModel>> streamParClasse(String idClasse) => _col
      .where('idClasse', isEqualTo: idClasse)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => CoefficientModel.fromFirestore(d)).toList());

  /// Obtenir le coefficient d'une matière pour une classe (one-shot)
  Future<double> getCoefficient(String idClasse, String matiere) async {
    final snap = await _col
        .where('idClasse', isEqualTo: idClasse)
        .where('matiere', isEqualTo: matiere)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return 1.0;
    return (snap.docs.first.data()['valeur'] as num?)?.toDouble() ?? 1.0;
  }

  /// Définir ou mettre à jour le coefficient d'une matière pour une classe
  Future<bool> definirCoefficient(CoefficientModel coeff) async {
    _setLoading(true);
    try {
      // Chercher si existe déjà
      final snap = await _col
          .where('idClasse', isEqualTo: coeff.idClasse)
          .where('matiere', isEqualTo: coeff.matiere)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({'valeur': coeff.valeur});
      } else {
        await _col.add(coeff.toMap());
      }
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Supprimer le coefficient d'une matière pour une classe
  Future<bool> supprimer(String id) async {
    _setLoading(true);
    try {
      await _col.doc(id).delete();
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mise à jour en cascade quand une classe est renommée
  Future<void> onClasseRenommee(String idClasse, String nouveauNom) async {
    final snap = await _col.where('idClasse', isEqualTo: idClasse).get();
    for (final doc in snap.docs) {
      await doc.reference.update({'nomClasse': nouveauNom});
    }
  }

  /// Mise à jour en cascade quand une matière est renommée
  Future<void> onMatiereRenommee(
      String ancienNom, String nouveauNom) async {
    final snap = await _col.where('matiere', isEqualTo: ancienNom).get();
    for (final doc in snap.docs) {
      await doc.reference.update({'matiere': nouveauNom});
    }
  }

  /// Suppression en cascade quand une classe est supprimée
  Future<void> onClasseSupprimee(String idClasse) async {
    final snap = await _col.where('idClasse', isEqualTo: idClasse).get();
    for (final doc in snap.docs) await doc.reference.delete();
  }

  /// Suppression en cascade quand une matière est supprimée
  Future<void> onMatiereSupprimee(String nomMatiere) async {
    final snap = await _col.where('matiere', isEqualTo: nomMatiere).get();
    for (final doc in snap.docs) await doc.reference.delete();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}