// lib/services/notification_service.dart
// Service Firebase Cloud Messaging (FCM)
//
// PRÉREQUIS :
//   1. Activer FCM dans la console Firebase
//   2. Ajouter firebase_messaging: ^14.0.0 dans pubspec.yaml
//   3. Sur Android : AndroidManifest.xml → permission INTERNET déjà présente
//   4. Sur iOS : activer Push Notifications dans Xcode + Capabilities
//
// UTILISATION :
//   await NotificationService.instance.initialiser();
//   await NotificationService.instance.envoyerNouvelleNote(idEleve, matiere);

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gestion_ecole/config/app_logger.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  // ── Initialisation ────────────────────────────────────────────────────────
  Future<void> initialiser() async {
    // Demande de permission (iOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.info('Permission FCM : ${settings.authorizationStatus}');

    // Config notifs locales (pour affichage en foreground)
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Canal Android
    const canal = AndroidNotificationChannel(
      'gestion_ecole_canal',
      'Gestion École',
      description: 'Notifications de l\'application Gestion École',
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);

    // Afficher les notifications en foreground
    FirebaseMessaging.onMessage.listen(_afficherNotifLocale);

    AppLogger.info('NotificationService initialisé');
  }

  // ── Enregistrement du token FCM pour un utilisateur ───────────────────────
  Future<void> enregistrerToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection('utilisateur')
        .doc(uid)
        .update({'fcmToken': token});
    AppLogger.info('Token FCM enregistré pour $uid');

    // Écoute rafraîchissement du token
    _messaging.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('utilisateur')
          .doc(uid)
          .update({'fcmToken': newToken});
    });
  }

  // ── Affichage local ───────────────────────────────────────────────────────
  Future<void> _afficherNotifLocale(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    await _localNotif.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'gestion_ecole_canal',
          'Gestion École',
          channelDescription: 'Notifications de l\'application',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MÉTHODES MÉTIER — Enregistrement en Firestore pour envoi via Cloud Function
  // ══════════════════════════════════════════════════════════════════════════
  // Note : FCM ne peut pas envoyer directement depuis le client.
  // On écrit dans une collection 'notifications_queue' que Cloud Functions traite.
  // Si vous n'avez pas Cloud Functions, utilisez les Topics FCM depuis Admin SDK.

  /// Notifier un élève d'une nouvelle note
  Future<void> envoyerNouvelleNote(String idEleve, String matiere) async {
    await _queueNotification(
      destinataireId: idEleve,
      titre: '📚 Nouvelle note disponible',
      corps: 'Votre note en $matiere a été saisie.',
      type: 'nouvelle_note',
      data: {'matiere': matiere},
    );
  }

  /// Notifier un élève d'une absence enregistrée
  Future<void> envoyerNouvelleAbsence(
      String idEleve, String matiere, String typePresence) async {
    final libelle = typePresence == 'retard' ? 'retard' : 'absence';
    await _queueNotification(
      destinataireId: idEleve,
      titre: '⚠️ ${libelle[0].toUpperCase()}${libelle.substring(1)} enregistré(e)',
      corps: 'Un(e) $libelle a été enregistré(e) en $matiere.',
      type: 'absence',
      data: {'matiere': matiere, 'typePresence': typePresence},
    );
  }

  /// Notifier un élève de la publication de son bulletin
  Future<void> envoyerPublicationBulletin(
      String idEleve, String semestre) async {
    final sem = semestre == 'S1' ? '1er semestre' : '2ème semestre';
    await _queueNotification(
      destinataireId: idEleve,
      titre: '📄 Bulletin disponible',
      corps: 'Votre bulletin du $sem est maintenant disponible.',
      type: 'bulletin',
      data: {'semestre': semestre},
    );
  }

  /// Écriture dans la queue Firestore (traitement par Cloud Function)
  Future<void> _queueNotification({
    required String destinataireId,
    required String titre,
    required String corps,
    required String type,
    Map<String, dynamic> data = const {},
  }) async {
    await FirebaseFirestore.instance.collection('notifications_queue').add({
      'destinataireId': destinataireId,
      'titre':          titre,
      'corps':          corps,
      'type':           type,
      'data':           data,
      'envoye':         false,
      'dateCreation':   FieldValue.serverTimestamp(),
    });
    AppLogger.info('Notification queued → $destinataireId : $titre');
  }
}