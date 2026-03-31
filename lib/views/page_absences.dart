// lib/views/page_absences.dart
// MODIFIÉ :
//   - Filtre type (Tous | Absences | Retards)
//   - Formulaire : champ type, enseignantNom (auto), raison (optionnel)
//   - Card : affiche le type avec badge coloré

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/models/absence_model.dart';
import 'package:gestion_ecole/view_model/absence_view_model.dart';
import 'package:gestion_ecole/view_model/classe_view_model.dart';

class PageAbsences extends StatefulWidget {
  const PageAbsences({super.key});
  @override
  State<PageAbsences> createState() => _PageAbsencesState();
}

class _PageAbsencesState extends State<PageAbsences> {
  String? _role, _uid;
  bool _roleCharge = false;

  String? _filtreIdClasse, _filtreNomClasse, _filtreMatiere;
  bool? _filtreJustifiee;
  String? _filtreType; // null=tous | 'absence' | 'retard'

  List<String>? _idElevesClasse;

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
      _idElevesClasse = null;
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
    if (!_roleCharge)
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Center(child: CircularProgressIndicator(color: scheme.primary)),
      );

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Absences & Retards'),
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
                  builder: (_) => FormulaireAbsence(idEnseignant: _uid!),
                ),
              ),
              icon: const Icon(Icons.person_off_rounded),
              label: const Text('Enregistrer'),
            )
          : null,
    );
  }

  // ── Filtres ────────────────────────────────────────────────────────────────
  Widget _buildFiltres() {
    final scheme = Theme.of(context).colorScheme;
    final cvm = context.watch<ClasseViewModel>();

    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne 1 : classe + matière + reset ──────────────────────────────
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
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'Toutes les classes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurface.withOpacity(0.5),
                                ),
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
                        filtreActuel: _filtreMatiere,
                        uid: _role == 'eleve' ? _uid : null,
                        onChanged: (m) => setState(() => _filtreMatiere = m),
                      ),
              ),
              if (_filtreIdClasse != null ||
                  _filtreMatiere != null ||
                  _filtreJustifiee != null ||
                  _filtreType != null)
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
                      _filtreJustifiee = null;
                      _filtreType = null;
                      _idElevesClasse = null;
                    }),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Ligne 2 : filtre TYPE (Tous | Absences | Retards) ───────────────
          Row(
            children: [
              _Chip(
                'Tous',
                null,
                _filtreType == null,
                () => setState(() => _filtreType = null),
                const Color(0xFF1A3A8F),
              ),
              const SizedBox(width: 8),
              _Chip(
                'Absences',
                'absence',
                _filtreType == 'absence',
                () => setState(() => _filtreType = 'absence'),
                Colors.red,
              ),
              const SizedBox(width: 8),
              _Chip(
                'Retards',
                'retard',
                _filtreType == 'retard',
                () => setState(() => _filtreType = 'retard'),
                const Color(0xFFC0692A),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Ligne 3 : filtre JUSTIFIÉE ──────────────────────────────────────
          Row(
            children: [
              _Chip(
                'Toutes',
                null,
                _filtreJustifiee == null,
                () => setState(() => _filtreJustifiee = null),
                scheme.primary,
              ),
              const SizedBox(width: 8),
              _Chip(
                'Justifiées',
                true,
                _filtreJustifiee == true,
                () => setState(() => _filtreJustifiee = true),
                const Color(0xFF2A8A5C),
              ),
              const SizedBox(width: 8),
              _Chip(
                'Non justifiées',
                false,
                _filtreJustifiee == false,
                () => setState(() => _filtreJustifiee = false),
                Colors.red,
              ),
            ],
          ),

          if (_filtreNomClasse != null || _filtreMatiere != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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

  // ── Liste ──────────────────────────────────────────────────────────────────
  Widget _buildListe() {
    final vm = context.watch<AbsenceViewModel>();
    final scheme = Theme.of(context).colorScheme;

    Stream<List<AbsenceModel>> stream;
    if (_role == 'eleve')
      stream = vm.streamEleve(_uid!);
    else if (_role == 'enseignant')
      stream = vm.streamEnseignant(_uid!);
    else
      stream = vm.streamAbsences;

    return StreamBuilder<List<AbsenceModel>>(
      stream: stream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Center(
            child: CircularProgressIndicator(color: scheme.primary),
          );

        var list = snap.data ?? [];

        if (_filtreJustifiee != null)
          list = list.where((a) => a.justifiee == _filtreJustifiee).toList();
        if (_filtreMatiere != null)
          list = list.where((a) => a.matiere == _filtreMatiere).toList();
        if (_filtreType != null)
          list = list
              .where(
                (a) => _filtreType == 'retard'
                    ? a.type == TypePresence.retard
                    : a.type == TypePresence.absence,
              )
              .toList();

        if (_filtreIdClasse != null) {
          if (_idElevesClasse == null)
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          if (_idElevesClasse!.isEmpty)
            list = [];
          else
            list = list
                .where((a) => _idElevesClasse!.contains(a.idEleve))
                .toList();
        }

        if (list.isEmpty)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 56,
                    color: scheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Aucun enregistrement trouvé',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: list.length,
          itemBuilder: (_, i) => _AbsenceCard(
            absence: list[i],
            peutModifier: _role == 'enseignant' && list[i].idEnseignant == _uid,
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CARD ABSENCE — affiche type + raison
// ════════════════════════════════════════════════════════════════════════════
class _AbsenceCard extends StatelessWidget {
  final AbsenceModel absence;
  final bool peutModifier;
  const _AbsenceCard({required this.absence, required this.peutModifier});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.read<AbsenceViewModel>();
    final col = absence.justifiee ? const Color(0xFF2A8A5C) : Colors.red;
    final typeCol = absence.type == TypePresence.retard
        ? const Color(0xFFC0692A)
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: typeCol, width: 4)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: typeCol.withOpacity(0.1),
          child: Icon(
            absence.type == TypePresence.retard
                ? Icons.access_time_rounded
                : (absence.justifiee
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded),
            color: typeCol,
            size: 20,
          ),
        ),
        title: Text(
          absence.nomEleve,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Badge(absence.typeLabel, typeCol),
                _Badge(absence.matiere, const Color(0xFF7B3FA0)),
                _Badge(absence.dateFormatee, const Color(0xFF1A3A8F)),
                _Badge(absence.justifiee ? 'Justifiée' : 'Non justifiée', col),
                if (absence.raison.isNotEmpty)
                  _Badge(absence.raison, scheme.primary),
              ],
            ),
            if (absence.enseignantNom.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Par : ${absence.enseignantNom}',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withOpacity(0.45),
                  ),
                ),
              ),
          ],
        ),
        trailing: peutModifier
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Modifier',
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    onPressed: () {
                      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormulaireAbsence(
                            absence: absence,
                            idEnseignant: uid,
                          ),
                        ),
                      );
                    },
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
              )
            : null,
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, AbsenceViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?'),
        content: Text(
          'Supprimer cet enregistrement pour ${absence.nomEleve} ?',
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
              final ok = await vm.supprimer(absence.id!);
              if (context.mounted)
                _snack(
                  context,
                  ok ? 'Supprimé' : vm.erreur ?? 'Erreur',
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
// FORMULAIRE ABSENCE — MODIFIÉ : type, enseignantNom, raison
// ════════════════════════════════════════════════════════════════════════════
class FormulaireAbsence extends StatefulWidget {
  final AbsenceModel? absence;
  final String idEnseignant;
  const FormulaireAbsence({
    super.key,
    this.absence,
    required this.idEnseignant,
  });
  @override
  State<FormulaireAbsence> createState() => _FormulaireAbsenceState();
}

class _FormulaireAbsenceState extends State<FormulaireAbsence> {
  DateTime _date = DateTime.now();
  bool _justifiee = false;
  TypePresence _type = TypePresence.absence;
  String? _idClasseFiltre, _idEtu, _nomEtu, _matiere;
  String _raisonCtrl = '';
  String _enseignantNom = '';

  List<Map<String, dynamic>> _eleves = [];
  List<Map<String, String>> _classesEnseignant = [];
  List<String> _matieresEnseignant = [];

  bool get _estModif => widget.absence != null;

  @override
  void initState() {
    super.initState();
    if (_estModif) {
      final a = widget.absence!;
      _date = a.date;
      _justifiee = a.justifiee;
      _type = a.type;
      _idEtu = a.idEleve;
      _nomEtu = a.nomEleve;
      _matiere = a.matiere;
      _raisonCtrl = a.raison;
    }
    _chargerDonneesEnseignant();
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
    // Charger le nom de l'enseignant
    final userDoc = await FirebaseFirestore.instance
        .collection('utilisateur')
        .doc(widget.idEnseignant)
        .get();
    if (mounted)
      setState(() {
        _classesEnseignant =
            cls.entries.map((e) => {'id': e.key, 'nom': e.value}).toList()
              ..sort((a, b) => a['nom']!.compareTo(b['nom']!));
        _matieresEnseignant = mats.toList()..sort();
        _enseignantNom = userDoc.data()?['nomComplet'] as String? ?? '';
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
      });
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (p != null) setState(() => _date = p);
  }

  Future<void> _enregistrer() async {
    if (_idEtu == null) {
      _snack(context, 'Sélectionnez un élève', Colors.orange);
      return;
    }
    if (_matiere == null) {
      _snack(context, 'Sélectionnez une matière', Colors.orange);
      return;
    }

    final vm = context.read<AbsenceViewModel>();
    final absence = AbsenceModel(
      idEleve: _idEtu!,
      nomEleve: _nomEtu!,
      matiere: _matiere!,
      date: _date,
      justifiee: _justifiee,
      idEnseignant: widget.idEnseignant,
      enseignantNom: _enseignantNom,
      type: _type,
      raison: _raisonCtrl,
    );
    final ok = _estModif
        ? await vm.modifier(widget.absence!.id!, absence)
        : await vm.ajouter(absence);
    if (mounted) {
      _snack(
        context,
        ok ? (_estModif ? 'Modifié ✓' : 'Enregistré ✓') : vm.erreur ?? 'Erreur',
        ok ? Colors.green : Colors.red,
      );
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.watch<AbsenceViewModel>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(_estModif ? 'Modifier' : 'Enregistrer une absence/retard'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Type : Absence | Retard ─────────────────────────────────────
            _SectionTitre('Type d\'enregistrement', Icons.category_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeBtn(
                    'Absence',
                    TypePresence.absence,
                    _type == TypePresence.absence,
                    Colors.red,
                    () => setState(() => _type = TypePresence.absence),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeBtn(
                    'Retard',
                    TypePresence.retard,
                    _type == TypePresence.retard,
                    const Color(0xFFC0692A),
                    () => setState(() => _type = TypePresence.retard),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!_estModif) ...[
              // ── Classe ───────────────────────────────────────────────────
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
                      decoration: _deco('Classe', Icons.class_rounded, scheme),
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
                        });
                        if (val != null) {
                          _chargerEleves(val);
                          _chargerMatieresParClasse(val);
                        }
                      },
                    ),
              const SizedBox(height: 16),

              // ── Élève ─────────────────────────────────────────────────────
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
                      onChanged: (val) => setState(() {
                        _idEtu = val;
                        _nomEtu =
                            _eleves.firstWhere(
                                  (e) => e['id'] == val,
                                )['nomComplet']
                                as String?;
                      }),
                    ),
              const SizedBox(height: 16),

              // ── Matière ───────────────────────────────────────────────────
              _SectionTitre('Matière', Icons.book_rounded),
              const SizedBox(height: 12),
              _matieresEnseignant.isEmpty
                  ? _InfoBox(
                      _idClasseFiltre == null
                          ? 'Sélectionnez d\'abord une classe'
                          : 'Aucune matière',
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
                      items: _matieresEnseignant
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _matiere = val),
                    ),
              const SizedBox(height: 16),
            ] else ...[
              _InfoBox(_nomEtu ?? '', Icons.person_rounded, scheme),
              const SizedBox(height: 10),
              _InfoBox(_matiere ?? '', Icons.book_rounded, scheme),
              const SizedBox(height: 16),
            ],

            // ── Date ─────────────────────────────────────────────────────────
            _SectionTitre('Date', Icons.calendar_today_rounded),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: scheme.outlineVariant.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Raison (optionnel) ────────────────────────────────────────────
            _SectionTitre('Raison (optionnel)', Icons.notes_rounded),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _raisonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Maladie, rendez-vous médical...',
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (v) => _raisonCtrl = v,
            ),
            const SizedBox(height: 16),

            // ── Justifiée ─────────────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (_justifiee ? const Color(0xFF2A8A5C) : Colors.red)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_justifiee ? const Color(0xFF2A8A5C) : Colors.red)
                      .withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _justifiee
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: _justifiee ? const Color(0xFF2A8A5C) : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _justifiee ? 'Justifié(e)' : 'Non justifié(e)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _justifiee
                            ? const Color(0xFF2A8A5C)
                            : Colors.red,
                      ),
                    ),
                  ),
                  Switch(
                    value: _justifiee,
                    onChanged: (v) => setState(() => _justifiee = v),
                    activeColor: const Color(0xFF2A8A5C),
                  ),
                ],
              ),
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
                            : 'Enregistrer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bouton type (Absence | Retard) ────────────────────────────────────────────
class _TypeBtn extends StatelessWidget {
  final String label;
  final TypePresence val;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeBtn(this.label, this.val, this.selected, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(selected ? 0 : 0.3)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    ),
  );
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
          _DItem(Icons.star_rounded, 'Notes', Routeur.routeNotes, false),
          _DItem(
            Icons.event_busy_rounded,
            'Absences',
            Routeur.routeAbsences,
            true,
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
          _DItem(Icons.star_rounded, 'Notes', Routeur.routeNotes, false),
          _DItem(
            Icons.event_busy_rounded,
            'Absences',
            Routeur.routeAbsences,
            true,
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
          _DItem(Icons.star_rounded, 'Mes Notes', Routeur.routeNotes, false),
          _DItem(
            Icons.event_busy_rounded,
            'Mes Absences',
            Routeur.routeAbsences,
            true,
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
// DROPDOWNS & HELPERS (repris de l'original, inchangés)
// ════════════════════════════════════════════════════════════════════════════
class _Chip extends StatelessWidget {
  final String label;
  final dynamic val;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _Chip(this.label, this.val, this.selected, this.onTap, this.color);
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
  final String? filtreActuel, uid;
  final void Function(String?) onChanged;
  const _DropdownFiltreMatiere({
    required this.filtreActuel,
    required this.onChanged,
    this.uid,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stream = uid != null
        ? FirebaseFirestore.instance
              .collection('absence')
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
            final m = (uid != null ? d['matiere'] : d['nom']) as String?;
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

class _SectionTitre extends StatelessWidget {
  final String titre;
  final IconData icon;
  const _SectionTitre(this.titre, this.icon);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          titre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: scheme.primary,
          ),
        ),
      ],
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
