// lib/views/page_login.dart
// MODIFIÉ : Ajout connexion Google + garde la structure existante

// PRÉREQUIS pour Google Sign-In :
//   1. pubspec.yaml : ajouter
//        google_sign_in: ^6.2.1
//        firebase_auth: (déjà présent)
//   2. Firebase Console → Authentication → Sign-in methods → activer Google
//   3. Android : SHA-1 enregistré dans Firebase Console
//   4. iOS : GoogleService-Info.plist à jour + CFBundleURLSchemes dans Info.plist

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gestion_ecole/config/app_logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gestion_ecole/config/routeur.dart';
import 'package:gestion_ecole/core/app_state/app_state.dart';
import 'package:provider/provider.dart';

class PageLogin extends StatefulWidget {
  const PageLogin({super.key});
  @override
  State<PageLogin> createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── Connexion email / mot de passe ────────────────────────────────────────
  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      if (mounted) await _naviguerSelonRole(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          message = "L'email ou le mot de passe est incorrect.";
          break;
        case 'invalid-email':
          message = 'Adresse email invalide.';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Réessayez plus tard.';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé.';
          break;
        case 'network-request-failed':
          message = 'Erreur réseau. Vérifiez votre connexion.';
          break;
        default:
          message = "L'email ou le mot de passe est incorrect.";
      }
      if (mounted) _snack(message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Connexion Google ──────────────────────────────────────────────────────
  Future<void> loginAvecGoogle() async {
    setState(() => isGoogleLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        clientId: "1038055476346-2j1jaruhn64nlmos82ep1g1vobgraort.apps.googleusercontent.com",
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // L'utilisateur a annulé
        setState(() => isGoogleLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final uid = userCredential.user!.uid;

      // Vérifier si l'utilisateur existe déjà dans Firestore
      final doc = await FirebaseFirestore.instance
          .collection('utilisateur')
          .doc(uid)
          .get();

      if (!doc.exists) {
        // Nouveau compte Google → créer un profil Firestore avec rôle 'eleve' par défaut
        // L'admin devra modifier le rôle si nécessaire
        await FirebaseFirestore.instance.collection('utilisateur').doc(uid).set(
          {
            'uid': uid,
            'nomComplet': googleUser.displayName ?? '',
            'email': googleUser.email,
            'adresse': '',
            'telephone': '',
            'role': 'eleve', // rôle par défaut
            'dateCreation': FieldValue.serverTimestamp(),
          },
        );
      }
      if (mounted) await _naviguerSelonRole(uid);
    } on FirebaseAuthException catch (e) {
      if (mounted) _snack(e.message ?? 'Erreur Google Sign-In');
    } catch (e) {
      if (mounted) {
        AppLogger.erreur('Google Sign-In error: $e');
        _snack('Erreur lors de la connexion avec Google.');
      }
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
    }
  }

  // ── Navigation selon rôle ─────────────────────────────────────────────────
  Future<void> _naviguerSelonRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('utilisateur')
        .doc(uid)
        .get();
    final role = doc.data()?['role'] as String? ?? '';
    if (!mounted) return;
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, Routeur.routeAccueil);
        break;
      case 'enseignant':
        Navigator.pushReplacementNamed(context, Routeur.routeAccueilEnseignant);
        break;
      case 'eleve':
        Navigator.pushReplacementNamed(context, Routeur.routeAccueilEleve);
        break;
      default:
        await FirebaseAuth.instance.signOut();
        if (mounted) _snack('Accès non autorisé pour ce compte.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/illustration_login.svg',
                    height: 140,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Connexion',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connectez-vous à votre espace',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 36),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.outlineVariant.withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Email ────────────────────────────────────────────────
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'exemple@ecole.com',
                            prefixIcon: Icon(
                              Icons.email_rounded,
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
                              borderSide: BorderSide(
                                color: scheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Mot de passe ─────────────────────────────────────────
                        TextField(
                          controller: passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: Icon(
                              Icons.lock_rounded,
                              size: 20,
                              color: scheme.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 20,
                                color: scheme.onSurface.withOpacity(0.5),
                              ),
                              onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible,
                              ),
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
                              borderSide: BorderSide(
                                color: scheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Bouton Connexion ─────────────────────────────────────
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: isLoading ? null : login,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Séparateur ───────────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: scheme.outlineVariant.withOpacity(0.5),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'ou',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurface.withOpacity(0.45),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: scheme.outlineVariant.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Bouton Google ────────────────────────────────────────
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: isGoogleLoading ? null : loginAvecGoogle,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: scheme.outlineVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isGoogleLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.primary,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Logo Google en SVG inline (pas de dépendance externe)
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: const _GoogleLogo(),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continuer avec Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: scheme.onSurface.withOpacity(
                                            0.8,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Toggle thème ─────────────────────────────────────────────────────
          Positioned(
            top: 40,
            right: 8,
            child: SafeArea(
              child: IconButton(
                tooltip: appState.estEnModeSombre
                    ? 'Mode clair'
                    : 'Mode sombre',
                icon: Icon(
                  appState.estEnModeSombre
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: scheme.onSurface.withOpacity(0.55),
                ),
                onPressed: () {
                  if (appState.estEnModeSombre)
                    appState.forcerModeClair();
                  else
                    appState.forcerModeSombre();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo Google simplifié (pas de package images) ─────────────────────────────
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GoogleLogoPainter(), size: const Size(20, 20));
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Cercle de fond
    paint.color = Colors.white;
    canvas.drawCircle(center, r, paint);

    // Simplifié : juste un "G" coloré
    final tp = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
