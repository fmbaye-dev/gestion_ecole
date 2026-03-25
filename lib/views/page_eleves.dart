// lib/views/page_eleves.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/models/eleve_model.dart';
import 'package:gestion_ecole/view_model/eleve_view_model.dart';
import 'package:gestion_ecole/view_model/classe_view_model.dart';
import 'package:gestion_ecole/models/note_model.dart';
import 'package:gestion_ecole/models/absence_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// PAGE ÉLÈVES
// ════════════════════════════════════════════════════════════════════════════
class PageEleves extends StatefulWidget {
  const PageEleves({super.key});
  @override
  State<PageEleves> createState() => _PageElevesState();
}

class _PageElevesState extends State<PageEleves> {
  String _q = '';

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
    final vm = context.watch<EleveViewModel>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Élèves'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      drawer: _DrawerAdmin(onDeconnexion: _deconnexion),
      body: Column(
        children: [
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _q = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Rechercher un élève...',
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
            child: StreamBuilder<List<EleveModel>>(
              stream: vm.streamEleves,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: scheme.primary),
                  );
                }
                final list = (snap.data ?? [])
                    .where(
                      (e) =>
                          _q.isEmpty || e.nomComplet.toLowerCase().contains(_q),
                    )
                    .toList();
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 56,
                            color: scheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _q.isEmpty
                                ? 'Aucun élève.\nAppuyez sur + pour en ajouter.'
                                : 'Aucun résultat pour "$_q"',
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
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _EleveCard(eleve: list[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormulaireEleve()),
        ),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CARD ÉLÈVE — tap → détail
// ════════════════════════════════════════════════════════════════════════════
class _EleveCard extends StatelessWidget {
  final EleveModel eleve;
  const _EleveCard({required this.eleve});
  static const _kColor = Color(0xFF7B3FA0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.read<EleveViewModel>();

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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // ── Tap → Page Détail ───────────────────────────────────────────
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PageDetailEleve(eleve: eleve)),
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: _kColor.withOpacity(0.12),
          child: Text(
            eleve.initiales,
            style: const TextStyle(
              color: _kColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        title: Text(
          eleve.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              eleve.email,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.55),
              ),
            ),
            if (eleve.nomClasse.isNotEmpty)
              Text(
                eleve.nomClasse,
                style: TextStyle(
                  fontSize: 11,
                  color: _kColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
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
                  builder: (_) => FormulaireEleve(eleve: eleve),
                ),
              ),
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

  void _confirmerSuppression(BuildContext context, EleveViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer l\'élève ?'),
        content: Text(
          '${eleve.nomComplet} sera supprimé définitivement.\n\nSes notes et absences seront également supprimées.',
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
              final ok = await vm.supprimer(eleve.id!);
              if (context.mounted)
                _snack(
                  context,
                  ok ? 'Élève supprimé' : vm.erreur ?? 'Erreur',
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
// PAGE DÉTAIL ÉLÈVE — admin ET enseignant
// ════════════════════════════════════════════════════════════════════════════
class PageDetailEleve extends StatelessWidget {
  final EleveModel eleve;
  const PageDetailEleve({super.key, required this.eleve});

  static const _kViolet = Color(0xFF7B3FA0);
  static const _kBleu = Color(0xFF1A3A8F);
  static const _kVert = Color(0xFF2A8A5C);
  static const _kOrange = Color(0xFFC0692A);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(eleve.nomComplet),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        actions: [
          // Modifier (admin seulement — l'enseignant voit en lecture seule)
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('utilisateur')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get(),
            builder: (_, snap) {
              final role =
                  (snap.data?.data() as Map<String, dynamic>?)?['role'] ?? '';
              if (role != 'admin') return const SizedBox();
              return IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormulaireEleve(eleve: eleve),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _carteIdentite(scheme),
            const SizedBox(height: 16),
            _sectionTitre('Notes', Icons.star_rounded, _kBleu),
            const SizedBox(height: 10),
            _buildNotes(context, scheme),
            const SizedBox(height: 16),
            _sectionTitre('Absences', Icons.event_busy_rounded, _kOrange),
            const SizedBox(height: 10),
            _buildAbsences(context, scheme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitre(String titre, IconData icon, Color color) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(
        titre,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: color,
        ),
      ),
    ],
  );

  Widget _carteIdentite(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kViolet.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _kViolet,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    eleve.initiales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eleve.nomComplet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (eleve.nomClasse.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            eleve.nomClasse,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Infos
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow(Icons.email_rounded, 'Email', eleve.email),
                const Divider(height: 16),
                _infoRow(
                  Icons.phone_rounded,
                  'Téléphone',
                  eleve.telephone.isEmpty ? '—' : eleve.telephone,
                ),
                const Divider(height: 16),
                _infoRow(
                  Icons.location_on_rounded,
                  'Adresse',
                  eleve.adresse.isEmpty ? '—' : eleve.adresse,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: _kViolet.withOpacity(0.7)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildNotes(BuildContext context, ColorScheme scheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('note')
          .where('idEleve', isEqualTo: eleve.id)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: scheme.primary),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _vide(
            'Aucune note enregistrée',
            Icons.star_border_rounded,
            _kBleu,
          );
        }
        final notes =
            snap.data!.docs.map((d) => NoteModel.fromFirestore(d)).toList()
              ..sort((a, b) => a.matiere.compareTo(b.matiere));

        final moyenne =
            notes.map((n) => n.valeur).reduce((a, b) => a + b) / notes.length;

        return Column(
          children: [
            // Carte moyenne
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _kBleu.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBleu.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: _kBleu, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Moyenne générale',
                    style: TextStyle(
                      color: _kBleu,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${moyenne.toStringAsFixed(2)} / 20',
                    style: const TextStyle(
                      color: _kBleu,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...notes.map((n) => _noteRow(n, scheme)),
          ],
        );
      },
    );
  }

  Widget _noteRow(NoteModel note, ColorScheme scheme) {
    final color = note.mentionColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  note.valeurFormatee,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '/20',
                  style: TextStyle(color: color.withOpacity(0.7), fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.matiere,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note.mention,
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsences(BuildContext context, ColorScheme scheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('absence')
          .where('idEleve', isEqualTo: eleve.id)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: scheme.primary),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _vide(
            'Aucune absence enregistrée',
            Icons.event_available_rounded,
            _kOrange,
          );
        }
        final absences =
            snap.data!.docs.map((d) => AbsenceModel.fromFirestore(d)).toList()
              ..sort((a, b) => b.date.compareTo(a.date));

        final nbJ = absences.where((a) => a.justifiee).length;
        final nbNJ = absences.where((a) => !a.justifiee).length;

        return Column(
          children: [
            // Résumé
            Row(
              children: [
                Expanded(
                  child: _statMini(
                    'Total',
                    '${absences.length}',
                    Icons.event_busy_rounded,
                    _kOrange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statMini(
                    'Justifiées',
                    '$nbJ',
                    Icons.check_circle_rounded,
                    _kVert,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statMini(
                    'Non just.',
                    '$nbNJ',
                    Icons.cancel_rounded,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...absences.map((a) => _absenceRow(a, scheme)),
          ],
        );
      },
    );
  }

  Widget _absenceRow(AbsenceModel absence, ColorScheme scheme) {
    final col = absence.justifiee ? _kVert : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: col, width: 3)),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withOpacity(0.04), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Icon(
            absence.justifiee
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: col,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  absence.matiere,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  absence.dateFormatee,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: col.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              absence.justifiee ? 'Justifiée' : 'Non justifiée',
              style: TextStyle(
                color: col,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statMini(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
            ),
          ],
        ),
      );

  Widget _vide(String msg, IconData icon, Color color) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 36, color: color.withOpacity(0.4)),
        const SizedBox(height: 8),
        Text(
          msg,
          style: TextStyle(color: color.withOpacity(0.6), fontSize: 13),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// FORMULAIRE AJOUT / MODIFICATION ÉLÈVE
// ════════════════════════════════════════════════════════════════════════════
class FormulaireEleve extends StatefulWidget {
  final EleveModel? eleve;
  const FormulaireEleve({super.key, this.eleve});
  @override
  State<FormulaireEleve> createState() => _FormulaireEleveState();
}

class _FormulaireEleveState extends State<FormulaireEleve> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom,
      _email,
      _motPasse,
      _telephone,
      _adresse;
  bool _motPasseVisible = false;
  String? _idClasse, _nomClasse;
  bool get _estModif => widget.eleve != null;

  @override
  void initState() {
    super.initState();
    final e = widget.eleve;
    _nom = TextEditingController(text: e?.nomComplet ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _motPasse = TextEditingController();
    _telephone = TextEditingController(text: e?.telephone ?? '');
    _adresse = TextEditingController(text: e?.adresse ?? '');
    _idClasse = e?.idClasse;
    _nomClasse = e?.nomClasse;
  }

  @override
  void dispose() {
    for (final c in [_nom, _email, _motPasse, _telephone, _adresse])
      c.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idClasse == null || _idClasse!.isEmpty) {
      _snack(context, 'Veuillez sélectionner une classe', Colors.orange);
      return;
    }
    final vm = context.read<EleveViewModel>();
    final model = EleveModel(
      nomComplet: _nom.text.trim(),
      email: _email.text.trim(),
      motPasse: _motPasse.text.trim(),
      telephone: _telephone.text.trim(),
      adresse: _adresse.text.trim(),
      idClasse: _idClasse!,
      nomClasse: _nomClasse ?? '',
    );
    final ok = _estModif
        ? await vm.modifier(widget.eleve!.id!, model)
        : await vm.ajouter(model);
    if (mounted) {
      _snack(
        context,
        ok
            ? (_estModif ? 'Élève modifié ✓' : 'Élève ajouté ✓')
            : vm.erreur ?? 'Erreur',
        ok ? Colors.green : Colors.red,
      );
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.watch<EleveViewModel>();
    final cvm = context.watch<ClasseViewModel>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(_estModif ? 'Modifier l\'élève' : 'Ajouter un élève'),
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
              _Champ(
                ctrl: _nom,
                label: 'Nom complet',
                icon: Icons.badge_rounded,
              ),
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
                      icon: Icon(
                        _motPasseVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _motPasseVisible = !_motPasseVisible),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                type: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _Champ(
                ctrl: _adresse,
                label: 'Adresse',
                icon: Icons.location_on_rounded,
                lines: 2,
              ),
              const SizedBox(height: 24),
              _SectionTitre('Classe', Icons.class_rounded),
              const SizedBox(height: 14),
              cvm.classes.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Aucune classe disponible.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              Routeur.routeClasses,
                            ),
                            child: const Text('Créer'),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: cvm.classes.any((c) => c.id == _idClasse)
                          ? _idClasse
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Classe',
                        prefixIcon: const Icon(Icons.class_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: cvm.classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.nomClasse),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() {
                        _idClasse = val;
                        _nomClasse = cvm.classes
                            .firstWhere((c) => c.id == val)
                            .nomClasse;
                      }),
                      validator: (v) => v == null ? 'Classe requise' : null,
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
                              : 'Ajouter l\'élève',
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
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DRAWER ADMIN — déconnexion via callback
// ════════════════════════════════════════════════════════════════════════════
class _DrawerAdmin extends StatelessWidget {
  final VoidCallback onDeconnexion;
  const _DrawerAdmin({required this.onDeconnexion});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

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
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: scheme.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Administrateur',
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
              children: [
                _DItem(
                  Icons.dashboard_rounded,
                  'Tableau de bord',
                  Routeur.routeAccueil,
                  false,
                ),
                const _DLabel('GESTION'),
                _DItem(
                  Icons.school_rounded,
                  'Élèves',
                  Routeur.routeEleves,
                  true,
                ),
                _DItem(
                  Icons.person_rounded,
                  'Enseignants',
                  Routeur.routeEnseignants,
                  false,
                ),
                _DItem(
                  Icons.class_rounded,
                  'Classes',
                  Routeur.routeClasses,
                  false,
                ),
                _DItem(
                  Icons.book_rounded,
                  'Matières',
                  Routeur.routeMatieres,
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
                Divider(
                  height: 20,
                  color: scheme.outlineVariant.withOpacity(0.4),
                ),
                _DItem(
                  Icons.person_outline_rounded,
                  'Mon Profil',
                  Routeur.routeProfil,
                  false,
                ),
              ],
            ),
          ),
          // ── Bouton déconnexion unifié ────────────────────────────────────
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

// ── Helpers ───────────────────────────────────────────────────────────────────
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    validator:
        validator ?? (v) => (v == null || v.isEmpty) ? '$label requis' : null,
  );
}

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
