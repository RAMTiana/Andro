# Mon Budget (Flutter) — MVP

Budget quotidien simple, hors-ligne : « Il te reste X à dépenser aujourd'hui »,
saisie en 2 taps, import des SMS Mobile Money (Android).
Tout est stocké localement (SQLite). Aucun serveur nécessaire pour le MVP.

## Installation (étapes)

1. Installe Flutter : https://docs.flutter.dev/get-started/install
2. Crée un projet vierge (génère android/ et ios/) :
   `flutter create --org com.example --project-name budget_app budget_app`
3. Décompresse cette archive PAR-DESSUS le dossier `budget_app` créé
   (accepte le remplacement de `pubspec.yaml`, `lib/`, `test/`).
   Supprime `test/widget_test.dart` (généré par Flutter, obsolète).
4. Android — SMS :
   - ajoute la ligne de `android_patch/AndroidManifest_additions.xml`
     dans `android/app/src/main/AndroidManifest.xml` (avant `<application>`) ;
   - remplace `android/app/src/main/kotlin/com/example/budget_app/MainActivity.kt`
     par `android_patch/MainActivity.kt` (adapte la ligne `package` si besoin).
5. `flutter pub get`
6. `flutter test`   (money, calcul du budget, parseur SMS)
7. `flutter run`    (téléphone Android branché)

## Fichiers (aucun > 500 lignes)

| Fichier | Rôle |
|---|---|
| `pubspec.yaml` | Dépendances : sqflite, provider, uuid, permission_handler |
| `assets/sms_rules.json` | Règles de lecture des SMS (EXEMPLES à adapter) |
| `lib/main.dart`, `lib/app.dart` | Démarrage, thème, choix onboarding / accueil |
| `lib/core/money.dart` | Montants en entiers : format et saisie |
| `lib/core/currencies.dart` | Devises, décimales, symboles |
| `lib/core/strings.dart` | Textes FR / EN |
| `lib/core/date_fmt.dart` | Formats de date |
| `lib/data/models.dart` | Account, Category, TxRec, PlannedItem, BudgetSettings |
| `lib/data/db.dart` | Schéma SQLite |
| `lib/data/repository.dart` | Requêtes SQL |
| `lib/domain/daily_budget_calculator.dart` | Formule du budget du jour |
| `lib/sms/sms_parser.dart` | SMS -> transaction (règles JSON) |
| `lib/sms/sms_reader.dart` | Lecture des SMS via le canal natif |
| `lib/state/app_state.dart` | État de l'app (Provider) |
| `lib/features/onboarding_screen.dart` | Première configuration |
| `lib/features/home_screen.dart` | Écran principal |
| `lib/features/add_transaction_sheet.dart` | Saisie rapide |
| `lib/features/transactions_screen.dart` | Liste des transactions |
| `lib/features/review_screen.dart` | Import SMS + validation |
| `lib/features/budget_settings_screen.dart` | Épargne, période, alerte, langue |
| `lib/features/planned_items_screen.dart` | Charges et rentrées prévues |
| `android_patch/MainActivity.kt` | Lecture native de la boîte SMS |
| `test/*.dart` | Tests unitaires |

## Limites connues

- Le code n'a pas été compilé ici : lance `flutter test` et corrige les
  éventuelles erreurs de version de paquets.
- `sms_rules.json` contient des motifs génériques : copie de vrais SMS
  (MVola, Orange Money, Airtel Money...) et ajuste `senders` et `pattern`.
- Une seule devise (celle du profil) dans le MVP ; la colonne `currency`
  est déjà là pour le multi-devises plus tard.
- Alertes affichées dans l'app (pas de notification push pour l'instant).
- Google Play restreint l'accès aux SMS : teste par APK avant de publier.
