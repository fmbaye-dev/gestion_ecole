// lib/repositories/firebase_service.dart
// MODIFIÉ : streamAbsencesFiltrees avec filtre type (absence|retard)

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
  // HELPER
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _supprimerDocs(QuerySnapshot snap) async {
    for (final doc in snap.docs) await doc.reference.delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH & CRÉATION UTILISATEUR
  // ══════════════════════════════════════════════════════════════════════════
  Future<UserModel> createUser({
    required String nomComplet,
    required String email,
    required String motPasse,
    required String adresse,
    required String telephone,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: motPasse,
    );
    final uid = credential.user?.uid;
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
  }

  Future<void> modifierEleve(String id, Map<String, dynamic> data) {
    data['dateModification'] = FieldValue.serverTimestamp();
    return _utilisateurs.doc(id).update(data);
  }

  Future<void> supprimerEleve(String id) async {
    final notes = await _notes.where('idEleve', isEqualTo: id).get();
    await _supprimerDocs(notes);
    final absences = await _absences.where('idEleve', isEqualTo: id).get();
    await _supprimerDocs(absences);
    await _utilisateurs.doc(id).delete();
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
  }

  Future<void> modifierEnseignant(String id, Map<String, dynamic> data) async {
    data['dateModification'] = FieldValue.serverTimestamp();
    await _utilisateurs.doc(id).update(data);
    if (data.containsKey('nomComplet')) {
      final snap = await _enseignements
          .where('idEnseignant', isEqualTo: id)
          .get();
      for (final doc in snap.docs)
        await doc.reference.update({'nomEnseignant': data['nomComplet']});
    }
  }

  Future<void> supprimerEnseignant(String id) async {
    final ens = await _enseignements.where('idEnseignant', isEqualTo: id).get();
    await _supprimerDocs(ens);
    final notes = await _notes.where('idEnseignant', isEqualTo: id).get();
    await _supprimerDocs(notes);
    final abs = await _absences.where('idEnseignant', isEqualTo: id).get();
    await _supprimerDocs(abs);
    await _utilisateurs.doc(id).delete();
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
    return doc.id;
  }

  Future<void> modifierClasse(String id, String nouveauNom) async {
    await _classes.doc(id).update({'nomClasse': nouveauNom});
    final ensSnap = await _enseignements.where('idClasse', isEqualTo: id).get();
    for (final doc in ensSnap.docs)
      await doc.reference.update({'nomClasse': nouveauNom});
    final etuSnap = await _utilisateurs
        .where('role', isEqualTo: 'eleve')
        .where('idClasse', isEqualTo: id)
        .get();
    for (final doc in etuSnap.docs)
      await doc.reference.update({'nomClasse': nouveauNom});
  }

  Future<void> supprimerClasse(String id) async {
    final ens = await _enseignements.where('idClasse', isEqualTo: id).get();
    await _supprimerDocs(ens);
    final eleves = await _utilisateurs
        .where('role', isEqualTo: 'eleve')
        .where('idClasse', isEqualTo: id)
        .get();
    for (final doc in eleves.docs)
      await doc.reference.update({'idClasse': '', 'nomClasse': ''});
    await _classes.doc(id).delete();
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
    return doc.id;
  }

  Future<void> modifierEnseignement(String id, Map<String, dynamic> data) =>
      _enseignements.doc(id).update(data);

  Future<void> supprimerEnseignement(String id) =>
      _enseignements.doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // MATIÈRES
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> supprimerMatiere(String id, String nomMatiere) async {
    final ens = await _enseignements
        .where('matiere', isEqualTo: nomMatiere)
        .get();
    await _supprimerDocs(ens);
    final notes = await _notes.where('matiere', isEqualTo: nomMatiere).get();
    await _supprimerDocs(notes);
    final abs = await _absences.where('matiere', isEqualTo: nomMatiere).get();
    await _supprimerDocs(abs);
    await _matieres.doc(id).delete();
  }

  Future<void> modifierMatiere(
    String id,
    String ancienNom,
    String nouveauNom,
  ) async {
    await _matieres.doc(id).update({'nom': nouveauNom});
    for (final snap in [
      await _enseignements.where('matiere', isEqualTo: ancienNom).get(),
      await _notes.where('matiere', isEqualTo: ancienNom).get(),
      await _absences.where('matiere', isEqualTo: ancienNom).get(),
    ]) {
      for (final doc in snap.docs)
        await doc.reference.update({'matiere': nouveauNom});
    }
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
    String? semestre,
  }) {
    Query q = _notes;
    if (idEleve != null) q = q.where('idEleve', isEqualTo: idEleve);
    if (matiere != null) q = q.where('matiere', isEqualTo: matiere);
    if (idEnseignant != null)
      q = q.where('idEnseignant', isEqualTo: idEnseignant);
    if (semestre != null) q = q.where('semestre', isEqualTo: semestre);
    return q.snapshots();
  }

  Future<String> ajouterNote(Map<String, dynamic> data) async {
    data['dateCreation'] = FieldValue.serverTimestamp();
    final doc = await _notes.add(data);
    return doc.id;
  }

  Future<void> modifierNote(String id, Map<String, dynamic> data) {
    data['dateModification'] = FieldValue.serverTimestamp();
    return _notes.doc(id).update(data);
  }

  Future<void> supprimerNote(String id) => _notes.doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // ABSENCES — MODIFIÉ : filtre type
  // ══════════════════════════════════════════════════════════════════════════
  Stream<QuerySnapshot> streamAbsences() => _absences.snapshots();

  Stream<QuerySnapshot> streamAbsencesEleve(String idEleve) =>
      _absences.where('idEleve', isEqualTo: idEleve).snapshots();

  Stream<QuerySnapshot> streamAbsencesEnseignant(String idEnseignant) =>
      _absences.where('idEnseignant', isEqualTo: idEnseignant).snapshots();

  /// Stream avec filtres combinés : type + classe (via idEleves) + matière + date
  Stream<QuerySnapshot> streamAbsencesFiltrees({
    String? idEleve,
    String? type, // 'absence' | 'retard' | null = tous
    String? matiere,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) {
    Query q = _absences;
    if (idEleve != null) q = q.where('idEleve', isEqualTo: idEleve);
    if (type != null) q = q.where('type', isEqualTo: type);
    if (matiere != null) q = q.where('matiere', isEqualTo: matiere);
    if (dateDebut != null)
      q = q.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut),
      );
    if (dateFin != null)
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateFin));
    return q.snapshots();
  }

  Future<String> ajouterAbsence(Map<String, dynamic> data) async {
    data['dateCreation'] = FieldValue.serverTimestamp();
    final doc = await _absences.add(data);
    return doc.id;
  }

  Future<void> modifierAbsence(String id, Map<String, dynamic> data) {
    data['dateModification'] = FieldValue.serverTimestamp();
    return _absences.doc(id).update(data);
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
