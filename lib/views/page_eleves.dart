// lib/views/page_eleves.dart
//   contact et résumé des notes/absences.
//   Tap sur _EleveCard ouvre maintenant la fiche détail.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/models/eleve_model.dart';
import 'package:gestion_ecole/view_model/eleve_view_model.dart';
import 'package:gestion_ecole/view_model/classe_view_model.dart';
import 'package:gestion_ecole/models/classe_model.dart';

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
  String? _filtreIdClasse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.watch<EleveViewModel>();
    final cvm = context.watch<ClasseViewModel>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Élèves'),
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
            child: Column(
              children: [
                TextField(
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
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
                          child: DropdownButton<String?>(
                            value: _filtreIdClasse,
                            isExpanded: true,
                            hint: Row(
                              children: [
                                Icon(
                                  Icons.class_rounded,
                                  size: 16,
                                  color: scheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Toutes les classes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurface,
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.class_rounded,
                                      size: 16,
                                      color: scheme.onSurface.withOpacity(0.5),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Toutes les classes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: scheme.onSurface.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...cvm.classes.map(
                                (c) => DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.class_rounded,
                                        size: 16,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.nomClasse,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _filtreIdClasse = val),
                          ),
                        ),
                      ),
                    ),
                    if (_filtreIdClasse != null)
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
                          onPressed: () =>
                              setState(() => _filtreIdClasse = null),
                        ),
                      ),
                  ],
                ),
                if (_filtreIdClasse != null)
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
                          cvm.classes
                              .firstWhere(
                                (c) => c.id == _filtreIdClasse,
                                orElse: () => ClasseModel(nomClasse: ''),
                              )
                              .nomClasse,
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
          ),
          Expanded(
            child: StreamBuilder<List<EleveModel>>(
              stream: _filtreIdClasse != null
                  ? vm.streamParClasse(_filtreIdClasse!)
                  : vm.streamEleves,
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
                            _q.isNotEmpty
                                ? 'Aucun résultat pour "$_q"'
                                : _filtreIdClasse != null
                                ? 'Aucun élève dans cette classe'
                                : 'Aucun élève.\nAppuyez sur + pour en ajouter.',
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
// CARD ÉLÈVE — BUG #3 CORRIGÉ : tap ouvre PageDetailEleve
// ════════════════════════════════════════════════════════════════════════════
class _EleveCard extends StatelessWidget {
  final EleveModel eleve;
  const _EleveCard({required this.eleve});

  static const kColor = Color(0xFF7B3FA0);

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
        // ✅ BUG #3 CORRIGÉ : Tap ouvre la fiche détail élève
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PageDetailEleve(eleve: eleve)),
        ),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: kColor.withOpacity(0.12),
          child: Text(
            eleve.initiales,
            style: const TextStyle(
              color: kColor,
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
            Row(
              children: [
                if (eleve.nomClasse.isNotEmpty) _Badge(eleve.nomClasse, kColor),
                if (eleve.nomClasse.isNotEmpty &&
                    eleve.anneeScolaire.isNotEmpty)
                  const SizedBox(width: 6),
                if (eleve.anneeScolaire.isNotEmpty)
                  _Badge(eleve.anneeScolaire, const Color(0xFF1A3A8F)),
              ],
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
        content: Text('${eleve.nomComplet} sera supprimé définitivement.'),
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
// PAGE DÉTAIL ÉLÈVE — BUG #3 CORRIGÉ
// Affiche : nom, prénom, classe, contact, résumé notes/absences
// Accessible pour enseignant et administrateur
// ════════════════════════════════════════════════════════════════════════════
class PageDetailEleve extends StatelessWidget {
  final EleveModel eleve;
  final bool lectureSeule;

  const PageDetailEleve({
    super.key,
    required this.eleve,
    this.lectureSeule = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Fiche élève'),
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
                      builder: (_) => FormulaireEleve(eleve: eleve),
                    ),
                  ),
                ),
              ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
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
                        color: scheme.onPrimary.withOpacity(0.5),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        eleve.initiales,
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    eleve.nomComplet,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eleve.email,
                    style: TextStyle(
                      color: scheme.onPrimary.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.onPrimary.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: scheme.onPrimary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ÉLÈVE',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
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
                  // ── Coordonnées ─────────────────────────────────────────
                  _SectionCard(
                    titre: 'Coordonnées',
                    icone: Icons.contact_phone_rounded,
                    items: [
                      _InfoItem(
                        Icons.phone_rounded,
                        'Téléphone',
                        eleve.telephone,
                      ),
                      _InfoItem(
                        Icons.location_on_rounded,
                        'Adresse',
                        eleve.adresse,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Scolarité ────────────────────────────────────────────
                  _SectionCard(
                    titre: 'Scolarité',
                    icone: Icons.school_rounded,
                    items: [
                      _InfoItem(Icons.class_rounded, 'Classe', eleve.nomClasse),
                      _InfoItem(
                        Icons.calendar_today_rounded,
                        'Année scolaire',
                        eleve.anneeScolaire,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Résumé notes & absences ──────────────────────────────
                  _ResumeEleveCard(idEleve: eleve.id!),
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

// ── Carte résumé notes/absences ──────────────────────────────────────────────
class _ResumeEleveCard extends StatelessWidget {
  final String idEleve;
  const _ResumeEleveCard({required this.idEleve});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('note')
            .where('idEleve', isEqualTo: idEleve)
            .get(),
        FirebaseFirestore.instance
            .collection('absence')
            .where('idEleve', isEqualTo: idEleve)
            .get(),
      ]),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: scheme.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final nbNotes = snap.data?[0].docs.length ?? 0;
        final nbAbsences = snap.data?[1].docs.length ?? 0;
        final absences = snap.data?[1].docs ?? [];
        final nbNonJustifiees = absences
            .where(
              (d) => (d.data() as Map<String, dynamic>)['justifiee'] == false,
            )
            .length;

        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        size: 15,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Résumé',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.4)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.star_rounded,
                        valeur: '$nbNotes',
                        label: 'Notes',
                        color: const Color(0xFF1A3A8F),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: scheme.outlineVariant.withOpacity(0.4),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.event_busy_rounded,
                        valeur: '$nbAbsences',
                        label: 'Absences',
                        color: Colors.red,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: scheme.outlineVariant.withOpacity(0.4),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.warning_amber_rounded,
                        valeur: '$nbNonJustifiees',
                        label: 'Non justif.',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String valeur, label;
  final Color color;
  const _StatItem({
    required this.icon,
    required this.valeur,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 6),
      Text(
        valeur,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    ],
  );
}

// ── Sections génériques (copiées depuis page_enseignants.dart) ───────────────
class _SectionCard extends StatelessWidget {
  final String titre;
  final IconData icone;
  final List<_InfoItem> items;
  const _SectionCard({
    required this.titre,
    required this.icone,
    required this.items,
  });

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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icone, size: 15, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  titre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.4)),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, size: 18, color: scheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.value.isEmpty ? '—' : item.value,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 68,
                    endIndent: 16,
                    color: scheme.outlineVariant.withOpacity(0.3),
                  ),
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

// ════════════════════════════════════════════════════════════════════════════
// FORMULAIRE AJOUT / MODIFICATION
// ════════════════════════════════════════════════════════════════════════════
class FormulaireEleve extends StatefulWidget {
  final EleveModel? eleve;
  const FormulaireEleve({super.key, this.eleve});
  @override
  State<FormulaireEleve> createState() => _FormulaireEleveState();
}

class _FormulaireEleveState extends State<FormulaireEleve> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _email;
  late final TextEditingController _motPasse;
  late final TextEditingController _telephone;
  late final TextEditingController _adresse;
  late final TextEditingController _anneeScolaire;
  bool _motPasseVisible = false;
  String? _idClasse;
  String? _nomClasse;
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
    _anneeScolaire = TextEditingController(
      text: e?.anneeScolaire.isNotEmpty == true
          ? e!.anneeScolaire
          : EleveModel.anneeCourante(),
    );
    _idClasse = e?.idClasse;
    _nomClasse = e?.nomClasse;
  }

  @override
  void dispose() {
    for (final c in [
      _nom,
      _email,
      _motPasse,
      _telephone,
      _adresse,
      _anneeScolaire,
    ])
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
      anneeScolaire: _anneeScolaire.text.trim(),
    );
    final ok = _estModif
        ? await vm.modifier(widget.eleve!.id!, model)
        : await vm.ajouter(model);
    if (mounted) {
      final errMsg = ok ? null : _emailExistantMessage(vm.erreur ?? '');
      _snack(
        context,
        ok
            ? (_estModif ? 'Élève modifié ✓' : 'Élève ajouté ✓')
            : errMsg ?? vm.erreur ?? 'Erreur',
        ok ? Colors.green : Colors.red,
      );
      if (ok) Navigator.pop(context);
    }
  }

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
              _SectionTitre('Scolarité', Icons.school_rounded),
              const SizedBox(height: 14),
              _Champ(
                ctrl: _anneeScolaire,
                label: 'Année scolaire (ex: 2024-2025)',
                icon: Icons.calendar_today_rounded,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Année scolaire requise';
                  final regex = RegExp(r'^\d{4}-\d{4}$');
                  if (!regex.hasMatch(v)) return 'Format attendu : 2024-2025';
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
                  isActive: false,
                ),
                const _DLabel('GESTION'),
                _DItem(
                  Icons.school_rounded,
                  'Élèves',
                  Routeur.routeEleves,
                  isActive: true,
                ),
                _DItem(
                  Icons.person_rounded,
                  'Enseignants',
                  Routeur.routeEnseignants,
                  isActive: false,
                ),
                _DItem(
                  Icons.class_rounded,
                  'Classes',
                  Routeur.routeClasses,
                  isActive: false,
                ),
                _DItem(
                  Icons.book_rounded,
                  'Matières',
                  Routeur.routeMatieres,
                  isActive: false,
                ),
                const _DLabel('ACADÉMIQUE'),
                _DItem(
                  Icons.star_rounded,
                  'Notes',
                  Routeur.routeNotes,
                  isActive: false,
                ),
                _DItem(
                  Icons.event_busy_rounded,
                  'Absences',
                  Routeur.routeAbsences,
                  isActive: false,
                ),
                _DItem(
                  Icons.description_rounded,
                  'Bulletins',
                  Routeur.routeBulletin,
                  isActive: false,
                ),
                Divider(
                  height: 20,
                  color: scheme.outlineVariant.withOpacity(0.4),
                ),
                _DItem(
                  Icons.person_outline_rounded,
                  'Mon Profil',
                  Routeur.routeProfil,
                  isActive: false,
                ),
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
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Déconnexion'),
                      content: const Text(
                        'Voulez-vous vraiment vous déconnecter ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            'Déconnecter',
                            style: TextStyle(color: scheme.onError),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted)
                      Navigator.pushReplacementNamed(
                        context,
                        Routeur.routeInitial,
                      );
                  }
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
// HELPERS
// ════════════════════════════════════════════════════════════════════════════
class _DItem extends StatelessWidget {
  final IconData icon;
  final String label, route;
  final bool isActive;
  const _DItem(this.icon, this.label, this.route, {required this.isActive});
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

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
