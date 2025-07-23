import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:storarch/Screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'Screens/landing_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['https://tjlcoderpvovxytqmrox.supabase.co']!,
    anonKey: dotenv.env[
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqbGNvZGVycHZvdnh5dHFtcm94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAzMzI1MTMsImV4cCI6MjA2NTkwODUxM30.kk2bte4j0HtbOS4D_wtOvKH6SDLS7RVm3SW3xiRX01I']!,
  );

  runApp(const Storarch());
}

class DefaultFirebaseOptions {
  // ignore: prefer_typing_uninitialized_variables
  static var currentPlatform;
}

class Storarch extends StatelessWidget {
  const Storarch({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Storarch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}
