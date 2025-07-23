import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/providers/auth_provider.dart';
import 'src/providers/loan_provider.dart';
import 'src/providers/language_provider.dart';
import 'src/screens/splash_screen.dart';
import 'src/utils/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
      ],
      child: const FinanceLoanApp(),
    ),
  );
}

class FinanceLoanApp extends StatelessWidget {
  const FinanceLoanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Finance Loan App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: languageProvider.currentLanguage == 'ar' || 
                       languageProvider.currentLanguage == 'ku' 
                ? 'Cairo' 
                : 'Roboto',
            useMaterial3: true,
          ),
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('ar', ''),
            Locale('ku', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
