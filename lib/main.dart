import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'styles/colors.dart';
import 'styles/typography.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/doctor_details_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/video_call_screen.dart';
import 'screens/prescriptions_screen.dart';

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

class MediCareApp extends StatelessWidget {
  const MediCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediCare',
      debugShowCheckedModeBanner: false,
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
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/doctor-details': (context) => const DoctorDetailsScreen(),
        '/booking': (context) => const BookingScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/appointments': (context) => const AppointmentsScreen(),
        '/video-call': (context) => const VideoCallScreen(),
        '/prescriptions': (context) => const PrescriptionsScreen(),
        '/pharmacy': (context) => const Scaffold(
          body: Center(
            child: Text('Pharmacy Store (Coming Soon!)'),
          ),
        ),
      },
    );
  }
}