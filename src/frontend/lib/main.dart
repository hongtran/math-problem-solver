import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math_problem_solver/providers/math_solver_provider.dart';
import 'package:math_problem_solver/screens/home_screen.dart';
import 'package:math_problem_solver/utils/theme.dart';

void main() {
  runApp(const MathProblemSolverApp());
}

class MathProblemSolverApp extends StatelessWidget {
  const MathProblemSolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MathSolverProvider()),
      ],
      child: MaterialApp(
        title: 'Math Problem Solver',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
} 
