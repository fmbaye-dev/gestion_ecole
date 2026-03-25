// lib/view_model/note_view_model.dart

import 'package:flutter/material.dart';
import 'package:gestion_ecole/models/note_model.dart';
import 'package:gestion_ecole/repositories/firebase_service.dart';

class NoteViewModel extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  bool _isLoading = false;
  String? _erreur;

  bool get isLoading => _isLoading;
  String? get erreur => _erreur;

  // ── Toutes les notes (admin) ───────────────────────────────────────────
  Stream<List<NoteModel>> get streamNotes => _service.streamNotes().map(
    (s) => s.docs.map((d) => NoteModel.fromFirestore(d)).toList()
      ..sort((a, b) {
        final cmp = a.matiere.compareTo(b.matiere);
        return cmp != 0 ? cmp : a.nomEleve.compareTo(b.nomEleve);
      }),
  );

  // ── Notes d'un élève ────────────────────────────────────────────────────
  Stream<List<NoteModel>> streamEleve(String idEleve) => _service
      .streamNotesEleve(idEleve)
      .map(
        (s) =>
            s.docs.map((d) => NoteModel.fromFirestore(d)).toList()
              ..sort((a, b) => a.matiere.compareTo(b.matiere)),
      );

  // ── Notes saisies par un enseignant ──────────────────────────────────────
  Stream<List<NoteModel>> streamEnseignant(String idEnseignant) => _service
      .streamNotesEnseignant(idEnseignant)
      .map(
        (s) =>
            s.docs.map((d) => NoteModel.fromFirestore(d)).toList()
              ..sort((a, b) => a.matiere.compareTo(b.matiere)),
      );

  // ── Notes filtrées ────────────────────────────────────────────────────────
  Stream<List<NoteModel>> streamFiltrees({
    String? idEleve,
    String? matiere,
    String? idEnseignant,
    String? semestre,
  }) => _service
      .streamNotesFiltrees(
        idEleve: idEleve,
        matiere: matiere,
        idEnseignant: idEnseignant,
        semestre: semestre,
      )
      .map(
        (s) =>
            s.docs.map((d) => NoteModel.fromFirestore(d)).toList()
              ..sort((a, b) {
                final cmp = a.matiere.compareTo(b.matiere);
                return cmp != 0 ? cmp : a.nomEleve.compareTo(b.nomEleve);
              }),
      );

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<bool> ajouter(NoteModel note) async {
    _setLoading(true);
    try {
      await _service.ajouterNote(note.toMap());
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> modifier(String id, NoteModel note) async {
    _setLoading(true);
    try {
      await _service.modifierNote(id, note.toMap());
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
      await _service.supprimerNote(id);
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
