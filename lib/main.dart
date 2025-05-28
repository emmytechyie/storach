import 'package:flutter/material.dart';
import 'Screens/landing_screen.dart';


void main() {
  runApp(const Storarch());
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
      // Set the initial route to the new LandingScreen
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
   }
  );
 }
}