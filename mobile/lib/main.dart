import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'providers/classcr_state.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClassCRApp());
}

class ClassCRApp extends StatefulWidget {
  const ClassCRApp({super.key});

  @override
  State<ClassCRApp> createState() => _ClassCRAppState();
}

class _ClassCRAppState extends State<ClassCRApp> {
  late final ClassCRState _state;

  @override
  void initState() {
    super.initState();
    _state = ClassCRState();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassCR - College Attendance & CR Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(state: _state),
    );
  }
}
