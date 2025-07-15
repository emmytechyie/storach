import 'package:flutter/material.dart';
import 'package:storarch/Screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Screens/landing_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tjlcoderpvovxytqmrox.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqbGNvZGVycHZvdnh5dHFtcm94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAzMzI1MTMsImV4cCI6MjA2NTkwODUxM30.kk2bte4j0HtbOS4D_wtOvKH6SDLS7RVm3SW3xiRX01I',
  );
  print('[main.dart] Supabase initialized. Running app.');

  runApp(const Storarch());
}

class DefaultFirebaseOptions {
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