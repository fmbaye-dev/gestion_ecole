# 📋 Fichiers modifiés — Gestion École

## Fichiers à intégrer

| Fichier modifié | Destination dans le projet |
|---|---|
| `models/absence_model.dart` | `lib/models/absence_model.dart` |
| `models/eleve_model.dart` | `lib/models/eleve_model.dart` |
| `repositories/firebase_service.dart` | `lib/repositories/firebase_service.dart` |
| `view_model/absence_view_model.dart` | `lib/view_model/absence_view_model.dart` |
| `views/page_absences.dart` | `lib/views/page_absences.dart` |
| `views/page_bulletin.dart` | `lib/views/page_bulletin.dart` |
| `views/page_eleves_modifie.dart` | Remplacer `FormulaireEleve` et `PageDetailEleve` dans `lib/views/page_eleves.dart` |
| `views/page_login.dart` | `lib/views/page_login.dart` |
| `services/notification_service.dart` | `lib/services/notification_service.dart` ← **NOUVEAU** |

---

## 📦 Dépendances à ajouter dans pubspec.yaml

```yaml
dependencies:
  # Déjà présentes
  firebase_core: ...
  cloud_firestore: ...
  firebase_auth: ...

  # À ajouter
  google_sign_in: ^6.2.1
  firebase_messaging: ^14.9.4
  flutter_local_notifications: ^17.2.3
```

---

## 🔥 Configuration Firebase Console

### 1. Connexion Google
1. Firebase Console → Authentication → Sign-in methods
2. Activer **Google**
3. Android : ajouter l'empreinte SHA-1 dans les paramètres du projet

### 2. Firebase Cloud Messaging (FCM)
1. Firebase Console → Cloud Messaging
2. Android : `google-services.json` déjà configuré (vérifier la version)
3. iOS : activer Push Notifications dans Xcode → Signing & Capabilities

---

## ✅ Ce qui a été implémenté

### 1. Absences & Retards (module complet)
- `AbsenceModel` : nouveau champ `type` (absence/retard), `enseignantNom`, `raison`
- `FormulaireAbsence` : boutons Absence/Retard, champ raison, nom enseignant auto-rempli
- `PageAbsences` : 3 filtres de type (Tous | Absences | Retards)
- `firebase_service.dart` : `streamAbsencesFiltrees` avec filtre type

### 2. Élèves — Tuteur & Santé
- `EleveModel` : champs `nomTuteur`, `contactTuteur`, `emailTuteur`, `maladies`, `handicaps`, `observationsMedicales`
- `FormulaireEleve` : sections Tuteur et Santé (avec badge confidentiel)
- `PageDetailEleve` : affichage conditionnel tuteur + santé

### 3. Bulletin
- Affiche absences et retards en temps réel
- Bouton "Notifier l'élève" (admin/enseignant) → enqueue dans `notifications_queue`

### 4. Connexion Google
- `PageLogin` : bouton "Continuer avec Google"
- Création automatique du profil Firestore si nouveau compte Google (rôle `eleve` par défaut)

### 5. Notifications Firebase (infrastructure)
- `NotificationService` : initialisation FCM, enregistrement token, méthodes métier
- `envoyerNouvelleNote()`, `envoyerNouvelleAbsence()`, `envoyerPublicationBulletin()`
- Pattern queue Firestore → à traiter via **Cloud Functions**

---

## ⚠️ Intégration NotificationService dans main.dart

```dart
// Dans main.dart, après Firebase.initializeApp :
await NotificationService.instance.initialiser();

// Dans UserViewModel ou après login, enregistrer le token :
await NotificationService.instance.enregistrerToken(uid);
```

---

## 📝 Note sur page_eleves_modifie.dart

Ce fichier contient uniquement les classes **modifiées** (`FormulaireEleve`, `PageDetailEleve`, helpers).
Dans votre `page_eleves.dart` existant :
1. Supprimer l'ancienne `FormulaireEleve` et `PageDetailEleve`
2. Copier-coller les nouvelles versions depuis `page_eleves_modifie.dart`
3. Les autres classes (`PageEleves`, `_EleveCard`, drawer, etc.) restent inchangées