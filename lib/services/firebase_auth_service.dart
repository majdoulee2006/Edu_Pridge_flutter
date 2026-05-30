import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  // طلب OTP
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function() onCodeSent,
    required void Function(String error) onError,
    required void Function(UserCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        final result = await _auth.signInWithCredential(credential);
        onAutoVerified(result);
      },
      verificationFailed: (FirebaseAuthException e) {
        final msg = switch (e.code) {
          'invalid-phone-number'  => 'رقم الهاتف غير صالح',
          'too-many-requests'     => 'طلبات كثيرة، حاول لاحقاً',
          'quota-exceeded'        => 'تجاوزت الحد المسموح',
          'network-request-failed'=> 'تحقق من الاتصال بالإنترنت',
          _                       => 'حدث خطأ: ${e.message}',
        };
        onError(msg);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken    = resendToken;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // التحقق من الكود
  Future<UserCredential?> verifyOTP({
    required String otp,
    required void Function(String error) onError,
  }) async {
    if (_verificationId == null) {
      onError('اطلب الكود أولاً');
      return null;
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-verification-code' => 'الكود غير صحيح',
        'session-expired'           => 'انتهت صلاحية الكود، اطلب كوداً جديداً',
        'invalid-verification-id'   => 'جلسة غير صالحة، أعد المحاولة',
        _                           => 'خطأ: ${e.message}',
      };
      onError(msg);
      return null;
    }
  }

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();
}
