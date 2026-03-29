// lib/views/page_notes.dart
// Admin      → toutes les notes, filtre classe + matière + semestre (lecture)
// Enseignant → ses notes, filtre classe (ses classes) + matière + semestre, saisir/modifier/supprimer
// Élève      → ses notes, filtre matière + semestre (lecture)
//
// Règles métier :
//   - 2 devoirs (D1, D2) + 1 composition (Compo) par semestre
//   - Coefficient par matière/classe (collection 'coefficient')
//   - Un élève ne peut avoir qu'UNE seule note par matière+semestre

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/models/note_model.dart';
import 'package:gestion_ecole/view_model/note_view_model.dart';
import 'package:gestion_ecole/view_model/classe_view_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// PAGE NOTES
// ════════════════════════════════════════════════════════════════════════════
class PageNotes extends StatefulWidget {
  const PageNotes({super.key});
  @override
  State<PageNotes> createState() => _PageNotesState();
}

class _PageNotesState extends State<PageNotes> {
  String? _role, _uid;
  bool _roleCharge = false;
  String? _filtreIdClasse, _filtreNomClasse, _filtreMatiere;
  String? _filtreSemestre; // null = tous, 'S1', 'S2'
  List<String> _idElevesClasse = [];

  @override
  void initState() {
    super.initState();
    _chargerRole();
  }

  Future<void> _chargerRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _uid = user.uid;
    final doc = await FirebaseFirestore.instance
        .collection('utilisateur')
        .doc(user.uid)
        .get();
    if (mounted)
      setState(() {
        _role = doc.data()?['role'] ?? '';
        _roleCharge = true;
      });
  }

  Future<void> _onClasseChanged(String? idClasse, String? nomClasse) async {
    setState(() {
      _filtreIdClasse = idClasse;
      _filtreNomClasse = nomClasse;
      _filtreMatiere = null;
      _idElevesClasse = [];
    });
    if (idClasse == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('utilisateur')
        .where('role', isEqualTo: 'eleve')
        .where('idClasse', isEqualTo: idClasse)
        .get();
    if (mounted)
      setState(() => _idElevesClasse = snap.docs.map((d) => d.id).toList());
  }

  Future<void> _deconnexion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Déconnecter',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted)
        Navigator.pushReplacementNamed(context, Routeur.routeInitial);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_roleCharge) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Center(child: CircularProgressIndicator(color: scheme.primary)),
      );
    }
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Notes'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      drawer: _DrawerRole(role: _role ?? 'eleve', onDeconnexion: _deconnexion),
      body: Column(
        children: [
          _buildFiltres(),
          Expanded(child: _buildListe()),
        ],
      ),
      floatingActionButton: _role == 'enseignant'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormulaireNote(idEnseignant: _uid!),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Saisir une note'),
            )
          : null,
    );
  }

  // ── Filtres ──────────────────────────────────────────────────────────────
  Widget _buildFiltres() {
    final scheme = Theme.of(context).colorScheme;
    final cvm = context.watch<ClasseViewModel>();

    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        children: [
          Row(
            children: [
              if (_role != 'eleve') ...[
                Expanded(
                  child: _role == 'enseignant'
                      ? _DropdownClasseEnseignant(
                          idEnseignant: _uid!,
                          value: _filtreIdClasse,
                          onChanged: _onClasseChanged,
                        )
                      : _DropdownFiltre(
                          hint: 'Toutes les classes',
                          value: _filtreIdClasse,
                          actif: _filtreIdClasse != null,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'Toutes les classes',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            ...cvm.classes.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.nomClasse,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            final nom = val == null
                                ? null
                                : cvm.classes
                                      .firstWhere((c) => c.id == val)
                                      .nomClasse;
                            _onClasseChanged(val, nom);
                          },
                        ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _role == 'enseignant'
                    ? _DropdownMatiereEnseignant(
                        idEnseignant: _uid!,
                        idClasse: _filtreIdClasse,
                        filtreActuel: _filtreMatiere,
                        onChanged: (m) => setState(() => _filtreMatiere = m),
                      )
                    : _DropdownFiltreMatiere(
                        uid: _uid!,
                        role: _role!,
                        filtreActuel: _filtreMatiere,
                        onChanged: (m) => setState(() => _filtreMatiere = m),
                      ),
              ),
              if (_filtreIdClasse != null ||
                  _filtreMatiere != null ||
                  _filtreSemestre != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 20,
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () => setState(() {
                      _filtreIdClasse = null;
                      _filtreNomClasse = null;
                      _filtreMatiere = null;
                      _filtreSemestre = null;
                      _idElevesClasse = [];
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ChipFiltre(
                'Tous',
                null,
                _filtreSemestre == null,
                () => setState(() => _filtreSemestre = null),
                scheme.primary,
              ),
              const SizedBox(width: 8),
              _ChipFiltre(
                'Semestre 1',
                'S1',
                _filtreSemestre == 'S1',
                () => setState(() => _filtreSemestre = 'S1'),
                const Color(0xFF2A8A5C),
              ),
              const SizedBox(width: 8),
              _ChipFiltre(
                'Semestre 2',
                'S2',
                _filtreSemestre == 'S2',
                () => setState(() => _filtreSemestre = 'S2'),
                const Color(0xFF7B3FA0),
              ),
            ],
          ),
          if (_filtreNomClasse != null || _filtreMatiere != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_rounded,
                    size: 14,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    [
                      if (_filtreNomClasse != null) _filtreNomClasse!,
                      if (_filtreMatiere != null) _filtreMatiere!,
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Liste ────────────────────────────────────────────────────────────────
  Widget _buildListe() {
    final vm = context.watch<NoteViewModel>();
    final scheme = Theme.of(context).colorScheme;

    Stream<List<NoteModel>> stream;
    if (_role == 'eleve') {
      stream = vm.streamFiltrees(
        idEleve: _uid,
        matiere: _filtreMatiere,
        semestre: _filtreSemestre,
      );
    } else if (_role == 'enseignant') {
      stream = vm
          .streamEnseignant(_uid!)
          .map(
            (list) => list.where((n) {
              if (_filtreSemestre != null && n.semestre != _filtreSemestre)
                return false;
              if (_filtreMatiere != null && n.matiere != _filtreMatiere)
                return false;
              if (_filtreIdClasse != null &&
                  _idElevesClasse.isNotEmpty &&
                  !_idElevesClasse.contains(n.idEleve))
                return false;
              return true;
            }).toList(),
          );
    } else {
      stream = vm
          .streamFiltrees(matiere: _filtreMatiere, semestre: _filtreSemestre)
          .map((list) {
            if (_filtreIdClasse != null && _idElevesClasse.isNotEmpty)
              return list
                  .where((n) => _idElevesClasse.contains(n.idEleve))
                  .toList();
            return list;
          });
    }

    return StreamBuilder<List<NoteModel>>(
      stream: stream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Center(
            child: CircularProgressIndicator(color: scheme.primary),
          );
        final list = snap.data ?? [];
        if (list.isEmpty)
          return _vide(
            context,
            Icons.star_border_rounded,
            'Aucune note trouvée',
            scheme.onSurface.withOpacity(0.3),
          );
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: list.length,
          itemBuilder: (_, i) => _NoteCard(
            note: list[i],
            peutModifier: _role == 'enseignant' && list[i].idEnseignant == _uid,
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CARD NOTE — 2 devoirs + 1 compo
// ════════════════════════════════════════════════════════════════════════════
class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final bool peutModifier;
  const _NoteCard({required this.note, required this.peutModifier});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.read<NoteViewModel>();
    final moy = note.moyenneMatiere;
    final color = note.mentionColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.nomEleve,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _Badge(note.matiere, const Color(0xFF7B3FA0)),
                          const SizedBox(width: 6),
                          _Badge(
                            note.semestre == 'S1' ? 'Semestre 1' : 'Semestre 2',
                            const Color(0xFF1A3A8F),
                          ),
                          const SizedBox(width: 6),
                          _Badge(
                            'Coeff. ${NoteModel.fmt(note.coefficient)}',
                            const Color(0xFFC0692A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Moyenne
                if (moy != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          NoteModel.fmt(moy),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '/20',
                          style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (peutModifier) ...[
                  IconButton(
                    tooltip: 'Modifier',
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormulaireNote(
                          note: note,
                          idEnseignant: note.idEnseignant,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: Icon(
                      Icons.delete_rounded,
                      size: 20,
                      color: scheme.error,
                    ),
                    onPressed: () => _confirmerSuppression(context, vm),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.4)),
            const SizedBox(height: 10),

            // ── Sous-notes : D1, D2, Compo ─────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (note.devoir1 != null)
                  _SubNote('D1', note.devoir1!, const Color(0xFF1A6A9A)),
                if (note.devoir2 != null)
                  _SubNote('D2', note.devoir2!, const Color(0xFF1A6A9A)),
                if (note.compo != null)
                  _SubNote('Compo', note.compo!, const Color(0xFF7B3FA0)),
              ],
            ),

            // Moyennes partielles
            if (note.moyenneDevoirs != null || note.compo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (note.moyenneDevoirs != null) ...[
                    Text(
                      'Moy. Devoirs : ',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      NoteModel.fmt(note.moyenneDevoirs),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A6A9A),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (note.compo != null) ...[
                    Text(
                      'Compo : ',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      NoteModel.fmt(note.compo),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B3FA0),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            if (moy != null) ...[
              const SizedBox(height: 4),
              Text(
                note.mention,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, NoteViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la note ?'),
        content: Text(
          'La note de ${note.nomEleve} en ${note.matiere} sera supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.supprimer(note.id!);
              if (context.mounted)
                _snack(
                  context,
                  ok ? 'Note supprimée' : vm.erreur ?? 'Erreur',
                  ok ? scheme.error : Colors.orange,
                );
            },
            child: Text('Supprimer', style: TextStyle(color: scheme.onError)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FORMULAIRE NOTE
// Règles :
//   - 2 devoirs (D1, D2) + 1 composition
//   - Coefficient par matière/classe chargé depuis Firestore
//   - Vérification unicité : un élève ne peut avoir qu'une note par matière+semestre
// ════════════════════════════════════════════════════════════════════════════
class FormulaireNote extends StatefulWidget {
  final NoteModel? note;
  final String idEnseignant;
  const FormulaireNote({super.key, this.note, required this.idEnseignant});
  @override
  State<FormulaireNote> createState() => _FormulaireNoteState();
}

class _FormulaireNoteState extends State<FormulaireNote> {
  final _fk = GlobalKey<FormState>();

  final _d1 = TextEditingController();
  final _d2 = TextEditingController();
  final _compo = TextEditingController();

  String _semestre = 'S1';
  String? _idClasseFiltre, _idEtu, _nomEtu, _matiere;
  double _coefficient = 1.0;
  List<Map<String, dynamic>> _eleves = [];
  List<Map<String, String>> _classesEnseignant = [];
  List<String> _matieresEnseignant = [];

  // IDs des notes déjà existantes pour l'élève sélectionné (matiere+semestre)
  Set<String> _notesExistantes = {};
  bool _chargementCoeff = false;

  bool get _estModif => widget.note != null;

  @override
  void initState() {
    super.initState();
    if (_estModif) {
      final n = widget.note!;
      _semestre = n.semestre;
      _idEtu = n.idEleve;
      _nomEtu = n.nomEleve;
      _matiere = n.matiere;
      _coefficient = n.coefficient;
      if (n.devoir1 != null) _d1.text = NoteModel.fmt(n.devoir1);
      if (n.devoir2 != null) _d2.text = NoteModel.fmt(n.devoir2);
      if (n.compo != null) _compo.text = NoteModel.fmt(n.compo);
    }
    _chargerDonneesEnseignant();
  }

  @override
  void dispose() {
    for (final c in [_d1, _d2, _compo]) c.dispose();
    super.dispose();
  }

  double? _parse(String v) {
    if (v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    return (n != null && n >= 0 && n <= 20) ? n : null;
  }

  String? _validateNote(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n < 0 || n > 20) return 'Entre 0 et 20';
    return null;
  }

  Future<void> _chargerDonneesEnseignant() async {
    final snap = await FirebaseFirestore.instance
        .collection('enseignement')
        .where('idEnseignant', isEqualTo: widget.idEnseignant)
        .get();
    final Map<String, String> cls = {};
    final Set<String> mats = {};
    for (final doc in snap.docs) {
      final d = doc.data();
      final id = d['idClasse'] as String? ?? '';
      final nm = d['nomClasse'] as String? ?? '';
      final mt = d['matiere'] as String? ?? '';
      if (id.isNotEmpty) cls[id] = nm;
      if (mt.isNotEmpty) mats.add(mt);
    }
    if (mounted)
      setState(() {
        _classesEnseignant =
            cls.entries.map((e) => {'id': e.key, 'nom': e.value}).toList()
              ..sort((a, b) => a['nom']!.compareTo(b['nom']!));
        _matieresEnseignant = mats.toList()..sort();
      });
  }

  Future<void> _chargerMatieresParClasse(String idClasse) async {
    final snap = await FirebaseFirestore.instance
        .collection('enseignement')
        .where('idEnseignant', isEqualTo: widget.idEnseignant)
        .where('idClasse', isEqualTo: idClasse)
        .get();
    final mats = <String>{};
    for (final doc in snap.docs) {
      final m = doc.data()['matiere'] as String? ?? '';
      if (m.isNotEmpty) mats.add(m);
    }
    if (mounted)
      setState(() {
        _matieresEnseignant = mats.toList()..sort();
        if (_matiere != null && !_matieresEnseignant.contains(_matiere))
          _matiere = null;
      });
  }

  Future<void> _chargerEleves(String idClasse) async {
    final snap = await FirebaseFirestore.instance
        .collection('utilisateur')
        .where('role', isEqualTo: 'eleve')
        .where('idClasse', isEqualTo: idClasse)
        .get();
    if (mounted)
      setState(() {
        _eleves = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _idEtu = null;
        _nomEtu = null;
        _notesExistantes = {};
      });
  }

  /// Charge les notes déjà saisies pour cet élève → pour bloquer les doublons
  Future<void> _chargerNotesExistantes(String idEleve) async {
    final snap = await FirebaseFirestore.instance
        .collection('note')
        .where('idEleve', isEqualTo: idEleve)
        .get();
    if (mounted) {
      setState(() {
        // Clé = "matiere|semestre"
        _notesExistantes = snap.docs
            .map((d) {
              final data = d.data();
              // Exclure la note en cours de modification
              if (_estModif && d.id == widget.note!.id) return '';
              return '${data['matiere']}|${data['semestre']}';
            })
            .where((k) => k.isNotEmpty)
            .toSet();
      });
    }
  }

  /// Charge le coefficient de la matière pour la classe sélectionnée
  Future<void> _chargerCoefficient(String idClasse, String matiere) async {
    setState(() => _chargementCoeff = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('coefficient')
          .where('idClasse', isEqualTo: idClasse)
          .where('matiere', isEqualTo: matiere)
          .limit(1)
          .get();
      if (mounted) {
        setState(() {
          _coefficient = snap.docs.isEmpty
              ? 1.0
              : (snap.docs.first.data()['valeur'] as num?)?.toDouble() ?? 1.0;
        });
      }
    } finally {
      if (mounted) setState(() => _chargementCoeff = false);
    }
  }

  bool _noteDejaExistante() {
    if (_idEtu == null || _matiere == null) return false;
    return _notesExistantes.contains('$_matiere|$_semestre');
  }

  Future<void> _enregistrer() async {
    if (!_fk.currentState!.validate()) return;
    if (!_estModif && _idEtu == null) {
      _snack(context, 'Sélectionnez un élève', Colors.orange);
      return;
    }
    if (!_estModif && _matiere == null) {
      _snack(context, 'Sélectionnez une matière', Colors.orange);
      return;
    }
    if (!_estModif && _noteDejaExistante()) {
      _snack(
        context,
        'Cet élève a déjà une note en $_matiere pour le $_semestre.\nModifiez la note existante.',
        Colors.orange,
      );
      return;
    }

    final vm = context.read<NoteViewModel>();
    final note = NoteModel(
      idEleve: _idEtu!,
      nomEleve: _nomEtu!,
      matiere: _matiere!,
      idEnseignant: widget.idEnseignant,
      semestre: _semestre,
      devoir1: _parse(_d1.text),
      devoir2: _parse(_d2.text),
      compo: _parse(_compo.text),
      coefficient: _coefficient,
    );

    final ok = _estModif
        ? await vm.modifier(widget.note!.id!, note)
        : await vm.ajouter(note);

    if (mounted) {
      _snack(
        context,
        ok
            ? (_estModif ? 'Note modifiée ✓' : 'Note ajoutée ✓')
            : vm.erreur ?? 'Erreur',
        ok ? Colors.green : Colors.red,
      );
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.watch<NoteViewModel>();
    final noteBloquee = !_estModif && _noteDejaExistante();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(_estModif ? 'Modifier la note' : 'Saisir une note'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      body: Form(
        key: _fk,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Semestre ────────────────────────────────────────────────
              _SectionTitre('Semestre', Icons.calendar_today_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SemestreBtn(
                      'Semestre 1',
                      'S1',
                      _semestre == 'S1',
                      scheme,
                      () => setState(() {
                        _semestre = 'S1';
                        if (_idEtu != null) _chargerNotesExistantes(_idEtu!);
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SemestreBtn(
                      'Semestre 2',
                      'S2',
                      _semestre == 'S2',
                      scheme,
                      () => setState(() {
                        _semestre = 'S2';
                        if (_idEtu != null) _chargerNotesExistantes(_idEtu!);
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Classe (seulement en création) ──────────────────────────
              if (!_estModif) ...[
                _SectionTitre('Classe', Icons.class_rounded),
                const SizedBox(height: 12),
                _classesEnseignant.isEmpty
                    ? _InfoBox(
                        'Aucune classe assignée',
                        Icons.warning_amber_rounded,
                        scheme,
                        color: Colors.orange,
                      )
                    : DropdownButtonFormField<String>(
                        value:
                            _classesEnseignant.any(
                              (c) => c['id'] == _idClasseFiltre,
                            )
                            ? _idClasseFiltre
                            : null,
                        decoration: _deco(
                          'Classe',
                          Icons.class_rounded,
                          scheme,
                        ),
                        items: _classesEnseignant
                            .map(
                              (c) => DropdownMenuItem(
                                value: c['id'],
                                child: Text(c['nom'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _idClasseFiltre = val;
                            _eleves = [];
                            _idEtu = null;
                            _matiere = null;
                            _coefficient = 1.0;
                            _notesExistantes = {};
                          });
                          if (val != null) {
                            _chargerEleves(val);
                            _chargerMatieresParClasse(val);
                          }
                        },
                      ),
                const SizedBox(height: 16),

                // ── Élève ─────────────────────────────────────────────────
                _SectionTitre('Élève', Icons.school_rounded),
                const SizedBox(height: 12),
                _idClasseFiltre == null
                    ? _InfoBox(
                        'Sélectionnez d\'abord une classe',
                        Icons.info_outline_rounded,
                        scheme,
                        muted: true,
                      )
                    : _eleves.isEmpty
                    ? _InfoBox(
                        'Aucun élève dans cette classe',
                        Icons.warning_amber_rounded,
                        scheme,
                        color: Colors.orange,
                      )
                    : DropdownButtonFormField<String>(
                        value: _eleves.any((e) => e['id'] == _idEtu)
                            ? _idEtu
                            : null,
                        decoration: _deco(
                          'Sélectionner un élève',
                          Icons.person_rounded,
                          scheme,
                        ),
                        items: _eleves
                            .map(
                              (e) => DropdownMenuItem(
                                value: e['id'] as String,
                                child: Text(e['nomComplet'] as String? ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (val) async {
                          setState(() {
                            _idEtu = val;
                            _nomEtu =
                                _eleves.firstWhere(
                                      (e) => e['id'] == val,
                                    )['nomComplet']
                                    as String?;
                          });
                          if (val != null) await _chargerNotesExistantes(val);
                        },
                      ),
                const SizedBox(height: 16),

                // ── Matière ───────────────────────────────────────────────
                _SectionTitre('Matière', Icons.book_rounded),
                const SizedBox(height: 12),
                _matieresEnseignant.isEmpty
                    ? _InfoBox(
                        _idClasseFiltre == null
                            ? 'Sélectionnez d\'abord une classe'
                            : 'Aucune matière pour cette classe',
                        Icons.info_outline_rounded,
                        scheme,
                        muted: true,
                      )
                    : DropdownButtonFormField<String>(
                        value: _matieresEnseignant.contains(_matiere)
                            ? _matiere
                            : null,
                        decoration: _deco(
                          'Sélectionner une matière',
                          Icons.book_rounded,
                          scheme,
                        ),
                        items: _matieresEnseignant.map((m) {
                          final deja =
                              _idEtu != null &&
                              _notesExistantes.contains('$m|$_semestre');
                          return DropdownMenuItem(
                            value: m,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    m,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (deja) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Déjà noté',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          setState(() => _matiere = val);
                          if (val != null && _idClasseFiltre != null)
                            await _chargerCoefficient(_idClasseFiltre!, val);
                        },
                      ),
                const SizedBox(height: 16),

                // ── Alerte doublon ────────────────────────────────────────
                if (noteBloquee)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Cet élève a déjà une note pour cette matière et ce semestre. Veuillez modifier la note existante.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!noteBloquee) const SizedBox(height: 0),
              ] else ...[
                _InfoBox(_nomEtu ?? '', Icons.person_rounded, scheme),
                const SizedBox(height: 10),
                _InfoBox(_matiere ?? '', Icons.book_rounded, scheme),
                const SizedBox(height: 16),
              ],

              // ── Coefficient ──────────────────────────────────────────────
              if (!noteBloquee) ...[
                _SectionTitre(
                  'Coefficient de la matière',
                  Icons.calculate_rounded,
                  color: const Color(0xFFC0692A),
                ),
                const SizedBox(height: 12),
                _estModif
                    ? _InfoBox(
                        'Coefficient : ${NoteModel.fmt(_coefficient)}',
                        Icons.calculate_rounded,
                        scheme,
                      )
                    : _chargementCoeff
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _CoefficientSelector(
                        valeur: _coefficient,
                        onChanged: _estModif
                            ? null
                            : (v) => setState(() => _coefficient = v),
                      ),
                const SizedBox(height: 20),

                // ── Devoirs ──────────────────────────────────────────────
                _SectionTitre(
                  'Devoirs',
                  Icons.edit_document,
                  color: const Color(0xFF1A6A9A),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NoteField(
                        ctrl: _d1,
                        label: 'Devoir 1',
                        validator: _validateNote,
                        color: const Color(0xFF1A6A9A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NoteField(
                        ctrl: _d2,
                        label: 'Devoir 2',
                        validator: _validateNote,
                        color: const Color(0xFF1A6A9A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Composition ──────────────────────────────────────────
                _SectionTitre(
                  'Composition',
                  Icons.article_rounded,
                  color: const Color(0xFF7B3FA0),
                ),
                const SizedBox(height: 12),
                _NoteField(
                  ctrl: _compo,
                  label: 'Composition',
                  validator: _validateNote,
                  color: const Color(0xFF7B3FA0),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: vm.isLoading ? null : _enregistrer,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: vm.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _estModif
                                ? 'Enregistrer les modifications'
                                : 'Enregistrer la note',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SÉLECTEUR DE COEFFICIENT
// ════════════════════════════════════════════════════════════════════════════
class _CoefficientSelector extends StatelessWidget {
  final double valeur;
  final void Function(double)? onChanged;
  const _CoefficientSelector({required this.valeur, required this.onChanged});

  static const _valeurs = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final couleur = const Color(0xFFC0692A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _valeurs.map((v) {
            final selected = (v - valeur).abs() < 0.01;
            return GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? couleur : couleur.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: couleur.withOpacity(selected ? 0 : 0.3),
                  ),
                ),
                child: Text(
                  'Coeff. ${NoteModel.fmt(v)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : couleur,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          'Coefficient actuel : ${NoteModel.fmt(valeur)}',
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DROPDOWNS
// ════════════════════════════════════════════════════════════════════════════
class _DropdownFiltre extends StatelessWidget {
  final String hint;
  final String? value;
  final bool actif;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?) onChanged;
  const _DropdownFiltre({
    required this.hint,
    required this.value,
    required this.actif,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: actif
                ? scheme.primary.withOpacity(0.5)
                : scheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withOpacity(0.5),
            ),
          ),
          style: TextStyle(fontSize: 13, color: scheme.onSurface),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DropdownFiltreMatiere extends StatelessWidget {
  final String uid, role;
  final String? filtreActuel;
  final void Function(String?) onChanged;
  const _DropdownFiltreMatiere({
    required this.uid,
    required this.role,
    required this.filtreActuel,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stream = role == 'eleve'
        ? FirebaseFirestore.instance
              .collection('note')
              .where('idEleve', isEqualTo: uid)
              .snapshots()
        : FirebaseFirestore.instance
              .collection('matiere')
              .orderBy('nom')
              .snapshots();
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (_, snap) {
        final mats = <String>{};
        if (snap.hasData)
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final m = (role == 'eleve' ? d['matiere'] : d['nom']) as String?;
            if (m != null && m.isNotEmpty) mats.add(m);
          }
        final list = mats.toList()..sort();
        return DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: filtreActuel != null
                    ? scheme.primary.withOpacity(0.5)
                    : scheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: DropdownButton<String>(
              value: list.contains(filtreActuel) ? filtreActuel : null,
              isExpanded: true,
              hint: Text(
                'Toutes les matières',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Toutes les matières',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                ...list.map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

class _DropdownClasseEnseignant extends StatelessWidget {
  final String idEnseignant;
  final String? value;
  final void Function(String? id, String? nom) onChanged;
  const _DropdownClasseEnseignant({
    required this.idEnseignant,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enseignement')
          .where('idEnseignant', isEqualTo: idEnseignant)
          .snapshots(),
      builder: (_, snap) {
        final Map<String, String> cls = {};
        if (snap.hasData)
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final id = d['idClasse'] as String? ?? '';
            final nm = d['nomClasse'] as String? ?? '';
            if (id.isNotEmpty) cls[id] = nm;
          }
        final entries = cls.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        return DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: value != null
                    ? scheme.primary.withOpacity(0.5)
                    : scheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: DropdownButton<String>(
              value: cls.containsKey(value) ? value : null,
              isExpanded: true,
              hint: Text(
                'Mes classes',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Mes classes',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                ...entries.map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              onChanged: (val) => onChanged(val, val == null ? null : cls[val]),
            ),
          ),
        );
      },
    );
  }
}

class _DropdownMatiereEnseignant extends StatelessWidget {
  final String idEnseignant;
  final String? idClasse, filtreActuel;
  final void Function(String?) onChanged;
  const _DropdownMatiereEnseignant({
    required this.idEnseignant,
    required this.idClasse,
    required this.filtreActuel,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Query q = FirebaseFirestore.instance
        .collection('enseignement')
        .where('idEnseignant', isEqualTo: idEnseignant);
    if (idClasse != null) q = q.where('idClasse', isEqualTo: idClasse);
    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (_, snap) {
        final mats = <String>{};
        if (snap.hasData)
          for (final doc in snap.data!.docs) {
            final m =
                (doc.data() as Map<String, dynamic>)['matiere'] as String?;
            if (m != null && m.isNotEmpty) mats.add(m);
          }
        final list = mats.toList()..sort();
        return DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: filtreActuel != null
                    ? scheme.primary.withOpacity(0.5)
                    : scheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: DropdownButton<String>(
              value: list.contains(filtreActuel) ? filtreActuel : null,
              isExpanded: true,
              hint: Text(
                'Mes matières',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Mes matières',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                ...list.map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DRAWER
// ════════════════════════════════════════════════════════════════════════════
class _DrawerRole extends StatelessWidget {
  final String role;
  final VoidCallback onDeconnexion;
  const _DrawerRole({required this.role, required this.onDeconnexion});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    IconData icone;
    String titre;
    List<Widget> items;

    switch (role) {
      case 'admin':
        icone = Icons.admin_panel_settings_rounded;
        titre = 'Administrateur';
        items = [
          _DItem(
            Icons.dashboard_rounded,
            'Tableau de bord',
            Routeur.routeAccueil,
            false,
          ),
          const _DLabel('GESTION'),
          _DItem(Icons.school_rounded, 'Élèves', Routeur.routeEleves, false),
          _DItem(
            Icons.person_rounded,
            'Enseignants',
            Routeur.routeEnseignants,
            false,
          ),
          _DItem(Icons.class_rounded, 'Classes', Routeur.routeClasses, false),
          _DItem(Icons.book_rounded, 'Matières', Routeur.routeMatieres, false),
          const _DLabel('ACADÉMIQUE'),
          _DItem(Icons.star_rounded, 'Notes', Routeur.routeNotes, true),
          _DItem(
            Icons.event_busy_rounded,
            'Absences',
            Routeur.routeAbsences,
            false,
          ),
          _DItem(
            Icons.description_rounded,
            'Bulletins',
            Routeur.routeBulletin,
            false,
          ),
          Divider(height: 20, color: scheme.outlineVariant.withOpacity(0.4)),
          _DItem(
            Icons.person_outline_rounded,
            'Mon Profil',
            Routeur.routeProfil,
            false,
          ),
        ];
        break;
      case 'enseignant':
        icone = Icons.school_rounded;
        titre = 'Enseignant';
        items = [
          _DItem(
            Icons.dashboard_rounded,
            'Tableau de bord',
            Routeur.routeAccueilEnseignant,
            false,
          ),
          const _DLabel('ACADÉMIQUE'),
          _DItem(Icons.star_rounded, 'Notes', Routeur.routeNotes, true),
          _DItem(
            Icons.event_busy_rounded,
            'Absences',
            Routeur.routeAbsences,
            false,
          ),
          _DItem(
            Icons.description_rounded,
            'Bulletins',
            Routeur.routeBulletin,
            false,
          ),
          Divider(height: 20, color: scheme.outlineVariant.withOpacity(0.4)),
          _DItem(
            Icons.person_outline_rounded,
            'Mon Profil',
            Routeur.routeProfil,
            false,
          ),
        ];
        break;
      default:
        icone = Icons.person_rounded;
        titre = 'Élève';
        items = [
          _DItem(
            Icons.dashboard_rounded,
            'Tableau de bord',
            Routeur.routeAccueilEleve,
            false,
          ),
          const _DLabel('MES DONNÉES'),
          _DItem(Icons.star_rounded, 'Mes Notes', Routeur.routeNotes, true),
          _DItem(
            Icons.event_busy_rounded,
            'Mes Absences',
            Routeur.routeAbsences,
            false,
          ),
          _DItem(
            Icons.description_rounded,
            'Mon Bulletin',
            Routeur.routeBulletin,
            false,
          ),
          Divider(height: 20, color: scheme.outlineVariant.withOpacity(0.4)),
          _DItem(
            Icons.person_outline_rounded,
            'Mon Profil',
            Routeur.routeProfil,
            false,
          ),
        ];
    }

    return Drawer(
      backgroundColor: scheme.surface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            color: scheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.onPrimary.withOpacity(0.2),
                  child: Icon(icone, color: scheme.onPrimary, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  titre,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: scheme.onPrimary.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: items,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Material(
              color: scheme.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pop(context);
                  onDeconnexion();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: scheme.error, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Déconnexion',
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPERS COMMUNS
// ════════════════════════════════════════════════════════════════════════════
class _DItem extends StatelessWidget {
  final IconData icon;
  final String label, route;
  final bool isActive;
  const _DItem(this.icon, this.label, this.route, this.isActive);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive ? scheme.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context);
            if (!isActive) Navigator.pushReplacementNamed(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? scheme.primary
                      : scheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? scheme.primary
                        : scheme.onSurface.withOpacity(0.85),
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DLabel extends StatelessWidget {
  final String label;
  const _DLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    ),
  );
}

class _SectionTitre extends StatelessWidget {
  final String titre;
  final IconData icon;
  final Color? color;
  const _SectionTitre(this.titre, this.icon, {this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: c),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titre,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: c,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipFiltre extends StatelessWidget {
  final String label;
  final String? val;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _ChipFiltre(
    this.label,
    this.val,
    this.selected,
    this.onTap,
    this.color,
  );
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(selected ? 0 : 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : color,
        ),
      ),
    ),
  );
}

class _SubNote extends StatelessWidget {
  final String label;
  final double valeur;
  final Color color;
  const _SubNote(this.label, this.valeur, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label : ',
          style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
        ),
        Text(
          NoteModel.fmt(valeur),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _NoteField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? Function(String?) validator;
  final Color color;
  const _NoteField({
    required this.ctrl,
    required this.label,
    required this.validator,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textAlign: TextAlign.center,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: color),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      suffixText: '/20',
      suffixStyle: TextStyle(fontSize: 10, color: color.withOpacity(0.6)),
    ),
    validator: validator,
  );
}

class _SemestreBtn extends StatelessWidget {
  final String label, val;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;
  const _SemestreBtn(
    this.label,
    this.val,
    this.selected,
    this.scheme,
    this.onTap,
  );
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? scheme.primary
              : scheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : scheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final ColorScheme scheme;
  final bool muted;
  final Color? color;
  const _InfoBox(
    this.text,
    this.icon,
    this.scheme, {
    this.muted = false,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final c =
        color ?? (muted ? scheme.onSurface.withOpacity(0.4) : scheme.primary);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: c, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

InputDecoration _deco(String label, IconData icon, ColorScheme scheme) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

Widget _vide(BuildContext ctx, IconData icon, String msg, Color color) =>
    Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 14),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 14),
            ),
          ],
        ),
      ),
    );

void _snack(BuildContext ctx, String msg, Color color) =>
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
