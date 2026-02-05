import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login.dart';
import 'screens/auth/signup.dart';
import 'screens/welcome.dart';
import 'screens/home_screen.dart';
import 'screens/route_screen.dart';
import 'screens/ride_screen.dart';
import 'screens/book_ride_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/add_card_screen.dart';
import 'screens/top_up_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/wallet_details_screen.dart';
import 'screens/verify_transfer_screen.dart';
import 'screens/auth/otp_verification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Sure-Ride",
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signup': (context) => SignUpScreen(),
        '/login': (context) => LoginScreen(),
        '/otp': (context) => const OTPScreen(phoneNumber: '', verificationId: '' ),
        '/home': (context) => const HomeScreen(),
        '/route': (context) => const RouteScreen(),
        '/ride': (context) => RideScreen(),
        '/bookride': (context) => BookRideScreen(),
        '/wallet': (context) => WalletScreen(),
        '/add-card': (context) => const AddCardScreen(),
        '/top-up': (context) => TopUpScreen(),
        '/transfer': (context) => const TransferScreen(),
        '/wallet-detail': (context) => const WalletDetailsScreen(amount: 0),
        '/verify-transfer': (context) => const VerifyingTransactionScreen(),
      },
      home: const SplashScreen(),
    );
  }
}