// lib/views/page_mon_profil.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/core/app_state/app_state.dart';

class PageMonProfil extends StatefulWidget {
  const PageMonProfil({super.key});

  @override
  State<PageMonProfil> createState() => _PageMonProfilState();
}

class _PageMonProfilState extends State<PageMonProfil> {
  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    return await FirebaseFirestore.instance
        .collection('utilisateur')
        .doc(user.uid)
        .get();
  }

  String _initiales(String nom) {
    final p = nom.trim().split(' ');
    if (p.length >= 2 && p[0].isNotEmpty && p[1].isNotEmpty) {
      return '${p[0][0]}${p[1][0]}'.toUpperCase();
    }
    return nom.isNotEmpty ? nom[0].toUpperCase() : 'U';
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'enseignant':
        return 'Enseignant';
      case 'eleve':
        return 'Élève';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      drawer: _AppDrawerSimple(),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }
          if (snapshot.hasError) {
            return _EtatErreur(message: '${snapshot.error}');
          }
          final data = snapshot.data?.data();
          if (data == null) {
            return const _EtatErreur(message: 'Profil introuvable.');
          }

          final nomComplet = data['nomComplet'] as String? ?? '';
          final email = data['email'] as String? ?? '';
          final role = data['role'] as String? ?? '';
          final telephone = data['telephone'] as String? ?? '';
          final adresse = data['adresse'] as String? ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                _Header(
                  initiales: _initiales(nomComplet),
                  nomComplet: nomComplet,
                  email: email,
                  roleLabel: _roleLabel(role),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      _Section(
                        titre: 'Informations personnelles',
                        icone: Icons.person_rounded,
                        items: [
                          _Item(Icons.badge_rounded, 'Nom complet', nomComplet),
                          _Item(Icons.email_rounded, 'Email', email),
                          _Item(Icons.phone_rounded, 'Téléphone', telephone),
                          _Item(Icons.location_on_rounded, 'Adresse', adresse),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Section(
                        titre: 'Accès & Rôle',
                        icone: Icons.shield_rounded,
                        items: [
                          _Item(
                            Icons.manage_accounts_rounded,
                            'Rôle',
                            _roleLabel(role),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _CarteApparence(),
                      const SizedBox(height: 14),
                      _BoutonDeconnexion(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HEADER
// ════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String initiales;
  final String nomComplet;
  final String email;
  final String roleLabel;

  const _Header({
    required this.initiales,
    required this.nomComplet,
    required this.email,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      color: scheme.primary,
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
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
                initiales,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nomComplet.isEmpty ? 'Utilisateur' : nomComplet,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.onPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.onPrimary.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: scheme.onPrimary, size: 14),
                const SizedBox(width: 6),
                Text(
                  roleLabel.toUpperCase(),
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
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SECTION CARTE INFOS
// ════════════════════════════════════════════════════════════════════════════
class _Item {
  final IconData icon;
  final String label;
  final String value;
  const _Item(this.icon, this.label, this.value);
}

class _Section extends StatelessWidget {
  final String titre;
  final IconData icone;
  final List<_Item> items;

  const _Section({
    required this.titre,
    required this.icone,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
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
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.value.isEmpty ? '—' : item.value,
                              style: text.bodyMedium?.copyWith(
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

// ════════════════════════════════════════════════════════════════════════════
// CARTE APPARENCE
// ════════════════════════════════════════════════════════════════════════════
class _CarteApparence extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appState = context.watch<AppState>();
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            appState.estEnModeSombre
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            size: 18,
            color: scheme.primary,
          ),
        ),
        title: Text(
          'Apparence',
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          appState.estEnModeSombre ? 'Mode sombre' : 'Mode clair',
          style: text.bodySmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: Switch(
          value: appState.estEnModeSombre,
          activeColor: scheme.primary,
          onChanged: (v) {
            if (v)
              appState.forcerModeSombre();
            else
              appState.forcerModeClair();
          },
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BOUTON DÉCONNEXION
// ════════════════════════════════════════════════════════════════════════════
class _BoutonDeconnexion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Déconnexion'),
              content: const Text('Voulez-vous vraiment vous déconnecter ?'),
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
              Navigator.pushReplacementNamed(context, Routeur.routeInitial);
            }
          }
        },
        icon: Icon(Icons.logout_rounded, color: scheme.error, size: 20),
        label: Text(
          'Se déconnecter',
          style: TextStyle(
            color: scheme.error,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.error.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DRAWER DYNAMIQUE selon le rôle
// ════════════════════════════════════════════════════════════════════════════
class _AppDrawerSimple extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: scheme.surface,
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // On relit le rôle pour construire le bon drawer
        future: user == null
            ? null
            : FirebaseFirestore.instance
                  .collection('utilisateur')
                  .doc(user.uid)
                  .get(),
        builder: (context, snap) {
          final role = snap.data?.data()?['role'] as String? ?? '';
          final nomComplet = snap.data?.data()?['nomComplet'] as String? ?? '';

          return Column(
            children: [
              // ── Header ────────────────────────────────────────────────
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
                        _iconeRole(role),
                        color: scheme.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nomComplet.isEmpty ? _titreRole(role) : nomComplet,
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

              // ── Items selon le rôle ────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  children: [
                    ..._itemsParRole(role, context, scheme),
                    Divider(
                      height: 20,
                      color: scheme.outlineVariant.withOpacity(0.4),
                    ),
                    _DrawerItem(
                      Icons.person_outline_rounded,
                      'Mon Profil',
                      Routeur.routeProfil,
                      true, // actif car on est sur cette page
                    ),
                  ],
                ),
              ),

              // ── Déconnexion ────────────────────────────────────────────
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
                          Icon(
                            Icons.logout_rounded,
                            color: scheme.error,
                            size: 20,
                          ),
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
          );
        },
      ),
    );
  }

  // ── Icône selon le rôle ──────────────────────────────────────────────────
  IconData _iconeRole(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'enseignant':
        return Icons.school_rounded;
      case 'eleve':
        return Icons.person_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  // ── Titre selon le rôle ──────────────────────────────────────────────────
  String _titreRole(String role) {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'enseignant':
        return 'Enseignant';
      case 'eleve':
        return 'Élève';
      default:
        return 'Utilisateur';
    }
  }

  // ── Items de navigation selon le rôle ───────────────────────────────────
  List<Widget> _itemsParRole(
    String role,
    BuildContext context,
    ColorScheme scheme,
  ) {
    switch (role) {
      // ── ADMIN ────────────────────────────────────────────────────────────
      case 'admin':
        return [
          _DrawerItem(
            Icons.dashboard_rounded,
            'Tableau de bord',
            Routeur.routeAccueil,
            false,
          ),
          const _DrawerLabel('GESTION'),
          _DrawerItem(
            Icons.school_rounded,
            'Élèves',
            Routeur.routeEleves,
            false,
          ),
          _DrawerItem(
            Icons.person_rounded,
            'Enseignants',
            Routeur.routeEnseignants,
            false,
          ),
          _DrawerItem(
            Icons.class_rounded,
            'Classes',
            Routeur.routeClasses,
            false,
          ),
          _DrawerItem(
            Icons.book_rounded,
            'Matières',
            Routeur.routeMatieres,
            false,
          ),
          const _DrawerLabel('ACADÉMIQUE'),
          _DrawerItem(Icons.star_rounded, 'Notes', Routeur.routeNotes, false),
          _DrawerItem(
            Icons.event_busy_rounded,
            'Absences',
            Routeur.routeAbsences,
            false,
          ),
        ];

      // ── ENSEIGNANT ───────────────────────────────────────────────────────
      case 'enseignant':
        return [
          _DrawerItem(
            Icons.dashboard_rounded,
            'Tableau de bord',
            Routeur.routeAccueilEnseignant,
            false,
          ),
          const _DrawerLabel('ACADÉMIQUE'),
          _DrawerItem(Icons.star_rounded, 'Notes', Routeur.routeNotes, false),
          _DrawerItem(
            Icons.event_busy_rounded,
            'Absences',
            Routeur.routeAbsences,
            false,
          ),
        ];

      // ── ÉLÈVE ─────────────────────────────────────────────────────────
      case 'eleve':
        return [
          _DrawerItem(
            Icons.dashboard_rounded,
            'Tableau de bord',
            Routeur.routeAccueilEleve,
            false,
          ),
          const _DrawerLabel('MES DONNÉES'),
          _DrawerItem(
            Icons.star_rounded,
            'Mes Notes',
            Routeur.routeNotes,
            false,
          ),
          _DrawerItem(
            Icons.event_busy_rounded,
            'Mes Absences',
            Routeur.routeAbsences,
            false,
          ),
        ];

      // ── DÉFAUT ────────────────────────────────────────────────────────────
      default:
        return [];
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WIDGETS PARTAGÉS DU DRAWER
// ════════════════════════════════════════════════════════════════════════════
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _DrawerItem(this.icon, this.label, this.route, this.isActive);

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

class _DrawerLabel extends StatelessWidget {
  final String label;
  const _DrawerLabel(this.label);

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

// ════════════════════════════════════════════════════════════════════════════
// ÉTAT ERREUR
// ════════════════════════════════════════════════════════════════════════════
class _EtatErreur extends StatelessWidget {
  final String message;
  const _EtatErreur({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: scheme.error.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
