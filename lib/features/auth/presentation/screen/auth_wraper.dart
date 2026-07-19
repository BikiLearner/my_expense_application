import 'package:expence_app/features/creditCardManagement/presentation/screens/credit_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../home_screen.dart';
import '../../../expense/presentation/screens/expence_screen.dart';
import '../provider/auth_provider.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<AuthProvider>().authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Color(0xFF64FFDA),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: Color(0xFF64FFDA)),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user is logged in
        final user = snapshot.data;

        if (user == null) {
          // User is not logged in - show login screen
          return const LoginScreen();
        }

        // User is logged in - show expense screen
        return const HomeScreen();
      },
    );
  }
}
