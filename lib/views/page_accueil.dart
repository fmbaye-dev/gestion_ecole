// lib/views/page_accueil.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PageAccueil extends StatefulWidget {
  const PageAccueil({super.key});

  @override
  State<PageAccueil> createState() => _PageAccueilState();
}

class _PageAccueilState extends State<PageAccueil> {
  Future<void> _deconnexion() async {
    final confirm = await showDialog<bool>(
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
            child: Text('Déconnecter',
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: scheme.shadow.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 14),
        Text(value, style: TextStyle(fontSize: 26,
            fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 3),
        Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.55))),
      ]),
    );
  }

  Widget _dashboardCards() {
    final scheme = Theme.of(context).colorScheme;
    const cEleve   = Color(0xFF1A3A8F);
    const cEnseignant = Color(0xFF2A8A5C);
    const cClasse     = Color(0xFFD4A843);
    const cAbsence    = Color(0xFFC0692A);

    final futureEleves   = FirebaseFirestore.instance.collection('utilisateur')
        .where('role', isEqualTo: 'eleve').get();
    final futureEnseignants = FirebaseFirestore.instance.collection('utilisateur')
        .where('role', isEqualTo: 'enseignant').get();
    final futureClasses     = FirebaseFirestore.instance.collection('classe').get();
    final futureUtilisateurs = FirebaseFirestore.instance.collection('utilisateur').get();

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([futureEleves, futureEnseignants,
                           futureClasses, futureUtilisateurs]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: scheme.primary));
        }
        if (snapshot.hasError) {
          return _EtatErreur(message: 'Erreur de chargement des statistiques');
        }
        final results        = snapshot.data!;
        final nbEleves    = results[0].docs.length;
        final nbEnseignants  = results[1].docs.length;
        final nbClasses      = results[2].docs.length;
        final nbUtilisateurs = results[3].docs.length;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _statCard('Élèves',    '$nbEleves',    Icons.school_rounded,      cEleve),
            _statCard('Enseignants',  '$nbEnseignants',  Icons.person_rounded,      cEnseignant),
            _statCard('Classes',      '$nbClasses',      Icons.class_rounded,       cClasse),
            _statCard('Utilisateurs', '$nbUtilisateurs', Icons.people_rounded,      cAbsence),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user   = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        centerTitle: false, elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      drawer: _DrawerAccueil(onDeconnexion: _deconnexion),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Bannière
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bienvenue Administrateur',
                    style: TextStyle(color: scheme.onPrimary,
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(user?.email ?? '',
                    style: TextStyle(
                        color: scheme.onPrimary.withOpacity(0.8), fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: scheme.onPrimary.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: Icon(Icons.admin_panel_settings_rounded,
                    color: scheme.onPrimary, size: 28),
              ),
            ]),
          ),
          const SizedBox(height: 22),

          // Stats
          Text('Vue d\'ensemble', style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _dashboardCards(),
          const SizedBox(height: 24),

          // Ajouter un admin
          _FormulaireAdmin(),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DRAWER
// ════════════════════════════════════════════════════════════════════════════
class _DrawerAccueil extends StatelessWidget {
  final VoidCallback onDeconnexion;
  const _DrawerAccueil({required this.onDeconnexion});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user   = FirebaseAuth.instance.currentUser;

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
            Text('Administrateur', style: TextStyle(color: scheme.onPrimary,
                fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(user?.email ?? '',
                style: TextStyle(color: scheme.onPrimary.withOpacity(0.8),
                    fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            children: [
              _DItem(Icons.dashboard_rounded,     'Tableau de bord', '/accueil',     isActive: true),
              const _DLabel('GESTION'),
              _DItem(Icons.school_rounded,         'Élèves',      '/eleves'),
              _DItem(Icons.person_rounded,         'Enseignants',    '/enseignants'),
              _DItem(Icons.class_rounded,          'Classes',        '/classes'),
              _DItem(Icons.book_rounded,           'Matières',       '/matieres'),
              const _DLabel('ACADÉMIQUE'),
              _DItem(Icons.star_rounded,           'Notes',          '/notes'),
              _DItem(Icons.event_busy_rounded,     'Absences',       '/absences'),
              Divider(height: 20, color: scheme.outlineVariant.withOpacity(0.4)),
              _DItem(Icons.person_outline_rounded, 'Mon Profil',     '/profil'),
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
              onTap: () { Navigator.pop(context); onDeconnexion(); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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

class _DItem extends StatelessWidget {
  final IconData icon; final String label, route; final bool isActive;
  const _DItem(this.icon, this.label, this.route, {this.isActive = false});
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
                    decoration: BoxDecoration(color: scheme.primary,
                        shape: BoxShape.circle)),
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
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
    child: Text(label, style: TextStyle(fontSize: 10,
        fontWeight: FontWeight.bold, letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
  );
}

class _EtatErreur extends StatelessWidget {
  final String message;
  const _EtatErreur({required this.message});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline_rounded,
            color: scheme.error.withOpacity(0.6), size: 20),
        const SizedBox(width: 8),
        Text(message,
            style: TextStyle(color: scheme.onSurface.withOpacity(0.55))),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FORMULAIRE CRÉATION ADMIN
// ════════════════════════════════════════════════════════════════════════════
class _FormulaireAdmin extends StatefulWidget {
  @override
  State<_FormulaireAdmin> createState() => _FormulaireAdminState();
}

class _FormulaireAdminState extends State<_FormulaireAdmin> {
  final _fk       = GlobalKey<FormState>();
  final _nom      = TextEditingController();
  final _email    = TextEditingController();
  final _motPasse = TextEditingController();
  final _tel      = TextEditingController();
  final _adresse  = TextEditingController();

  bool _motPasseVisible = false;
  bool _isLoading       = false;

  @override
  void dispose() {
    for (final c in [_nom, _email, _motPasse, _tel, _adresse]) c.dispose();
    super.dispose();
  }

  Future<void> _creerAdmin() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Créer le compte Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _email.text.trim(),
        password: _motPasse.text.trim(),
      );
      final uid = credential.user?.uid;

      // Stocker dans Firestore avec rôle admin
      await FirebaseFirestore.instance
          .collection('utilisateur')
          .doc(uid)
          .set({
        'uid':          uid,
        'nomComplet':   _nom.text.trim(),
        'email':        _email.text.trim(),
        'telephone':    _tel.text.trim(),
        'adresse':      _adresse.text.trim(),
        'role':         'admin',
        'date_creation': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _nom.clear(); _email.clear(); _motPasse.clear();
        _tel.clear(); _adresse.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Administrateur créé ✓',
              style: TextStyle(fontWeight: FontWeight.w500)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use': msg = 'Email déjà utilisé.'; break;
        case 'weak-password':        msg = 'Mot de passe trop faible.'; break;
        case 'invalid-email':        msg = 'Email invalide.'; break;
        default: msg = e.message ?? 'Erreur de création.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: scheme.shadow.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Form(
        key: _fk,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // Titre
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.admin_panel_settings_rounded,
                  size: 18, color: scheme.primary)),
            const SizedBox(width: 10),
            Text('Créer un administrateur',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 15, color: scheme.primary)),
          ]),
          const SizedBox(height: 20),

          // Nom
          _Champ(ctrl: _nom, label: 'Nom complet',
              icon: Icons.badge_rounded, scheme: scheme),
          const SizedBox(height: 12),

          // Email
          _Champ(ctrl: _email, label: 'Email',
              icon: Icons.email_rounded, scheme: scheme,
              type: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Email invalide' : null),
          const SizedBox(height: 12),

          // Mot de passe
          TextFormField(
            controller: _motPasse,
            obscureText: !_motPasseVisible,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock_rounded,
                  size: 20, color: scheme.primary),
              suffixIcon: IconButton(
                icon: Icon(_motPasseVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded, size: 20,
                    color: scheme.onSurface.withOpacity(0.5)),
                onPressed: () => setState(
                    () => _motPasseVisible = !_motPasseVisible),
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

          // Téléphone
          _Champ(ctrl: _tel, label: 'Téléphone',
              icon: Icons.phone_rounded, scheme: scheme,
              type: TextInputType.phone),
          const SizedBox(height: 12),

          // Adresse
          _Champ(ctrl: _adresse, label: 'Adresse',
              icon: Icons.location_on_rounded, scheme: scheme, lines: 2),
          const SizedBox(height: 20),

          // Bouton
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _isLoading ? null : _creerAdmin,
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Créer l\'administrateur',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Champ helper ──────────────────────────────────────────────────────────────
class _Champ extends StatelessWidget {
  final TextEditingController   ctrl;
  final String                  label;
  final IconData                icon;
  final ColorScheme             scheme;
  final TextInputType           type;
  final int                     lines;
  final String? Function(String?)? validator;

  const _Champ({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.scheme,
    this.type      = TextInputType.text,
    this.lines     = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, keyboardType: type, maxLines: lines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: scheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
    ),
    validator: validator ??
        (v) => (v == null || v.isEmpty) ? '$label requis' : null,
  );
}