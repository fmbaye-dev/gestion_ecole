// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String nomComplet;
  final String email;
  final String motPasse; // Vide après création (non stocké en clair)
  final String adresse;
  final String telephone;
  final String role;

  UserModel({
    required this.uid,
    required this.nomComplet,
    required this.email,
    this.motPasse =
        '', // Optionnel : on ne stocke jamais le mot de passe en clair
    required this.adresse,
    required this.telephone,
    required this.role,
  });

  static const _validRoles = {'admin', 'enseignant', 'eleve'};

  static List<String> validateBusinessRules({
    required String nomComplet,
    required String email,
    required String motPasse,
    required String adresse,
    required String telephone,
    required String role,
  }) {
    final errors = <String>[];

    if (nomComplet.trim().isEmpty)
      errors.add('Le nom complet est obligatoire.');
    else if (nomComplet.trim().length < 3)
      errors.add('Le nom complet doit contenir au moins 3 caractères.');

    if (email.trim().isEmpty)
      errors.add("L'email est obligatoire.");
    else if (!_isEmailValid(email.trim()))
      errors.add("L'email est invalide.");

    if (motPasse.isEmpty) {
      errors.add('Le mot de passe est obligatoire.');
    } else {
      if (motPasse.length < 8) {
        errors.add('Le mot de passe doit contenir au moins 8 caractères.');
      }
      if (!RegExp(r'[A-Z]').hasMatch(motPasse)) {
        errors.add('Le mot de passe doit contenir une lettre majuscule.');
      }
      if (!RegExp(r'[a-z]').hasMatch(motPasse)) {
        errors.add('Le mot de passe doit contenir une lettre minuscule.');
      }
      if (!RegExp(r'[0-9]').hasMatch(motPasse)) {
        errors.add('Le mot de passe doit contenir un chiffre.');
      }
    }

    if (adresse.trim().isEmpty)
      errors.add("L'adresse est obligatoire.");
    else if (adresse.trim().length < 5)
      errors.add("L'adresse est trop courte.");

    if (telephone.trim().isEmpty)
      errors.add('Le téléphone est obligatoire.');
    else if (!_isTelephoneValide(telephone.trim()))
      errors.add('Le format du téléphone est invalide.');

    if (role.trim().isEmpty)
      errors.add('Le rôle est obligatoire.');
    else if (!_validRoles.contains(role))
      errors.add('Le rôle doit être admin, enseignant ou eleve.');

    return errors;
  }

  static void enforceBusinessRules({
    required String nomComplet,
    required String email,
    required String motPasse,
    required String adresse,
    required String telephone,
    required String role,
  }) {
    final errors = validateBusinessRules(
      nomComplet: nomComplet,
      email: email,
      motPasse: motPasse,
      adresse: adresse,
      telephone: telephone,
      role: role,
    );
    if (errors.isNotEmpty) throw ValidationException(errors);
  }

  static bool _isEmailValid(String email) =>
      RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}").hasMatch(email);

  static bool _isTelephoneValide(String telephone) {
    final numeric = telephone.replaceAll(RegExp(r'[^0-9]'), '');
    return numeric.length >= 8 && numeric.length <= 15;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    nomComplet: map['nomComplet'] ?? '',
    email: map['email'] ?? '',
    motPasse: '', // Jamais lu depuis Firestore (non stocké)
    adresse: map['adresse'] ?? '',
    telephone: map['telephone'] ?? '',
    role: map['role'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nomComplet': nomComplet,
    'email': email,
    // motPasse jamais inclus dans les données Firestore
    'adresse': adresse,
    'telephone': telephone,
    'role': role,
  };
}

/// Exception métier levée quand les règles de validation échouent.
class ValidationException implements Exception {
  final List<String> errors;
  const ValidationException(this.errors);

  @override
  String toString() => errors.join('\n');
}
