import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/claims/new_claim_screen.dart';
import '../features/claims/claim_detail_screen.dart';
import '../features/reports/report_screen.dart';
import '../models/claim_model.dart';
import '../models/report_model.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/new-claim',
      builder: (context, state) => const NewClaimScreen(),
    ),
    GoRoute(
      path: '/claim-detail',
      builder: (context, state) =>
          ClaimDetailScreen(claim: state.extra as ClaimModel),
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) =>
          ReportScreen(report: state.extra as ReportModel),
    ),
  ],
);
