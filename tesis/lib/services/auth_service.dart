import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  /// Mensaje pendiente para mostrar en el login tras un bloqueo (cuenta borrada).
  static String? pendingLoginError;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Crear/actualizar usuario en DB
    final user = credential.user!;
    final now = DateTime.now().toIso8601String();
    final userRef = _db.child('users/${user.uid}');
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      // Bloqueo especial: cuenta marcada como borrada
      if (data['deleted'] == true || data['status'] == 'deleted') {
        pendingLoginError = 'Cuenta borrada. Contacta al administrador.';
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-deleted',
          message: 'Cuenta borrada',
        );
      }
      await userRef.update({
        'lastLogin': now,
        'loginCount': ((data['loginCount'] as int?) ?? 0) + 1,
        'updatedAt': now,
      });
    } else {
      // Obtener todos los chips
      final devicesSnap = await _db.child('devices').get();
      final defaultChips = <String, bool>{};
      if (devicesSnap.exists) {
        final devices = devicesSnap.value as Map;
        for (var chipId in devices.keys) {
          defaultChips[chipId.toString()] = false;
        }
      }

      await userRef.set({
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'createdAt': now,
        'lastLogin': now,
        'loginCount': 1,
        'role': 'user',
        'status': 'active',
        'provider': 'email/password',
        'chips': defaultChips,
      });
    }

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }
}
