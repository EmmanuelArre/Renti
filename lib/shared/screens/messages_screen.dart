import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/bottom_nav.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/models/chat.dart';
import 'package:renti/repositories/chat_repository.dart';
import 'package:renti/shared/screens/chat_screen.dart';

/// 17 · Mensajes
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = appState.user?.uid ?? '';
    return NavScaffold(
      current: 0,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 12),
            child: BigTitle('Mensajes'),
          ),
          Expanded(
            child: StreamBuilder<List<ChatPreview>>(
              stream: ChatRepository.instance.conversaciones(uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorView(
                    message: 'No se pudieron cargar tus conversaciones.',
                  );
                }
                if (!snap.hasData) return const LoadingView();
                final chats = snap.data!;
                if (chats.isEmpty) {
                  return const EmptyView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Aún no tienes conversaciones',
                    subtitle:
                        'Usa "Contactar" en un alojamiento para escribirle al arrendador.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                      RentiTheme.pad, 0, RentiTheme.pad, 24),
                  children: [for (final c in chats) _ChatRow(chat: c)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final ChatPreview chat;
  const _ChatRow({required this.chat});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(otherId: chat.otherId, name: chat.name),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.line, width: 1.5)),
        ),
        child: Row(
          children: [
            Avatar(chat.initials, size: 48, highlighted: chat.unread),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: chat.unread ? FontWeight.w800 : FontWeight.w400,
                      color: chat.unread ? RentiColors.blue : context.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat.time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.muted,
                  ),
                ),
                const SizedBox(height: 8),
                if (chat.unread)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: RentiColors.orange,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
