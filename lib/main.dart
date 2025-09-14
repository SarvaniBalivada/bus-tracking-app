import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bus_tracking_app/firebase_options.dart';
import 'package:bus_tracking_app/providers/auth_provider.dart';
import 'package:bus_tracking_app/providers/bus_provider.dart';
import 'package:bus_tracking_app/screens/auth/login_screen.dart';
import 'package:bus_tracking_app/screens/admin/admin_dashboard.dart';
import 'package:bus_tracking_app/screens/user/user_dashboard.dart';
import 'package:bus_tracking_app/screens/user/bus_route_search_screen.dart';
import 'package:bus_tracking_app/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
      ],
      child: MaterialApp(
        title: 'Bus Tracking App',
        theme: ThemeData(
          primaryColor: AppColors.primaryColor,
          primaryColorLight: AppColors.primaryLight,
          primaryColorDark: AppColors.primaryDark,
          scaffoldBackgroundColor: AppColors.backgroundColor,
          cardColor: AppColors.surfaceColor,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppColors.primaryColor.withValues(alpha: 0.3),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintStyle: const TextStyle(color: AppColors.textHint),
          ),
          textTheme: TextTheme(
            bodyLarge: const TextStyle(color: AppColors.textPrimary),
            bodyMedium: const TextStyle(color: AppColors.textPrimary),
            titleLarge: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/user': (context) => const UserDashboard(),
          '/route-search': (context) => const BusRouteSearchScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (auth.user == null) {
          return const LoginScreen();
        }
        
        // Check user role and navigate accordingly
        if (auth.user!.isAdmin) {
          return const AdminDashboard();
        } else {
          return const UserDashboard();
        }
      },
    );
  }
}