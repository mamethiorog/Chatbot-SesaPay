# 🤖 SesaPay Chatbot — Assistant de Réclamations

Assistant IA pour la gestion des réclamations des étudiants concernant leur bourse SesaPay. Développé dans le cadre d'un stage à SesaPay.

---

## 📁 Structure du projet

```
sesapay-chatbot/
│
├── backend/
│   ├── server.js               ← Serveur Node.js principal
│   ├── package.json            ← Dépendances Node.js
│   ├── .env                    ← Variables d'environnement (⚠️ ne pas partager)
│   └── .gitignore              ← Exclut .env et node_modules
│
├── front/
│   └── index.html              ← Interface web du chatbot (démo / test)
│
└── flutter/
    ├── sesapay_chat_service.dart  ← Service de communication avec le backend
    ├── chat_screen.dart           ← Interface Flutter du chatbot
    └── pubspec_dependencies.txt   ← Dépendance à ajouter dans pubspec.yaml
```

---

## 🏗️ Architecture globale

```
Application Flutter (iOS + Android)
            │
            ▼
    Node.js Backend (API REST)
            │
    ┌───────┴───────┐
    │               │
 Gemini API      MongoDB
 (IA Gemini)    (Base de données)
    │
 Nodemailer
 (Tickets email)
```

---

## ⚙️ Prérequis

- **Node.js** v18 ou supérieur
- **npm** v8 ou supérieur
- **Flutter** SDK 3.x
- Un compte **Google AI Studio** → clé API Gemini 
- Un cluster **MongoDB Atlas** (gratuit) ou MongoDB local
- Un compte **Gmail** avec mot de passe d'application activé

---

## 🚀 Installation et lancement du backend

### 1. Cloner le dépôt

```bash
git clone https://github.com/mamethiorog/sesapay-chatbot.git
cd sesapay-chatbot/backend
```

### 2. Installer les dépendances

```bash
npm install
```

### 3. Configurer les variables d'environnement

Créez un fichier `.env` dans le dossier `backend/` :

```env
# ── API Gemini ──────────────────────────────────────────────
# Obtenir sur : https://aistudio.google.com
GEMINI_API_KEY=AIzaSy...

# ── MongoDB ─────────────────────────────────────────────────
# Obtenir sur : https://cloud.mongodb.com
MONGODB_URI=mongodb+srv://utilisateur:motdepasse@cluster.mongodb.net/sesapay

# ── Email (tickets de réclamation) ──────────────────────────
# Utiliser un mot de passe d'application Gmail
# https://myaccount.google.com/apppasswords
EMAIL_USER=expediteur@gmail.com
EMAIL_PASS=xxxx xxxx xxxx xxxx
EMAIL_DESTINATAIRE=service-client@sesatechnologies.com
EMAIL_CC=superviseur@sesatechnologies.com,autre@sesatechnologies.com

# ── Serveur ──────────────────────────────────────────────────
PORT=3000
```

### 4. Lancer le serveur

```bash
npm start
```

Vous devez voir :

```
✅ MongoDB connecté
✅ Serveur SesaPay demarre sur http://localhost:3000
📧 Email: expediteur@gmail.com
🎯 Tickets vers: callcenter@sesatechnologies.com
```

### 5. Vérifier que tout fonctionne

```bash
curl http://localhost:3000/health
```

Réponse attendue :

```json
{
  "status": "ok",
  "service": "SesaPay Chatbot API",
  "mongodb": "connecté"
}
```

---

## 🌐 Interface web (démo)

Ouvrez `front/index.html` dans votre navigateur **après** avoir lancé le backend.

> ⚠️ Ne pas ouvrir le fichier HTML en double-cliquant dessus — le navigateur bloquera les requêtes vers localhost. Servez-le depuis Node.js ou un serveur local.

Pour le servir depuis Node.js, ajoutez cette route dans `server.js` :

```js
const fs   = require("fs");
const path = require("path");

// Route pour servir le frontend
if (req.method === "GET" && req.url === "/") {
  const filePath = path.join(__dirname, "../front/index.html");
  fs.readFile(filePath, function(err, data) {
    if (err) { res.writeHead(404); res.end("Non trouvé"); return; }
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end(data);
  });
  return;
}
```

Puis ouvrez : **http://localhost:3000**

---

## 📱 Intégration Flutter

### 1. Copier les fichiers

Copiez `sesapay_chat_service.dart` et `chat_screen.dart` dans votre projet Flutter :

```
lib/
└── features/
    └── chatbot/
        ├── sesapay_chat_service.dart
        └── chat_screen.dart
```

### 2. Ajouter la dépendance HTTP

Dans `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
```

Puis :

```bash
flutter pub get
```

### 3. Configurer l'URL du backend

Dans `sesapay_chat_service.dart`, remplacez :

```dart
static const String backendURL = 'https://chatbot-sesapay-production.up.railway.app';
```

Par l'URL du serveur SesaPay en production :

```dart
static const String backendURL = 'https://votre-serveur.sesatechnologies.com';
```

### 4. Intégrer l'écran dans la navigation

```dart
import 'features/chatbot/chat_screen.dart';

// Dans votre navigator ou router :
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ChatScreen()),
);
```

---

## 🗄️ Base de données MongoDB

Le backend crée automatiquement 4 collections :

| Collection | Contenu |
|---|---|
| `students` | Nom et téléphone des étudiants |
| `conversations` | Historique complet des échanges |
| `tickets` | Réclamations créées avec statut |
| `analytics` | Statistiques d'usage |

---

## 🔌 API REST — Documentation

### GET `/health`
Vérifie que le serveur et MongoDB sont opérationnels.

**Réponse :**
```json
{
  "status": "ok",
  "service": "SesaPay Chatbot API",
  "mongodb": "connecté"
}
```

---

### POST `/chat`
Envoie un message et reçoit une réponse de l'IA.

**Headers :**
```
Content-Type: application/json
```

**Corps de la requête :**
```json
{
  "history": [
    {
      "role": "user",
      "parts": [{ "text": "Bonjour" }]
    },
    {
      "role": "model",
      "parts": [{ "text": "Bonjour ! Votre prénom et nom ?" }]
    },
    {
      "role": "user",
      "parts": [{ "text": "Mamadou Diallo, 77 123 45 67" }]
    }
  ]
}
```

**Réponse normale :**
```json
{
  "reply": "Merci Mamadou ! Quel est votre problème ?"
}
```

**Réponse avec ticket créé :**
```json
{
  "reply": "Votre ticket SESA-482910 a été créé ! Notre équipe vous contactera bientôt.",
  "ticket": "SESA-482910"
}
```

---

## 🔒 Sécurité

- La clé API Gemini est uniquement dans `.env` — jamais exposée au client
- Le fichier `.env` est exclu de Git via `.gitignore`
- Le frontend ne communique jamais directement avec Gemini
- Les variables sensibles sur le serveur de production sont configurées via les variables d'environnement du système

---

## 🌍 Déploiement en production

Sur le serveur SesaPay, configurez les variables d'environnement au niveau du système :

```bash
export GEMINI_API_KEY="AIzaSy..."
export MONGODB_URI="mongodb+srv://..."
export EMAIL_USER="..."
export EMAIL_PASS="..."
export EMAIL_DESTINATAIRE="..."
export EMAIL_CC="..."
export PORT=3000
```

Puis lancez avec **PM2** pour que le serveur reste actif en permanence :

```bash
npm install -g pm2
pm2 start server.js --name "sesapay-chatbot"
pm2 save
pm2 startup
```

---

## 📞 Contact & Support

- **Développeur** : Mame Thioro Gueye (stagiaire SesaPay) +33745463453

---

## 🔮 Évolutions intéressantes ou suggestions

- [ ] Intégration d'une base documentaire (RAG) pour des réponses basées sur les documents internes SesaPay
- [ ] Tableau de bord admin pour visualiser les analytics
- [ ] Support vocal via Twilio (serveur vocal interactif) : Une évolution naturelle serait d'intégrer une interface vocale via Twilio Voice. L'architecture backend Node.js que j'ai mise en place est déjà compatible — il suffirait d'ajouter une route de gestion des appels et de connecter les services de reconnaissance et synthèse vocale. Cela permettrait à SesaPay d'avoir un serveur vocal interactif (SVI) intelligent qui répond aux appels des étudiants avant de les rediriger vers un agent humain si nécessaire.


