import 'package:hive/hive.dart';
import '../models/assignment.dart';
import '../models/submission.dart';

class OfflineService {
  static const String userBoxName = 'userBox';

  Future<void> saveAssignments(List<Assignment> assignments) async {
    final box = await Hive.openBox('assignments');
    await box.put('list', assignments.map((a) => a.toMap()).toList());
  }

  Future<List<Assignment>> getAssignments() async {
    final box = await Hive.openBox('assignments');
    final data = box.get('list', defaultValue: []);
    return (data as List)
        .map((e) =>
            Assignment.fromMap(Map<String, dynamic>.from(e), e['id'] ?? ''))
        .toList();
  }

  Future<void> saveSubmissions(List<Submission> submissions) async {
    final box = await Hive.openBox('submissions');
    await box.put('list', submissions.map((s) => s.toMap()).toList());
  }

  Future<List<Submission>> getSubmissions() async {
    final box = await Hive.openBox('submissions');
    final data = box.get('list', defaultValue: []);
    return (data as List)
        .map((e) =>
            Submission.fromMap(Map<String, dynamic>.from(e), e['id'] ?? ''))
        .toList();
  }

  Future<void> saveUser(Map<String, dynamic> userData) async {
    final box = await Hive.openBox(userBoxName);
    await box.put('user', userData);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final box = await Hive.openBox(userBoxName);
    return (box.get('user') as Map?)?.cast<String, dynamic>();
  }

  Future<void> clearUser() async {
    final box = await Hive.openBox(userBoxName);
    await box.delete('user');
  }
}
