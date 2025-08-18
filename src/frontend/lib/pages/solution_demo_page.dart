import 'package:flutter/material.dart';
import '../widgets/solution_display_widget.dart';
import '../models/math_problem.dart';

class SolutionDemoPage extends StatefulWidget {
  const SolutionDemoPage({super.key});

  @override
  State<SolutionDemoPage> createState() => _SolutionDemoPageState();
}

class _SolutionDemoPageState extends State<SolutionDemoPage> {
  int currentSolutionIndex = 0;

  final List<MathSolution> sampleSolutions = [
    SolutionDisplayWidget.createSampleSolution2(),
    SolutionDisplayWidget.createSampleSolution1(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Solution Display Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Solution selector
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Sample Solution:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (int i = 0; i < sampleSolutions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Solution ${i + 1}'),
                          selected: currentSolutionIndex == i,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                currentSolutionIndex = i;
                              });
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Solution display
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SolutionDisplayWidget(
                solution: sampleSolutions[currentSolutionIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
