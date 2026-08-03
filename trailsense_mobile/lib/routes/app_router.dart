import 'package:get/get.dart';
import '../features/splash/bindings/splash_binding.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/bindings/login_binding.dart';                  
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/bindings/home_binding.dart';                    
import '../features/home/presentation/screens/home_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const home = '/home';

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
      name: home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
