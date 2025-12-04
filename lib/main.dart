import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_word_screen.dart';
import 'screens/word_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'services/database_service.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if user has set up a child profile yet
  final dbService = DatabaseService();
  final profile = await dbService.getChildProfile();
  
  // First time? Start onboarding. Already set up? Go to home.
  final initialRoute = profile == null ? '/onboarding' : '/home';

  runApp(MyVoiceApp(initialRoute: initialRoute));
}

class MyVoiceApp extends StatelessWidget {
  final String initialRoute;

  const MyVoiceApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyVoice',
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/add_word': (context) => const AddWordScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      // Handle dynamic routes with arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/word_detail') {
          final args = settings.arguments as String; // Word ID
          return MaterialPageRoute(
            builder: (context) => WordDetailScreen(wordId: args),
          );
        }
        return null;
      },
    );
  }
}
