import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'employee_model.dart';

class EmployeeLocalStorage {
  static const String _employeesFile = 'employees.json';
  static const String _syncQueueFile = 'sync_queue.json';

  Future<List<Employee>> loadEmployees() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_employeesFile');

    if (!await file.exists()) {
      return [];
    }

    try {
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = json['data'] as List;
      return data
          .map((e) => Employee.fromLocalJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveEmployees(List<Employee> employees) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_employeesFile');

    final json = {'data': employees.map((e) => e.toJson()).toList()};

    await file.writeAsString(jsonEncode(json));
  }

  Future<List<SyncOperation>> loadPendingOperations() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_syncQueueFile');

    if (!await file.exists()) {
      return [];
    }

    try {
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final operations = json['operations'] as List;
      return operations
          .map((e) => SyncOperation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addSyncOperation(SyncOperation operation) async {
    final operations = await loadPendingOperations();
    operations.add(operation);
    await savePendingOperations(operations);
  }

  Future<void> savePendingOperations(List<SyncOperation> operations) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_syncQueueFile');

    final json = {'operations': operations.map((e) => e.toJson()).toList()};

    await file.writeAsString(jsonEncode(json));
  }

  Future<void> clearPendingOperations() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_syncQueueFile');

    if (await file.exists()) {
      await file.delete();
    }
  }
}
