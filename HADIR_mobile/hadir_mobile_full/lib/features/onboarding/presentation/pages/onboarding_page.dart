import 'package:flutter/material.dart';

/// Onboarding page for first-time users
/// 
/// This page introduces users to the HADIR Mobile app features
/// and guides them through the initial setup process.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Welcome to HADIR',
      description: 'AI-Enhanced Student Registration System using advanced computer vision technology.',
      image: Icons.face_retouching_natural,
      color: Colors.blue,
    ),
    OnboardingItem(
      title: 'Smart Face Detection',
      description: 'Our AI automatically detects and analyzes faces to select the best photos for registration.',
      image: Icons.face,
      color: Colors.green,
    ),
    OnboardingItem(
      title: 'Quick Registration',
      description: 'Register students quickly and efficiently with our streamlined process.',
      image: Icons.person_add,
      color: Colors.orange,
    ),
    OnboardingItem(
      title: 'Ready to Start',
      description: 'You\'re all set! Let\'s begin registering students with HADIR.',
      image: Icons.rocket_launch,
      color: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingItems.length,
                itemBuilder: (context, index) {
                  final item = _onboardingItems[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image/Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Icon(
                            item.image,
                            size: 64,
                            color: item.color,
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Title
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          item.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingItems.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_back_ios, size: 16),
                          Text('Previous'),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _currentPage == _onboardingItems.length - 1
                        ? _finishOnboarding
                        : _nextPage,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentPage == _onboardingItems.length - 1 
                            ? 'Get Started' 
                            : 'Next'),
                        if (_currentPage < _onboardingItems.length - 1)
                          const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipOnboarding() {
    // TODO: Navigate to login page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Onboarding skipped - Navigate to Login')),
    );
  }

  void _finishOnboarding() {
    // TODO: Mark onboarding as complete and navigate to login
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Onboarding complete - Navigate to Login')),
    );
  }
}

/// Onboarding item model
class OnboardingItem {
  final String title;
  final String description;
  final IconData image;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}