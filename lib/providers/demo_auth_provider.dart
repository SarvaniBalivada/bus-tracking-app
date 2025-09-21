import 'package:flutter/material.dart';
import 'package:omnitrack/models/user_model.dart';
import 'package:omnitrack/utils/constants.dart';

class DemoAuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _error = null;
      
      // Demo authentication - in real app this would be Firebase
      await Future.delayed(const Duration(seconds: 1));
      
      // Create demo user based on email
      bool isAdmin = email.toLowerCase().contains('admin');
      
      _user = UserModel(
        uid: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: isAdmin ? 'Demo Admin' : 'Demo User',
        role: isAdmin ? UserRoles.admin : UserRoles.user,
        isAdmin: isAdmin,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      _setLoading(true);
      _error = null;
      
      // Demo registration
      await Future.delayed(const Duration(seconds: 1));
      
      _user = UserModel(
        uid: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        role: role,
        isAdmin: role == UserRoles.admin,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}