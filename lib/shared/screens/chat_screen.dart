import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/models/chat.dart';
import 'package:renti/repositories/chat_repository.dart';

/// 18 · Chat en tiempo real con otra persona.
class ChatScreen extends StatefulWidget {
  final String otherId;
  final String name;
  const ChatScreen({super.key, required this.otherId, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _enviando = false;

  String get _miUid => appState.user?.uid ?? '';
  late final String _chatId = ChatRepository.idDe(_miUid, widget.otherId);

  @override
  void initState() {
    super.initState();
    ChatRepository.instance.marcarLeido(_chatId, _miUid);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _input.text.trim();
    if (t.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      await ChatRepository.instance.enviar(
        yo: appState.user,
        otroUid: widget.otherId,
        otroNombre: widget.name,
        texto: t,
      );
      _input.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) showSnack(context, AppState.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 12),
              child: ScreenHeader(title: widget.name),
            ),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: ChatRepository.instance.mensajes(_chatId, _miUid),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return ErrorView(
                      message: 'No se pudieron cargar los mensajes.',
                      onRetry: () => setState(() {}),
                    );
                  }
                  if (!snap.hasData) return const LoadingView();
                  final msgs = snap.data!;
                  if (msgs.isEmpty) {
                    return Center(
                      child: Text(
                        'Escribe tu primer mensaje 👋',
                        style: TextStyle(color: context.muted, fontSize: 16),
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(_scroll.position.maxScrollExtent);
                    }
                  });
                  return ListView.builder(
                    controller: _scroll,
                    padding:
                        const EdgeInsets.symmetric(horizontal: RentiTheme.pad),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) => _Bubble(msgs[i]),
                  );
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(RentiTheme.pad, 8, RentiTheme.pad, 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 6, 6, 6),
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: context.line, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        maxLength: 1000,
                        style: TextStyle(color: context.ink, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: TextStyle(color: context.muted),
                          border: InputBorder.none,
                          isDense: true,
                          counterText: '',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: RentiColors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: _enviando
                            ? const Padding(
                                padding: EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  const _Bubble(this.m);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: m.mine
              ? RentiColors.blue
              : (context.isDark ? const Color(0xFF262B3D) : RentiColors.bubbleGrey),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: m.mine ? Colors.white : context.ink,
          ),
        ),
      ),
    );
  }
}
