import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'employee_model.dart';

class EmployeeLocalStorage {
  static const String _employeesFile = 'employees.json';
  static const String _syncQueueFile = 'sync_queue.json';
  static const String _localIdCounterFile = 'local_id_counter.json';

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

  Future<Employee?> loadEmployee(int id) async {
    final employees = await loadEmployees();
    try {
      return employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveEmployees(List<Employee> employees) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_employeesFile');

    final json = {'data': employees.map((e) => e.toJson()).toList()};

    await file.writeAsString(jsonEncode(json));
  }

  Future<void> addEmployee(Employee employee) async {
    final employees = await loadEmployees();
    employees.add(employee);
    await saveEmployees(employees);
  }

  Future<Employee> addEmployeeOffline({
    required String name,
    required String salary,
    required String age,
  }) async {
    final localId = await getNextLocalId();
    final employee = Employee(
      id: localId,
      name: name,
      salary: salary,
      age: age,
      profileImage: '',
    );

    await addSyncOperation(SyncOperation.create(employee: employee));

    await addEmployee(employee);

    return employee;
  }

  Future<void> updateEmployee(Employee employee) async {
    final employees = await loadEmployees();
    final index = employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      employees[index] = employee;
      await saveEmployees(employees);
    }
  }

  Future<void> updateEmployeeOffline(Employee employee) async {
    await addSyncOperation(SyncOperation.update(employee: employee));
    await updateEmployee(employee);
  }

  Future<void> deleteEmployee(int id) async {
    final employees = await loadEmployees();
    employees.removeWhere((e) => e.id == id);
    await saveEmployees(employees);
  }

  Future<void> deleteEmployeeOffline(int id) async {
    final employee = await loadEmployee(id);
    if (employee != null) {
      await addSyncOperation(SyncOperation.delete(employee: employee));
    }
    await deleteEmployee(id);
  }

  Future<int> getNextLocalId() async {
    final id = await _loadLocalIdCounter();
    await _saveLocalIdCounter(id - 1);
    return id;
  }

  Future<int> _loadLocalIdCounter() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_localIdCounterFile');

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return json['counter'] as int;
      } catch (e) {
        return -1;
      }
    }
    return -1;
  }

  Future<void> _saveLocalIdCounter(int counter) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_localIdCounterFile');

    final json = {'counter': counter};
    await file.writeAsString(jsonEncode(json));
  }

  Future<List<SyncOperation>> getAllPendingOperations() async {
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
    final operations = await getAllPendingOperations();
    operations.add(operation);
    await savePendingOperations(operations);
  }

  Future<void> savePendingOperations(List<SyncOperation> operations) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_syncQueueFile');

    final json = {'operations': operations.map((e) => e.toJson()).toList()};

    await file.writeAsString(jsonEncode(json));
  }

  Future<List<Employee>> mergeWithPendingOperations(
    List<Employee> serverEmployees,
  ) async {
    final operations = await getAllPendingOperations();
    final result = List<Employee>.from(serverEmployees);

    for (final op in operations) {
      switch (op.type) {
        case SyncOperationType.create:
          result.add(op.employee);
          break;
        case SyncOperationType.update:
          final index = result.indexWhere((e) => e.id == op.employee.id);
          if (index != -1) {
            result[index] = op.employee;
          }
          break;
        case SyncOperationType.delete:
          result.removeWhere((e) => e.id == op.employee.id);
          break;
      }
    }

    await saveEmployees(result);
    return result;
  }
}
