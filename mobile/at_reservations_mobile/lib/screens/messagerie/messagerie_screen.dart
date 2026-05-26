import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../design/design_system.dart';
import '../../services/api_service.dart';

// ─── Model ─────────────────────────────────────────────────────────────────
class ConversationModel {
  final int    id;
  final String nom;
  final String? lastMessage;
  final DateTime? lastAt;
  final int    unread;
  final String? initiales;
  final int?   interlocuteurId;

  const ConversationModel({
    required this.id, required this.nom,
    this.lastMessage, this.lastAt,
    this.unread = 0, this.initiales,
    this.interlocuteurId,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j) {
    String? nom;
    int? interlocuteurId;
    // Format réel de l'API : {interlocuteur: {id, name, role}}
    final inter = j['interlocuteur'] as Map<String, dynamic>?;
    if (inter != null) {
      nom = inter['name'] as String?;
      interlocuteurId = inter['id'] as int?;
    }
    // Fallback : liste participants
    if (nom == null) {
      final participants = j['participants'] as List?;
      if (participants != null && participants.isNotEmpty &&
          participants.first is Map<String, dynamic>) {
        final other = participants.first as Map<String, dynamic>;
        nom = '${other['prenom'] ?? ''} ${other['nom'] ?? ''}'.trim();
        interlocuteurId ??= other['id'] as int?;
      }
    }
    nom = (nom?.trim().isNotEmpty == true)
        ? nom!
        : (j['nom'] as String? ?? j['title'] as String? ?? 'Conversation');
    final init = nom.isNotEmpty
        ? nom.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join()
        : '?';
    DateTime? lastAt;
    final rawAt = j['dernier_message_at'] as String?
        ?? j['last_message_at'] as String?
        ?? j['updated_at'] as String?;
    if (rawAt != null) { try { lastAt = DateTime.parse(rawAt); } catch (_) {} }
    return ConversationModel(
      id: j['id'] as int? ?? 0,
      nom: nom,
      lastMessage: j['dernier_message'] as String?
          ?? j['last_message'] as String?,
      lastAt: lastAt,
      unread: j['non_lus'] as int? ?? j['unread_count'] as int? ?? 0,
      initiales: init,
      interlocuteurId: interlocuteurId,
    );
  }
}

// ─── Avatar color helper ───────────────────────────────────────────────────
Color _avatarColor(String name) {
  final colors = [
    DS.secondary,
    DS.primary,
    const Color(0xFF7C3AED),
    const Color(0xFF0891B2),
    const Color(0xFFD97706),
    const Color(0xFF059669),
  ];
  return colors[name.hashCode.abs() % colors.length];
}

// ─── Messagerie Screen ─────────────────────────────────────────────────────
class ImessagerieScreen extends StatefulWidget {
  const ImessagerieScreen({super.key});
  @override
  State<ImessagerieScreen> createState() => _ImessagerieScreenState();
}

class _ImessagerieScreenState extends State<ImessagerieScreen> {
  List<ConversationModel> _convs    = [];
  List<ConversationModel> _filtered = [];
  bool   _loading = true;
  Timer? _timer;
  bool   _searchFocused = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
    _searchCtrl.addListener(_onSearch);
    _searchFocus.addListener(() =>
        setState(() => _searchFocused = _searchFocus.hasFocus));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final data = await ApiService().get('/conversations');
      // L'API retourne { data: { conversations: [...] } }
      final dynamic rawData = data['data'];
      List list = const [];
      if (rawData is Map<String, dynamic>) {
        final c = rawData['conversations'];
        if (c is List) list = c;
      } else if (rawData is List) {
        list = rawData;
      } else if (data is List) {
        list = data;
      }
      if (mounted) {
        final convs = list
            .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _convs    = convs;
          _filtered = convs;
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _convs
          : _convs.where((c) =>
              c.nom.toLowerCase().contains(q) ||
              (c.lastMessage?.toLowerCase().contains(q) ?? false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalUnread = _convs.fold(0, (sum, c) => sum + c.unread);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Hero AppBar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            stretch: true,
            backgroundColor: DS.secondary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, size: 22),
                onPressed: _showNewConv,
                tooltip: 'Nouvelle conversation',
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(fit: StackFit.expand, children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF001A5E), Color(0xFF003DA5), Color(0xFF0057CC)],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                // Wave circles
                Positioned(
                  right: -40, bottom: -40,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  left: -20, top: -20,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DS.primary.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                // Dot pattern
                CustomPaint(painter: _DotsPainter()),
                // Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: DS.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.chat_bubble_rounded,
                                      color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: 8),
                                Text('Messagerie',
                                  style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  )),
                                if (totalUnread > 0) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: DS.error,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [BoxShadow(
                                        color: DS.error.withValues(alpha: 0.4),
                                        blurRadius: 8, offset: const Offset(0, 2),
                                      )],
                                    ),
                                    child: Text('$totalUnread',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 12, fontWeight: FontWeight.w800,
                                      )),
                                  )
                                      .animate(onPlay: (c) => c.repeat())
                                      .scaleXY(begin: 1.0, end: 1.15,
                                          duration: 800.ms, curve: Curves.easeInOut)
                                      .then()
                                      .scaleXY(begin: 1.15, end: 1.0,
                                          duration: 800.ms, curve: Curves.easeInOut),
                                ],
                              ]),
                            ],
                          )),
                        ]),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
            title: Row(children: [
              Text('Messagerie',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
              if (totalUnread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: DS.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$totalUnread',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w800,
                    )),
                ),
              ],
            ]),
          ),

          // ── Search ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _searchFocused
                        ? DS.primary.withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _searchFocused
                          ? DS.primary.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: _searchFocused ? 12 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une conversation…',
                    hintStyle: GoogleFonts.inter(
                        color: DS.textPlaceholder, fontSize: 14),
                    prefixIcon: Icon(IconlyLight.search,
                        color: _searchFocused ? DS.primary : DS.textPlaceholder,
                        size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                size: 16, color: DS.textPlaceholder),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // ── Compteur résultats ────────────────────────────────────────
          if (!_loading && _convs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text(
                  '${_filtered.length} conversation${_filtered.length > 1 ? "s" : ""}',
                  style: GoogleFonts.inter(
                    color: DS.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // ── Contenu ───────────────────────────────────────────────────
          if (_loading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => const _ConvSkeleton(),
                childCount: 7,
              ),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                isSearch: _searchCtrl.text.isNotEmpty,
                onNew: _showNewConv,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == _filtered.length) return const SizedBox(height: 140);
                  return _ConvTile(
                    conv: _filtered[i],
                    index: i,
                    onTap: () {
                      final conv = _filtered[i];
                      final nomEnc = Uri.encodeComponent(conv.nom);
                      final recvId = conv.interlocuteurId ?? 0;
                      context.go('/messagerie/${conv.id}?nom=$nomEnc&receiverId=$recvId');
                    },
                  );
                },
                childCount: _filtered.length + 1,
              ),
            ),
        ],
      ),
    );
  }

  void _showNewConv() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _NewConvSheet(
        onSelectUser: (userId, userName) {
          Navigator.pop(sheetCtx);
          final nomEnc = Uri.encodeComponent(userName);
          context.go('/messagerie/0?nom=$nomEnc&receiverId=$userId');
        },
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isSearch;
  final VoidCallback onNew;
  const _EmptyState({required this.isSearch, required this.onNew});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 110, height: 110,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.secondary.withValues(alpha: 0.04),
              ),
            ),
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                gradient: DS.gradientBlue,
                shape: BoxShape.circle,
                boxShadow: DS.shadowBlue,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded,
                size: 32, color: Colors.white),
            ),
          ]),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.95, end: 1.0, duration: 2000.ms,
                curve: Curves.easeInOut),
        const SizedBox(height: 24),
        Text(
          isSearch ? 'Aucun résultat' : 'Aucune conversation',
          style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w800, color: DS.textPrimary),
        )
            .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
        const SizedBox(height: 8),
        Text(
          isSearch
              ? 'Essayez avec un autre terme'
              : 'Commencez une nouvelle discussion',
          style: GoogleFonts.inter(color: DS.textSecondary, fontSize: 14),
        )
            .animate().fadeIn(delay: 200.ms),
        if (!isSearch) ...[
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onNew,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: DS.gradientGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: DS.shadowGreen,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Nouvelle conversation',
                  style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
              ]),
            ),
          )
              .animate().fadeIn(delay: 300.ms),
        ],
      ]),
    ),
  );
}

// ─── Skeleton ─────────────────────────────────────────────────────────────
class _ConvSkeleton extends StatelessWidget {
  const _ConvSkeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: const Color(0xFFE5E7EB),
    highlightColor: const Color(0xFFF9FAFB),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Container(width: 54, height: 54, decoration: const BoxDecoration(
          color: Colors.white, shape: BoxShape.circle)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 140,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7))),
            const SizedBox(height: 8),
            Container(height: 11, width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5))),
          ],
        )),
      ]),
    ),
  );
}

// ─── Tile de conversation ─────────────────────────────────────────────────
class _ConvTile extends StatefulWidget {
  final ConversationModel conv;
  final int index;
  final VoidCallback onTap;
  const _ConvTile({
    required this.conv, required this.index, required this.onTap,
  });
  @override
  State<_ConvTile> createState() => _ConvTileState();
}

class _ConvTileState extends State<_ConvTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final conv     = widget.conv;
    final hasUnread = conv.unread > 0;
    final timeStr  = conv.lastAt != null
        ? timeago.format(conv.lastAt!, locale: 'fr')
        : '';
    final color = _avatarColor(conv.nom);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: _pressed
          ? const Color(0xFFF0F4FF)
          : hasUnread
              ? DS.primary.withValues(alpha: 0.02)
              : Colors.white,
      child: InkWell(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            // Avatar with optional unread indicator ring
            Stack(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: hasUnread
                      ? Border.all(color: DS.primary, width: 2.5)
                      : null,
                  boxShadow: [BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8, offset: const Offset(0, 3),
                  )],
                ),
                child: Center(child: Text(conv.initiales ?? '?',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 18,
                  ))),
              ),
              if (hasUnread)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: DS.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        conv.unread > 9 ? '9+' : '${conv.unread}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 8, fontWeight: FontWeight.w800,
                        )),
                    ),
                  ),
                ),
            ]),
            const SizedBox(width: 14),
            // Texte
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(conv.nom,
                    style: GoogleFonts.inter(
                      fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15, color: DS.textPrimary),
                    overflow: TextOverflow.ellipsis)),
                  Text(timeStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: hasUnread ? DS.primary : DS.textMuted,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400)),
                ]),
                const SizedBox(height: 4),
                Text(
                  conv.lastMessage ?? 'Pas encore de message',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: hasUnread ? DS.textSecondary : DS.textMuted,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
          ]),
        ),
      ),
    )
        .animate(delay: (widget.index * 50).ms)
        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
        .slideX(begin: 0.06, duration: 280.ms, curve: Curves.easeOut);
  }
}

// ─── New conversation sheet ───────────────────────────────────────────────
class _NewConvSheet extends StatefulWidget {
  final void Function(int userId, String userName) onSelectUser;
  const _NewConvSheet({required this.onSelectUser});
  @override
  State<_NewConvSheet> createState() => _NewConvSheetState();
}

class _NewConvSheetState extends State<_NewConvSheet> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      // /utilisateurs/contacts retourne {data:{contacts:[{id,nom_complet,email,role,...}]}}
      final resp = await ApiService().get('/utilisateurs/contacts');
      final data = resp is Map<String, dynamic> ? resp['data'] : null;
      final rawList = data is Map<String, dynamic> ? data['contacts'] : null;
      final List<dynamic> source = rawList is List ? rawList : [];
      final flat = source
          .whereType<Map<String, dynamic>>()
          .map((u) => {
                'id':    u['id'],
                'name':  u['nom_complet'] as String? ?? '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.trim(),
                'email': u['email'] as String? ?? '',
                'role':  u['role'] as String? ?? '',
              })
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      if (mounted) {
        setState(() { _users = flat; _filtered = flat; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger les contacts : $e'),
            backgroundColor: DS.error,
          ),
        );
      }
    }
  }

  void _onSearch() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users.where((u) =>
              (u['name'] as String? ?? '').toLowerCase().contains(q) ||
              (u['email'] as String? ?? '').toLowerCase().contains(q) ||
              (u['role'] as String? ?? '').toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height * 0.75;
    return Container(
      height: sh,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        // Handle
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2))),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: DS.gradientBlue,
                shape: BoxShape.circle,
                boxShadow: DS.shadowBlue,
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nouvelle conversation',
                  style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: DS.textPrimary)),
                Text('Sélectionnez un destinataire',
                  style: GoogleFonts.inter(
                    fontSize: 12, color: DS.textSecondary)),
              ])),
          ]),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _search,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur…',
              hintStyle: GoogleFonts.inter(
                  color: DS.textPlaceholder, fontSize: 14),
              prefixIcon: Icon(IconlyLight.search,
                  color: DS.textPlaceholder, size: 18),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(child: Text(
                      _users.isEmpty
                          ? 'Aucun utilisateur disponible'
                          : 'Aucun résultat',
                      style: GoogleFonts.inter(color: DS.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final u = _filtered[i];
                        final name = u['name'] as String? ?? '';
                        final role = u['role'] as String? ?? '';
                        final init = name.split(' ').take(2)
                            .map((w) => w.isNotEmpty ? w[0] : '').join();
                        final color = _avatarColor(name);
                        return ListTile(
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: Text(init,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 16))),
                          ),
                          title: Text(name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 14,
                              color: DS.textPrimary)),
                          subtitle: Text(role,
                            style: GoogleFonts.inter(
                              fontSize: 12, color: DS.textMuted)),
                          onTap: () => widget.onSelectUser(
                              u['id'] as int, name),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        );
                      },
                    ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ─── Dots painter ─────────────────────────────────────────────────────────
class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final rng = Random(42);
    for (var i = 0; i < 20; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 3 + 1,
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
