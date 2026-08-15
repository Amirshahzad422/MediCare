import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'styles/colors.dart';
import 'styles/typography.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/doctors_screen.dart';
import 'screens/doctor_details_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/video_call_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/prescriptions_screen.dart';
import 'screens/pharmacy_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/about_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/blog_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/doctor_onboarding_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/review_screen.dart';
import 'screens/patient_onboarding_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/medicine_detail_screen.dart';
import 'screens/doctor_records_screen.dart';
import 'utils/db_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MediCareApp(),
    ),
  );
}

class MediCareApp extends ConsumerStatefulWidget {
  const MediCareApp({super.key});

  @override
  ConsumerState<MediCareApp> createState() => _MediCareAppState();
}

class _MediCareAppState extends ConsumerState<MediCareApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediCare',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.deepBlue,
          primary: AppColors.deepBlue,
          secondary: AppColors.mediumBlue,
          surface: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.white,
        textTheme: TextTheme(
          displayLarge: AppTypography.displayLarge,
          titleLarge: AppTypography.titleLarge,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepBlue,
            foregroundColor: AppColors.white,
            textStyle: AppTypography.buttonText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.deepBlue,
            selectedForegroundColor: AppColors.white,
            backgroundColor: AppColors.iceBlue,
            foregroundColor: AppColors.deepBlue,
            textStyle: AppTypography.bodyMedium,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
          },
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/otp': (context) => const OtpScreen(),
        '/doctor-onboarding': (context) => const DoctorOnboardingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/doctors': (context) => const DoctorsScreen(),
        '/doctor-details': (context) => const DoctorDetailsScreen(),
        '/booking': (context) => const BookingScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/video-call': (context) => const VideoCallScreen(),
        '/chat': (context) => const ChatScreen(),
        '/prescriptions': (context) => const PrescriptionsScreen(),
        '/pharmacy': (context) => const PharmacyScreen(),
        '/medicine-detail': (context) => const MedicineDetailScreen(),
        '/doctor-records': (context) => const DoctorRecordsScreen(),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/orders': (context) => const OrdersScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/doctor-dashboard': (context) => const DoctorDashboardScreen(),
        '/about': (context) => const AboutScreen(),
        '/contact': (context) => const ContactScreen(),
        '/faq': (context) => const FaqScreen(),
        '/blog': (context) => const BlogScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/reviews': (context) => const ReviewScreen(),
        '/patient-onboarding': (context) => const PatientOnboardingScreen(),
        '/not-found': (context) => const NotFoundScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => const NotFoundScreen(),
        );
      },
    );
  }
}