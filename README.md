# chocTV (Flutter)

Lecteur IPTV + suivi sportif pour Android. Lit des playlists M3U (chaînes en clair /
flux librement redistribuables), affiche l'agenda et les scores des matchs, et relie
les deux : taper un match ouvre la chaîne associée.

---

## ⚠️ Légalité — à lire

L'app ne contient **aucun flux**. Tu fournis toi-même la source des chaînes (dans les
Réglages de l'app). N'y mets que des flux que tu as le **droit** de rediffuser.

- « Gratuit à la télé » ≠ « libre de redistribution » (TNT, ZDF, beIN, Canal+, Star Sports… protègent leurs flux).
- L'agenda et les scores viennent de TheSportsDB : ce sont des **données factuelles**, utilisation légale.
- La responsabilité de ce qui est diffusé t'appartient.

---

## Fonctionnalités

- **Chaînes** : playlist chargée automatiquement, recherche, filtre par catégorie, auto-refresh (10 min).
- **Favoris** : épingle des chaînes (★), persistés entre les sessions.
- **Récemment vues** : accès rapide aux dernières chaînes ouvertes.
- **Matchs** : agenda + scores (auto-refresh 60 s), 6 grandes compétitions.
- **Lien Matchs → Chaînes** : taper un match ouvre la chaîne associée à la compétition.
- **Réglages** : changer la source (URL de playlist) sans toucher au code.

---

## Prérequis

1. Installer **Flutter** : https://docs.flutter.dev/get-started/install
2. Installer **Android Studio** (SDK Android + émulateur ou téléphone en mode dev).
3. Vérifier : `flutter doctor` (Android au vert).

---

## Mise en route (automatique)

```bash
cd iptv_app
bash setup.sh        # génère android/, installe les deps, patche le manifest
flutter run          # lance sur un appareil/émulateur
```

Le script `setup.sh` règle tout, y compris l'autorisation des flux HTTP en clair.

### Ou manuellement

```bash
cd iptv_app
flutter create .
flutter pub get
flutter run
```
Dans ce cas, ajoute à la main dans `android/app/src/main/AndroidManifest.xml` :
`android:usesCleartextTraffic="true"` sur la balise `<application>`.

---

## Configurer la source des chaînes

- **Dans l'app** : onglet Chaînes → icône ⚙️ → coller l'URL de ta playlist → Enregistrer.
- **Par défaut** : modifiable dans `lib/config.dart` (`defaultPlaylistUrl`).
- **Association compétition → chaîne** : `lib/channel_repository.dart`
  (mots-clés cherchés dans le nom/groupe des chaînes de ta playlist).

---

## Générer l'APK

```bash
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```
Transfère le `.apk` sur ton téléphone et installe-le (autoriser les sources inconnues).

---

## Structure du code

```
lib/
├── main.dart                  # entrée + thème
├── config.dart                # URL de playlist par défaut
├── channel_repository.dart    # chaînes en mémoire + association ligue→chaîne
├── models/
│   ├── channel.dart
│   └── match_event.dart
├── services/
│   ├── m3u_parser.dart        # analyse M3U
│   ├── playlist_service.dart  # chargement playlist
│   ├── sports_service.dart    # agenda + scores (TheSportsDB)
│   └── prefs_service.dart     # favoris, récents, URL (persistance)
├── screens/
│   ├── root_screen.dart       # navigation 2 onglets
│   ├── home_screen.dart       # chaînes + favoris + récents + réglages
│   ├── matches_screen.dart    # agenda + scores, tap → chaîne
│   ├── player_screen.dart     # lecteur (Chewie / ExoPlayer)
│   └── settings_screen.dart   # source modifiable + à propos
└── widgets/
    └── channel_card.dart      # carte logo + favori
```

## Pistes futures (optionnelles)

- Notifications avant le coup d'envoi (nécessite une config native dédiée).
- Plusieurs playlists, import de fichier local.
- Guide EPG via fichiers XMLTV.
