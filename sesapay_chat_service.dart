import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================
// sesapay_chat_service.dart
// Communique avec le backend Node.js SesaPay
// A remplacer par l'URL du serveur en production
// quand il sera configuré
// ============================================================

// MARK: - Modèles de données

class ChatPart {
  final String text;
  ChatPart({required this.text});
  Map<String, dynamic> toJson() => {'text': text};
}

class ChatMessage {
  final String role;
  final List<ChatPart> parts;
  ChatMessage({required this.role, required this.parts});
  Map<String, dynamic> toJson() => {
    'role': role,
    'parts': parts.map((p) => p.toJson()).toList(),
  };
}

class ChatResponse {
  final String reply;
  final String? ticket;
  ChatResponse({required this.reply, this.ticket});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply:  json['reply']  ?? 'Désolé, je ne peux pas répondre pour le moment.',
      ticket: json['ticket'],
    );
  }
}

// MARK: - Service Principal

class SesaPayChatService {

  // A remplacer par l'URL du serveur en production
  static const String backendURL = 'https://chatbot-sesapay-production.up.railway.app';

  // Timeout 60 secondes
  static const Duration timeout = Duration(seconds: 60);

  // Historique complet de la conversation
  final List<ChatMessage> _history = [];

  // --------------------------------------------------------
  // Vérifier que le serveur est opérationnel
  // Appelez au chargement de l'écran chat
  // --------------------------------------------------------
  Future<bool> verifierServeur() async {
    try {
      final response = await http
          .get(Uri.parse('$backendURL/health'))
          .timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --------------------------------------------------------
  // Envoyer un message et recevoir une réponse
  // --------------------------------------------------------
  Future<ChatResponse> envoyerMessage(String texte) async {
    // Ajouter le message de l'étudiant à l'historique
    _history.add(ChatMessage(
      role:  'user',
      parts: [ChatPart(text: texte)],
    ));

    try {
      final response = await http
          .post(
            Uri.parse('$backendURL/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'history': _history.map((m) => m.toJson()).toList(),
              // nom et telephone seront extraits automatiquement
              // par le backend via extraireInfos()
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatResponse = ChatResponse.fromJson(data);

        // Ajouter la réponse du bot à l'historique
        _history.add(ChatMessage(
          role:  'model',
          parts: [ChatPart(text: chatResponse.reply)],
        ));

        return chatResponse;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      // Retirer le dernier message en cas d'erreur
      if (_history.isNotEmpty) _history.removeLast();
      rethrow;
    }
  }

  // --------------------------------------------------------
  // Réinitialiser la conversation (nouvelle session)
  // --------------------------------------------------------
  void reinitialiser() {
    _history.clear();
  }
}
