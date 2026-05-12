# 🤖 Chatbot Réclamations SesaPay

Chatbot IA pour la gestion des réclamations des étudiants concernant leur bourse SesaPay.

---

## 📁 Structure du projet

```
sesapay/
├── backend/
│   ├── server.js       ← Serveur Node.js (contient la clé API, sécurisé)
│   ├── package.json    ← Dépendances Node.js
│   └── .env            ← Clé API Gemini (NE PAS partager !)
│
└── frontend/
    └── index.html      ← Interface du chatbot (aucune clé ici)
```

---

## 🚀 Installation et lancement

### Étape 1 — Installer Node.js
Téléchargez Node.js sur https://nodejs.org (version LTS recommandée)

### Étape 2 — Configurer la clé API
Ouvrez `backend/.env` et remplacez :
```
GEMINI_API_KEY=VOTRE_CLE_GEMINI_ICI
```
par votre vraie clé obtenue sur https://aistudio.google.com

### Étape 3 — Installer les dépendances
Ouvrez un terminal dans le dossier `backend/` et tapez :
```bash
npm install
```

### Étape 4 — Démarrer le backend
```bash
npm start
```
Vous devriez voir :
```
✅ Serveur SesaPay démarré sur http://localhost:3000
```

### Étape 5 — Ouvrir le frontend
Double-cliquez sur `frontend/index.html` dans votre navigateur.
Le chatbot est opérationnel !

---

## 🔒 Sécurité

- La clé API Gemini est uniquement dans `backend/.env`
- Le fichier `.env` ne doit JAMAIS être partagé ou mis sur GitHub
- Le frontend ne contient aucune clé — il parle uniquement au backend

---

## 🌍 Mise en production

Pour déployer en ligne (ex: sur un serveur sénégalais ou Render.com) :
1. Déployez le backend sur un serveur Node.js
2. Changez `BACKEND_URL` dans `frontend/index.html` vers l'URL de votre serveur
3. Hébergez le frontend sur n'importe quel hébergeur web

---

## 📞 Support
Service client SesaPay : +221 78 308 01 01 / +221 78 308 00 00
