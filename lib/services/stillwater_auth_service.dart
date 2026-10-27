import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class StillwaterAuthService extends ChangeNotifier {
  static final StillwaterAuthService _instance = StillwaterAuthService._internal();
  factory StillwaterAuthService() => _instance;
  
  StillwaterAuthService._internal() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _currentUser = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('StillwaterAuthService: Firebase Auth listener skipped (not initialized/test mode): $e');
    }
  }

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && !_currentUser!.isAnonymous;
  String? get uid => _currentUser?.uid;
  String? get email => _currentUser?.email;
  String? get displayName => _currentUser?.displayName;
  String? get photoURL => _currentUser?.photoURL;

  bool get isStillwaterSuperUser {
    if (_currentUser == null) return false;
    final suUids = ['stqIDYHVcLRxjclsqaksiKMvSXz2'];
    final suEmails = ['heidlessemail18@gmail.com', 'heidlessemail20@gmail.com', 'heidlessemail22@gmail.com'];
    return suUids.contains(_currentUser!.uid) || suEmails.contains(_currentUser!.email?.toLowerCase());
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return cred;
    } catch (e) {
      debugPrint('Stillwater Auth error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return cred;
    } catch (e) {
      debugPrint('Stillwater Auth sign-up error: $e');
      rethrow;
    }
  }

  bool _isGoogleSignInCancellation(dynamic e) {
    if (e == null) return true;
    if (e is FirebaseAuthException) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        return true;
      }
    }
    final s = e.toString().toLowerCase();
    return s.contains('popup-closed-by-user') ||
        s.contains('popup_closed_by_user') ||
        s.contains('canceled') ||
        s.contains('cancelled') ||
        s.contains('user-cancelled') ||
        s.contains('12501') ||
        s.contains('sign_in_canceled') ||
        s.contains('sign_in_cancelled');
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        return await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User canceled the sign-in flow
          debugPrint('Google Sign-In canceled by user');
          return null;
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      if (_isGoogleSignInCancellation(e)) {
        debugPrint('Google Sign-In canceled/dismissed by user: $e');
        return null;
      }
      debugPrint('Stillwater Google Auth error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous auth error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('SignOut error: $e');
    }
  }
}
