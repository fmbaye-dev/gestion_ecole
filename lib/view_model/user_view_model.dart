// lib/viewmodels/user_view_model.dart

import 'package:flutter/material.dart';
import 'package:gestion_ecole/models/user_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class UserViewModel extends ChangeNotifier {
  final FirebaseService _service;

  bool isLoading = false;
  String? errorMessage; // ✅ Nullable

  UserViewModel({FirebaseService? service}) // ✅ Paramètre nullable
    : _service = service ?? FirebaseService();

  Future<UserModel?> registerUser({
    // ✅ Retour nullable
    required String nomComplet,
    required String email,
    required String motPasse,
    required String adresse,
    required String telephone,
    required String role,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // Validation métier
      final errors = UserModel.validateBusinessRules(
        nomComplet: nomComplet,
        email: email,
        motPasse: motPasse,
        adresse: adresse,
        telephone: telephone,
        role: role,
      );
      if (errors.isNotEmpty) throw ValidationException(errors);

      // Création via le service (Firebase Auth + Firestore)
      final user = await _service.createUser(
        nomComplet: nomComplet,
        email: email,
        motPasse: motPasse,
        adresse: adresse,
        telephone: telephone,
        role: role,
      );

      return user;
    } catch (e) {
      errorMessage = e is ValidationException
          ? e.errors.join('\n')
          : e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
