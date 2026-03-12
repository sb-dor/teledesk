import 'package:flutter/foundation.dart';
import 'package:teledesk/src/feature/chats/model/conversation.dart';

enum ChatsTab { open, mine }

class ChatsDataController with ChangeNotifier {
  ChatsTab _selectedTab = ChatsTab.open;
  String _searchQuery = '';
  List<Conversation> _searchResults = [];
  bool _isSearching = false;

  ChatsTab get selectedTab => _selectedTab;
  String get searchQuery => _searchQuery;
  List<Conversation> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  void selectTab(ChatsTab tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;
    notifyListeners();
  }

  void setSearchResults(List<Conversation> results) {
    _searchResults = results;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }
}
