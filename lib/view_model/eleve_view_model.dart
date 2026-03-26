// lib/view_model/eleve_view_model.dart
// pas déconnecter l'administrateur lors de la création d'un élève.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gestion_ecole/config/app_logger.dart';
import 'package:gestion_ecole/models/eleve_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class EleveViewModel extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();

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
    FirebaseApp? secondaryApp;
    try {
      // ✅ BUG #7 CORRIGÉ : Utiliser une instance Firebase secondaire
      // pour ne pas remplacer la session admin courante
      secondaryApp = await Firebase.initializeApp(
        name: 'eleveCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: eleve.email.trim(),
        password: eleve.motPasse.trim(),
      );
      final uid = credential.user?.uid;

      // Nettoyage de l'instance secondaire immédiatement après création
      await secondaryAuth.signOut();
      await secondaryApp.delete();
      secondaryApp = null;

      await _service.ajouterEleveAvecUid(uid!, eleve.toMap());
      AppLogger.info('Élève créé : $uid (admin session préservée)');
      _erreur = null;
      return true;
    } on FirebaseAuthException catch (e) {
      await _cleanupSecondaryApp(secondaryApp);
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
      await _cleanupSecondaryApp(secondaryApp);
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _cleanupSecondaryApp(FirebaseApp? app) async {
    if (app == null) return;
    try {
      await FirebaseAuth.instanceFor(app: app).signOut();
      await app.delete();
    } catch (_) {}
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
