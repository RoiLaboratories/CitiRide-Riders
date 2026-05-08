import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_model.dart';
import 'onboarding_page.dart';
import '../../providers/onboarding_provider.dart';


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  void _goToLastPage() {
    _pageController.animateToPage(
      onboardingPages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _next(BuildContext context, int index) {
    if (index == onboardingPages.length - 1) {
      /// Navigate to Welcome
      Navigator.pushReplacementNamed(context, '/welcome');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(onboardingIndexProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            /// TOP BAR (DOTS + SKIP)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child:Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    /// DOTS
                    Row(
                      children: List.generate(
                        onboardingPages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          height: 8,
                          width: currentIndex == index ? 10 : 8,
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    /// SKIP
                    if (currentIndex != onboardingPages.length - 1)
                      TextButton(
                        onPressed: _goToLastPage,
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: Color(0xFF2F323D),
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            /// PAGE VIEW
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingPages.length,
                onPageChanged: (index) {
                  ref.read(onboardingIndexProvider.notifier).state = index;
                },
                itemBuilder: (ctx, index) =>
                  OnboardingPage(data: onboardingPages[index]),
              ),
            ),

            /// BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: SizedBox(
                width: 300,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _next(context, currentIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    currentIndex == onboardingPages.length - 1
                        ? "Get Started"
                        : "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
