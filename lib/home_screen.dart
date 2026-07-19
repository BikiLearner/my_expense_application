import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/providers/home_navigation_provider.dart';

import 'features/creditCardManagement/presentation/screens/credit_expense_screen.dart';
import 'features/expense/presentation/screens/expence_screen.dart';

/// The new app entry screen. Swipe left/right to move between
/// ExpenseScreen and CreditExpenseScreen — no nav bar, no buttons.
/// The active screen is remembered across app restarts via
/// HomeNavigationProvider.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeNavigationProvider, bool>(
      selector: (_, nav) => nav.initialized,
      builder: (context, initialized, _) {
        if (!initialized) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            ),
          );
        }

        // Stable reference for the PageController + onPageChanged callback.
        // Rebuild is already gated by `initialized` above, so this read
        // won't cause extra rebuilds when currentIndex changes via swipe.
        final nav = context.read<HomeNavigationProvider>();

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: PageView(
            controller: nav.pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: nav.onPageChanged,
            children: const [
              ExpenseScreen(),
              CreditExpenseScreen(),
            ],
          ),
        );
      },
    );
  }
}