import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:math_problem_solver/providers/math_solver_provider.dart';
import 'package:math_problem_solver/widgets/image_capture_widget.dart';
import 'package:math_problem_solver/widgets/solution_display_widget.dart';
import 'package:math_problem_solver/widgets/problem_history_widget.dart';
import 'package:math_problem_solver/widgets/email_input_dialog.dart';
import 'package:math_problem_solver/pages/solution_demo_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Start with Solve tab as default
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _problemDescriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    // Check API connection on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MathSolverProvider>();
      await provider.checkApiConnection();
      await provider.loadUserEmail();

      // Load user history if email is already set
      if (provider.hasUserEmail) {
        await provider.loadUserProblems(provider.currentUserEmail!);
        // Show welcome back message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Welcome back! Email: ${provider.currentUserEmail}'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _problemDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Problem Solver'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildCurrentTab(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt),
            label: 'Solve',
          ),
          NavigationDestination(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildHistoryTab();
      case 1:
        return _buildSolveTab();
      case 2:
        return _buildAboutTab();
      default:
        return _buildSolveTab();
    }
  }

  /// Show email input dialog
  void _showEmailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmailInputDialog(
        initialEmail: context.read<MathSolverProvider>().currentUserEmail,
        onEmailSubmitted: (email) async {
          await context.read<MathSolverProvider>().setUserEmail(email);
          _problemDescriptionController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email saved: $email'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  /// Handle solve button press
  void _handleSolvePress() {
    final provider = context.read<MathSolverProvider>();

    if (!provider.hasUserEmail) {
      _showEmailDialog();
      return;
    }

    // Continue with solving the problem
    provider.solveMathProblem(
        problemDescription: _problemDescriptionController.text.trim());
  }

  /// Handle tab selection and load history if needed
  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Load history when history tab is selected
    if (index == 0) {
      // History tab
      final provider = context.read<MathSolverProvider>();
      if (provider.hasUserEmail && provider.userProblemHistory.isEmpty) {
        // Load history only if we have an email and no history yet
        provider.loadUserProblems(provider.currentUserEmail!);
      }
    }
  }

  Widget _buildSolveTab() {
    return Consumer<MathSolverProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Solve Math Problems with AI',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Take a photo of your math homework and get step-by-step solutions',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Email display section
                      Consumer<MathSolverProvider>(
                        builder: (context, provider, child) {
                          if (provider.hasUserEmail) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Email: ${provider.currentUserEmail}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _showEmailDialog(),
                                    icon: Icon(
                                      Icons.edit,
                                      color: Colors.green[700],
                                      size: 18,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Warning icon and text in a row
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Email required to save solutions',
                                          style: TextStyle(
                                            color: Colors.orange[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Button in its own row to prevent overflow
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _showEmailDialog,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Add Email'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Image capture section
              ImageCaptureWidget(
                onImageSelected: (Uint8List imageBytes, String fileName) {
                  provider.setSelectedImage(imageBytes, fileName);
                  _problemDescriptionController
                      .clear(); // Clear description when new image is selected
                },
                selectedImage: provider.selectedImage,
                selectedImageName: provider.selectedImageName,
                onClearImage: () {
                  provider.clearSelectedImage();
                  _problemDescriptionController
                      .clear(); // Clear description when image is cleared
                },
              ),
              const SizedBox(height: 24),

              // Problem description input
              if (provider.selectedImage != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Problem Description (Optional)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _problemDescriptionController,
                          decoration: const InputDecoration(
                            hintText:
                                'Add any additional context about the problem...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Solve button
                Tooltip(
                  message: provider.hasUserEmail
                      ? 'Click to solve the math problem'
                      : 'Please add your email first to save solutions',
                  child: ElevatedButton.icon(
                    onPressed: (provider.state == MathSolverState.loading ||
                            !provider.hasUserEmail)
                        ? null
                        : _handleSolvePress,
                    icon: provider.state == MathSolverState.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.science),
                    label: Text(
                      provider.state == MathSolverState.loading
                          ? 'Solving...'
                          : (provider.hasUserEmail
                              ? 'Solve Problem'
                              : 'Add Email'),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          provider.hasUserEmail ? null : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Solution display
              if (provider.currentSolution != null) ...[
                SolutionDisplayWidget(solution: provider.currentSolution!),
                const SizedBox(height: 24),
                // Clear form after successful solution
                ElevatedButton.icon(
                  onPressed: () {
                    provider.clearSolution();
                    _problemDescriptionController.clear();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Solve Another Problem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Error display
              if (provider.errorMessage != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Error',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => provider.clearError(),
                          child: const Text('Dismiss'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<MathSolverProvider>(
      builder: (context, provider, child) {
        // Don't load history here to avoid infinite loops
        // History will be loaded when the tab is first selected

        if (!provider.hasUserEmail) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Email Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter your email to view your problem history',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showEmailDialog,
                  icon: const Icon(Icons.email),
                  label: const Text('Enter Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Email header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'History for: ${provider.currentUserEmail}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showEmailDialog(),
                    icon: Icon(
                      Icons.edit,
                      color: Colors.blue[700],
                      size: 18,
                    ),
                    tooltip: 'Change Email',
                  ),
                  IconButton(
                    onPressed: provider.isLoadingHistory
                        ? null
                        : () {
                            final provider = context.read<MathSolverProvider>();
                            if (provider.hasUserEmail) {
                              provider
                                  .loadUserProblems(provider.currentUserEmail!);
                            }
                          },
                    icon: provider.isLoadingHistory
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.refresh,
                            color: Colors.blue[700],
                            size: 18,
                          ),
                    tooltip: 'Refresh History',
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Email'),
                          content: const Text(
                              'Are you sure you want to clear your email and all saved problems?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await context
                                    .read<MathSolverProvider>()
                                    .clearUserEmail();
                                _problemDescriptionController.clear();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Email and history cleared'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.blue[700],
                      size: 18,
                    ),
                    tooltip: 'Clear Email & History',
                  ),
                ],
              ),
            ),
            // Problem history
            Expanded(
              child: provider.isLoadingHistory
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading your problem history...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : provider.userProblemHistory.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No problems solved yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Solve your first math problem to see it here',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const ProblemHistoryWidget(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Math Problem Solver',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This app uses advanced AI technology to help students solve math problems step by step.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    context,
                    Icons.camera_alt,
                    'Take Photos',
                    'Capture math problems using your device camera',
                  ),
                  _buildFeatureItem(
                    context,
                    Icons.upload,
                    'Upload Images',
                    'Select existing images from your gallery',
                  ),
                  _buildFeatureItem(
                    context,
                    Icons.science,
                    'AI-Powered Solutions',
                    'Get detailed step-by-step explanations',
                  ),
                  _buildFeatureItem(
                    context,
                    Icons.history,
                    'Problem History',
                    'Keep track of all your solved problems',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Use',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildStepItem(context, '1',
                      'Take a photo or upload an image of your math problem'),
                  _buildStepItem(context, '2',
                      'Optionally add a description for better context'),
                  _buildStepItem(context, '3',
                      'Tap "Solve Problem" to get AI-powered solution'),
                  _buildStepItem(context, '4',
                      'Review the step-by-step solution and final answer'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SolutionDemoPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.science),
                      label: const Text(
                        'View Solution Demo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
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

  Widget _buildFeatureItem(
      BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, String step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
