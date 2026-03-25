// lib/views/page_matieres.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/models/matiere_model.dart';
import 'package:gestion_ecole/view_model/matiere_view_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// PAGE MATIÈRES (admin uniquement)
// ════════════════════════════════════════════════════════════════════════════
class PageMatieres extends StatelessWidget {
  const PageMatieres({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.watch<MatiereViewModel>();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Matières'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      drawer: const _DrawerAdmin(),
      body: StreamBuilder<List<MatiereModel>>(
        stream: vm.streamMatieres,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 56,
                      color: scheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Aucune matière.\nAppuyez sur + pour en ajouter.',
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: list.length,
            itemBuilder: (_, i) => _MatiereCard(matiere: list[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBottomSheet(context, vm),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, MatiereViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    final nomCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nouvelle matière',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Entrez le nom de la matière',
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nomCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nom de la matière',
                hintText: 'ex : Mathématiques, Français, SVT...',
                prefixIcon: Icon(
                  Icons.book_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () async {
                  final nom = nomCtrl.text.trim();
                  if (nom.isEmpty) return;
                  final ok = await vm.ajouter(nom);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Matière "$nom" ajoutée ✓'
                              : vm.erreur ?? 'Erreur',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: ok ? Colors.green : scheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(12),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Ajouter',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CARD MATIÈRE
// ════════════════════════════════════════════════════════════════════════════
class _MatiereCard extends StatelessWidget {
  final MatiereModel matiere;
  const _MatiereCard({required this.matiere});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vm = context.read<MatiereViewModel>();

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
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.book_rounded, color: scheme.primary, size: 20),
        ),
        title: Text(
          matiere.nom,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modifier
            IconButton(
              tooltip: 'Modifier',
              icon: Icon(Icons.edit_rounded, size: 20, color: scheme.primary),
              onPressed: () => _showModifierDialog(context, vm),
            ),
            // Supprimer
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

  void _showModifierDialog(BuildContext context, MatiereViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    final ctrl = TextEditingController(text: matiere.nom);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier la matière'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nom de la matière',
            prefixIcon: Icon(Icons.book_rounded, color: scheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final nouveau = ctrl.text.trim();
              if (nouveau.isEmpty || nouveau == matiere.nom) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              // CASCADE UPDATE via firebase_service
              final ok = await vm.modifier(matiere.id!, matiere.nom, nouveau);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Matière renommée ✓' : vm.erreur ?? 'Erreur',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: ok ? Colors.green : scheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(12),
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, MatiereViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la matière ?'),
        content: Text('"${matiere.nom}" sera supprimée définitivement.'),
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
              await vm.supprimer(matiere.id!, matiere.nom);
            },
            child: Text('Supprimer', style: TextStyle(color: scheme.onError)),
          ),
        ],
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
                  false,
                ),
                const _DLabel('GESTION'),
                _DItem(
                  Icons.school_rounded,
                  'Élèves',
                  Routeur.routeEleves,
                  false,
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
                  true,
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
                  if (confirm == true && context.mounted) {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(
                        context,
                        Routeur.routeInitial,
                      );
                    }
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
