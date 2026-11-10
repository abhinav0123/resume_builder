import 'package:career_ai/screens/sim_binding.dart';
import 'package:flutter/material.dart';
// import 'screens/home_screen.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  runApp(const CareerAiApp());
}

class CareerAiApp extends StatelessWidget {
  const CareerAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4457D9)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
      home: const SimSelectionScreen(),
    );
  }
}
