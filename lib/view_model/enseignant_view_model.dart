// lib/view_model/enseignant_view_model.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_ecole/config/app_logger.dart';
import 'package:gestion_ecole/models/enseignant_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class EnseignantViewModel extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _erreur;

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  Stream<List<EnseignantModel>> get streamEnseignants =>
      _service.streamEnseignants().map((s) {
        final list = s.docs
            .map((d) => EnseignantModel.fromFirestore(d))
            .toList();
        list.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
        return list;
      });

  Future<bool> ajouter(
    EnseignantModel enseignant, {
    String motPasse = '',
  }) async {
    _setLoading(true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: enseignant.email.trim(),
        password: motPasse.trim(),
      );
      final uid = credential.user?.uid;
      await _service.ajouterEnseignantAvecUid(uid!, enseignant.toMap());
      AppLogger.info('Enseignant créé : $uid');
      _erreur = null;
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _erreur = 'Email déjà utilisé.';
          break;
        case 'weak-password':
          _erreur = 'Mot de passe trop faible (min. 6 car.).';
          break;
        case 'invalid-email':
          _erreur = 'Email invalide.';
          break;
        default:
          _erreur = e.message ?? 'Erreur Auth.';
      }
      return false;
    } catch (e) {
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> modifier(String id, EnseignantModel enseignant) async {
    _setLoading(true);
    try {
      // modifierEnseignant gère la cascade (nomEnseignant dans enseignements)
      await _service.modifierEnseignant(id, enseignant.toMap());
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
      // supprimerEnseignant gère la cascade (enseignements + notes + absences)
      await _service.supprimerEnseignant(id);
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
