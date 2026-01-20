import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'employee_model.dart';

class EmployeeLocalStorage {
  static const String _employeesFile = 'employees.json';
  static const String _syncQueueFile = 'sync_queue.json';
  static const String _localIdCounterFile = 'local_id_counter.json';

  int _localIdCounter = -1;
  bool _localIdCounterLoaded = false;

  List<Employee> _employees = [];
  bool _employeesLoaded = false;

  List<SyncOperation> _pendingOperations = [];
  bool _operationsLoaded = false;

  Future<void> _ensureLocalIdCounterLoaded() async {
    if (_localIdCounterLoaded) return;
    _localIdCounter = await _loadLocalIdCounterFromFile();
    _localIdCounterLoaded = true;
  }

  Future<void> _ensureEmployeesLoaded() async {
    if (_employeesLoaded) return;
    _employees = await _loadEmployeesFromFile();
    _employeesLoaded = true;
  }

  Future<void> _ensureOperationsLoaded() async {
    if (_operationsLoaded) return;
    _pendingOperations = await _loadOperationsFromFile();
    _operationsLoaded = true;
  }

  Future<List<Employee>> _loadEmployeesFromFile() async {
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

  Future<void> _saveEmployeesToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_employeesFile');

    final json = {'data': _employees.map((e) => e.toJson()).toList()};

    await file.writeAsString(jsonEncode(json));
  }

  Future<List<Employee>> getAllEmployees() async {
    await _ensureEmployeesLoaded();
    return List<Employee>.from(_employees);
  }

  Future<Employee?> getEmployee(int id) async {
    await _ensureEmployeesLoaded();
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveEmployees(List<Employee> employees) async {
    await _ensureEmployeesLoaded();
    _employees = List<Employee>.from(employees);
    await _saveEmployeesToFile();
  }

  Future<void> addEmployee(Employee employee) async {
    await _ensureEmployeesLoaded();
    _employees.add(employee);
    await _saveEmployeesToFile();
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
    await _ensureEmployeesLoaded();
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _employees[index] = employee;
      await _saveEmployeesToFile();
    }
  }

  Future<void> updateEmployeeOffline(Employee employee) async {
    await addSyncOperation(SyncOperation.update(employee: employee));
    await updateEmployee(employee);
  }

  Future<void> deleteEmployee(int id) async {
    await _ensureEmployeesLoaded();
    _employees.removeWhere((e) => e.id == id);
    await _saveEmployeesToFile();
  }

  Future<void> deleteEmployeeOffline(int id) async {
    final employee = await getEmployee(id);
    if (employee != null) {
      await addSyncOperation(SyncOperation.delete(employee: employee));
    }
    await deleteEmployee(id);
  }

  Future<int> getNextLocalId() async {
    await _ensureLocalIdCounterLoaded();
    final id = _localIdCounter;
    _localIdCounter--;
    await _saveLocalIdCounter();
    return id;
  }

  Future<int> _loadLocalIdCounterFromFile() async {
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

  Future<void> _saveLocalIdCounter() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_localIdCounterFile');

    final json = {'counter': _localIdCounter};
    await file.writeAsString(jsonEncode(json));
  }

  Future<List<SyncOperation>> _loadOperationsFromFile() async {
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

  Future<void> _saveOperationsToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_syncQueueFile');

    final json = {
      'operations': _pendingOperations.map((e) => e.toJson()).toList(),
    };

    await file.writeAsString(jsonEncode(json));
  }

  Future<List<SyncOperation>> getAllPendingOperations() async {
    await _ensureOperationsLoaded();
    return List<SyncOperation>.from(_pendingOperations);
  }

  Future<void> addSyncOperation(SyncOperation operation) async {
    await _ensureOperationsLoaded();
    _pendingOperations.add(operation);
    await _saveOperationsToFile();
  }

  Future<void> savePendingOperations(List<SyncOperation> operations) async {
    await _ensureOperationsLoaded();
    _pendingOperations = List<SyncOperation>.from(operations);
    if (_pendingOperations.isEmpty) {
      _localIdCounter = -1;
      await _saveLocalIdCounter();
    }
    await _saveOperationsToFile();
  }
}
