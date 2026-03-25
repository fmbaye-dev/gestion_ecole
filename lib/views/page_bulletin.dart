// lib/views/page_bulletin.dart
//
// Élève      → son propre bulletin
// Enseignant → bulletins des élèves de ses classes
// Admin      → bulletins de tous les élèves

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/models/note_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// PAGE BULLETIN
// ════════════════════════════════════════════════════════════════════════════
class PageBulletin extends StatefulWidget {
  const PageBulletin({super.key});
  @override
  State<PageBulletin> createState() => _PageBulletinState();
}

class _PageBulletinState extends State<PageBulletin> {
  String? _role, _uid;
  bool _roleCharge = false;
  String _semestre = 'S1';
  String? _filtreIdClasse, _filtreNomClasse, _filtreIdEleve, _filtreNomEleve;

  // Listes chargées depuis Firestore
  List<Map<String, String>> _classesEnseignant = [];
  List<Map<String, String>> _elevesClasse = [];

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
    final role = doc.data()?['role'] as String? ?? '';
    if (mounted) {
      setState(() {
        _role = role;
        _roleCharge = true;
      });
      if (role == 'eleve') {
        // Élève voit son propre bulletin
        _filtreIdEleve = user.uid;
        _filtreNomEleve = doc.data()?['nomComplet'] as String? ?? '';
      } else if (role == 'enseignant') {
        _chargerClassesEnseignant();
      }
    }
  }

  Future<void> _chargerClassesEnseignant() async {
    final snap = await FirebaseFirestore.instance
        .collection('enseignement')
        .where('idEnseignant', isEqualTo: _uid)
        .get();
    final Map<String, String> cls = {};
    for (final doc in snap.docs) {
      final d = doc.data();
      final id = d['idClasse'] as String? ?? '';
      final nm = d['nomClasse'] as String? ?? '';
      if (id.isNotEmpty) cls[id] = nm;
    }
    if (mounted)
      setState(() {
        _classesEnseignant =
            cls.entries.map((e) => {'id': e.key, 'nom': e.value}).toList()
              ..sort((a, b) => a['nom']!.compareTo(b['nom']!));
      });
  }

  Future<void> _onClasseChanged(String? idClasse, String? nomClasse) async {
    setState(() {
      _filtreIdClasse = idClasse;
      _filtreNomClasse = nomClasse;
      _filtreIdEleve = null;
      _filtreNomEleve = null;
      _elevesClasse = [];
    });
    if (idClasse == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('utilisateur')
        .where('role', isEqualTo: 'eleve')
        .where('idClasse', isEqualTo: idClasse)
        .get();
    if (mounted)
      setState(() {
        _elevesClasse = snap.docs.map((d) {
          final data = d.data();
          return {'id': d.id, 'nom': data['nomComplet'] as String? ?? ''};
        }).toList()..sort((a, b) => a['nom']!.compareTo(b['nom']!));
      });
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
        title: const Text('Bulletin'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      drawer: _DrawerRole(role: _role ?? 'eleve', onDeconnexion: _deconnexion),
      body: Column(
        children: [
          _buildFiltres(scheme),
          Expanded(child: _buildContenu(scheme)),
        ],
      ),
    );
  }

  // ── Filtres ──────────────────────────────────────────────────────────────
  Widget _buildFiltres(ColorScheme scheme) {
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Semestre ──────────────────────────────────────────────────────
          Row(
            children: [
              _ChipFiltre(
                'Semestre 1',
                'S1',
                _semestre == 'S1',
                () => setState(() => _semestre = 'S1'),
                const Color(0xFF2A8A5C),
              ),
              const SizedBox(width: 8),
              _ChipFiltre(
                'Semestre 2',
                'S2',
                _semestre == 'S2',
                () => setState(() => _semestre = 'S2'),
                const Color(0xFF7B3FA0),
              ),
            ],
          ),

          if (_role != 'eleve') ...[
            const SizedBox(height: 10),

            // ── Filtre classe ─────────────────────────────────────────────────
            if (_role == 'enseignant' && _classesEnseignant.isNotEmpty)
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _filtreIdClasse != null
                          ? scheme.primary.withOpacity(0.5)
                          : scheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  child: DropdownButton<String>(
                    value:
                        _classesEnseignant.any(
                          (c) => c['id'] == _filtreIdClasse,
                        )
                        ? _filtreIdClasse
                        : null,
                    isExpanded: true,
                    hint: Text(
                      'Sélectionner une classe',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    style: TextStyle(fontSize: 13, color: scheme.onSurface),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Toutes mes classes',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      ..._classesEnseignant.map(
                        (c) => DropdownMenuItem(
                          value: c['id'],
                          child: Text(c['nom'] ?? ''),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      final nom = val == null
                          ? null
                          : _classesEnseignant.firstWhere(
                              (c) => c['id'] == val,
                            )['nom'];
                      _onClasseChanged(val, nom);
                    },
                  ),
                ),
              ),

            // Admin → filtre toutes classes
            if (_role == 'admin')
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classe')
                    .snapshots(),
                builder: (_, snap) {
                  final classes = snap.hasData
                      ? snap.data!.docs
                            .map(
                              (d) => {
                                'id': d.id,
                                'nom':
                                    (d.data() as Map)['nomClasse'] as String? ??
                                    '',
                              },
                            )
                            .toList()
                      : <Map<String, String>>[];
                  classes.sort((a, b) => a['nom']!.compareTo(b['nom']!));
                  return DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _filtreIdClasse != null
                              ? scheme.primary.withOpacity(0.5)
                              : scheme.outlineVariant.withOpacity(0.4),
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: classes.any((c) => c['id'] == _filtreIdClasse)
                            ? _filtreIdClasse
                            : null,
                        isExpanded: true,
                        hint: Text(
                          'Toutes les classes',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        style: TextStyle(fontSize: 13, color: scheme.onSurface),
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
                          ...classes.map(
                            (c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text(c['nom'] ?? ''),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          final nom = val == null
                              ? null
                              : classes.firstWhere(
                                  (c) => c['id'] == val,
                                )['nom'];
                          _onClasseChanged(val, nom);
                        },
                      ),
                    ),
                  );
                },
              ),

            // ── Filtre élève (si classe choisie) ─────────────────────────────
            if (_filtreIdClasse != null && _elevesClasse.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _filtreIdEleve != null
                          ? scheme.primary.withOpacity(0.5)
                          : scheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _elevesClasse.any((e) => e['id'] == _filtreIdEleve)
                        ? _filtreIdEleve
                        : null,
                    isExpanded: true,
                    hint: Text(
                      'Tous les élèves',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    style: TextStyle(fontSize: 13, color: scheme.onSurface),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Tous les élèves',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      ..._elevesClasse.map(
                        (e) => DropdownMenuItem(
                          value: e['id'],
                          child: Text(e['nom'] ?? ''),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() {
                      _filtreIdEleve = val;
                      _filtreNomEleve = val == null
                          ? null
                          : _elevesClasse.firstWhere(
                              (e) => e['id'] == val,
                            )['nom'];
                    }),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Contenu principal ─────────────────────────────────────────────────────
  Widget _buildContenu(ColorScheme scheme) {
    // Élève → bulletin personnel
    if (_role == 'eleve' && _filtreIdEleve != null) {
      return _BulletinEleve(
        idEleve: _filtreIdEleve!,
        nomEleve: _filtreNomEleve ?? '',
        semestre: _semestre,
      );
    }

    // Admin/Enseignant avec élève sélectionné → bulletin de cet élève
    if (_filtreIdEleve != null) {
      return _BulletinEleve(
        idEleve: _filtreIdEleve!,
        nomEleve: _filtreNomEleve ?? '',
        semestre: _semestre,
      );
    }

    // Admin/Enseignant avec classe sélectionnée → liste des élèves
    if (_filtreIdClasse != null && _elevesClasse.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _elevesClasse.length,
        itemBuilder: (_, i) {
          final e = _elevesClasse[i];
          return _EleveListItem(
            nom: e['nom'] ?? '',
            onTap: () => setState(() {
              _filtreIdEleve = e['id'];
              _filtreNomEleve = e['nom'];
            }),
          );
        },
      );
    }

    // Aucun filtre sélectionné
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 56,
              color: scheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 14),
            Text(
              _role == 'eleve'
                  ? 'Chargement...'
                  : 'Sélectionnez une classe pour voir les bulletins',
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
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BULLETIN D'UN ÉLÈVE
// ════════════════════════════════════════════════════════════════════════════
class _BulletinEleve extends StatelessWidget {
  final String idEleve, nomEleve, semestre;
  const _BulletinEleve({
    required this.idEleve,
    required this.nomEleve,
    required this.semestre,
  });

  static const _kBleu = Color(0xFF1A3A8F);
  static const _kVert = Color(0xFF2A8A5C);
  static const _kViolet = Color(0xFF7B3FA0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('note')
          .where('idEleve', isEqualTo: idEleve)
          .where('semestre', isEqualTo: semestre)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Center(
            child: CircularProgressIndicator(color: scheme.primary),
          );

        final notes = (snap.data?.docs ?? [])
            .map((d) => NoteModel.fromFirestore(d))
            .toList();

        if (notes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 56,
                    color: scheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Aucune note pour $nomEleve\nen $semestre',
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
        }

        // Calculer moyenne générale (pondérée par les moyennes matières)
        final moysMatieres = notes
            .map((n) => n.moyenneMatiere)
            .whereType<double>()
            .toList();
        final moyGeneral = moysMatieres.isEmpty
            ? null
            : moysMatieres.reduce((a, b) => a + b) / moysMatieres.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header bulletin ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kBleu,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomEleve,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            semestre == 'S1' ? 'Semestre 1' : 'Semestre 2',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (moyGeneral != null)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  NoteModel.fmt(moyGeneral),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  '/20',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _mention(moyGeneral),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Tableau des matières ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant.withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // En-tête tableau
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _kBleu.withOpacity(0.07),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Matière',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          _enteteCol('D1'),
                          _enteteCol('D2'),
                          _enteteCol('D3'),
                          _enteteCol('C1'),
                          _enteteCol('C2'),
                          _enteteCol('Moy.', bold: true),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withOpacity(0.4),
                    ),

                    ...notes.asMap().entries.map((entry) {
                      final i = entry.key;
                      final note = entry.value;
                      final moy = note.moyenneMatiere;
                      final col = note.mentionColor;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    note.matiere,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _cellNote(
                                  note.devoir1,
                                  const Color(0xFF1A6A9A),
                                ),
                                _cellNote(
                                  note.devoir2,
                                  const Color(0xFF1A6A9A),
                                ),
                                _cellNote(
                                  note.devoir3,
                                  const Color(0xFF1A6A9A),
                                ),
                                _cellNote(note.compo1, _kViolet),
                                _cellNote(note.compo2, _kViolet),
                                // Moyenne matière
                                SizedBox(
                                  width: 44,
                                  child: Center(
                                    child: moy == null
                                        ? Text(
                                            '—',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: scheme.onSurface
                                                  .withOpacity(0.4),
                                            ),
                                          )
                                        : Text(
                                            NoteModel.fmt(moy),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: col,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i < notes.length - 1)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: scheme.outlineVariant.withOpacity(0.3),
                            ),
                        ],
                      );
                    }),

                    // ── Ligne total ───────────────────────────────────────────────
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withOpacity(0.5),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Moyenne générale',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          SizedBox(width: 44),
                          SizedBox(width: 44),
                          SizedBox(width: 44),
                          SizedBox(width: 44),
                          SizedBox(width: 44),
                          SizedBox(
                            width: 44,
                            child: Center(
                              child: moyGeneral == null
                                  ? Text(
                                      '—',
                                      style: TextStyle(
                                        color: scheme.onSurface.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _couleurMoyenne(
                                          moyGeneral,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        NoteModel.fmt(moyGeneral),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _couleurMoyenne(moyGeneral),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Légende ───────────────────────────────────────────────────────
              _Legende(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _enteteCol(String txt, {bool bold = false}) => SizedBox(
    width: 44,
    child: Center(
      child: Text(
        txt,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: const Color(0xFF1A3A8F),
        ),
      ),
    ),
  );

  Widget _cellNote(double? val, Color color) => SizedBox(
    width: 44,
    child: Center(
      child: val == null
          ? Text('—', style: const TextStyle(fontSize: 11, color: Colors.grey))
          : Text(
              NoteModel.fmt(val),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
    ),
  );

  Color _couleurMoyenne(double moy) {
    if (moy >= 16) return const Color(0xFF2A8A5C);
    if (moy >= 12) return const Color(0xFF1A3A8F);
    if (moy >= 8) return const Color(0xFFC0692A);
    return const Color(0xFFD32F2F);
  }

  String _mention(double m) {
    if (m >= 16) return 'Très Bien';
    if (m >= 14) return 'Bien';
    if (m >= 12) return 'Assez Bien';
    if (m >= 10) return 'Passable';
    return 'Insuffisant';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LÉGENDE COEFFICIENTS
// ════════════════════════════════════════════════════════════════════════════
class _Legende extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coefficients',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegItem(
                'D1, D2, D3',
                'Devoirs',
                const Color(0xFF1A6A9A),
                'Coeff. 1',
              ),
              const SizedBox(width: 16),
              _LegItem(
                'C1, C2',
                'Compositions',
                const Color(0xFF7B3FA0),
                'Coeff. 2',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Formule : Moy. matière = (Moy.Devoirs × 1 + Moy.Compos × 2) / 3',
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegItem extends StatelessWidget {
  final String code, label, coeff;
  final Color color;
  const _LegItem(this.code, this.label, this.color, this.coeff);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$code ($label)',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(coeff, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    ],
  );
}

// ════════════════════════════════════════════════════════════════════════════
// ITEM ÉLÈVE DANS LA LISTE
// ════════════════════════════════════════════════════════════════════════════
class _EleveListItem extends StatelessWidget {
  final String nom;
  final VoidCallback onTap;
  const _EleveListItem({required this.nom, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF1A3A8F).withOpacity(0.1),
          child: Text(
            _initiales(nom),
            style: const TextStyle(
              color: Color(0xFF1A3A8F),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          nom,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: Icon(
          Icons.description_rounded,
          color: scheme.primary,
          size: 20,
        ),
      ),
    );
  }

  String _initiales(String nom) {
    final p = nom.trim().split(' ');
    if (p.length >= 2 && p[0].isNotEmpty && p[1].isNotEmpty)
      return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return nom.isNotEmpty ? nom[0].toUpperCase() : '?';
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
          _DItem(Icons.star_rounded, 'Notes', Routeur.routeNotes, false),
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
            true,
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
            false,
          ),
          _DItem(
            Icons.description_rounded,
            'Bulletins',
            Routeur.routeBulletin,
            true,
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
            false,
          ),
          _DItem(
            Icons.description_rounded,
            'Mon Bulletin',
            Routeur.routeBulletin,
            true,
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

// ────────────────────────────────────────────────────────────────────────────
class _ChipFiltre extends StatelessWidget {
  final String label;
  final String val;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
