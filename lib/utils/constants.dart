import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color accentColor = Color(0xFFFF5722);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
}

class AppStrings {
  static const String appName = 'Bus Tracking App';
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to continue';
  static const String adminDashboard = 'Admin Dashboard';
  static const String userDashboard = 'Bus Tracking';
  
  // Firebase collection names
  static const String usersCollection = 'users';
  static const String busesCollection = 'buses';
  static const String stationsCollection = 'stations';
  static const String tripsCollection = 'trips';
  static const String realTimeDataCollection = 'real_time_data';
}

class AppDimensions {
  static const double padding = 16.0;
  static const double margin = 16.0;
  static const double borderRadius = 8.0;
  static const double buttonHeight = 48.0;
  static const double cardElevation = 4.0;
}

class UserRoles {
  static const String admin = 'admin';
  static const String user = 'user';
}

class BusStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String maintenance = 'maintenance';
  static const String emergency = 'emergency';
}

class TripStatus {
  static const String scheduled = 'scheduled';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}