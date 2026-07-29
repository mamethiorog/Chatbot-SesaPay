import 'package:flutter/material.dart';
import 'sesapay_chat_service.dart';

// ============================================================
// chat_screen.dart
// Interface du chatbot SesaPay — couleurs jaune/doré officielles
// ============================================================

// MARK: - Modèle message UI
class MessageUI {
  final String texte;
  final bool estBot;
  final String heure;
  MessageUI({required this.texte, required this.estBot, required this.heure});
}

// MARK: - Couleurs SesaPay
class SesaPayColors {
  static const Color jauneMain    = Color(0xFFF3BC2D);
  static const Color jauneClair   = Color(0xFFFFCE52);
  static const Color jaunePale    = Color(0xFFFFD66B);
  static const Color fondChat     = Color(0xFFFFFDF5);
  static const Color fondPage     = Color(0xFFF8F6EF);
  static const Color texteDore    = Color(0xFFD89C00);
  static const Color texteOr      = Color(0xFFA06B00);
  static const Color fondFooter   = Color(0xFFFFF7D8);
  static const Color borderFooter = Color(0xFFFFD66B);
}

// MARK: - Écran principal du chat
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SesaPayChatService _chatService = SesaPayChatService();
  final List<MessageUI>    _messages    = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController   _scrollController = ScrollController();
  bool _isLoading = false;

  // Réponses rapides
  final List<String> _quickRepliesDefault = [
    "Ma bourse n'est pas arrivée",
    "Je ne peux pas retirer",
    "Mon solde est incorrect",
    "Mon compte est bloqué",
  ];

  @override
  void initState() {
    super.initState();
    _verifierEtDemarrer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------
  // Vérifier le serveur et envoyer le message de bienvenue
  // --------------------------------------------------------
  Future<void> _verifierEtDemarrer() async {
    setState(() => _isLoading = true);
    final estOk = await _chatService.verifierServeur();
    if (estOk) {
      await _envoyerMessage("Bonjour", afficherDansUI: false);
    } else {
      setState(() => _isLoading = false);
      _afficherErreur("Impossible de joindre le serveur. Vérifiez votre connexion.");
    }
  }

  // --------------------------------------------------------
  // Envoyer un message
  // --------------------------------------------------------
  Future<void> _envoyerMessage(String texte, {bool afficherDansUI = true}) async {
    if (texte.trim().isEmpty || _isLoading) return;

    if (afficherDansUI) {
      _ajouterMessage(texte, estBot: false);
      _controller.clear();
    }

    setState(() => _isLoading = true);

    try {
      final response = await _chatService.envoyerMessage(texte);
      _ajouterMessage(response.reply, estBot: true);

      // Si un ticket a été créé
      if (response.ticket != null) {
        _afficherBanniereTicket(response.ticket!);
      }
    } catch (e) {
      _afficherErreur(
        "Connexion impossible. Contactez le service client au +221 78 308 01 01",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --------------------------------------------------------
  // Ajouter un message dans la liste
  // --------------------------------------------------------
  void _ajouterMessage(String texte, {required bool estBot}) {
    final heure = TimeOfDay.now().format(context);
    setState(() {
      _messages.add(MessageUI(texte: texte, estBot: estBot, heure: heure));
    });
    _scrollerVersLeBas();
  }

  void _scrollerVersLeBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --------------------------------------------------------
  // Afficher une erreur
  // --------------------------------------------------------
  void _afficherErreur(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Erreur"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // Bannière de confirmation ticket
  // --------------------------------------------------------
  void _afficherBanniereTicket(String numeroTicket) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ Ticket $numeroTicket créé · Notre équipe vous contactera bientôt",
          style: const TextStyle(color: Color(0xFFA06B00)),
        ),
        backgroundColor: const Color(0xFFFFF3DC),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SesaPayColors.fondPage,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Barre de chargement
          if (_isLoading)
            LinearProgressIndicator(
              backgroundColor: SesaPayColors.jaunePale,
              color: SesaPayColors.jauneMain,
              minHeight: 3,
            ),

          // Zone messages
          Expanded(
            child: Container(
              color: SesaPayColors.fondChat,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageRow(msg);
                },
              ),
            ),
          ),

          // Réponses rapides (uniquement si dernier message est du bot)
          if (_messages.isNotEmpty && _messages.last.estBot && !_isLoading)
            _buildQuickReplies(),

          // Barre de saisie
          _buildInputBar(),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // AppBar
  // --------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF3BC2D),
              Color(0xFFFFCE52),
              Color(0xFFFFD66B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            child: const Text("🤖", style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Assistant SesaPay",
                style: TextStyle(
                  color: Color(0xFFE8F5F7),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8B818),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Réclamations bourses · En ligne",
                    style: TextStyle(color: Color(0xFFE8F5F7), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // --------------------------------------------------------
  // Ligne de message
  // --------------------------------------------------------
  Widget _buildMessageRow(MessageUI msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.estBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar bot
          if (msg.estBot) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: SesaPayColors.jauneClair,
              child: const Text("🤖", style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 6),
          ],

          // Bulle
          Flexible(
            child: Column(
              crossAxisAlignment: msg.estBot
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.estBot ? Colors.white : null,
                    gradient: msg.estBot
                        ? null
                        : const LinearGradient(
                            colors: [
                              Color(0xFFF3BC2D),
                              Color(0xFFFFCE52),
                              Color(0xFFFFD66B),
                            ],
                          ),
                    border: msg.estBot
                        ? Border.all(color: const Color(0xFFE0E0E0))
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(msg.estBot ? 4 : 16),
                      bottomRight: Radius.circular(msg.estBot ? 16 : 4),
                    ),
                  ),
                  child: Text(
                    msg.texte,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: msg.estBot ? const Color(0xFF222222) : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    msg.heure,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFFAAAAAA)),
                  ),
                ),
              ],
            ),
          ),

          // Avatar user
          if (!msg.estBot) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE8E8E8),
              child: const Text("👤", style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // Réponses rapides
  // --------------------------------------------------------
  Widget _buildQuickReplies() {
    return Container(
      color: SesaPayColors.fondChat,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickRepliesDefault.map((qr) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: OutlinedButton(
                onPressed: () => _envoyerMessage(qr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SesaPayColors.texteDore,
                  side: const BorderSide(color: SesaPayColors.jauneMain, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: Text(qr),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // Barre de saisie
  // --------------------------------------------------------
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              onSubmitted: _envoyerMessage,
              decoration: InputDecoration(
                hintText: "Décrivez votre problème...",
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: SesaPayColors.jauneClair, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading
                ? null
                : () => _envoyerMessage(_controller.text),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: [
                          Color(0xFFF3BC2D),
                          Color(0xFFFFCE52),
                          Color(0xFFFFD66B),
                        ],
                      ),
                color: _isLoading ? Colors.grey.shade300 : null,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // Footer
  // --------------------------------------------------------
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      color: SesaPayColors.fondFooter,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: SesaPayColors.borderFooter),
        ),
      ),
      child: const Text(
        "Service client · +221 78 308 01 01 · +221 78 308 00 00",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: SesaPayColors.texteOr),
      ),
    );
  }
}
