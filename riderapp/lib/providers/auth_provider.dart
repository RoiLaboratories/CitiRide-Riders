import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;
  ConfirmationResult? _webConfirmationResult;
  bool isLoading = false;

  User? get currentUser => _auth.currentUser;

  /// Generate a temporary username based on phone number
  String _generateTemporaryUsername(String phoneNumber) {
    // Remove non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Take last 6 digits for username
    final lastDigits = digits.length >= 6
        ? digits.substring(digits.length - 6)
        : digits;

    // Generate random 4-digit suffix
    final randomSuffix = (1000 + DateTime.now().millisecondsSinceEpoch % 9000)
        .toString();

    return 'user_${lastDigits}_$randomSuffix';
  }

  /// Send OTP (Android, iOS, Web)
  Future<void> sendVerificationCode({
    required String phoneNumber,
    required void Function(
      String verificationId,
      ConfirmationResult? confirmationResult,
    )
    onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
  }) async {
    isLoading = true;
    _verificationId = null;
    _webConfirmationResult = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        final recaptchaVerifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instanceFor(
            app: Firebase.app(),
            pluginConstants: <dynamic, dynamic>{},
          ),
          container: 'recaptcha-container',
        );

        final confirmationResult = await FirebaseAuth.instance
            .signInWithPhoneNumber(phoneNumber, recaptchaVerifier);
        _webConfirmationResult = confirmationResult;

        debugPrint(
          'sendVerificationCode web: confirmationResult set: ${_webConfirmationResult != null}',
        );

        isLoading = false;
        notifyListeners();
        onCodeSent('', confirmationResult);
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
            await _tryCreateOrUpdateUser();
            isLoading = false;
            notifyListeners();
          },
          verificationFailed: (FirebaseAuthException e) {
            isLoading = false;
            notifyListeners();
            onFailed(e);
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            isLoading = false;
            notifyListeners();
            onCodeSent(verificationId, null);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      if (e is FirebaseAuthException) {
        onFailed(e);
      } else {
        onFailed(FirebaseAuthException(code: 'unknown', message: e.toString()));
      }
    }
  }

  /// Verify OTP (Android, iOS, Web)
  Future<UserCredential> verifyOTP(
    String smsCode, {
    String? verificationId,
    ConfirmationResult? webConfirmationResult,
  }) async {
    UserCredential userCredential;
    final resolvedVerificationId = verificationId ?? _verificationId;
    final resolvedWebConfirmationResult =
        webConfirmationResult ?? _webConfirmationResult;
    // Log inputs for debugging verification issues
    debugPrint(
      'verifyOTP called. hasVerificationId: ${resolvedVerificationId != null}, '
      'hasWebConfirmationResult: ${resolvedWebConfirmationResult != null}, '
      'isWeb: $kIsWeb',
    );

    if (kIsWeb) {
      if (resolvedWebConfirmationResult == null) {
        debugPrint('verifyOTP error: no web confirmation result');
        throw Exception("No web confirmation result found");
      }
      try {
        userCredential = await resolvedWebConfirmationResult.confirm(smsCode);
      } catch (e) {
        debugPrint('Web confirm failed: $e');
        rethrow;
      }
    } else {
      if (resolvedVerificationId == null) {
        debugPrint('verifyOTP error: no verification id available');
        throw Exception("No verification ID found");
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: resolvedVerificationId,
        smsCode: smsCode,
      );

      try {
        userCredential = await _auth.signInWithCredential(credential);
      } catch (e) {
        debugPrint('signInWithCredential failed: $e');
        rethrow;
      }
    }

    await _tryCreateOrUpdateUser();
    _verificationId = null;
    _webConfirmationResult = null;

    return userCredential;
  }

  Future<void> _tryCreateOrUpdateUser() async {
    try {
      await _createOrUpdateUser();
    } catch (e, stackTrace) {
      debugPrint('createOrUpdateUser failed after phone auth: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Create or update user in Firestore with temporary data
  Future<void> _createOrUpdateUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final phoneNumber = user.phoneNumber ?? '';
    final temporaryUsername = _generateTemporaryUsername(phoneNumber);

    final userRef = _firestore.collection('users').doc(user.uid);

    // Check if user already exists
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      // New user - create with temporary username
      await userRef.set({
        'uid': user.uid,
        'phoneNumber': phoneNumber,
        'email': null,
        'displayName': null,
        'temporaryUsername': temporaryUsername,
        'username': temporaryUsername,
        'photoURL': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isVerified': true,
        'isProfileComplete': false,
        'hasAddedEmail': false,
        'hasCustomUsername': false,
      });
    } else {
      // Existing user - update last login time
      await userRef.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  /// Update user profile (can be called later from profile screen)
  Future<void> updateUserProfile({
    String? email,
    String? displayName,
    String? username,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final userRef = _firestore.collection('users').doc(user.uid);
    final updateData = <String, dynamic>{
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };

    // Update email if provided
    if (email != null && email.isNotEmpty) {
      updateData['email'] = email;
      updateData['hasAddedEmail'] = true;

      // You can also update email in Firebase Auth if needed
      // await user.updateEmail(email);
    }

    // Update display name if provided
    if (displayName != null && displayName.isNotEmpty) {
      updateData['displayName'] = displayName;
    }

    // Update username if provided (check if different from temporary)
    if (username != null && username.isNotEmpty) {
      updateData['username'] = username;
      updateData['hasCustomUsername'] = true;
    }

    // Update photo URL if provided
    if (photoURL != null && photoURL.isNotEmpty) {
      updateData['photoURL'] = photoURL;
    }

    // Check if profile is now complete
    final userDoc = await userRef.get();
    final userData = userDoc.data();

    final hasEmail = email != null || (userData?['email'] != null);
    final hasDisplayName =
        displayName != null || (userData?['displayName'] != null);
    final hasCustomUsername =
        username != null || (userData?['hasCustomUsername'] == true);

    updateData['isProfileComplete'] =
        hasEmail && hasDisplayName && hasCustomUsername;

    await userRef.update(updateData);
    notifyListeners();
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data();
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
