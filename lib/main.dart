import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_tracking_app/providers/demo_auth_provider.dart';
import 'package:bus_tracking_app/providers/demo_bus_provider.dart';
import 'package:bus_tracking_app/screens/auth/login_screen.dart';
import 'package:bus_tracking_app/screens/admin/admin_dashboard.dart';
import 'package:bus_tracking_app/screens/user/user_dashboard.dart';
import 'package:bus_tracking_app/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase removed for web demo - will work with Android
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DemoAuthProvider()),
        ChangeNotifierProvider(create: (_) => DemoBusProvider()),
      ],
      child: MaterialApp(
        title: 'Bus Tracking App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primaryColor,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/user': (context) => const UserDashboard(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DemoAuthProvider>(
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