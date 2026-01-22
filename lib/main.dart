import 'package:expence_app/providers/export_provider.dart';
import 'package:expence_app/providers/setting_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'providers/auth_provider.dart';
import 'auth_wraper.dart';
import 'providers/expence_provider.dart';
import 'expence_screen.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ExportProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
      ),
    );
    ;
  }
}
