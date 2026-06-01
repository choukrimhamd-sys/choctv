# chocTV — Fiche de passation

## État : prêt à compiler

App Flutter Android. Lecteur IPTV (playlists M3U) + agenda/scores sportifs,
avec favoris, chaînes récentes, source configurable et icône chocTV.

## Construire l'APK (2 façons)

**Local** (Flutter + Android Studio installés) :
```bash
cd iptv_app
bash build_apk.sh        # prépare tout ET construit l'APK
# ou : bash setup.sh && flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

**Cloud** (sans rien installer) : pousser le dossier sur GitHub →
onglet Actions → télécharger l'artifact `chocTV-apk`. Workflow déjà fourni
dans `.github/workflows/build-apk.yml`.

## À faire avant utilisation réelle

1. **Source des chaînes** : dans l'app (⚙️ Réglages) ou `lib/config.dart`,
   mettre une playlist M3U que tu as le DROIT de rediffuser.
2. **Association match → chaîne** : ajuster les mots-clés dans
   `lib/channel_repository.dart` selon les noms des chaînes de ta playlist.

## Fait

- [x] Lecteur HLS (Chewie/ExoPlayer)
- [x] Parseur M3U + chargement auto + auto-refresh
- [x] Favoris + récents persistants (shared_preferences)
- [x] Onglet Matchs (TheSportsDB) + scores auto
- [x] Tap match → ouverture de la chaîne associée
- [x] Réglages (sources modifiables dans l'app)
- [x] Multi-sources : plusieurs playlists nommées, URL ou M3U collé, choix de l'active
- [x] Nom + icône chocTV (auto au build via flutter_launcher_icons)
- [x] Scripts setup.sh / build_apk.sh + workflow CI GitHub Actions
- [x] Publicités AdMob : bannière en bas + interstitiel occasionnel (IDs de TEST)

## Passer la pub en réel (avant publication)

1. Créer un compte sur admob.google.com, déclarer l'app, créer les blocs d'annonces.
2. Dans `lib/services/ads_service.dart` : remplacer `bannerUnitId` et
   `interstitialUnitId` par tes vrais identifiants.
3. Dans `setup.sh` : remplacer l'App ID de test
   (`ca-app-pub-3940256099942544~3347511713`) par ton vrai App ID AdMob.
4. AdMob fonctionne même hors Google Play, MAIS interdit le contenu protégé
   sans droits → garder des sources légales.

## Pas encore fait (optionnel)

- [ ] Notifications avant le coup d'envoi (nécessite config native :
      flutter_local_notifications + desugaring Gradle + permissions).
- [ ] Import de playlist locale / plusieurs sources.
- [ ] Guide EPG (XMLTV).

## Rappel légal

L'app ne fournit aucun flux. La légalité dépend de la source que tu y mets.
Agenda et scores = données factuelles publiques (OK).
