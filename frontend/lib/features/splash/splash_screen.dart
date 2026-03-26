import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF43A047),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 56,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 600),
                      child: const Text(
                        'Disaster',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    FadeInDown(
                      delay: const Duration(milliseconds: 350),
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'Compensation',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[100],
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeIn(
                      delay: const Duration(milliseconds: 700),
                      duration: const Duration(milliseconds: 800),
                      child: const Text(
                        'Automated · Fast · Transparent',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: FadeIn(
                  delay: const Duration(milliseconds: 900),
                  duration: const Duration(milliseconds: 600),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
