import 'package:flutter/material.dart';

class AppConstants {
  static const String googleApiKey = 'AIzaSyBzOsBP82jE7eJvzywPDbS5t8YvkZQhTmo'; // Replace with your actual Google Maps API key
}

class AppColors {
  // Primary colors - Modern blue gradient theme
  static const Color primaryColor = Color(0xFF1E88E5); // Bright blue
  static const Color primaryLight = Color(0xFF6AB7FF);
  static const Color primaryDark = Color(0xFF005CB2);

  // Secondary colors - Teal accent
  static const Color secondaryColor = Color(0xFF00ACC1); // Teal
  static const Color secondaryLight = Color(0xFF5DDEF4);
  static const Color secondaryDark = Color(0xFF007C91);

  // Accent colors
  static const Color accentColor = Color(0xFFFF6F00); // Orange accent
  static const Color accentLight = Color(0xFFFFA040);
  static const Color accentDark = Color(0xFFC43E00);

  // Background and surface colors
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFEF5350);

  // Transport specific colors
  static const Color busActive = Color(0xFF4CAF50);
  static const Color busInactive = Color(0xFF9E9E9E);
  static const Color busEmergency = Color(0xFFF44336);
  static const Color busMaintenance = Color(0xFFFF9800);

  // Map colors
  static const Color mapMarkerBus = Color(0xFF1E88E5);
  static const Color mapMarkerStation = Color(0xFF00ACC1);
  static const Color mapRouteLine = Color(0xFF1E88E5);
}

class AppStrings {
  static const String appName = 'OmniTrack';
  static const String loginTitle = 'Welcome to OmniTrack';
  static const String loginSubtitle = 'Your journey starts here';
  static const String adminDashboard = 'Admin Dashboard';
  static const String userDashboard = 'OmniTrack';
  
  // Firebase collection names
  static const String usersCollection = 'users';
  static const String busesCollection = 'buses';
  static const String stationsCollection = 'stations';
  static const String routesCollection = 'routes';
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