import 'package:get/get.dart';
import '../features/splash/bindings/splash_binding.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/bindings/login_binding.dart';
import '../features/auth/bindings/register_binding.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/register_form_screen.dart';
import '../features/auth/presentation/screens/verify_code_screen.dart';
import '../features/auth/presentation/screens/register_success_screen.dart';
import '../features/main/bindings/main_binding.dart';
import '../features/main/presentation/screens/main_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const main = '/main';

  static final routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: welcome,
      page: () => const WelcomeScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: main,
      page: () => const MainScreen(),
      binding: MainBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // ==========================================
    // REGISTRO
    // ==========================================
    GetPage(
      name: '/register',
      page: () => const RegisterScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/register-form',
      page: () => const RegisterFormScreen(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/verify-code',
      page: () => const VerifyCodeScreen(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/register-success',
      page: () => const RegisterSuccessScreen(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}