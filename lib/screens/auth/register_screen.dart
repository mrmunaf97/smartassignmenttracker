import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../teacher/teacher_dashboard.dart';
import '../student/student_dashboard.dart';
import '../../services/offline_service.dart';
import '../common/color.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart';
import 'package:flutter/foundation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'student';
  final _authService = AuthService();
  final _offlineService = OfflineService();
  bool _loading = false;
  String? _error;

  void _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _authService.signUp(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _role,
      );
      print('Register result: $result');
      if (result != null) {
        final role = result['role'] ?? 'student';
        final user = result['user'];
        // Fetch Firestore user doc for name
        final db = _authService.db;
        final userDoc = await db.collection('users').doc(user.uid).get();
        final userName = userDoc.data()?['name'] ?? _nameController.text;
        await _offlineService.saveUser({
          'uid': user.uid,
          'role': role,
          'email': _emailController.text,
          'name': userName,
        });
        print('Role after register: $role');
        if (!mounted) return;
        if (role == 'teacher') {
          print('Navigating to TeacherDashboard');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => TeacherDashboard()),
            (route) => false,
          );
        } else {
          print('Navigating to StudentDashboard');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => StudentDashboard()),
            (route) => false,
          );
        }
      } else {
        print('Register result is null');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      print('Register error: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: kIsWeb
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _buildRegisterCard(),
                    ),
                  )
                : _buildRegisterCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Card(
      color: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Account',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign up to get started',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
              ],
              onChanged: (val) => setState(() => _role = val!),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Register'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
