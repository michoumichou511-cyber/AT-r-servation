import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/presence_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/voice_input.dart';

// ─── Model ─────────────────────────────────────────────────────────────────
class MessageModel {
  final int    id;
  final String contenu;
  final int    senderId;
  final DateTime? createdAt;
  final bool   lu;

  const MessageModel({
    required this.id,
    required this.contenu,
    required this.senderId,
    this.createdAt,
    this.lu = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) {
    final raw = j['created_at'] as String? ?? j['date'] as String?;
    final createdAt = parseBackendDate(raw);
    return MessageModel(
      id:        j['id'] as int? ?? 0,
      contenu:   j['contenu'] as String? ?? j['message'] as String? ?? '',
      senderId:  j['sender_id'] as int? ?? j['expediteur_id'] as int? ?? 0,
      createdAt: createdAt,
      lu:        j['lu'] as bool? ?? false,
    );
  }
}

// ─── Conversation Screen ───────────────────────────────────────────────────
class ConversationScreen extends StatefulWidget {
  final int conversationId;
  final String? nomCorrespondant;
  final int? receiverId;
  const ConversationScreen({
    super.key,
    required this.conversationId,
    this.nomCorrespondant,
    this.receiverId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with SingleTickerProviderStateMixin {
  List<MessageModel> _messages = [];
  bool   _loading = true;
  bool   _sending = false;
  bool   _typingIndicator = false;
  Timer? _timer;
  Timer? _presenceTimer;
  PresenceStatus? _presenceStatus;
  late int _convId;
  int? _receiverId;
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();
  late final AnimationController _sendCtrl;

  @override
  void initState() {
    super.initState();
    _convId = widget.conversationId;
    _receiverId = widget.receiverId;
    _sendCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _load();
    _loadPresence();
    _timer = Timer.periodic(const Duration(seconds: 30),
        (_) => _load(silent: true));
    _presenceTimer = Timer.periodic(const Duration(minutes: 1),
        (_) => _loadPresence());
    _ctrl.addListener(() {
      final hasText = _ctrl.text.isNotEmpty;
      if (hasText != _typingIndicator) {
        setState(() => _typingIndicator = hasText);
        if (hasText) { _sendCtrl.forward(); } else { _sendCtrl.reverse(); }
      }
    });
  }

  Future<void> _loadPresence() async {
    if (_receiverId == null) return;
    final status = await PresenceService().fetchStatus(_receiverId!);
    if (mounted && status != null) {
      setState(() => _presenceStatus = status);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _presenceTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    _sendCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    // Nouvelle conversation pas encore créée → liste vide
    if (_convId == 0) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final data = await ApiService().get('/conversations/$_convId/messages');
      // API retourne { data: { messages: [...] } }
      final dynamic rawData = data['data'];
      List list = const [];
      if (rawData is Map<String, dynamic>) {
        final m = rawData['messages'];
        if (m is List) list = m;
      } else if (rawData is List) {
        list = rawData;
      }
      if (mounted) {
        setState(() {
          _messages = list
              .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e is ApiException ? e.message : 'Erreur de chargement',
                style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: DS.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending || _receiverId == null) return;
    HapticFeedback.lightImpact();
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      // POST /messages avec receiver_id — le backend crée la conv si besoin
      await ApiService().post('/messages', {
        'receiver_id': _receiverId,
        'contenu': text,
      });
      // Si nouvelle conversation, trouver l'ID créé par le backend
      if (_convId == 0) {
        await _discoverConversation();
      } else {
        await _load(silent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : e.toString(),
              style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: DS.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Après envoi du premier message, trouve la conversation créée.
  Future<void> _discoverConversation() async {
    try {
      final data = await ApiService().get('/conversations');
      final dynamic rawData = data['data'];
      List list = const [];
      if (rawData is Map<String, dynamic>) {
        final c = rawData['conversations'];
        if (c is List) list = c;
      } else if (rawData is List) {
        list = rawData;
      }
      for (final c in list) {
        if (c is! Map<String, dynamic>) continue;
        final inter = c['interlocuteur'] as Map<String, dynamic>?;
        if (inter != null && inter['id'] == _receiverId) {
          if (mounted) setState(() => _convId = c['id'] as int? ?? 0);
          break;
        }
      }
      await _load(silent: true);
    } catch (_) {}
  }

  // Get initials from name
  String _initiales(String? nom) {
    if (nom == null || nom.isEmpty) return '?';
    return nom.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
  }

  // Dialog d'information pour le bouton appel (VoIP non implémenté)
  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [
          Icon(Icons.call, color: Color(0xFF00A650)),
          SizedBox(width: 8),
          Text('Appel vocal'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_forwarded,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Fonctionnalité d\'appel vocal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Les appels VoIP seront disponibles dans une prochaine '
              'version de l\'application.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me   = context.watch<AuthProvider>().user;
    final nom  = widget.nomCorrespondant ?? 'Conversation';
    final init = _initiales(nom);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: DS.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF001A5E), Color(0xFF003DA5)],
            ),
          ),
        ),
        title: Row(children: [
          // Avatar
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DS.primary, DS.primary.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [BoxShadow(
                color: DS.primary.withValues(alpha: 0.3),
                blurRadius: 8, offset: const Offset(0, 2),
              )],
            ),
            child: Center(child: Text(init,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13, fontWeight: FontWeight.w800,
              ))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nom,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 15,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis),
              Row(children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: (_presenceStatus?.isOnline ?? false)
                        ? DS.success
                        : Colors.white38,
                    shape: BoxShape.circle,
                    boxShadow: (_presenceStatus?.isOnline ?? false)
                        ? [BoxShadow(
                            color: DS.success.withValues(alpha: 0.5),
                            blurRadius: 4, spreadRadius: 1,
                          )]
                        : null,
                  ),
                ),
                Text(
                  _presenceStatus?.label ?? 'En ligne',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white70)),
              ]),
            ],
          )),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, size: 20),
            tooltip: 'Appel vocal',
            onPressed: () => _showCallDialog(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        // ── Messages ────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: SpinKitWave(color: DS.primary, size: 30))
              : _messages.isEmpty
                  ? _EmptyConv()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg    = _messages[i];
                        final isMine = me != null && msg.senderId == me.id;
                        final showDate = i == 0 ||
                            _isDifferentDay(_messages[i - 1].createdAt,
                                msg.createdAt);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDate)
                              _DateDivider(msg.createdAt),
                            _Bubble(
                              msg: msg,
                              isMine: isMine,
                              initiales: init,
                              index: i,
                            ),
                          ],
                        );
                      },
                    ),
        ),

        // ── Input zone ──────────────────────────────────────────────────
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: context.borderColor,
                    width: 1,
                  ),
                ),
                boxShadow: [BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 10, offset: const Offset(0, -2),
                )],
              ),
              padding: EdgeInsets.only(
                left: 12, right: 8, top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: SafeArea(
                top: false,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  // Text field
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: context.inputFill,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _inputFocus.hasFocus
                              ? DS.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              focusNode: _inputFocus,
                              maxLines: 5,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Écrivez un message…',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                hintStyle: GoogleFonts.inter(
                                    color: DS.textPlaceholder, fontSize: 14),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          VoiceInputButton(
                            onResult: (text) {
                              _ctrl.text = _ctrl.text.isEmpty
                                  ? text
                                  : '${_ctrl.text} $text';
                              _ctrl.selection = TextSelection.collapsed(
                                  offset: _ctrl.text.length);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  AnimatedBuilder(
                    animation: _sendCtrl,
                    builder: (ctx, child) => Transform.scale(
                      scale: 0.85 + 0.15 * _sendCtrl.value,
                      child: _sending
                          ? Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: DS.primary.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _send,
                              child: Container(
                                width: 46, height: 46,
                                decoration: BoxDecoration(
                                  gradient: _typingIndicator
                                      ? DS.gradientGreen
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFFD1D5DB),
                                            Color(0xFFD1D5DB),
                                          ],
                                        ),
                                  shape: BoxShape.circle,
                                  boxShadow: _typingIndicator ? DS.shadowGreen : null,
                                ),
                                child: Icon(
                                  Icons.send_rounded,
                                  color: _typingIndicator
                                      ? Colors.white
                                      : DS.textPlaceholder,
                                  size: 20,
                                ),
                              ),
                            ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  bool _isDifferentDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime? date;
  const _DateDivider(this.date);

  String _label() {
    if (date == null) return '';
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(date!.year, date!.month, date!.day);
    final diff  = today.difference(day).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    return DateFormat('EEEE d MMMM', 'fr_FR').format(date!);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Expanded(child: Container(height: 1,
          color: DS.border.withValues(alpha: 0.5))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: DS.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_label(),
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: context.textMuted,
            )),
        ),
      ),
      Expanded(child: Container(height: 1,
          color: DS.border.withValues(alpha: 0.5))),
    ]),
  );
}

// ─── Empty conversation ───────────────────────────────────────────────────
class _EmptyConv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(
          gradient: DS.gradientBlue,
          shape: BoxShape.circle,
          boxShadow: DS.shadowBlue,
        ),
        child: const Icon(Icons.chat_bubble_outline_rounded,
            color: Colors.white, size: 38),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.95, end: 1.0, duration: 2000.ms,
              curve: Curves.easeInOut),
      const SizedBox(height: 20),
      Text('Commencez la conversation',
        style: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary)),
      const SizedBox(height: 6),
      Text('Écrivez le premier message ci-dessous',
        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13)),
    ]),
  );
}

// ─── Message bubble ───────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMine;
  final String initiales;
  final int index;
  const _Bubble({
    required this.msg, required this.isMine,
    required this.initiales, required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = msg.createdAt != null
        ? DateFormat('HH:mm').format(msg.createdAt!)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar interlocuteur
          if (!isMine) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                gradient: DS.gradientBlue,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(initiales.isNotEmpty
                  ? initiales[0] : '?',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10, fontWeight: FontWeight.w800,
                ))),
            ),
          ],

          // Bulle
          Flexible(
            child: Container(
              margin: isMine
                  ? const EdgeInsets.only(left: 60)
                  : const EdgeInsets.only(right: 60),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMine ? DS.gradientGreen : null,
                color: isMine ? null : context.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                boxShadow: isMine
                    ? [BoxShadow(
                        color: DS.primary.withValues(alpha: 0.25),
                        blurRadius: 8, offset: const Offset(0, 3),
                      )]
                    : DS.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(msg.contenu,
                    style: GoogleFonts.inter(
                      color: isMine ? Colors.white : context.textPrimary,
                      fontSize: 14, height: 1.4,
                    )),
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.65)
                            : DS.textPlaceholder,
                      )),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        msg.lu ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 12,
                        color: msg.lu
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: (index * 20).ms)
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.05, duration: 200.ms, curve: Curves.easeOut);
  }
}
