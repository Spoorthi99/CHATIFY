import 'package:chatify/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/snackbar_service.dart';
import '../services/navigation_service.dart';
import '../services/db_service.dart';

enum AuthStatus {
  NotAuthenticated,
  Authenticating,
  Authenticated,
  UserNotFound,
  Error,
}

class AuthProvider extends ChangeNotifier {
  FirebaseUser user;
  AuthStatus status;
  FirebaseAuth _auth;
  AuthResult _result;
  static AuthProvider instance = AuthProvider();

  AuthProvider() {
    _auth = FirebaseAuth.instance;
    _checkCurrentUserIsAuthenticated();
  }

  void _autoLogin() async {
    if (user != null) {
      await DBService.instance.updateUserLastSeenTime(user.uid);

      return NavigationService.instance.navigateToReplacement("home");
    }
  }

  void _checkCurrentUserIsAuthenticated() async {
    user = await _auth.currentUser();
    if (user != null) {
      notifyListeners();
      await _autoLogin();
    }
  }

  void loginUserWithEmailAndPassword(String _email, String _password) async {
    status = AuthStatus.Authenticating;
    notifyListeners();
    try {
      _result = await _auth.signInWithEmailAndPassword(
          email: _email, password: _password);
      user = _result.user;
      status = AuthStatus.Authenticated;
      SnackBarService.instance.showSnackBarSuccess("Welcome, ${user.email}");
      await DBService.instance.updateUserLastSeenTime(user.uid);
      NavigationService.instance.navigateToReplacement("home");
    } catch (error) {
      status = AuthStatus.Error;
      user = null;
      switch (error.code) {
        case "ERROR_INVALID_EMAIL":
          SnackBarService.instance.showSnackBarError("Error authenticating");
          break;
        case "ERROR_WRONG_PASSWORD":
          SnackBarService.instance.showSnackBarError("Error authenticating");
          break;
        case "ERROR_USER_NOT_FOUND":
          SnackBarService.instance.showSnackBarError("Error authenticating");
          break;
        case "ERROR_USER_DISABLED":
          SnackBarService.instance.showSnackBarError("Error authenticating");
          break;
        case "ERROR_TOO_MANY_REQUESTS":
          SnackBarService.instance.showSnackBarError("Error authenticating");
          break;
        case "ERROR_OPERATION_NOT_ALLOWED":
          SnackBarService.instance.showSnackBarError("Error authenticating");
          break;
        default:
          SnackBarService.instance.showSnackBarError("Error authenticating");
      }
    }
    /*catch (e) {
      status = AuthStatus.Error;
      user = null;
      SnackBarService.instance.showSnackBarError("Error authenticating");
    
    }*/
    notifyListeners();
  }

  void registerUserWithEmailAndPassword(String _email, String _password,
      Future<void> onSuccess(String _uid)) async {
    status = AuthStatus.Authenticating;
    notifyListeners();
    try {
      AuthResult _result = await _auth.createUserWithEmailAndPassword(
          email: _email, password: _password);
      user = _result.user;
      status = AuthStatus.Authenticated;
      await onSuccess(user.uid);
      SnackBarService.instance.showSnackBarSuccess("Welcome, ${user.email}");
      await DBService.instance.updateUserLastSeenTime(user.uid);
      NavigationService.instance.goBack();
      NavigationService.instance.navigateToReplacement("home");
    } catch (e) {
      status = AuthStatus.Error;
      user = null;
      SnackBarService.instance.showSnackBarError("Error registering user");
    }
    notifyListeners();
  }

  void logoutUSer(Future<void> onSuccess()) async {
    try {
      await _auth.signOut();
      user = null;
      status = AuthStatus.NotAuthenticated;
      await onSuccess();
      await NavigationService.instance.navigateToReplacement("login");
      //SnackBarService.instance.showSnackBarSuccess("Logged out succesfully!");
    } catch (e) {
      SnackBarService.instance.showSnackBarError("Error Logging out");
    }
    notifyListeners();
  }
}
