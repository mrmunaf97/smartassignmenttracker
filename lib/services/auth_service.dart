import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final doc = await _db.collection('users').doc(result.user!.uid).get();
    if (result.user != null) {
      final token = await NotificationService().getFcmToken();
      if (token != null) {
        await _db
            .collection('users')
            .doc(result.user!.uid)
            .update({'fcmToken': token});
      }
    }
    return {'user': result.user, 'role': doc.data()?['role'] ?? 'student'};
  }

  Future<Map<String, dynamic>?> signUp(
      String name, String email, String password, String role) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await _db.collection('users').doc(result.user!.uid).set({
      'name': name,
      'email': email,
      'role': role,
    });
    if (result.user != null) {
      final token = await NotificationService().getFcmToken();
      if (token != null) {
        await _db
            .collection('users')
            .doc(result.user!.uid)
            .update({'fcmToken': token});
      }
    }
    return {'user': result.user, 'role': role};
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, user.uid);
  }
}
