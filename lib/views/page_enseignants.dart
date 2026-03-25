// lib/views/page_enseignants.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/models/enseignant_model.dart';
import 'package:gestion_ecole/view_model/enseignant_view_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// PAGE LISTE DES ENSEIGNANTS
// ════════════════════════════════════════════════════════════════════════════
class PageEnseignants extends StatefulWidget {
  const PageEnseignants({super.key});

  @override
  State<PageEnseignants> createState() => _PageEnseignantsState();
}

class _PageEnseignantsState extends State<PageEnseignants> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.watch<EnseignantViewModel>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Enseignants'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      drawer: const _DrawerAdmin(),
      body: Column(
        children: [
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _q = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Rechercher un enseignant...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _q = ''),
                      )
                    : null,
                filled: true,
                fillColor: scheme.onSurface.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EnseignantModel>>(
              stream: vm.streamEnseignants,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: scheme.primary));
                }
                if (snap.hasError) {
                  return _vide(context, Icons.error_outline_rounded,
                      'Erreur de chargement', scheme.error);
                }
                final list = (snap.data ?? [])
                    .where((e) =>
                        _q.isEmpty || e.nomComplet.toLowerCase().contains(_q))
                    .toList();

                if (list.isEmpty) {
                  return _vide(
                    context,
                    Icons.person_off_outlined,
                    _q.isEmpty
                        ? 'Aucun enseignant.\nAppuyez sur + pour en ajouter.'
                        : 'Aucun résultat pour "$_q"',
                    scheme.onSurface.withOpacity(0.35),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _EnseignantCard(enseignant: list[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FormulaireEnseignant())),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _vide(BuildContext ctx, IconData icon, String msg, Color color) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 14),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 14)),
          ]),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// CARD ENSEIGNANT — tap → page détail
// ════════════════════════════════════════════════════════════════════════════
class _EnseignantCard extends StatelessWidget {
  final EnseignantModel enseignant;
  const _EnseignantCard({required this.enseignant});

  static const kColor = Color(0xFF2A8A5C);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.read<EnseignantViewModel>();

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
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Tap sur la card → page détail
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PageDetailEnseignant(enseignant: enseignant)),
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: kColor.withOpacity(0.12),
          child: Text(enseignant.initiales,
              style: const TextStyle(
                  color: kColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        title: Text(enseignant.nomComplet,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(enseignant.email,
              style: TextStyle(
                  fontSize: 12, color: scheme.onSurface.withOpacity(0.55))),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Modifier',
              icon: Icon(Icons.edit_rounded, size: 20, color: scheme.primary),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          FormulaireEnseignant(enseignant: enseignant))),
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: Icon(Icons.delete_rounded, size: 20, color: scheme.error),
              onPressed: () => _confirmerSuppression(context, vm),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, EnseignantViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer l\'enseignant ?'),
        content: Text('${enseignant.nomComplet} sera supprimé définitivement.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.supprimer(enseignant.id!);
              if (context.mounted)
                _snack(
                    context,
                    ok ? 'Enseignant supprimé' : vm.erreur ?? 'Erreur',
                    ok ? scheme.error : Colors.orange);
            },
            child:
                Text('Supprimer', style: TextStyle(color: scheme.onError)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE DÉTAIL ENSEIGNANT (accessible admin + élève)
// ════════════════════════════════════════════════════════════════════════════
class PageDetailEnseignant extends StatelessWidget {
  final EnseignantModel enseignant;
  /// Si true → pas de bouton modifier/supprimer (vue élève)
  final bool lectureSeule;

  const PageDetailEnseignant({
    super.key,
    required this.enseignant,
    this.lectureSeule = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Fiche enseignant'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        actions: lectureSeule
            ? null
            : [
                IconButton(
                  tooltip: 'Modifier',
                  icon: Icon(Icons.edit_rounded, color: scheme.primary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            FormulaireEnseignant(enseignant: enseignant)),
                  ),
                ),
              ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
              color: scheme.primary,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: scheme.onPrimary.withOpacity(0.5), width: 2.5),
                    ),
                    child: Center(
                      child: Text(enseignant.initiales,
                          style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(enseignant.nomComplet,
                      style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(enseignant.email,
                      style: TextStyle(
                          color: scheme.onPrimary.withOpacity(0.8),
                          fontSize: 13)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: scheme.onPrimary.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: scheme.onPrimary, size: 14),
                        const SizedBox(width: 6),
                        Text('ENSEIGNANT',
                            style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Coordonnées ──────────────────────────────────────────
                  _SectionCard(
                    titre: 'Coordonnées',
                    icone: Icons.contact_phone_rounded,
                    items: [
                      _InfoItem(Icons.phone_rounded, 'Téléphone',
                          enseignant.telephone),
                      _InfoItem(Icons.location_on_rounded, 'Adresse',
                          enseignant.adresse),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Enseignements ─────────────────────────────────────────
                  _EnseignementsCard(idEnseignant: enseignant.id!),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte section générique ───────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String titre;
  final IconData icone;
  final List<_InfoItem> items;
  const _SectionCard(
      {required this.titre, required this.icone, required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icone, size: 15, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Text(titre,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: scheme.primary)),
            ]),
          ),
          Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.4)),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(item.icon, size: 18, color: scheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurface.withOpacity(0.5))),
                          const SizedBox(height: 2),
                          Text(item.value.isEmpty ? '—' : item.value,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ]),
                ),
                if (i < items.length - 1)
                  Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                      color: scheme.outlineVariant.withOpacity(0.3)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label, value;
  const _InfoItem(this.icon, this.label, this.value);
}

// ── Carte enseignements de l'enseignant ───────────────────────────────────
class _EnseignementsCard extends StatelessWidget {
  final String idEnseignant;
  const _EnseignementsCard({required this.idEnseignant});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child:
                    Icon(Icons.school_rounded, size: 15, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Text('Enseignements',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: scheme.primary)),
            ]),
          ),
          Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.4)),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('enseignement')
                .where('idEnseignant', isEqualTo: idEnseignant)
                .snapshots(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: scheme.primary, strokeWidth: 2)),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18,
                        color: scheme.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 10),
                    Text('Aucun enseignement assigné',
                        style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.5),
                            fontSize: 13)),
                  ]),
                );
              }

              // Grouper par année scolaire
              final Map<String, List<Map<String, dynamic>>> parAnnee = {};
              for (final doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final annee = d['anneeScolaire'] as String? ?? '—';
                parAnnee.putIfAbsent(annee, () => []).add(d);
              }
              final annees = parAnnee.keys.toList()..sort((a, b) => b.compareTo(a));

              return Column(
                children: [
                  for (final annee in annees) ...[
                    // Sous-titre année
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: scheme.primary.withOpacity(0.05),
                      child: Text(annee,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.primary)),
                    ),
                    ...parAnnee[annee]!.asMap().entries.map((entry) {
                      final d = entry.value;
                      final matiere = d['matiere'] as String? ?? '';
                      final nomClasse = d['nomClasse'] as String? ?? '';
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF7B3FA0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.book_rounded,
                                  size: 18, color: Color(0xFF7B3FA0)),
                            ),
                            title: Text(matiere,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(nomClasse,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurface.withOpacity(0.55))),
                          ),
                          if (entry.key < parAnnee[annee]!.length - 1)
                            Divider(
                                height: 1,
                                indent: 68,
                                endIndent: 16,
                                color: scheme.outlineVariant.withOpacity(0.3)),
                        ],
                      );
                    }),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FORMULAIRE AJOUT / MODIFICATION — avec gestion email existant
// ════════════════════════════════════════════════════════════════════════════
class FormulaireEnseignant extends StatefulWidget {
  final EnseignantModel? enseignant;
  const FormulaireEnseignant({super.key, this.enseignant});

  @override
  State<FormulaireEnseignant> createState() => _FormulaireEnseignantState();
}

class _FormulaireEnseignantState extends State<FormulaireEnseignant> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nom;
  late final TextEditingController _email;
  late final TextEditingController _motPasse;
  late final TextEditingController _telephone;
  late final TextEditingController _adresse;
  late final TextEditingController _anneeScolaire;

  bool _motPasseVisible = false;
  bool get _estModif => widget.enseignant != null;

  final List<Map<String, String>> _enseignements = [];
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    final e = widget.enseignant;
    _nom = TextEditingController(text: e?.nomComplet ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _motPasse = TextEditingController();
    _telephone = TextEditingController(text: e?.telephone ?? '');
    _adresse = TextEditingController(text: e?.adresse ?? '');
    _anneeScolaire = TextEditingController();
    _chargerClasses();
    if (_estModif) _chargerEnseignementsExistants();
  }

  @override
  void dispose() {
    for (final c in [_nom, _email, _motPasse, _telephone, _adresse, _anneeScolaire])
      c.dispose();
    super.dispose();
  }

  Future<void> _chargerClasses() async {
    final snap = await FirebaseFirestore.instance.collection('classe').get();
    if (mounted)
      setState(() {
        _classes = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList()
          ..sort((a, b) =>
              (a['nomClasse'] as String).compareTo(b['nomClasse'] as String));
      });
  }

  Future<void> _chargerEnseignementsExistants() async {
    final snap = await FirebaseFirestore.instance
        .collection('enseignement')
        .where('idEnseignant', isEqualTo: widget.enseignant!.id)
        .get();
    if (mounted && snap.docs.isNotEmpty) {
      setState(() {
        for (final doc in snap.docs) {
          final d = doc.data();
          _enseignements.add({
            'docId': doc.id,
            'matiere': d['matiere'] ?? '',
            'idClasse': d['idClasse'] ?? '',
            'nomClasse': d['nomClasse'] ?? '',
            'annee': d['anneeScolaire'] ?? '',
          });
        }
        if (snap.docs.isNotEmpty) {
          _anneeScolaire.text =
              snap.docs.first.data()['anneeScolaire'] ?? '';
        }
      });
    }
  }

  void _ajouterEnseignement() {
    if (_classes.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) {
        String? idCls, nomCls, nomMat;
        return StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Ajouter un enseignement'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('matiere')
                      .orderBy('nom')
                      .snapshots(),
                  builder: (_, snap) {
                    final matieres = snap.hasData
                        ? snap.data!.docs
                            .map((d) =>
                                (d.data() as Map<String, dynamic>)['nom']
                                    as String)
                            .toList()
                        : <String>[];
                    return DropdownButtonFormField<String>(
                      value: matieres.contains(nomMat) ? nomMat : null,
                      decoration: InputDecoration(
                        labelText: 'Matière',
                        prefixIcon:
                            const Icon(Icons.book_rounded, size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: matieres
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) => setDlg(() => nomMat = val),
                    );
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: idCls,
                  decoration: InputDecoration(
                    labelText: 'Classe',
                    prefixIcon: const Icon(Icons.class_rounded, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _classes
                      .map((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(c['nomClasse'] as String),
                          ))
                      .toList(),
                  onChanged: (val) => setDlg(() {
                    idCls = val;
                    nomCls = _classes
                        .firstWhere((c) => c['id'] == val)['nomClasse']
                        as String;
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler')),
              FilledButton(
                onPressed: () {
                  if (nomMat == null || idCls == null) return;
                  setState(() => _enseignements.add({
                        'matiere': nomMat!,
                        'idClasse': idCls!,
                        'nomClasse': nomCls!,
                        'annee': _anneeScolaire.text.trim(),
                      }));
                  Navigator.pop(ctx);
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_enseignements.isEmpty) {
      _snack(context, 'Ajoutez au moins un enseignement', Colors.orange);
      return;
    }

    final vm = context.read<EnseignantViewModel>();
    final model = EnseignantModel(
      nomComplet: _nom.text.trim(),
      email: _email.text.trim(),
      telephone: _telephone.text.trim(),
      adresse: _adresse.text.trim(),
    );

    bool ok;
    String idEnseignant;

    if (_estModif) {
      ok = await vm.modifier(widget.enseignant!.id!, model);
      idEnseignant = widget.enseignant!.id!;
      if (ok) {
        final oldSnap = await FirebaseFirestore.instance
            .collection('enseignement')
            .where('idEnseignant', isEqualTo: idEnseignant)
            .get();
        for (final doc in oldSnap.docs) await doc.reference.delete();
        for (final e in _enseignements) {
          await FirebaseFirestore.instance.collection('enseignement').add({
            'idEnseignant': idEnseignant,
            'nomEnseignant': model.nomComplet,
            'idClasse': e['idClasse'],
            'nomClasse': e['nomClasse'],
            'matiere': e['matiere'],
            'anneeScolaire': _anneeScolaire.text.trim(),
            'dateCreation': FieldValue.serverTimestamp(),
          });
        }
      }
    } else {
      ok = await vm.ajouter(model, motPasse: _motPasse.text.trim());
      if (ok) {
        final snap = await FirebaseFirestore.instance
            .collection('utilisateur')
            .where('email', isEqualTo: _email.text.trim())
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          idEnseignant = snap.docs.first.id;
          for (final e in _enseignements) {
            await FirebaseFirestore.instance.collection('enseignement').add({
              'idEnseignant': idEnseignant,
              'nomEnseignant': model.nomComplet,
              'idClasse': e['idClasse'],
              'nomClasse': e['nomClasse'],
              'matiere': e['matiere'],
              'anneeScolaire': _anneeScolaire.text.trim(),
              'dateCreation': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    }

    if (mounted) {
      // Afficher l'erreur spécifique email existant
      final errMsg = ok
          ? null
          : _emailExistantMessage(vm.erreur ?? '');
      _snack(
          context,
          ok
              ? (_estModif ? 'Enseignant modifié ✓' : 'Enseignant ajouté ✓')
              : errMsg ?? vm.erreur ?? 'Erreur',
          ok ? Colors.green : Colors.red);
      if (ok) Navigator.pop(context);
    }
  }

  /// Traduit les codes Firebase Auth en messages lisibles
  String _emailExistantMessage(String raw) {
    if (raw.contains('email-already-in-use') ||
        raw.contains('email-already-exists') ||
        raw.contains('Email déjà utilisé')) {
      return 'Cet email est déjà utilisé par un autre compte.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.watch<EnseignantViewModel>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(_estModif
            ? 'Modifier l\'enseignant'
            : 'Ajouter un enseignant'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitre('Informations personnelles', Icons.person_rounded),
              const SizedBox(height: 14),

              _Champ(ctrl: _nom, label: 'Nom complet', icon: Icons.badge_rounded),
              const SizedBox(height: 12),
              _Champ(
                ctrl: _email,
                label: 'Email',
                icon: Icons.email_rounded,
                type: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Email invalide' : null,
              ),
              const SizedBox(height: 12),

              if (!_estModif) ...[
                TextFormField(
                  controller: _motPasse,
                  obscureText: !_motPasseVisible,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_motPasseVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded, size: 20),
                      onPressed: () =>
                          setState(() => _motPasseVisible = !_motPasseVisible),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              _Champ(
                  ctrl: _telephone,
                  label: 'Téléphone',
                  icon: Icons.phone_rounded,
                  type: TextInputType.phone),
              const SizedBox(height: 12),
              _Champ(
                  ctrl: _adresse,
                  label: 'Adresse',
                  icon: Icons.location_on_rounded,
                  lines: 2),
              const SizedBox(height: 24),

              _SectionTitre('Enseignements', Icons.school_rounded),
              const SizedBox(height: 8),

              _Champ(
                ctrl: _anneeScolaire,
                label: 'Année scolaire',
                icon: Icons.calendar_today_rounded,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Année scolaire requise' : null,
              ),
              const SizedBox(height: 12),

              ..._enseignements.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: scheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['matiere'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(e['nomClasse'] ?? '',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded,
                          color: scheme.error, size: 20),
                      onPressed: () =>
                          setState(() => _enseignements.removeAt(i)),
                    ),
                  ]),
                );
              }),

              OutlinedButton.icon(
                onPressed: _classes.isEmpty ? null : _ajouterEnseignement,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter un enseignement'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              if (_classes.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, Routeur.routeClasses),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Créer une classe d\'abord'),
                  ),
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
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          _estModif
                              ? 'Enregistrer les modifications'
                              : 'Ajouter l\'enseignant',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DRAWER ADMIN
// ════════════════════════════════════════════════════════════════════════════
class _DrawerAdmin extends StatelessWidget {
  const _DrawerAdmin();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: scheme.surface,
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          color: scheme.primary,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.onPrimary.withOpacity(0.2),
              child: Icon(Icons.admin_panel_settings_rounded,
                  color: scheme.onPrimary, size: 28),
            ),
            const SizedBox(height: 12),
            Text('Administrateur',
                style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(user?.email ?? '',
                style: TextStyle(
                    color: scheme.onPrimary.withOpacity(0.8), fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            children: [
              _DItem(Icons.dashboard_rounded, 'Tableau de bord',
                  Routeur.routeAccueil, false),
              const _DLabel('GESTION'),
              _DItem(Icons.school_rounded, 'Élèves', Routeur.routeEleves, false),
              _DItem(Icons.person_rounded, 'Enseignants',
                  Routeur.routeEnseignants, true),
              _DItem(Icons.class_rounded, 'Classes', Routeur.routeClasses, false),
              _DItem(Icons.book_rounded, 'Matières', Routeur.routeMatieres, false),
              _DItem(Icons.star_rounded, 'Notes', Routeur.routeNotes, false),
              _DItem(Icons.event_busy_rounded, 'Absences',
                  Routeur.routeAbsences, false),
              Divider(height: 20, color: scheme.outlineVariant.withOpacity(0.4)),
              _DItem(Icons.person_outline_rounded, 'Mon Profil',
                  Routeur.routeProfil, false),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Material(
            color: scheme.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Déconnexion'),
                    content:
                        const Text('Voulez-vous vraiment vous déconnecter ?'),
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
                if (confirm == true && context.mounted) {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted)
                    Navigator.pushReplacementNamed(
                        context, Routeur.routeInitial);
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Icon(Icons.logout_rounded, color: scheme.error, size: 20),
                  const SizedBox(width: 12),
                  Text('Déconnexion',
                      style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              Icon(icon,
                  size: 20,
                  color: isActive
                      ? scheme.primary
                      : scheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 14),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? scheme.primary
                          : scheme.onSurface.withOpacity(0.85))),
              if (isActive) ...[
                const Spacer(),
                Container(
                    width: 5,
                    height: 5,
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
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4))),
      );
}

class _SectionTitre extends StatelessWidget {
  final String titre;
  final IconData icon;
  const _SectionTitre(this.titre, this.icon);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: scheme.primary),
      ),
      const SizedBox(width: 10),
      Text(titre,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: scheme.primary)),
    ]);
  }
}

class _Champ extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  final int lines;
  final String? Function(String?)? validator;

  const _Champ({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.type = TextInputType.text,
    this.lines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator ??
            (v) => (v == null || v.isEmpty) ? '$label requis' : null,
      );
}

void _snack(BuildContext ctx, String msg, Color color) =>
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));