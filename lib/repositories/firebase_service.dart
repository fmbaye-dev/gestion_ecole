// lib/repositories/firebase_service.dart
//
// Cascades implémentées :
//  Élève supprimé      → DELETE ses Notes, DELETE ses Absences
//  Enseignant supprimé → DELETE ses Enseignements, DELETE ses Notes, DELETE ses Absences
//  Classe supprimée    → DELETE ses Enseignements, UPDATE idClasse='' des Élèves liés
//  Matière supprimée   → DELETE Enseignements liés, DELETE Notes liées, DELETE Absences liées
//  Classe renommée     → UPDATE nomClasse dans Enseignements liés + Élèves liés
//  Enseignant modifié  → UPDATE nomEnseignant dans Enseignements liés

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_ecole/config/app_logger.dart';
import 'package:gestion_ecole/models/user_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _utilisateurs =>
      _db.collection('utilisateur');
  CollectionReference<Map<String, dynamic>> get _classes =>
      _db.collection('classe');
  CollectionReference<Map<String, dynamic>> get _enseignements =>
      _db.collection('enseignement');
  CollectionReference<Map<String, dynamic>> get _notes =>
      _db.collection('note');
  CollectionReference<Map<String, dynamic>> get _absences =>
      _db.collection('absence');
  CollectionReference<Map<String, dynamic>> get _matieres =>
      _db.collection('matiere');

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER : suppression en batch d'une QuerySnapshot
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _supprimerDocs(QuerySnapshot snap) async {
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTHENTIFICATION & CRÉATION D'UTILISATEUR
  // ══════════════════════════════════════════════════════════════════════════

  /// Crée un compte Firebase Auth + enregistre le profil dans Firestore.
  /// Le mot de passe n'est JAMAIS stocké dans Firestore.
  Future<UserModel> createUser({
    required String nomComplet,
    required String email,
    required String motPasse,
    required String adresse,
    required String telephone,
    required String role,
  }) async {
    // 1. Création du compte Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: motPasse,
    );
    final uid = credential.user?.uid;

    // 2. Profil Firestore — sans motPasse
    final data = <String, dynamic>{
      'uid': uid,
      'nomComplet': nomComplet,
      'email': email,
      'adresse': adresse,
      'telephone': telephone,
      'role': role,
      'dateCreation': FieldValue.serverTimestamp(),
    };
    await _utilisateurs.doc(uid).set(data);
    AppLogger.info('Utilisateur créé : $uid ($role)');

    // 3. ✅ motPasse omis — valeur par défaut '' utilisée dans UserModel
    return UserModel(
      uid: uid ?? '',
      nomComplet: nomComplet,
      email: email,
      adresse: adresse,
      telephone: telephone,
      role: role,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ÉLÈVES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<QuerySnapshot> streamEleves() =>
      _utilisateurs.where('role', isEqualTo: 'eleve').snapshots();

  Stream<QuerySnapshot> streamElevesParClasse(String idClasse) => _utilisateurs
      .where('role', isEqualTo: 'eleve')
      .where('idClasse', isEqualTo: idClasse)
      .snapshots();

  Future<void> ajouterEleveAvecUid(
    String uid,
    Map<String, dynamic> data,
  ) async {
    data['dateCreation'] = FieldValue.serverTimestamp();
    await _utilisateurs.doc(uid).set(data);
    AppLogger.info('Élève ajouté : $uid');
  }

  Future<void> modifierEleve(String id, Map<String, dynamic> data) {
    data['dateModification'] = FieldValue.serverTimestamp();
    return _utilisateurs.doc(id).update(data.cast<Object, Object>());
  }

  /// DELETE élève → DELETE ses Notes + Absences (cascade)
  Future<void> supprimerEleve(String id) async {
    final notes = await _notes.where('idEleve', isEqualTo: id).get();
    await _supprimerDocs(notes);
    AppLogger.info(
      'Cascade: ${notes.docs.length} note(s) supprimée(s) pour élève $id',
    );

    final absences = await _absences.where('idEleve', isEqualTo: id).get();
    await _supprimerDocs(absences);
    AppLogger.info(
      'Cascade: ${absences.docs.length} absence(s) supprimée(s) pour élève $id',
    );

    await _utilisateurs.doc(id).delete();
    AppLogger.info('Élève supprimé : $id');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENSEIGNANTS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<QuerySnapshot> streamEnseignants() =>
      _utilisateurs.where('role', isEqualTo: 'enseignant').snapshots();

  Future<void> ajouterEnseignantAvecUid(
    String uid,
    Map<String, dynamic> data,
  ) async {
    data['dateCreation'] = FieldValue.serverTimestamp();
    await _utilisateurs.doc(uid).set(data);
    AppLogger.info('Enseignant ajouté : $uid');
  }

  /// UPDATE enseignant → UPDATE nomEnseignant dans Enseignements liés (cascade)
  Future<void> modifierEnseignant(String id, Map<String, dynamic> data) async {
    data['dateModification'] = FieldValue.serverTimestamp();
    await _utilisateurs.doc(id).update(data.cast<Object, Object>());

    if (data.containsKey('nomComplet')) {
      final snap = await _enseignements
          .where('idEnseignant', isEqualTo: id)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'nomEnseignant': data['nomComplet']});
      }
      AppLogger.info(
        'Cascade: nomEnseignant mis à jour dans ${snap.docs.length} enseignement(s)',
      );
    }
  }

  /// DELETE enseignant → DELETE Enseignements + Notes + Absences (cascade)
  Future<void> supprimerEnseignant(String id) async {
    final enseignements = await _enseignements
        .where('idEnseignant', isEqualTo: id)
        .get();
    await _supprimerDocs(enseignements);
    AppLogger.info(
      'Cascade: ${enseignements.docs.length} enseignement(s) supprimé(s)',
    );

    final notes = await _notes.where('idEnseignant', isEqualTo: id).get();
    await _supprimerDocs(notes);
    AppLogger.info('Cascade: ${notes.docs.length} note(s) supprimée(s)');

    final absences = await _absences.where('idEnseignant', isEqualTo: id).get();
    await _supprimerDocs(absences);
    AppLogger.info('Cascade: ${absences.docs.length} absence(s) supprimée(s)');

    await _utilisateurs.doc(id).delete();
    AppLogger.info('Enseignant supprimé : $id');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLASSES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<QuerySnapshot> streamClasses() => _classes.snapshots();

  Future<List<Map<String, dynamic>>> getClasses() async {
    final snap = await _classes.get();
    final list = snap.docs
        .where((d) => d.id.isNotEmpty)
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
    list.sort(
      (a, b) => (a['nomClasse'] as String).compareTo(b['nomClasse'] as String),
    );
    return list;
  }

  Future<String> ajouterClasse(Map<String, dynamic> data) async {
    data['dateCreation'] = FieldValue.serverTimestamp();
    final doc = await _classes.add(data);
    AppLogger.info('Classe ajoutée : ${doc.id}');
    return doc.id;
  }

  /// UPDATE classe → UPDATE nomClasse dans Enseignements + Élèves (cascade)
  Future<void> modifierClasse(String id, String nouveauNom) async {
    await _classes.doc(id).update({'nomClasse': nouveauNom});

    final ensSnap = await _enseignements.where('idClasse', isEqualTo: id).get();
    for (final doc in ensSnap.docs) {
      await doc.reference.update({'nomClasse': nouveauNom});
    }

    final etuSnap = await _utilisateurs
        .where('role', isEqualTo: 'eleve')
        .where('idClasse', isEqualTo: id)
        .get();
    for (final doc in etuSnap.docs) {
      await doc.reference.update({'nomClasse': nouveauNom});
    }

    AppLogger.info(
      'Classe $id renommée → $nouveauNom. '
      'Cascade: ${ensSnap.docs.length} enseignement(s), '
      '${etuSnap.docs.length} élève(s) mis à jour',
    );
  }

  /// DELETE classe → DELETE Enseignements + UPDATE idClasse='' des Élèves (cascade)
  Future<void> supprimerClasse(String id) async {
    final enseignements = await _enseignements
        .where('idClasse', isEqualTo: id)
        .get();
    await _supprimerDocs(enseignements);
    AppLogger.info(
      'Cascade: ${enseignements.docs.length} enseignement(s) supprimé(s)',
    );

    final eleves = await _utilisateurs
        .where('role', isEqualTo: 'eleve')
        .where('idClasse', isEqualTo: id)
        .get();
    for (final doc in eleves.docs) {
      await doc.reference.update({'idClasse': '', 'nomClasse': ''});
    }
    AppLogger.info(
      'Cascade: idClasse réinitialisé pour ${eleves.docs.length} élève(s)',
    );

    await _classes.doc(id).delete();
    AppLogger.info('Classe supprimée : $id');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENSEIGNEMENTS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<QuerySnapshot> streamEnseignements() => _enseignements.snapshots();

  Stream<QuerySnapshot> streamEnseignementsParClasse(String idClasse) =>
      _enseignements.where('idClasse', isEqualTo: idClasse).snapshots();

  Stream<QuerySnapshot> streamEnseignementsParEnseignant(String idEnseignant) =>
      _enseignements.where('idEnseignant', isEqualTo: idEnseignant).snapshots();

  Future<String> ajouterEnseignement(Map<String, dynamic> data) async {
    data['dateCreation'] = FieldValue.serverTimestamp();
    final doc = await _enseignements.add(data);
    AppLogger.info('Enseignement ajouté : ${doc.id}');
    return doc.id;
  }

  Future<void> modifierEnseignement(String id, Map<String, dynamic> data) =>
      _enseignements.doc(id).update(data.cast<Object, Object>());

  Future<void> supprimerEnseignement(String id) =>
      _enseignements.doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // MATIÈRES
  // ══════════════════════════════════════════════════════════════════════════

  /// DELETE matière → DELETE Enseignements + Notes + Absences liés (cascade)
  Future<void> supprimerMatiere(String id, String nomMatiere) async {
    final enseignements = await _enseignements
        .where('matiere', isEqualTo: nomMatiere)
        .get();
    await _supprimerDocs(enseignements);
    AppLogger.info(
      'Cascade: ${enseignements.docs.length} enseignement(s) supprimé(s)',
    );

    final notes = await _notes.where('matiere', isEqualTo: nomMatiere).get();
    await _supprimerDocs(notes);
    AppLogger.info('Cascade: ${notes.docs.length} note(s) supprimée(s)');

    final absences = await _absences
        .where('matiere', isEqualTo: nomMatiere)
        .get();
    await _supprimerDocs(absences);
    AppLogger.info('Cascade: ${absences.docs.length} absence(s) supprimée(s)');

    await _matieres.doc(id).delete();
    AppLogger.info('Matière supprimée : $nomMatiere');
  }

  /// UPDATE matière → UPDATE matiere dans Enseignements + Notes + Absences (cascade)
  Future<void> modifierMatiere(
    String id,
    String ancienNom,
    String nouveauNom,
  ) async {
    await _matieres.doc(id).update({'nom': nouveauNom});

    final ensSnap = await _enseignements
        .where('matiere', isEqualTo: ancienNom)
        .get();
    for (final doc in ensSnap.docs) {
      await doc.reference.update({'matiere': nouveauNom});
    }

    final notesSnap = await _notes.where('matiere', isEqualTo: ancienNom).get();
    for (final doc in notesSnap.docs) {
      await doc.reference.update({'matiere': nouveauNom});
    }

    final absSnap = await _absences
        .where('matiere', isEqualTo: ancienNom)
        .get();
    for (final doc in absSnap.docs) {
      await doc.reference.update({'matiere': nouveauNom});
    }

    AppLogger.info(
      'Matière "$ancienNom" → "$nouveauNom". '
      'Cascade: ${ensSnap.docs.length} ens, '
      '${notesSnap.docs.length} notes, '
      '${absSnap.docs.length} absences mis à jour',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<QuerySnapshot> streamNotes() => _notes.snapshots();

  Stream<QuerySnapshot> streamNotesEleve(String idEleve) =>
      _notes.where('idEleve', isEqualTo: idEleve).snapshots();

  Stream<QuerySnapshot> streamNotesEnseignant(String idEnseignant) =>
      _notes.where('idEnseignant', isEqualTo: idEnseignant).snapshots();

  Stream<QuerySnapshot> streamNotesFiltrees({
    String? idEleve,
    String? matiere,
    String? idEnseignant,
  }) {
    Query q = _notes;
    if (idEleve != null) q = q.where('idEleve', isEqualTo: idEleve);
    if (matiere != null) q = q.where('matiere', isEqualTo: matiere);
    if (idEnseignant != null) {
      q = q.where('idEnseignant', isEqualTo: idEnseignant);
    }
    return q.snapshots();
  }

  Future<String> ajouterNote(Map<String, dynamic> data) async {
    data['dateCreation'] = FieldValue.serverTimestamp();
    final doc = await _notes.add(data);
    AppLogger.info('Note ajoutée : ${doc.id}');
    return doc.id;
  }

  Future<void> modifierNote(String id, Map<String, dynamic> data) {
    data['dateModification'] = FieldValue.serverTimestamp();
    return _notes.doc(id).update(data.cast<Object, Object>());
  }

  Future<void> supprimerNote(String id) => _notes.doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // ABSENCES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<QuerySnapshot> streamAbsences() => _absences.snapshots();

  Stream<QuerySnapshot> streamAbsencesEleve(String idEleve) =>
      _absences.where('idEleve', isEqualTo: idEleve).snapshots();

  Stream<QuerySnapshot> streamAbsencesEnseignant(String idEnseignant) =>
      _absences.where('idEnseignant', isEqualTo: idEnseignant).snapshots();

  Future<String> ajouterAbsence(Map<String, dynamic> data) async {
    data['dateCreation'] = FieldValue.serverTimestamp();
    final doc = await _absences.add(data);
    AppLogger.info('Absence ajoutée : ${doc.id}');
    return doc.id;
  }

  Future<void> modifierAbsence(String id, Map<String, dynamic> data) {
    data['dateModification'] = FieldValue.serverTimestamp();
    return _absences.doc(id).update(data.cast<Object, Object>());
  }

  Future<void> supprimerAbsence(String id) => _absences.doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // STATS DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════

  Stream<int> streamCountEleves() => _utilisateurs
      .where('role', isEqualTo: 'eleve')
      .snapshots()
      .map((s) => s.size);

  Stream<int> streamCountEnseignants() => _utilisateurs
      .where('role', isEqualTo: 'enseignant')
      .snapshots()
      .map((s) => s.size);

  Stream<int> streamCountClasses() => _classes.snapshots().map((s) => s.size);

  Stream<int> streamCountAbsences() => _absences.snapshots().map((s) => s.size);

  Stream<int> streamAbsencesNonJustifiees() => _absences
      .where('justifiee', isEqualTo: false)
      .snapshots()
      .map((s) => s.size);

  Stream<QuerySnapshot> streamAbsNonJustifieesRecentes({int limit = 5}) =>
      _absences.where('justifiee', isEqualTo: false).limit(limit).snapshots();
}