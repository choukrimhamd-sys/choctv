#!/usr/bin/env bash
# Prépare ET construit l'APK en une seule commande.
#   cd iptv_app && bash build_apk.sh
set -e
bash setup.sh
echo "==> Construction de l'APK release"
flutter build apk --release
echo ""
echo "✅ APK prêt : build/app/outputs/flutter-apk/app-release.apk"
