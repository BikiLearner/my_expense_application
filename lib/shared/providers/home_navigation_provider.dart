import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global provider that owns which of the two swipeable screens
/// (Expense = 0, Credit Card = 1) is currently active.
///
/// - Persists the last active screen to SharedPreferences so it survives
///   app restarts.
/// - Exposes a single [PageController] so any widget can trigger a
///   smooth, animated switch between the two screens (e.g. a bottom
///   nav bar, a button inside ExpenseScreen, etc.) without needing
///   direct access to the PageView itself.
/// - Exposes [showCredit] as a derived flag so any widget (like the
///   grand-total card, quick stats, etc.) can theme itself for the
///   credit-card screen without keeping its own separate state that
///   could drift out of sync with [currentIndex].
class HomeNavigationProvider extends ChangeNotifier {
  static const String _prefKey = 'home_screen_index';

  static const int expenseIndex = 0;
  static const int creditIndex = 1;

  int _currentIndex = expenseIndex;
  int get currentIndex => _currentIndex;

  /// True whenever the Credit Card screen (index 1) is the active one.
  /// Derived from [currentIndex] — never set independently, so it can
  /// never disagree with which screen is actually showing.
  bool get showCredit => _currentIndex == creditIndex;

  bool _initialized = false;
  bool get initialized => _initialized;

  PageController? _pageController;
  PageController get pageController {
    _pageController ??= PageController(initialPage: _currentIndex);
    return _pageController!;
  }

  HomeNavigationProvider() {
    _loadSavedIndex();
  }

  Future<void> _loadSavedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    _currentIndex = prefs.getInt(_prefKey) ?? expenseIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, index);
  }

  /// Call this from PageView's onPageChanged (fires on user swipe).
  void onPageChanged(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    _saveIndex(index);
    notifyListeners();
  }

  /// Call this from ANYWHERE (a button, a tab bar, another screen) to
  /// programmatically switch the active screen with a smooth animation.
  Future<void> switchToScreen(int index, {bool animate = true}) async {
    if (index == _currentIndex) return;

    final controller = _pageController;
    if (controller != null && controller.hasClients) {
      if (animate) {
        await controller.animateToPage(
          index,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
        );
      } else {
        controller.jumpToPage(index);
      }
    }

    _currentIndex = index;
    await _saveIndex(index);
    notifyListeners();
  }

  /// Convenience helper for a flip/toggle button — switches between the
  /// two screens without the caller needing to know the raw indices.
  Future<void> toggleScreen({bool animate = true}) {
    return switchToScreen(
      showCredit ? expenseIndex : creditIndex,
      animate: animate,
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
}