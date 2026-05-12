// ============================================================
// BACKEND SesaPay — Serveur Node.js
// La clé API Gemini est sécurisée ici, invisible au navigateur
// ============================================================

const http = require("http");
const https = require("https");
require("dotenv").config();

const API_KEY = process.env.GEMINI_API_KEY;
const PORT = process.env.PORT || 3000;

const SYSTEM_PROMPT = `Tu es l'assistant virtuel de SesaPay, la plateforme de paiement des bourses étudiantes au Sénégal.

Contexte SesaPay :
- SesaPay est un porte-monnaie électronique pour étudiants sénégalais
- Les étudiants reçoivent leur bourse mensuelle via l'application SesaPay (Android et iOS)
- Points de retrait à Dakar : Fass, Massalikoul, Bop, Cité Keur Gorgui
- Points dans les universités : UGB (Saint-Louis), UASZ (Ziguinchor)
- Retrait avec codes #SES depuis l'application
- Service client : +221 78 308 01 01 ou +221 78 308 00 00
- Pour voir la disponibilité de la bourse : menu "Notifications" de l'application

Problèmes fréquents :
1. Bourse non reçue → vérifier les notifications, actualiser l'app, si persistant contacter le service client
2. Impossible de retirer / code SES ne fonctionne pas → vérifier le solde, aller dans un point agréé, contacter service client
3. Solde incorrect → vérifier dans l'accueil de l'app, contacter service client
4. Compte bloqué → contacter service client immédiatement
5. Problème de connexion → réinstaller l'app, vérifier connexion internet

Instructions :
- Réponds toujours en français, de façon claire et bienveillante
- Pose des questions ciblées pour identifier le problème précis
- Donne des étapes concrètes et numérotées
- Si non résolu, dirige vers le service client avec le numéro
- Maximum 4 phrases par réponse
- Au premier message, présente-toi brièvement et demande le type de problème`;

// -----------------------------------------------------------
// Appel à l'API Gemini (côté serveur, clé jamais exposée)
// -----------------------------------------------------------
function callGemini(history, callback) {
  const body = JSON.stringify({
    system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
    contents: history,
    generationConfig: { maxOutputTokens: 500, temperature: 0.7 }
  });

  const options = {
    hostname: "generativelanguage.googleapis.com",
    //path: `/v1beta/models/gemini-2.0-flash:generateContent?key=${API_KEY}`,
    path: `/v1beta/models/gemini-2.5-flash:generateContent?key=${API_KEY}`,
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(body)
    }
  };

  const req = https.request(options, (res) => {
    let data = "";
    res.on("data", (chunk) => (data += chunk));
    res.on("end", () => {
      try {
        const parsed = JSON.parse(data);
        const reply = parsed.candidates?.[0]?.content?.parts?.[0]?.text
          || "Désolé, je ne peux pas répondre pour le moment.";
        callback(null, reply);
      } catch (e) {
        callback("Erreur de parsing Gemini");
      }
    });
  });

  req.on("error", (e) => callback(e.message));
  req.write(body);
  req.end();
}

// -----------------------------------------------------------
// Serveur HTTP simple
// -----------------------------------------------------------
const server = http.createServer((req, res) => {

  // Headers CORS — autorise le frontend à appeler ce backend
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  // Réponse aux preflight CORS
  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  // Route santé — pour vérifier que le serveur tourne
  if (req.method === "GET" && req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", service: "SesaPay Chatbot API" }));
    return;
  }

  // Route principale — reçoit le message et retourne la réponse IA
  if (req.method === "POST" && req.url === "/chat") {
    let body = "";
    req.on("data", (chunk) => (body += chunk));
    req.on("end", () => {
      try {
        const { history } = JSON.parse(body);

        if (!history || !Array.isArray(history)) {
          res.writeHead(400, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: "Le champ 'history' est requis." }));
          return;
        }

        callGemini(history, (err, reply) => {
          if (err) {
            res.writeHead(500, { "Content-Type": "application/json" });
            res.end(JSON.stringify({ error: err }));
          } else {
            res.writeHead(200, { "Content-Type": "application/json" });
            res.end(JSON.stringify({ reply }));
          }
        });

      } catch (e) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "JSON invalide." }));
      }
    });
    return;
  }

  // Route inconnue
  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "Route introuvable." }));
});

server.listen(PORT, () => {
  console.log(`✅ Serveur SesaPay démarré sur http://localhost:${PORT}`);
  console.log(`   → Route chat  : POST http://localhost:${PORT}/chat`);
  console.log(`   → Route santé : GET  http://localhost:${PORT}/health`);
  if (API_KEY === "VOTRE_CLE_GEMINI_ICI" || !API_KEY) {
    console.warn("⚠️  ATTENTION : Clé API Gemini non configurée dans le fichier .env !");
  }
});
