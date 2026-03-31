// lib/views/page_bulletin.dart
// MODIFIÉ :
//   - Bulletin : affiche absences + retards (depuis collection 'absence')
//   - Bouton "Notifier" pour publier le bulletin (enqueue notification FCM)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/models/note_model.dart';
import 'package:gestion_ecole/view_model/absence_view_model.dart';

class PageBulletin extends StatefulWidget {
  const PageBulletin({super.key});
  @override
  State<PageBulletin> createState() => _PageBulletinState();
}

class _PageBulletinState extends State<PageBulletin> {
  String? _role, _uid;
  bool _roleCharge = false;
  String _semestre = 'S1';
  String? _filtreIdClasse, _filtreIdEleve, _filtreNomEleve;

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
        title: const Text('Bulletin de notes'),
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

  Widget _buildFiltres(ColorScheme scheme) {
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ChipFiltre(
                'Semestre 1',
                'S1',
                _semestre == 'S1',
                () => setState(() {
                  _semestre = 'S1';
                  if (_role == 'eleve')
                    _filtreIdEleve = FirebaseAuth.instance.currentUser?.uid;
                }),
                const Color(0xFF2A8A5C),
              ),
              const SizedBox(width: 8),
              _ChipFiltre(
                'Semestre 2',
                'S2',
                _semestre == 'S2',
                () => setState(() {
                  _semestre = 'S2';
                  if (_role == 'eleve')
                    _filtreIdEleve = FirebaseAuth.instance.currentUser?.uid;
                }),
                const Color(0xFF7B3FA0),
              ),
            ],
          ),

          if (_role != 'eleve') ...[
            const SizedBox(height: 10),
            if (_role == 'enseignant' && _classesEnseignant.isNotEmpty)
              _dropdownBox(
                scheme: scheme,
                actif: _filtreIdClasse != null,
                child: DropdownButton<String>(
                  value:
                      _classesEnseignant.any((c) => c['id'] == _filtreIdClasse)
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
                  return _dropdownBox(
                    scheme: scheme,
                    actif: _filtreIdClasse != null,
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
                            : classes.firstWhere((c) => c['id'] == val)['nom'];
                        _onClasseChanged(val, nom);
                      },
                    ),
                  );
                },
              ),

            if (_filtreIdClasse != null && _elevesClasse.isNotEmpty) ...[
              const SizedBox(height: 8),
              _dropdownBox(
                scheme: scheme,
                actif: _filtreIdEleve != null,
                child: DropdownButton<String>(
                  value: _elevesClasse.any((e) => e['id'] == _filtreIdEleve)
                      ? _filtreIdEleve
                      : null,
                  isExpanded: true,
                  hint: Text(
                    'Sélectionner un élève',
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
            ],
          ],
        ],
      ),
    );
  }

  Widget _dropdownBox({
    required ColorScheme scheme,
    required bool actif,
    required Widget child,
  }) => DropdownButtonHideUnderline(
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
      child: child,
    ),
  );

  Widget _buildContenu(ColorScheme scheme) {
    if (_filtreIdEleve != null) {
      return _BulletinEleve(
        idEleve: _filtreIdEleve!,
        nomEleve: _filtreNomEleve ?? '',
        semestre: _semestre,
        role: _role ?? 'eleve',
      );
    }
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
                  : 'Sélectionnez une classe pour afficher les bulletins',
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
// BULLETIN D'UN ÉLÈVE — MODIFIÉ : absences + retards + bouton notifier
// ════════════════════════════════════════════════════════════════════════════
class _BulletinEleve extends StatefulWidget {
  final String idEleve, nomEleve, semestre, role;
  const _BulletinEleve({
    required this.idEleve,
    required this.nomEleve,
    required this.semestre,
    required this.role,
  });
  @override
  State<_BulletinEleve> createState() => _BulletinEleveState();
}

class _BulletinEleveState extends State<_BulletinEleve> {
  int _nbAbsences = 0;
  int _nbRetards = 0;
  bool _notifEnvoyee = false;

  @override
  void initState() {
    super.initState();
    _chargerAbsences();
  }

  @override
  void didUpdateWidget(_BulletinEleve old) {
    super.didUpdateWidget(old);
    if (old.idEleve != widget.idEleve || old.semestre != widget.semestre)
      _chargerAbsences();
  }

  Future<void> _chargerAbsences() async {
    final snap = await FirebaseFirestore.instance
        .collection('absence')
        .where('idEleve', isEqualTo: widget.idEleve)
        .get();
    int abs = 0, ret = 0;
    for (final doc in snap.docs) {
      final type = (doc.data())['type'] as String?;
      if (type == 'retard')
        ret++;
      else
        abs++;
    }
    if (mounted)
      setState(() {
        _nbAbsences = abs;
        _nbRetards = ret;
      });
  }

  Future<void> _notifierEleve() async {
    await FirebaseFirestore.instance.collection('notifications_queue').add({
      'destinataireId': widget.idEleve,
      'titre': '📄 Bulletin disponible',
      'corps':
          'Votre bulletin du ${widget.semestre == 'S1' ? '1er' : '2ème'} semestre est disponible.',
      'type': 'bulletin',
      'data': {'semestre': widget.semestre},
      'envoye': false,
      'dateCreation': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      setState(() => _notifEnvoyee = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification envoyée ✓'),
          backgroundColor: Color(0xFF2A8A5C),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
        ),
      );
    }
  }

  static const _kBleu = Color(0xFF1A3A8F);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('note')
          .where('idEleve', isEqualTo: widget.idEleve)
          .where('semestre', isEqualTo: widget.semestre)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Center(
            child: CircularProgressIndicator(color: scheme.primary),
          );

        final notes =
            (snap.data?.docs ?? [])
                .map((d) => NoteModel.fromFirestore(d))
                .toList()
              ..sort((a, b) => a.matiere.compareTo(b.matiere));

        if (notes.isEmpty)
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
                    'Aucune note pour ${widget.nomEleve}\nen ${widget.semestre}',
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

        double sommeCoeff = 0, sommePonderee = 0;
        for (final n in notes) {
          final mp = n.moyennePonderee;
          if (mp != null) {
            sommeCoeff += n.coefficient;
            sommePonderee += mp;
          }
        }
        final moyGeneral = sommeCoeff > 0 ? sommePonderee / sommeCoeff : null;
        final totalCoeff = notes.fold<double>(0, (s, n) => s + n.coefficient);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              _buildHeader(scheme),
              const SizedBox(height: 12),

              // ── Tableau ───────────────────────────────────────────────────
              _buildTableau(
                scheme,
                notes,
                totalCoeff,
                sommePonderee,
                moyGeneral,
              ),
              const SizedBox(height: 12),

              // ── Absences & Retards ────────────────────────────────────────
              _buildAbsencesRetards(scheme),
              const SizedBox(height: 12),

              // ── Appréciations ─────────────────────────────────────────────
              if (moyGeneral != null) _buildAppreciations(scheme, moyGeneral),
              const SizedBox(height: 12),

              // ── Bouton Notifier (admin/enseignant seulement) ───────────────
              if (widget.role != 'eleve')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _notifEnvoyee ? null : _notifierEleve,
                    icon: Icon(
                      _notifEnvoyee
                          ? Icons.check_rounded
                          : Icons.notifications_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _notifEnvoyee
                          ? 'Notification envoyée ✓'
                          : 'Notifier l\'élève',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _notifEnvoyee
                          ? const Color(0xFF2A8A5C)
                          : _kBleu,
                      side: BorderSide(
                        color: _notifEnvoyee ? const Color(0xFF2A8A5C) : _kBleu,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              _buildLegende(scheme),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(ColorScheme scheme) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kBleu,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.nomEleve,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.semestre == 'S1' ? '1er Semestre' : '2ème Semestre',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    ),
  );

  // ── Absences & Retards ─────────────────────────────────────────────────────
  Widget _buildAbsencesRetards(ColorScheme scheme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        // Absences
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Colors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_nbAbsences',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'Absences',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: scheme.outlineVariant.withOpacity(0.4),
        ),
        // Retards
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0692A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFFC0692A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_nbRetards',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC0692A),
                      ),
                    ),
                    Text(
                      'Retards',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── Tableau ─────────────────────────────────────────────────────────────────
  Widget _buildTableau(
    ColorScheme scheme,
    List<NoteModel> notes,
    double totalCoeff,
    double totalPondere,
    double? moyGeneral,
  ) {
    const wMat = 110.0, wNum = 48.0, wApprec = 108.0;
    const headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 11,
      color: Colors.white,
    );
    Color rowColor(int i) =>
        i.isEven ? scheme.surface : scheme.onSurface.withOpacity(0.03);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: _kBleu,
              child: Row(
                children: [
                  _hCell('DISCIPLINES', wMat, headerStyle, left: true),
                  _hCell('Devoir', wNum, headerStyle),
                  _hCell('Comp', wNum, headerStyle),
                  _hCell('Moy/20', wNum, headerStyle),
                  _hCell('Coef', wNum, headerStyle),
                  _hCell('Moy×C', wNum, headerStyle),
                  _hCell('Appréciations', wApprec, headerStyle),
                ],
              ),
            ),
            ...notes.asMap().entries.map((entry) {
              final i = entry.key;
              final n = entry.value;
              final moy = n.moyenneMatiere;
              final pond = n.moyennePonderee;
              final col = _couleurNote(moy);
              return Container(
                color: rowColor(i),
                child: Row(
                  children: [
                    _dCell(
                      n.matiere,
                      wMat,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      left: true,
                    ),
                    _dCell(
                      NoteModel.fmt(n.moyenneDevoirs),
                      wNum,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A6A9A),
                      ),
                    ),
                    _dCell(
                      NoteModel.fmt(n.compo),
                      wNum,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B3FA0),
                      ),
                    ),
                    _dCell(
                      NoteModel.fmt(moy),
                      wNum,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: col,
                      ),
                    ),
                    _dCell(
                      NoteModel.fmt(n.coefficient),
                      wNum,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC0692A),
                      ),
                    ),
                    _dCell(
                      NoteModel.fmt(pond),
                      wNum,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: col,
                      ),
                    ),
                    _dCell(
                      n.appreciation,
                      wApprec,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: col,
                      ),
                    ),
                  ],
                ),
              );
            }),
            Divider(height: 1, color: _kBleu.withOpacity(0.3)),
            Container(
              color: _kBleu.withOpacity(0.06),
              child: Row(
                children: [
                  _dCell(
                    'TOTAL',
                    wMat,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    left: true,
                  ),
                  _dCell('', wNum),
                  _dCell('', wNum),
                  _dCell('', wNum),
                  _dCell(
                    NoteModel.fmt(totalCoeff),
                    wNum,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFC0692A),
                    ),
                  ),
                  _dCell(
                    NoteModel.fmt(totalPondere),
                    wNum,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  _dCell('', wApprec),
                ],
              ),
            ),
            Container(
              color: _kBleu.withOpacity(0.11),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: wMat,
                    child: const Text(
                      'Moyenne',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _couleurNote(moyGeneral).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _couleurNote(moyGeneral).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      moyGeneral != null
                          ? '${NoteModel.fmt(moyGeneral)} / 20'
                          : '— / 20',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _couleurNote(moyGeneral),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (moyGeneral != null)
                    Text(
                      _appreciation(moyGeneral),
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _couleurNote(moyGeneral),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppreciations(ColorScheme scheme, double moy) {
    final gauche = [
      {'label': 'Satisfaisant doit continuer', 'actif': moy >= 12},
      {'label': 'Peut Mieux Faire', 'actif': moy >= 8 && moy < 12},
      {'label': 'Insuffisant', 'actif': moy < 8},
      {'label': 'Risque de Redoubler', 'actif': moy < 8},
      {'label': "Risque l'exclusion", 'actif': false},
    ];
    final droite = [
      {'label': 'Félicitations', 'actif': moy >= 16},
      {'label': 'Encouragement', 'actif': moy >= 14 && moy < 16},
      {'label': "Tableau d'honneur", 'actif': moy >= 12 && moy < 14},
      {'label': 'Avertissement', 'actif': moy < 8},
      {'label': 'Blâme', 'actif': false},
    ];
    Widget case_(Map<String, dynamic> item) => Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.4)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item['label'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: (item['actif'] as bool)
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.7)),
            ),
            child: (item['actif'] as bool)
                ? const Center(
                    child: Text(
                      'X',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(children: gauche.map(case_).toList()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(children: droite.map(case_).toList()),
          ),
        ),
      ],
    );
  }

  Widget _buildLegende(ColorScheme scheme) => Container(
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
          'Formules de calcul',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        _leg('Devoir = (D1 + D2) / 2', const Color(0xFF1A6A9A)),
        const SizedBox(height: 4),
        _leg('Moy/20 = (Devoir + Comp) / 2', const Color(0xFF7B3FA0)),
        const SizedBox(height: 4),
        _leg('Moy×C = Moy/20 × Coefficient', const Color(0xFFC0692A)),
        const SizedBox(height: 4),
        _leg('Moyenne = Σ(Moy×C) ÷ Σ(Coefficients)', const Color(0xFF1A3A8F)),
      ],
    ),
  );

  Widget _leg(String txt, Color color) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          txt,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ],
  );

  Widget _hCell(String txt, double w, TextStyle style, {bool left = false}) =>
      Container(
        width: w,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          txt,
          textAlign: left ? TextAlign.left : TextAlign.center,
          style: style,
        ),
      );

  Widget _dCell(String txt, double w, {TextStyle? style, bool left = false}) =>
      Container(
        width: w,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Text(
          txt,
          textAlign: left ? TextAlign.left : TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style:
              style ??
              TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.5)),
        ),
      );

  Color _couleurNote(double? m) {
    if (m == null) return Colors.grey;
    if (m >= 16) return const Color(0xFF2A8A5C);
    if (m >= 12) return const Color(0xFF1A3A8F);
    if (m >= 8) return const Color(0xFFC0692A);
    return const Color(0xFFD32F2F);
  }

  String _appreciation(double m) {
    if (m >= 18) return 'Excellent travail';
    if (m >= 16) return 'Très Bon Travail';
    if (m >= 14) return 'Bon Travail';
    if (m >= 12) return 'A. Bien';
    if (m >= 10) return 'Passable';
    if (m >= 8) return 'Insuffisant';
    return 'Très Insuffisant';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ITEM ÉLÈVE
// ════════════════════════════════════════════════════════════════════════════
class _EleveListItem extends StatelessWidget {
  final String nom;
  final VoidCallback onTap;
  const _EleveListItem({required this.nom, required this.onTap});
  String _initiales(String n) {
    final p = n.trim().split(' ');
    if (p.length >= 2 && p[0].isNotEmpty && p[1].isNotEmpty)
      return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

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
        trailing: const Icon(
          Icons.description_rounded,
          color: Color(0xFF1A3A8F),
          size: 20,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DRAWER & HELPERS
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

class _ChipFiltre extends StatelessWidget {
  final String label, val;
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
