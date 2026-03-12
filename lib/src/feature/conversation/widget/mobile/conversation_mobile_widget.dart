import 'package:flutter/material.dart';
import 'package:teledesk/src/feature/conversation/widget/desktop/conversation_desktop_widget.dart';

/// On mobile the conversation UI is the same as desktop (full screen).
/// We reuse ConversationDesktopWidget directly.
class ConversationMobileWidget extends StatelessWidget {
  const ConversationMobileWidget({super.key});

  @override
  Widget build(BuildContext context) => const ConversationDesktopWidget();
}
