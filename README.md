# volley_meteo

Application Flutter affichant la météo pour les joueurs de volley.

## Télécharger l'APK sur Android

### 1. Prérequis

- Ton téléphone et ton ordinateur doivent être sur le **même réseau Wi-Fi**
- Sur Android, active **"Sources inconnues"** (Paramètres > Sécurité > Installer des applis inconnues)
- Python 3 installé sur l'ordinateur

Optionnel (pour afficher le QR code dans le terminal) :
```bash
pip3 install qrcode
```

### 2. Construire l'APK

```bash
flutter build apk --release
```

### 3. Lancer le serveur

```bash
python3 serve_apk.py
```

Le terminal affiche l'URL de téléchargement et, si `qrcode` est installé, un QR code directement dans le terminal.

### 4. Télécharger l'appli

- **Via QR code** : scanne le QR code affiché dans le terminal avec l'appareil photo de ton téléphone
- **Via URL** : ouvre l'URL affichée (ex: `http://192.168.x.x:8080/app-release.apk`) dans le navigateur de ton téléphone

Le fichier APK se télécharge, puis installe-le.

Appuie sur `Ctrl+C` pour arrêter le serveur.

### Erreur "adresse déjà utilisée"

Si le port 8080 est déjà occupé, libère-le avec :

```bash
lsof -ti :8080 | xargs kill -9
```

Puis relance `python3 serve_apk.py`.
