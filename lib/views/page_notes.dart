// lib/views/page_notes.dart
// Admin      → toutes les notes, filtre classe + matière (lecture seule)
// Enseignant → ses notes, filtre classe + matière, saisir/modifier/supprimer
// Élève   → ses notes, filtre matière (lecture seule)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/models/note_model.dart';
import 'package:gestion_ecole/view_model/note_view_model.dart';
import 'package:gestion_ecole/view_model/classe_view_model.dart';

class PageNotes extends StatefulWidget {
  const PageNotes({super.key});

  @override
  State<PageNotes> createState() => _PageNotesState();
}

class _PageNotesState extends State<PageNotes> {
  String? _role;
  String? _uid;
  bool    _roleCharge  = false;

  // Filtres
  String? _filtreIdClasse;
  String? _filtreNomClasse;
  String? _filtreMatiere;

  // Élèves de la classe sélectionnée (pour filtrage côté client)
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
        .collection('utilisateur').doc(user.uid).get();
    if (mounted) setState(() {
      _role       = doc.data()?['role'] as String? ?? '';
      _roleCharge = true;
    });
  }

  Future<void> _onClasseChanged(String? idClasse, String? nomClasse) async {
    setState(() {
      _filtreIdClasse    = idClasse;
      _filtreNomClasse   = nomClasse;
      _filtreMatiere     = null;
      _idElevesClasse = [];
    });
    if (idClasse == null) return;

    // Récupérer les IDs des élèves de cette classe
    final snap = await FirebaseFirestore.instance
        .collection('utilisateur')
        .where('role', isEqualTo: 'eleve')
        .where('idClasse', isEqualTo: idClasse)
        .get();
    if (mounted) setState(() {
      _idElevesClasse = snap.docs.map((d) => d.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_roleCharge) {
      return Scaffold(backgroundColor: scheme.surface,
          body: Center(child: CircularProgressIndicator(color: scheme.primary)));
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
      drawer: _buildDrawer(),
      body: Column(children: [
        // ── Filtres ─────────────────────────────────────────────────────────
        _buildFiltres(),
        // ── Liste ───────────────────────────────────────────────────────────
        Expanded(child: _buildListe()),
      ]),
      floatingActionButton: _role == 'enseignant'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => FormulaireNote(idEnseignant: _uid!))),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Saisir une note'),
            )
          : null,
    );
  }

  // ── Filtres ────────────────────────────────────────────────────────────────
  Widget _buildFiltres() {
    final scheme = Theme.of(context).colorScheme;
    final cvm    = context.watch<ClasseViewModel>();

    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(children: [
        Row(children: [
          // Filtre Classe (pas pour l'élève)
          if (_role != 'eleve') ...[
            Expanded(
              child: _role == 'enseignant'
                  // Enseignant : seulement ses classes via enseignement
                  ? _DropdownClasseEnseignant(
                      idEnseignant: _uid!,
                      value:        _filtreIdClasse,
                      onChanged:    _onClasseChanged,
                    )
                  // Admin : toutes les classes
                  : _DropdownFiltre(
                      hint:  'Toutes les classes',
                      value: _filtreIdClasse,
                      actif: _filtreIdClasse != null,
                      extra: [const DropdownMenuItem<String>(value: null,
                          child: Text('Toutes les classes',
                              style: TextStyle(fontSize: 13)))],
                      items: cvm.classes.map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.nomClasse,
                              style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        final nom = val == null ? null
                            : cvm.classes.firstWhere((c) => c.id == val).nomClasse;
                        _onClasseChanged(val, nom);
                      },
                    ),
            ),
            const SizedBox(width: 8),
          ],

          // Filtre Matière (élève : uniquement ses matières depuis ses notes)
          Expanded(
            child: _role == 'enseignant'
                ? _DropdownMatiereEnseignant(
                    idEnseignant: _uid!,
                    idClasse:     _filtreIdClasse,
                    filtreActuel: _filtreMatiere,
                    onChanged: (m) => setState(() => _filtreMatiere = m),
                  )
                : _DropdownFiltreMatiere(
                    uid:          _uid!,
                    role:         _role!,
                    idClasse:     _filtreIdClasse,
                    filtreActuel: _filtreMatiere,
                    onChanged: (m) => setState(() => _filtreMatiere = m),
                  ),
          ),

          // Bouton reset
          if (_filtreIdClasse != null || _filtreMatiere != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.clear_rounded, size: 20,
                    color: scheme.onSurface.withOpacity(0.5)),
                onPressed: () {
                  setState(() {
                    _filtreIdClasse    = null;
                    _filtreNomClasse   = null;
                    _filtreMatiere     = null;
                    _idElevesClasse = [];
                  });
                },
              ),
            ),
        ]),

        // Badge filtre actif
        if (_filtreIdClasse != null || _filtreMatiere != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              Icon(Icons.filter_alt_rounded, size: 14,
                  color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                [
                  if (_filtreNomClasse != null) _filtreNomClasse!,
                  if (_filtreMatiere != null) _filtreMatiere!,
                ].join(' · '),
                style: TextStyle(fontSize: 12, color: scheme.primary,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
      ]),
    );
  }

  // ── Liste ──────────────────────────────────────────────────────────────────
  Widget _buildListe() {
    final vm     = context.watch<NoteViewModel>();
    final scheme = Theme.of(context).colorScheme;

    Stream<List<NoteModel>> stream;

    if (_role == 'eleve') {
      stream = vm.streamFiltrees(
          idEleve: _uid, matiere: _filtreMatiere);
    } else if (_role == 'enseignant') {
      stream = vm.streamEnseignant(_uid!).map((list) {
        return list.where((n) {
          if (_filtreMatiere != null && n.matiere != _filtreMatiere) return false;
          if (_filtreIdClasse != null && _idElevesClasse.isNotEmpty &&
              !_idElevesClasse.contains(n.idEleve)) return false;
          return true;
        }).toList();
      });
    } else {
      // Admin
      stream = vm.streamFiltrees(matiere: _filtreMatiere).map((list) {
        if (_filtreIdClasse != null && _idElevesClasse.isNotEmpty) {
          return list.where((n) =>
              _idElevesClasse.contains(n.idEleve)).toList();
        }
        return list;
      });
    }

    return StreamBuilder<List<NoteModel>>(
      stream: stream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: scheme.primary));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return _vide(context, Icons.star_border_rounded,
              'Aucune note trouvée', scheme.onSurface.withOpacity(0.3));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: list.length,
          itemBuilder: (_, i) => _NoteCard(
            note:         list[i],
            peutModifier: _role == 'enseignant' &&
                          list[i].idEnseignant == _uid,
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    if (_role == 'admin')      return const _DrawerRole(role: 'admin');
    if (_role == 'enseignant') return const _DrawerRole(role: 'enseignant');
    return const _DrawerRole(role: 'eleve');
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DROPDOWN FILTRE GÉNÉRIQUE
// ════════════════════════════════════════════════════════════════════════════
class _DropdownFiltre extends StatelessWidget {
  final String                          hint;
  final String?                         value;
  final bool                            actif;
  final List<DropdownMenuItem<String>>  items;
  final List<DropdownMenuItem<String>>  extra;
  final void Function(String?)          onChanged;

  const _DropdownFiltre({
    required this.hint,
    required this.value,
    required this.actif,
    required this.items,
    required this.onChanged,
    this.extra = const [],
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
                  : scheme.outlineVariant.withOpacity(0.4)),
        ),
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 12,
              color: scheme.onSurface.withOpacity(0.5))),
          isExpanded: true,
          style: TextStyle(fontSize: 13, color: scheme.onSurface),
          items: [...extra, ...items],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Dropdown matière : admin → collection matiere / élève → ses propres notes
class _DropdownFiltreMatiere extends StatelessWidget {
  final String   uid;
  final String   role;
  final String?  idClasse;
  final String?  filtreActuel;
  final void Function(String?) onChanged;

  const _DropdownFiltreMatiere({
    required this.uid,
    required this.role,
    required this.idClasse,
    required this.filtreActuel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Élève : matières uniquement depuis ses propres notes
    // Admin    : toutes les matières de la collection 'matiere'
    final Stream<QuerySnapshot> stream;
    if (role == 'eleve') {
      stream = FirebaseFirestore.instance
          .collection('note')
          .where('idEleve', isEqualTo: uid)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('matiere')
          .orderBy('nom')
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (_, snap) {
        final matieres = <String>{};
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            // Pour l'élève le champ s'appelle 'matiere', pour admin c'est 'nom'
            final m = (role == 'eleve'
                ? d['matiere'] : d['nom']) as String?;
            if (m != null && m.isNotEmpty) matieres.add(m);
          }
        }
        final list = matieres.toList()..sort();

        return DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: filtreActuel != null
                      ? scheme.primary.withOpacity(0.5)
                      : scheme.outlineVariant.withOpacity(0.4)),
            ),
            child: DropdownButton<String>(
              value: list.contains(filtreActuel) ? filtreActuel : null,
              hint: Text('Toutes les matières',
                  style: TextStyle(fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.5))),
              isExpanded: true,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              items: [
                DropdownMenuItem<String>(value: null,
                    child: Text('Toutes les matières',
                        style: TextStyle(fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.5)))),
                ...list.map((m) => DropdownMenuItem(
                    value: m, child: Text(m,
                        style: const TextStyle(fontSize: 13)))),
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
// DROPDOWN CLASSES DE L'ENSEIGNANT (depuis enseignement)
// ════════════════════════════════════════════════════════════════════════════
class _DropdownClasseEnseignant extends StatelessWidget {
  final String  idEnseignant;
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
        // Dédupliquer les classes
        final Map<String, String> classes = {};
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final id  = d['idClasse']  as String? ?? '';
            final nom = d['nomClasse'] as String? ?? '';
            if (id.isNotEmpty) classes[id] = nom;
          }
        }
        final entries = classes.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        return DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: value != null
                  ? scheme.primary.withOpacity(0.5)
                  : scheme.outlineVariant.withOpacity(0.4)),
            ),
            child: DropdownButton<String>(
              value: classes.containsKey(value) ? value : null,
              isExpanded: true,
              hint: Text('Mes classes', style: TextStyle(fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.5))),
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              items: [
                DropdownMenuItem<String>(value: null,
                    child: Text('Mes classes', style: TextStyle(fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.5)))),
                ...entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value,
                        style: const TextStyle(fontSize: 13)))),
              ],
              onChanged: (val) => onChanged(
                val,
                val == null ? null : classes[val],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DROPDOWN MATIÈRES DE L'ENSEIGNANT (depuis enseignement)
// ════════════════════════════════════════════════════════════════════════════
class _DropdownMatiereEnseignant extends StatelessWidget {
  final String  idEnseignant;
  final String? idClasse;
  final String? filtreActuel;
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
        final matieres = <String>{};
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final m = (doc.data() as Map<String, dynamic>)['matiere']
                as String?;
            if (m != null && m.isNotEmpty) matieres.add(m);
          }
        }
        final list = matieres.toList()..sort();

        return DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: filtreActuel != null
                  ? scheme.primary.withOpacity(0.5)
                  : scheme.outlineVariant.withOpacity(0.4)),
            ),
            child: DropdownButton<String>(
              value: list.contains(filtreActuel) ? filtreActuel : null,
              isExpanded: true,
              hint: Text('Mes matières', style: TextStyle(fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.5))),
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              items: [
                DropdownMenuItem<String>(value: null,
                    child: Text('Mes matières', style: TextStyle(fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.5)))),
                ...list.map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: const TextStyle(fontSize: 13)))),
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
// CARD NOTE
// ════════════════════════════════════════════════════════════════════════════
class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final bool      peutModifier;
  const _NoteCard({required this.note, required this.peutModifier});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm     = context.read<NoteViewModel>();
    final color  = note.mentionColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: scheme.shadow.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text(note.valeurFormatee, style: TextStyle(color: color,
                fontWeight: FontWeight.bold, fontSize: 16)),
            Text('/20', style: TextStyle(
                color: color.withOpacity(0.7), fontSize: 9)),
          ]),
        ),
        title: Text(note.nomEleve, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(spacing: 6, runSpacing: 4, children: [
            _Badge(note.matiere,  const Color(0xFF7B3FA0)),
            _Badge(note.mention, color),
          ]),
        ),
        trailing: peutModifier
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: 'Modifier',
                  icon: Icon(Icons.edit_rounded, size: 20,
                      color: scheme.primary),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                          FormulaireNote(note: note,
                              idEnseignant: note.idEnseignant))),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: Icon(Icons.delete_rounded, size: 20,
                      color: scheme.error),
                  onPressed: () => _confirmerSuppression(context, vm),
                ),
              ])
            : null,
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, NoteViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Supprimer la note ?'),
      content: Text('La note de ${note.nomEleve} en ${note.matiere} '
          'sera supprimée.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await vm.supprimer(note.id!);
            if (context.mounted) _snack(context,
                ok ? 'Note supprimée' : vm.erreur ?? 'Erreur',
                ok ? scheme.error : Colors.orange);
          },
          child: Text('Supprimer', style: TextStyle(color: scheme.onError)),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FORMULAIRE NOTE
// ════════════════════════════════════════════════════════════════════════════
class FormulaireNote extends StatefulWidget {
  final NoteModel? note;
  final String     idEnseignant;
  const FormulaireNote({super.key, this.note, required this.idEnseignant});

  @override
  State<FormulaireNote> createState() => _FormulaireNoteState();
}

class _FormulaireNoteState extends State<FormulaireNote> {
  final _fk  = GlobalKey<FormState>();
  final _val = TextEditingController();

  String? _idClasseFiltre;
  String? _idEtu, _nomEtu;
  String? _matiere;
  List<Map<String, dynamic>> _eleves = [];

  bool get _estModif => widget.note != null;

  @override
  void initState() {
    super.initState();
    if (_estModif) {
      final n  = widget.note!;
      _val.text = n.valeurFormatee;
      _idEtu    = n.idEleve;
      _nomEtu   = n.nomEleve;
      _matiere  = n.matiere;
    }
  }

  @override
  void dispose() { _val.dispose(); super.dispose(); }

  Future<void> _chargerEleves(String idClasse) async {
    final snap = await FirebaseFirestore.instance
        .collection('utilisateur')
        .where('role', isEqualTo: 'eleve')
        .where('idClasse', isEqualTo: idClasse)
        .get();
    if (mounted) setState(() {
      _eleves = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _idEtu = null; _nomEtu = null;
    });
  }

  Future<void> _enregistrer() async {
    if (!_fk.currentState!.validate()) return;
    if (_idEtu == null) {
      _snack(context, 'Sélectionnez un élève', Colors.orange); return;
    }
    if (_matiere == null) {
      _snack(context, 'Sélectionnez une matière', Colors.orange); return;
    }
    final v = double.tryParse(_val.text.replaceAll(',', '.'));
    if (v == null || v < 0 || v > 20) {
      _snack(context, 'Note entre 0 et 20', Colors.orange); return;
    }

    final vm   = context.read<NoteViewModel>();
    final note = NoteModel(
      idEleve:   _idEtu!,
      nomEleve:  _nomEtu!,
      matiere:      _matiere!,
      valeur:       v,
      idEnseignant: widget.idEnseignant,
    );

    final ok = _estModif
        ? await vm.modifier(widget.note!.id!, note)
        : await vm.ajouter(note);

    if (mounted) {
      _snack(context,
          ok ? (_estModif ? 'Note modifiée ✓' : 'Note ajoutée ✓')
              : vm.erreur ?? 'Erreur',
          ok ? Colors.green : Colors.red);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm     = context.watch<NoteViewModel>();
    final cvm    = context.watch<ClasseViewModel>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(_estModif ? 'Modifier la note' : 'Saisir une note'),
        centerTitle: false, elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      body: Form(
        key: _fk,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

            // ── Classe (filtre, non stockée) ────────────────────────────
            if (!_estModif) ...[
              _SectionTitre('Classe', Icons.class_rounded),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: cvm.classes.any((c) => c.id == _idClasseFiltre)
                    ? _idClasseFiltre : null,
                decoration: _deco('Classe', Icons.class_rounded, scheme),
                items: cvm.classes.map((c) => DropdownMenuItem(
                    value: c.id, child: Text(c.nomClasse))).toList(),
                onChanged: (val) {
                  setState(() {
                    _idClasseFiltre = val;
                    _eleves      = [];
                    _idEtu          = null;
                  });
                  if (val != null) _chargerEleves(val);
                },
                validator: (v) => v == null ? 'Classe requise' : null,
              ),
              const SizedBox(height: 16),
            ],

            // ── Élève ────────────────────────────────────────────────
            _SectionTitre('Élève', Icons.school_rounded),
            const SizedBox(height: 14),
            if (_estModif)
              _InfoBox(_nomEtu ?? '', Icons.person_rounded, scheme)
            else if (_idClasseFiltre == null)
              _InfoBox('Sélectionnez d\'abord une classe',
                  Icons.info_outline_rounded, scheme, muted: true)
            else if (_eleves.isEmpty)
              _InfoBox('Aucun élève dans cette classe',
                  Icons.warning_amber_rounded, scheme,
                  color: Colors.orange)
            else
              DropdownButtonFormField<String>(
                value: _eleves.any((e) => e['id'] == _idEtu)
                    ? _idEtu : null,
                decoration: _deco('Sélectionner un élève',
                    Icons.person_rounded, scheme),
                items: _eleves.map((e) => DropdownMenuItem(
                    value: e['id'] as String,
                    child: Text(e['nomComplet'] as String? ?? ''))).toList(),
                onChanged: (val) => setState(() {
                  _idEtu  = val;
                  _nomEtu = _eleves.firstWhere(
                      (e) => e['id'] == val)['nomComplet'] as String?;
                }),
              ),
            const SizedBox(height: 20),

            // ── Matière (depuis Firestore) ───────────────────────────────
            _SectionTitre('Matière', Icons.book_rounded),
            const SizedBox(height: 14),
            if (_estModif)
              _InfoBox(_matiere ?? '', Icons.book_rounded, scheme)
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('matiere').orderBy('nom').snapshots(),
                builder: (_, snap) {
                  final matieres = snap.hasData
                      ? snap.data!.docs.map((d) =>
                          (d.data() as Map<String, dynamic>)['nom']
                          as String).toList()
                      : <String>[];
                  return DropdownButtonFormField<String>(
                    value: matieres.contains(_matiere) ? _matiere : null,
                    decoration: _deco('Sélectionner une matière',
                        Icons.book_rounded, scheme),
                    items: matieres.map((m) => DropdownMenuItem(
                        value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => _matiere = val),
                    validator: (v) => v == null ? 'Matière requise' : null,
                  );
                },
              ),
            const SizedBox(height: 16),

            // ── Valeur ──────────────────────────────────────────────────
            _SectionTitre('Note', Icons.star_rounded),
            const SizedBox(height: 14),
            TextFormField(
              controller: _val,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: _deco('Valeur (0 – 20)',
                  Icons.star_rounded, scheme)
                  .copyWith(suffixText: '/ 20'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Note requise';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n < 0 || n > 20) return 'Entre 0 et 20';
                return null;
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: vm.isLoading ? null : _enregistrer,
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: vm.isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_estModif
                        ? 'Enregistrer les modifications'
                        : 'Enregistrer la note',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DRAWER PAR RÔLE
// ════════════════════════════════════════════════════════════════════════════
class _DrawerRole extends StatelessWidget {
  final String role;
  const _DrawerRole({required this.role});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user   = FirebaseAuth.instance.currentUser;

    IconData icone;
    String   titre;
    List<Widget> items;

    switch (role) {
      case 'admin':
        icone = Icons.admin_panel_settings_rounded;
        titre = 'Administrateur';
        items = [
          _DItem(Icons.dashboard_rounded,     'Tableau de bord', Routeur.routeAccueil,     false),
          const _DLabel('GESTION'),
          _DItem(Icons.school_rounded,         'Élèves',      Routeur.routeEleves,   false),
          _DItem(Icons.person_rounded,         'Enseignants',    Routeur.routeEnseignants, false),
          _DItem(Icons.class_rounded,          'Classes',        Routeur.routeClasses,     false),
          _DItem(Icons.book_rounded,           'Matières',       Routeur.routeMatieres,    false),
          const _DLabel('ACADÉMIQUE'),
          _DItem(Icons.star_rounded,           'Notes',          Routeur.routeNotes,       true),
          _DItem(Icons.event_busy_rounded,     'Absences',       Routeur.routeAbsences,    false),
          Divider(height: 20, color: scheme.outlineVariant.withOpacity(0.4)),
          _DItem(Icons.person_outline_rounded, 'Mon Profil',     Routeur.routeProfil,      false),
        ];
        break;
      case 'enseignant':
        icone = Icons.school_rounded;
        titre = 'Enseignant';
        items = [
          _DItem(Icons.dashboard_rounded,     'Tableau de bord', Routeur.routeAccueilEnseignant, false),
          const _DLabel('ACADÉMIQUE'),
          _DItem(Icons.star_rounded,           'Notes',          Routeur.routeNotes,    true),
          _DItem(Icons.event_busy_rounded,     'Absences',       Routeur.routeAbsences, false),
          Divider(height: 20, color: scheme.outlineVariant.withOpacity(0.4)),
          _DItem(Icons.person_outline_rounded, 'Mon Profil',     Routeur.routeProfil,   false),
        ];
        break;
      default:
        icone = Icons.person_rounded;
        titre = 'Élève';
        items = [
          _DItem(Icons.dashboard_rounded,     'Tableau de bord', Routeur.routeAccueilEleve, false),
          const _DLabel('MES DONNÉES'),
          _DItem(Icons.star_rounded,           'Mes Notes',      Routeur.routeNotes,    true),
          _DItem(Icons.event_busy_rounded,     'Mes Absences',   Routeur.routeAbsences, false),
          Divider(height: 20, color: scheme.outlineVariant.withOpacity(0.4)),
          _DItem(Icons.person_outline_rounded, 'Mon Profil',     Routeur.routeProfil,   false),
        ];
    }

    return Drawer(
      backgroundColor: scheme.surface,
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          color: scheme.primary,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            CircleAvatar(radius: 28,
                backgroundColor: scheme.onPrimary.withOpacity(0.2),
                child: Icon(icone, color: scheme.onPrimary, size: 28)),
            const SizedBox(height: 12),
            Text(titre, style: TextStyle(color: scheme.onPrimary,
                fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(user?.email ?? '',
                style: TextStyle(
                    color: scheme.onPrimary.withOpacity(0.8), fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          children: items,
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Material(
            color: scheme.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                Navigator.pop(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Déconnexion'),
                    content: const Text(
                        'Voulez-vous vraiment vous déconnecter ?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler')),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: scheme.error,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Déconnecter',
                            style: TextStyle(color: scheme.onError)),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) Navigator.pushReplacementNamed(
                      context, Routeur.routeInitial);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                child: Row(children: [
                  Icon(Icons.logout_rounded, color: scheme.error, size: 20),
                  const SizedBox(width: 12),
                  Text('Déconnexion', style: TextStyle(color: scheme.error,
                      fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════════════════════
class _DItem extends StatelessWidget {
  final IconData icon; final String label, route; final bool isActive;
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
            child: Row(children: [
              Icon(icon, size: 20,
                  color: isActive ? scheme.primary
                      : scheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 14),
              Text(label, style: TextStyle(fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? scheme.primary
                      : scheme.onSurface.withOpacity(0.85))),
              if (isActive) ...[
                const Spacer(),
                Container(width: 5, height: 5,
                    decoration: BoxDecoration(
                        color: scheme.primary, shape: BoxShape.circle)),
              ],
            ]),
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
    child: Text(label, style: TextStyle(fontSize: 10,
        fontWeight: FontWeight.bold, letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
  );
}

class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11,
          color: color, fontWeight: FontWeight.w500)));
  }
}

class _SectionTitre extends StatelessWidget {
  final String titre; final IconData icon;
  const _SectionTitre(this.titre, this.icon);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Container(padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: scheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: scheme.primary)),
      const SizedBox(width: 10),
      Text(titre, style: TextStyle(fontWeight: FontWeight.bold,
          fontSize: 15, color: scheme.primary)),
    ]);
  }
}

class _InfoBox extends StatelessWidget {
  final String     text;
  final IconData   icon;
  final ColorScheme scheme;
  final bool       muted;
  final Color?     color;
  const _InfoBox(this.text, this.icon, this.scheme,
      {this.muted = false, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? (muted
        ? scheme.onSurface.withOpacity(0.4)
        : scheme.primary);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: c, fontSize: 13))),
      ]),
    );
  }
}

InputDecoration _deco(String label, IconData icon, ColorScheme scheme) =>
    InputDecoration(
      labelText: label, prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
    );

Widget _vide(BuildContext ctx, IconData icon, String msg, Color color) =>
    Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 56, color: color),
        const SizedBox(height: 14),
        Text(msg, textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 14)),
      ])));

void _snack(BuildContext ctx, String msg, Color color) =>
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));