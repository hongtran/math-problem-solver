import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math_problem_solver/providers/math_solver_provider.dart';
import 'package:math_problem_solver/models/math_problem.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_math_fork/flutter_math.dart';

class ProblemHistoryWidget extends StatelessWidget {
  const ProblemHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MathSolverProvider>(
      builder: (context, provider, child) {
        if (provider.problemHistory.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.problemHistory.length,
          itemBuilder: (context, index) {
            final problem = provider.problemHistory[index];
            return _buildHistoryItem(context, problem, index);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Problems Solved Yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start solving math problems to see your history here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to solve tab
                DefaultTabController.of(context)?.animateTo(0);
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Solve First Problem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
      BuildContext context, MathProblemHistory problem, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showProblemDetails(context, problem),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          problem.problemDescription ?? 'Math Problem',
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(problem.timestamp),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Answer preview and steps info
              if (problem.answer.isNotEmpty || problem.steps.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (problem.answer.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Answer: ${problem.answer.length > 50 ? '${problem.answer.substring(0, 50)}...' : problem.answer}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (problem.steps.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (problem.steps.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.format_list_numbered,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${problem.steps.length} step${problem.steps.length == 1 ? '' : 's'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Thumbnail image
              if (problem.imageBase64.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _base64ToBytes(problem.imageBase64),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reuseProblem(context, problem),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reuse'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareProblem(context, problem),
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Uint8List _base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return Uint8List(0);
    }
  }

  void _showProblemDetails(BuildContext context, MathProblemHistory problem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProblemDetailsSheet(problem: problem),
    );
  }

  void _reuseProblem(BuildContext context, MathProblemHistory problem) {
    final provider = context.read<MathSolverProvider>();
    provider.setSelectedImage(
      _base64ToBytes(problem.imageBase64),
      problem.problemDescription ?? 'math_problem.jpg',
    );

    // Navigate to solve tab
    DefaultTabController.of(context)?.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Problem loaded for solving'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareProblem(BuildContext context, MathProblemHistory problem) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing problem...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _ProblemDetailsSheet extends StatelessWidget {
  final MathProblemHistory problem;

  const _ProblemDetailsSheet({required this.problem});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Problem Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Problem image
                  if (problem.imageBase64.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _base64ToBytes(problem.imageBase64),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Problem info
                  _buildInfoRow('Problem ID', problem.id),
                  _buildInfoRow(
                      'Timestamp', _formatTimestamp(problem.timestamp)),
                  if (problem.problemDescription != null)
                    _buildInfoRow('Description', problem.problemDescription!),

                  const SizedBox(height: 24),

                  // Final Answer section
                  if (problem.answer.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                        ),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: _buildAnswerWidget(context, problem.answer),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Step-by-step solution section
                  if (problem.steps.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                          ),
                          const SizedBox(height: 24),
                          ...problem.steps.asMap().entries.map((entry) {
                            final index = entry.key;
                            final step = entry.value;
                            final isLast = index == problem.steps.length - 1;
                            return Column(
                              children: [
                                _buildStepInline(context, index + 1, step),
                                if (!isLast)
                                  Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    height: 1,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.1),
                                  ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Reuse problem logic here
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reuse This Problem'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('MMM dd, yyyy HH:mm').format(timestamp);
  }

  Uint8List _base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return Uint8List(0);
    }
  }

  // Helper method to build answer widget
  Widget _buildAnswerWidget(BuildContext context, String answer) {
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

  // Extract LaTeX from answer text
  String? _extractLatexFromAnswer(String answer) {
    // Look for LaTeX patterns in the answer
    if (answer.contains(r'\(') && answer.contains(r'\)')) {
      // Extract inline math
      final match = RegExp(r'\\\((.*?)\\\)').firstMatch(answer);
      if (match != null) {
        return match.group(1);
      }
    } else if (answer.contains(r'\[') && answer.contains(r'\]')) {
      // Extract display math
      final match = RegExp(r'\\\[(.*?)\\\]').firstMatch(answer);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  // Helper method to build step widget
  Widget _buildStepWidget(
      BuildContext context, int stepNumber, String stepContent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header with number
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  stepContent,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced step widget that handles math expressions
  Widget _buildStepInline(
      BuildContext context, int stepNumber, String stepContent) {
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

  void _addTextWithMathPlaceholders(List<InlineSpan> spans, String text,
      Map<String, String> mathPlaceholders, BuildContext context, bool isBold) {
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
}
