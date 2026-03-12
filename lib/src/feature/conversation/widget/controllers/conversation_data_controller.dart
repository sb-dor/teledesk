import 'package:flutter/foundation.dart';
import 'package:teledesk/src/feature/quick_replies/model/quick_reply.dart';

class ConversationDataController with ChangeNotifier {
  String _messageText = '';
  bool _showQuickReplies = false;
  List<QuickReply> _filteredReplies = [];
  bool _isNoteMode = false;

  String get messageText => _messageText;
  bool get showQuickReplies => _showQuickReplies;
  List<QuickReply> get filteredReplies => _filteredReplies;
  bool get isNoteMode => _isNoteMode;

  void setMessageText(String text, List<QuickReply> allReplies) {
    _messageText = text;
    if (text.startsWith('#') && text.length > 1) {
      final query = text.substring(1).toLowerCase();
      _filteredReplies = allReplies
          .where(
            (r) => r.title.toLowerCase().contains(query) || r.content.toLowerCase().contains(query),
          )
          .toList();
      _showQuickReplies = _filteredReplies.isNotEmpty;
    } else if (text == '#') {
      _filteredReplies = allReplies;
      _showQuickReplies = true;
    } else {
      _showQuickReplies = false;
      _filteredReplies = [];
    }
    notifyListeners();
  }

  void selectQuickReply(QuickReply reply) {
    _messageText = reply.content;
    _showQuickReplies = false;
    _filteredReplies = [];
    notifyListeners();
  }

  void toggleNoteMode() {
    _isNoteMode = !_isNoteMode;
    notifyListeners();
  }

  void clearMessage() {
    _messageText = '';
    _showQuickReplies = false;
    _filteredReplies = [];
    notifyListeners();
  }
}
