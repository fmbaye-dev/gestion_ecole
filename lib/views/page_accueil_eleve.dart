// lib/views/page_accueil_eleve.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gestion_ecole/config/routeur.dart';

class PageAccueilEleve extends StatefulWidget {
  const PageAccueilEleve({super.key});

  @override
  State<PageAccueilEleve> createState() => _PageAccueilEleveState();
}

class _PageAccueilEleveState extends State<PageAccueilEleve> {
  String? _nomEleve;
  String? _nomClasse;
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _chargerInfos();
  }

  Future<void> _chargerInfos() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('utilisateur')
        .doc(uid)
        .get();
    if (mounted)
      setState(() {
        _nomEleve = doc.data()?['nomComplet'] as String? ?? '';
        _nomClasse = doc.data()?['nomClasse'] as String? ?? '';
        _charge = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Espace Élève'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      drawer: const _DrawerEleve(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue Élève',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _charge ? (_nomEleve ?? '') : (user?.email ?? ''),
                          style: TextStyle(
                            color: scheme.onPrimary.withOpacity(0.85),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_nomClasse != null && _nomClasse!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Classe : $_nomClasse',
                            style: TextStyle(
                              color: scheme.onPrimary.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: scheme.onPrimary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Accès rapides',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // Grille accès rapides
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _AccesRapide(
                  icon: Icons.star_rounded,
                  label: 'Mes Notes',
                  color: const Color(0xFF1A3A8F),
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    Routeur.routeNotes,
                  ),
                ),
                _AccesRapide(
                  icon: Icons.event_busy_rounded,
                  label: 'Mes Absences',
                  color: const Color(0xFFC0692A),
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    Routeur.routeAbsences,
                  ),
                ),
                _AccesRapide(
                  icon: Icons.person_outline_rounded,
                  label: 'Mon Profil',
                  color: const Color(0xFF2A8A5C),
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    Routeur.routeProfil,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Accès rapide card ─────────────────────────────────────────────────────────
class _AccesRapide extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AccesRapide({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer élève ──────────────────────────────────────────────────────────────
class _DrawerEleve extends StatelessWidget {
  const _DrawerEleve();

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
                    Icons.school_rounded,
                    color: scheme.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Élève',
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
                  Routeur.routeAccueilEleve,
                  isActive: true,
                ),
                const _DLabel('MES DONNÉES'),
                _DItem(
                  Icons.star_rounded,
                  'Mes Notes',
                  Routeur.routeNotes,
                  isActive: false,
                ),
                _DItem(
                  Icons.event_busy_rounded,
                  'Mes Absences',
                  Routeur.routeAbsences,
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
