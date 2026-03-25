// lib/view_model/classe_view_model.dart

import 'package:flutter/material.dart';
import 'package:gestion_ecole/models/classe_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class ClasseViewModel extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  bool _isLoading = false;
  String? _erreur;
  List<ClasseModel> _classes = [];

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;
  List<ClasseModel> get classes => _classes;

  Stream<List<ClasseModel>> get streamClasses => _service.streamClasses().map(
    (s) => s.docs.map((d) => ClasseModel.fromFirestore(d)).toList(),
  );

  Future<void> chargerClasses() async {
    _setLoading(true);
    try {
      final data = await _service.getClasses();
      _classes = data
          .map((m) => ClasseModel.fromMap(m['id'] as String, m))
          .toList();
      _erreur = null;
    } catch (e) {
      _erreur = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> ajouter(ClasseModel classe) async {
    _setLoading(true);
    try {
      await _service.ajouterClasse(classe.toMap());
      await chargerClasses();
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
      await _service.supprimerClasse(id);
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

