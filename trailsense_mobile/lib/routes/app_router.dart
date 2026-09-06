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

import '../features/auth/bindings/forgot_password_binding.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/password_reset_success_screen.dart';

import '../features/perfil/bindings/perfil_binding.dart';
import '../features/perfil/presentation/screens/perfil_screen.dart';
import '../features/perfil/presentation/screens/editar_perfil_screen.dart';

import '../features/senderos/bindings/detalle_sendero_binding.dart';
import '../features/senderos/bindings/senderos_binding.dart';
import '../features/senderos/presentation/screens/detalle_sendero_screen.dart';
import '../features/senderos/presentation/screens/senderos_screen.dart';

import '../features/sesiones/presentation/screens/sesiones_screen.dart';
import '../features/sesiones/presentation/screens/detalle_recorrido_screen.dart';
import '../features/sesiones/presentation/screens/nuevo_recorrido_screen.dart';
import '../features/sesiones/bindings/detalle_recorrido_binding.dart';
import '../features/sesiones/bindings/nuevo_recorrido_binding.dart';
import '../features/sesiones/bindings/sesiones_binding.dart';

import '../features/reportes/bindings/crear_reporte_binding.dart';
import '../features/reportes/bindings/detalle_reporte_binding.dart';
import '../features/reportes/bindings/mis_reportes_binding.dart';
import '../features/reportes/presentation/screens/crear_reporte_screen.dart';
import '../features/reportes/presentation/screens/detalle_reporte_screen.dart';
import '../features/reportes/presentation/screens/mis_reportes_screen.dart';
import '../features/reportes/presentation/screens/reporte_success_screen.dart';


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
    // ==========================================
    // RECUPERACIÓN DE CONTRASEÑA
    // ==========================================
    GetPage(
      name: '/forgot-password',
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/password-reset-success',
      page: () => const PasswordResetSuccessScreen(),
      transition: Transition.rightToLeft,
    ),
    // ==========================================
    // PERFIL
    // ==========================================
    GetPage(
      name: '/perfil',
      page: () => const PerfilScreen(),
      binding: PerfilBinding(),
      transition: Transition.rightToLeft,
    ),

    GetPage(
      name: '/editar-perfil',
      page: () => const EditarPerfilScreen(),
      transition: Transition.rightToLeft,
    ),
    // ==========================================
    // SENDEROS
    // ==========================================
    GetPage(
      name: '/senderos',
      page: () => const SenderosScreen(),
      binding: SenderosBinding(),
    ),
    GetPage(
      name: '/detalle-sendero',
      page: () => const DetalleSenderoScreen(),
      binding: DetalleSenderoBinding(),
      transition: Transition.rightToLeft,
    ),
    // ==========================================
    // RECORRIDOS/SESIONES CAMINATA
    // ==========================================
    GetPage(
      name: '/sesiones',
      page: () => const SesionesScreen(),
      binding: SesionesBinding(),
    ),
    GetPage(
      name: '/nuevo-recorrido',
      page: () => const NuevoRecorridoScreen(),
      binding: NuevoRecorridoBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/detalle-recorrido',
      page: () => const DetalleRecorridoScreen(),
      binding: DetalleRecorridoBinding(),
      transition: Transition.rightToLeft,
    ),
    // ==========================================
    // REPORTES
    // ==========================================
    GetPage(
      name: '/mis-reportes',
      page: () => const MisReportesScreen(),
      binding: MisReportesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/detalle-reporte',
      page: () => const DetalleReporteScreen(),
      binding: DetalleReporteBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/crear-reporte',
      page: () => const CrearReporteScreen(),
      binding: CrearReporteBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/reporte-enviado',
      page: () => const ReporteSuccessScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
