import 'package:flutter/material.dart';
import 'package:math_problem_solver/models/math_problem.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class SolutionDisplayWidget extends StatelessWidget {
  final MathSolution solution;

  const SolutionDisplayWidget({
    super.key,
    required this.solution,
  });

  // Static method to create sample solutions for testing
  static MathSolution createSampleSolution1() {
    return MathSolution(
      solution: "To find the angle \\( \\angle BAC \\) in the given triangle, we can use the properties of angles in triangles and straight lines.\n\n1. **Identify the angles**:\n   - \\( \\angle ABC = 42^\\circ \\)\n   - \\( \\angle ADC = 70^\\circ \\)\n   - Since \\( BCD \\) is a straight line, we have:\n     \\[\n     \\angle BCD + \\angle ADC = 180^\\circ\n     \\]\n   - Therefore, \\( \\angle BCD = 180^\\circ - 70^\\circ = 110^\\circ \\).\n\n2. **In triangle \\( ACD \\)**:\n   - Since \\( ACD \\) is an isosceles triangle, we have \\( \\angle ACD = \\angle ADC = 70^\\circ \\).\n   - The sum of angles in triangle \\( ACD \\) is:\n     \\[\n     \\angle ACD + \\angle CAD + \\angle ADC = 180^\\circ\n     \\]\n   - Substituting the known angles:\n     \\[\n     70^\\circ + \\angle CAD + 70^\\circ = 180^\\circ\n     \\]\n   - Simplifying:\n     \\[\n     140^\\circ + \\angle CAD = 180^\\circ\n     \\]\n   - Thus:\n     \\[\n     \\angle CAD = 180^\\circ - 140^\\circ = 40^\\circ\n     \\]\n\n3. **Finding \\( \\angle BAC \\)**:\n   - Since \\( \\angle BAC = \\angle CAD \\):\n     \\[\n     \\angle BAC = 40^\\circ\n     \\]\n\nTherefore, the answer is:\n\n**Answer: 40°**",
      steps: [
        "To find the angle \\( \\angle BAC \\) in the given triangle, we can use the properties of angles in triangles and straight lines.",
        "1. **Identify the angles**:\n   - \\( \\angle ABC = 42^\\circ \\)\n   - \\( \\angle ADC = 70^\\circ \\)\n   - Since \\( BCD \\) is a straight line, we have:\n     \\[\n     \\angle BCD + \\angle ADC = 180^\\circ\n     \\]\n   - Therefore, \\( \\angle BCD = 180^\\circ - 70^\\circ = 110^\\circ \\).",
        "2. **In triangle \\( ACD \\)**:\n   - Since \\( ACD \\) is an isosceles triangle, we have \\( \\angle ACD = \\angle ADC = 70^\\circ \\).\n   - The sum of angles in triangle \\( ACD \\) is:\n     \\[\n     \\angle ACD + \\angle CAD + \\angle ADC = 180^\\circ\n     \\]\n   - Substituting the known angles:\n     \\[\n     70^\\circ + \\angle CAD + 70^\\circ = 180^\\circ\n     \\]\n   - Simplifying:\n     \\[\n     140^\\circ + \\angle CAD = 180^\\circ\n     \\]\n   - Thus:\n     \\[\n     \\angle CAD = 180^\\circ - 140^\\circ = 40^\\circ\n     \\]",
        "3. **Finding \\( \\angle BAC \\)**:\n   - Since \\( \\angle BAC = \\angle CAD \\):\n     \\[\n     \\angle BAC = 40^\\circ\n     \\]",
        "Therefore, the answer is:",
        "**Answer: 40°**"
      ],
      answer: "**Answer: 40°**",
      confidence: 0.95,
      processingTime: 2.3,
    );
  }

  static MathSolution createSampleSolution2() {
    return MathSolution(
      solution: "Complete solution for the expression problem",
      steps: [
        "To solve the expression \\(20 + (24 - 6) + 6 \\times 3\\), we will follow the order of operations (PEMDAS/BODMAS):",
        "1. **Parentheses/Brackets**: Calculate \\(24 - 6\\):\n   \\[\n   24 - 6 = 18\n   \\]",
        "2. **Multiplication**: Calculate \\(6 \\times 3\\):\n   \\[\n   6 \\times 3 = 18\n   \\]",
        "3. **Addition**: Now substitute back into the expression:\n   \\[\n   20 + 18 + 18\n   \\]",
        "4. **Final Calculation**:\n   \\[\n   20 + 18 = 38\n   \\]\n   \\[\n   38 + 18 = 56\n   \\]",
        "Thus, the value of the expression is \\(\\boxed{56}\\)."
      ],
      answer: "56",
      confidence: 0.98,
      processingTime: 1.8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solution',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Solved in ${solution.processingTime.toStringAsFixed(2)}s',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(solution.confidence * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Final answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Final Answer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: _buildAnswerMathWidget(context, solution.answer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step-by-step solution
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_list_numbered,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Step-by-Step Solution',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),

                  if (solution.steps.isNotEmpty) ...[
                    ...solution.steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      final isLast = index == solution.steps.length - 1;
                      return Column(
                        children: [
                          _buildStepInline(context, index + 1, step),
                          if (!isLast) 
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              height: 1,
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                            ),
                        ],
                      );
                    }).toList(),
                  ] else ...[
                    // Fallback to full solution if no steps
                    _buildStepInline(context, 1, solution.solution),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context, solution.solution),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    icon: Icon(
                      Icons.copy,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      'Copy Solution',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareSolution(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Replace simple Text with math-aware widget
  Widget _buildAnswerMathWidget(BuildContext context, String answer) {
    final latex = _extractLatexFromAnswer(answer);
    if (latex != null) {
      return Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            latex,
            textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }
    return Text(
      answer,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
      overflow: TextOverflow.visible,
      softWrap: true,
    );
  }

  Widget _buildStepInline(BuildContext context, int stepNumber, String stepContent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header with number
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRichStepContent(context, stepContent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRichStepContent(BuildContext context, String raw) {
    // Parse the content and render it properly
    return _buildFormattedContent(context, raw);
  }

  Widget _buildFormattedContent(BuildContext context, String text) {
    // First, let's handle the display math blocks that span multiple lines
    final processedText = _preprocessDisplayMath(text);
    
    // Split content by newlines first to handle paragraph structure
    final lines = processedText.split('\n');
    final contentWidgets = <Widget>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        // Add small spacing for empty lines
        contentWidgets.add(const SizedBox(height: 8));
        continue;
      }
      
      // Check if this is a display math block marker
      if (line == '##DISPLAY_MATH##') {
        // Skip this marker line
        continue;
      }
      
      // Check if this line contains display math
      if (line.contains(r'\[') && line.contains(r'\]')) {
        contentWidgets.add(_buildDisplayMathLine(context, line));
      } else if (line.startsWith('DISPLAY_MATH:')) {
        // Handle preprocessed display math
        final mathContent = line.substring('DISPLAY_MATH:'.length);
        contentWidgets.add(_buildDisplayMathWidget(context, mathContent));
      } else {
        // Regular text line with possible inline math and formatting
        contentWidgets.add(
          SizedBox(
            width: double.infinity,
            child: _buildTextLine(context, line),
          ),
        );
      }
      
      // Add spacing between lines (except for the last line)
      if (i < lines.length - 1) {
        contentWidgets.add(const SizedBox(height: 4));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  String _preprocessDisplayMath(String text) {
    // Handle multi-line display math blocks
    final displayMathRegex = RegExp(r'\\\[\s*\n\s*(.*?)\s*\n\s*\\\]', dotAll: true);
    
    return text.replaceAllMapped(displayMathRegex, (match) {
      final mathContent = match.group(1)!.trim();
      return 'DISPLAY_MATH:$mathContent';
    });
  }

  Widget _buildTextLine(BuildContext context, String line) {
    // IMPORTANT: Process math expressions FIRST, then bold formatting
    // This prevents bold regex from capturing math expressions inside bold text
    
    // Step 1: Find and temporarily replace math expressions with placeholders
    final mathPlaceholders = <String, String>{};
    var processedLine = line;
    int mathCounter = 0;
    
    // Replace inline math with placeholders
    final inlineMathRegex = RegExp(r'\\\((.*?)\\\)');
    processedLine = processedLine.replaceAllMapped(inlineMathRegex, (match) {
      final placeholder = '___MATH_${mathCounter++}___';
      mathPlaceholders[placeholder] = match.group(1)!;
      return placeholder;
    });
    
    // Step 2: Now process bold formatting on the line with math placeholders
    final spans = <InlineSpan>[];
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final boldMatches = boldRegex.allMatches(processedLine).toList();
    
    int lastIndex = 0;
    
    for (final boldMatch in boldMatches) {
      // Add text before bold match
      if (boldMatch.start > lastIndex) {
        final textBefore = processedLine.substring(lastIndex, boldMatch.start);
        if (textBefore.isNotEmpty) {
          _addTextWithMathPlaceholders(spans, textBefore, mathPlaceholders, context, false);
        }
      }
      
      // Add bold content (which may contain math placeholders)
      final boldContent = boldMatch.group(1)!;
      _addTextWithMathPlaceholders(spans, boldContent, mathPlaceholders, context, true);
      
      lastIndex = boldMatch.end;
    }
    
    // Add remaining text
    if (lastIndex < processedLine.length) {
      final remainingText = processedLine.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        _addTextWithMathPlaceholders(spans, remainingText, mathPlaceholders, context, false);
      }
    }
    
    // If no special formatting found, return simple text with math processing
    if (spans.isEmpty) {
      _addTextWithMathPlaceholders(spans, processedLine, mathPlaceholders, context, false);
    }
    
    return RichText(
      text: TextSpan(children: spans),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  void _addTextWithMathPlaceholders(
    List<InlineSpan> spans, 
    String text, 
    Map<String, String> mathPlaceholders, 
    BuildContext context, 
    bool isBold
  ) {
    // Find math placeholders in the text and replace them with math widgets
    final mathPlaceholderRegex = RegExp(r'___MATH_\d+___');
    final mathMatches = mathPlaceholderRegex.allMatches(text).toList();
    
    int lastIndex = 0;
    
    for (final mathMatch in mathMatches) {
      // Add text before math
      if (mathMatch.start > lastIndex) {
        final textBefore = text.substring(lastIndex, mathMatch.start);
        if (textBefore.isNotEmpty) {
          spans.add(TextSpan(
            text: textBefore,
            style: _getBaseTextStyle(context).copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ));
        }
      }
      
      // Add math widget
      final placeholder = mathMatch.group(0)!;
      final mathContent = mathPlaceholders[placeholder]!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _buildMathWidget(context, mathContent),
        ),
      ));
      
      lastIndex = mathMatch.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(
          text: remainingText,
          style: _getBaseTextStyle(context).copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ));
      }
    }
  }

  Widget _buildDisplayMathWidget(BuildContext context, String mathContent) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: _buildMathWidget(context, mathContent),
      ),
    );
  }

  Widget _buildMathWidget(BuildContext context, String mathContent) {
    // Debug: print the math content to see what we're trying to render
    print('Rendering math: "$mathContent"');
    
    try {
      // Try to render with Math.tex
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          mathContent,
          textStyle: _getBaseTextStyle(context).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } catch (e) {
      // Debug: print the error
      print('Math rendering error: $e');
      
      // Fallback to plain text with highlighting to show where math should be
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          border: Border.all(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'MATH: $mathContent',
          style: _getBaseTextStyle(context).copyWith(
            fontFamily: 'monospace',
            color: Colors.red,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }

  Widget _buildDisplayMathLine(BuildContext context, String line) {
    // Extract display math content
    final displayMathRegex = RegExp(r'\\\[([\s\S]*?)\\\]');
    final match = displayMathRegex.firstMatch(line);
    
    if (match != null) {
      final mathContent = match.group(1)!.trim();
      return _buildDisplayMathWidget(context, mathContent);
    }
    
    // Fallback to regular text if no display math found
    return _buildTextLine(context, line);
  }

  TextStyle _getBaseTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurface,
    ) ?? const TextStyle(fontSize: 16, height: 1.5);
  }

  String? _extractLatexFromAnswer(String content) {
    // Try to extract LaTeX from various formats
    final display = RegExp(r'\\\[\s*\n?\s*(.*?)\s*\n?\s*\\\]', dotAll: true).firstMatch(content);
    if (display != null) return display.group(1)!.trim();
    
    final inline = RegExp(r'\\\((.*?)\\\)').firstMatch(content);
    if (inline != null) return inline.group(1)!.trim();
    
    // Look for boxed answers
    final boxed = RegExp(r'\\boxed\{(.*?)\}').firstMatch(content);
    if (boxed != null) return boxed.group(1)!.trim();
    
    // Look for bold text that might be the answer
    final bold = RegExp(r'\*\*(.*?)\*\*').firstMatch(content);
    if (bold != null) return bold.group(1)!.trim();
    
    return null;
  }

  void _copyToClipboard(BuildContext context, String text) {
    // In a real app, you would use Clipboard.setData
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Solution copied to clipboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareSolution(BuildContext context) {
    // In a real app, you would use a sharing plugin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sharing solution...'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
