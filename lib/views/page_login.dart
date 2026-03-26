// lib/views/page_login.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  bool _passwordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      final uid = userCredential.user!.uid;
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
          Navigator.pushReplacementNamed(
            context,
            Routeur.routeAccueilEnseignant,
          );
          break;
        case 'eleve':
          Navigator.pushReplacementNamed(context, Routeur.routeAccueilEleve);
          break;
        default:
          await FirebaseAuth.instance.signOut();
          if (mounted) _snack('Accès non autorisé pour ce compte.');
      }
    } on FirebaseAuthException catch (e) {
      // ✅ BUG #8 CORRIGÉ : Tous les messages sont en français
      // Firebase Auth v9+ utilise 'invalid-credential' au lieu de
      // 'user-not-found' / 'wrong-password'
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          message =
              "L'email ou le mot de passe saisi est incorrect ou n'existe pas.";
          break;
        case 'invalid-email':
          message = 'Adresse email invalide.';
          break;
        case 'too-many-requests':
          message =
              'Trop de tentatives de connexion. Veuillez réessayer plus tard.';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé. Contactez l\'administrateur.';
          break;
        case 'network-request-failed':
          message =
              'Erreur de connexion réseau. Vérifiez votre connexion internet.';
          break;
        default:
          message =
              "L'email ou le mot de passe saisi est incorrect ou n'existe pas.";
      }
      if (mounted) _snack(message);
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
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
