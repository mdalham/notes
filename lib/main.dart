import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes/screen/support%20screen/splash_screen.dart';
import 'package:notes/service/provider/database_provider.dart';
import 'package:notes/service/provider/theme_provider.dart';
import 'package:notes/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:user_messaging_platform/user_messaging_platform.dart' as ump;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await MobileAds.instance.initialize();

  try {
    final ump.ConsentInformation consentInfo = await ump
        .UserMessagingPlatform
        .instance
        .requestConsentInfoUpdate();

    if (consentInfo.formStatus == ump.FormStatus.available) {
      await ump.UserMessagingPlatform.instance.showConsentForm();
    }
  } catch (e) {
    debugPrint('Consent check failed: $e');
  }


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NoteProvider()..loadNotes()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notes',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      home: SplashScreen(),
    );
  }
}
