import 'package:flutter/material.dart';
import '../../data/browser_service.dart';
import '../../domain/request_entry.dart';

class BrowserSpyProvider extends ChangeNotifier {
  final BrowserService _browserService = BrowserService();
  final List<RequestEntry> _capturedRequests = [];
  bool _isBrowserOpen = false;

  List<RequestEntry> get capturedRequests =>
      List.unmodifiable(_capturedRequests);

  // Filtering
  String _searchText = '';
  final Set<String> _activeFilters = {
    'xhr',
    'fetch',
    'document',
  }; // Default useful filters

  String get searchText => _searchText;
  Set<String> get activeFilters => Set.unmodifiable(_activeFilters);

  List<RequestEntry> get filteredRequests {
    return _capturedRequests.where((req) {
      // 1. Text Search (URL)
      if (_searchText.isNotEmpty &&
          !req.url.toLowerCase().contains(_searchText.toLowerCase())) {
        return false;
      }

      // 2. Resource Type Filter
      // If "All" is logically implied by empty filters or we want explicit control?
      // Let's say if filters are empty, show all? Or usually show none?
      // Better: if filter set is empty, maybe show all.
      // But typically we want specific types.

      if (_activeFilters.isEmpty) {
        return true; // Show all if nothing selected? Or none?
      }

      final type = req.resourceType?.toLowerCase() ?? 'other';

      // Simplification: Puppeteer types are verbose.
      // We might want to group them or match loosely.
      // Common: 'xhr', 'fetch', 'document', 'script', 'stylesheet', 'image', 'other'

      if (_activeFilters.contains('all')) return true;

      // Check exact match or mapped match
      if (_activeFilters.contains(type)) return true;

      // Handle 'other' fallback
      if (_activeFilters.contains('other') && type == 'other') return true;

      return false;
    }).toList();
  }

  bool get isBrowserOpen => _isBrowserOpen;

  BrowserSpyProvider() {
    _browserService.requestStream.listen((entry) {
      _capturedRequests.insert(0, entry); // Add to top
      notifyListeners();
    });
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  void toggleFilter(String filter) {
    if (filter == 'all') {
      if (_activeFilters.contains('all')) {
        _activeFilters.clear();
      } else {
        _activeFilters.clear();
        _activeFilters.add('all');
      }
    } else {
      _activeFilters.remove('all');
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    }
    notifyListeners();
  }

  Future<void> launchBrowser() async {
    await _browserService.launchBrowser();
    _isBrowserOpen = true;
    notifyListeners();
  }

  Future<void> stopBrowser() async {
    await _browserService.stopBrowser();
    _isBrowserOpen = false;
    notifyListeners();
  }

  void clearHistory() {
    _capturedRequests.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _browserService.dispose();
    super.dispose();
  }
}
