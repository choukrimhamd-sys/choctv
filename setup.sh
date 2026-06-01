#!/usr/bin/env bash
# Prépare le projet de A à Z : dossiers natifs, permissions, version Android, icônes.
#   cd iptv_app && bash setup.sh
set -e

echo "==> 1/6 Génération des dossiers de plateforme (android/, ios/...)"
flutter create .

echo "==> 2/6 Installation des dépendances"
flutter pub get

echo "==> 3/6 Patch du AndroidManifest (INTERNET + HTTP + AdMob)"
python3 - <<'PY'
import os, re
path = 'android/app/src/main/AndroidManifest.xml'
if not os.path.exists(path):
    print('   Manifest introuvable, patch ignoré.')
else:
    s = open(path, encoding='utf-8').read()
    if 'android.permission.INTERNET' not in s:
        idx = s.find('>')
        s = s[:idx+1] + '\n    <uses-permission android:name="android.permission.INTERNET"/>' + s[idx+1:]
    if 'usesCleartextTraffic' not in s:
        s = s.replace('<application',
                      '<application\n        android:usesCleartextTraffic="true"', 1)
    s = re.sub(r'android:label="[^"]*"', 'android:label="chocTV"', s, count=1)
    if 'com.google.android.gms.ads.APPLICATION_ID' not in s:
        meta = ('        <meta-data\n'
                '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
                '            android:value="ca-app-pub-3940256099942544~3347511713"/>\n')
        s = s.replace('</application>', meta + '    </application>', 1)
    open(path, 'w', encoding='utf-8').write(s)
    print('   Manifest patché.')
PY

echo "==> 4/6 Version Android minimale (requise par AdMob)"
python3 - <<'PY'
import os, re
for path in ['android/app/build.gradle.kts', 'android/app/build.gradle']:
    if not os.path.exists(path):
        continue
    s = open(path, encoding='utf-8').read()
    # Kotlin DSL : minSdk = ...
    s = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24', s)
    s = re.sub(r'minSdk\s*=\s*\d+', 'minSdk = 24', s)
    # Groovy : minSdkVersion ...
    s = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24', s)
    s = re.sub(r'minSdkVersion\s+\d+', 'minSdkVersion 24', s)
    open(path, 'w', encoding='utf-8').write(s)
    print('   minSdk forcé à 24 dans', path)
PY

echo "==> 5/6 Génération des icônes chocTV"
dart run flutter_launcher_icons

echo "==> 6/6 Terminé."
echo ""
echo "Construire l'APK : flutter build apk --release"
echo "APK : build/app/outputs/flutter-apk/app-release.apk"
