#!/usr/bin/env bash
# Prépare le projet de A à Z : dossiers natifs, permissions, dépendances.
# Utilisation :
#   cd iptv_app
#   bash setup.sh
set -e

echo "==> 1/5 Génération des dossiers de plateforme (android/, ios/...)"
flutter create .

echo "==> 2/5 Installation des dépendances"
flutter pub get

echo "==> 3/5 Patch du AndroidManifest (INTERNET + HTTP en clair)"
python3 - <<'PY'
import os
path = 'android/app/src/main/AndroidManifest.xml'
if not os.path.exists(path):
    print('   Manifest introuvable, patch ignoré.')
else:
    s = open(path, encoding='utf-8').read()
    if 'android.permission.INTERNET' not in s:
        idx = s.find('>')  # fin de la balise <manifest ...>
        s = s[:idx+1] + '\n    <uses-permission android:name="android.permission.INTERNET"/>' + s[idx+1:]
    if 'usesCleartextTraffic' not in s:
        s = s.replace('<application',
                      '<application\n        android:usesCleartextTraffic="true"', 1)
    # Nom affiché sous l'icône
    import re
    s = re.sub(r'android:label="[^"]*"', 'android:label="chocTV"', s, count=1)
    open(path, 'w', encoding='utf-8').write(s)
    print('   Manifest patché.')
PY

echo "==> 4/5 Génération des icônes chocTV"
dart run flutter_launcher_icons

echo "==> 5/5 Terminé."
echo ""
echo "Lancer en debug :   flutter run"
echo "Construire l'APK :  flutter build apk --release"
echo "APK généré dans :   build/app/outputs/flutter-apk/app-release.apk"
