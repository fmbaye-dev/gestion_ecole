// lib/view_model/eleve_view_model.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_ecole/config/app_logger.dart';
import 'package:gestion_ecole/models/eleve_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class EleveViewModel extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _erreur;

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  Stream<List<EleveModel>> get streamEleves => _service.streamEleves().map((s) {
    final list = s.docs.map((d) => EleveModel.fromFirestore(d)).toList();
    list.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
    return list;
  });

  Stream<List<EleveModel>> streamParClasse(String idClasse) =>
      _service.streamElevesParClasse(idClasse).map((s) {
        final list = s.docs.map((d) => EleveModel.fromFirestore(d)).toList();
        list.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
        return list;
      });

  Future<bool> ajouter(EleveModel eleve) async {
    _setLoading(true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: eleve.email.trim(),
        password: eleve.motPasse.trim(),
      );
      final uid = credential.user?.uid;
      await _service.ajouterEleveAvecUid(uid!, eleve.toMap());
      AppLogger.info('Élève créé : $uid');
      _erreur = null;
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _erreur = 'Email déjà utilisé.';
          break;
        case 'weak-password':
          _erreur = 'Mot de passe trop faible.';
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

  Future<bool> modifier(String id, EleveModel eleve) async {
    _setLoading(true);
    try {
      await _service.modifierEleve(id, eleve.toMap());
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
      await _service.supprimerEleve(id);
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
