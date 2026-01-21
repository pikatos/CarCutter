import 'dart:convert';
import 'dart:io';
import 'package:carcutter/common/lock.dart';
import 'package:path_provider/path_provider.dart';
import 'employee_model.dart';

class EmployeeLocalStorageContent {
  List<Employee> employees;
  List<SyncOperation> pendingOperations;
  int localIdCounter;

  EmployeeLocalStorageContent({
    required this.employees,
    required this.pendingOperations,
    required this.localIdCounter,
  });

  int getNextLocalId() {
    final id = localIdCounter;
    localIdCounter = id - 1;
    return id;
  }
}

class EmployeeLocalStorage {
  static const String _storageFile = 'storage.json';

  final Lock _lock;

  EmployeeLocalStorage() : _lock = Lock();

  Future<List<Employee>> loadEmployees() async {
    final content = await loadContent();
    return content.employees;
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
    await performTransaction((content) async {
      content.employees = employees;
    });
  }

  Future<void> addEmployee(Employee employee) async {
    await performTransaction((content) async {
      content.employees.add(employee);
    });
  }

  Future<Employee> addEmployeeOffline({
    required String name,
    required String salary,
    required String age,
  }) async {
    return await performTransaction((content) async {
      final employee = Employee(
        id: content.getNextLocalId(),
        name: name,
        salary: salary,
        age: age,
        profileImage: '',
      );
      content.employees.add(employee);
      content.pendingOperations.add(SyncOperation.create(employee: employee));
      return employee;
    });
  }

  Future<T> performTransaction<T>(
    Future<T> Function(EmployeeLocalStorageContent) transaction,
  ) async {
    await _lock.lock();
    try {
      var content = await loadContent();
      final result = await transaction(content);
      await saveContent(content);
      return result;
    } finally {
      _lock.release();
    }
  }

  Future<EmployeeLocalStorageContent> loadContent() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_storageFile');

    if (!await file.exists()) {
      return EmployeeLocalStorageContent(
        employees: [],
        pendingOperations: [],
        localIdCounter: -1,
      );
    }

    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    return EmployeeLocalStorageContent(
      employees:
          (json['employees'] as List?)
              ?.map((e) => Employee.fromLocalJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pendingOperations:
          (json['pendingOperations'] as List?)
              ?.map((e) => SyncOperation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      localIdCounter: json['localIdCounter'] as int? ?? -1,
    );
  }

  Future<void> saveContent(EmployeeLocalStorageContent content) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_storageFile');

    final json = {
      'employees': content.employees.map((e) => e.toJson()).toList(),
      'pendingOperations': content.pendingOperations
          .map((e) => e.toJson())
          .toList(),
      'localIdCounter': content.localIdCounter,
    };

    await file.writeAsString(jsonEncode(json));
  }

  Future<void> updateEmployee(Employee employee) async {
    await performTransaction((content) async {
      final index = content.employees.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        content.employees[index] = employee;
      }
    });
  }

  Future<void> updateEmployeeOffline(Employee employee) async {
    await performTransaction((content) async {
      final index = content.employees.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        content.employees[index] = employee;
        content.pendingOperations.add(SyncOperation.update(employee: employee));
      }
    });
  }

  Future<void> deleteEmployee(int id) async {
    await performTransaction((content) async {
      content.employees.removeWhere((e) => e.id == id);
    });
  }

  Future<void> deleteEmployeeOffline(int id) async {
    await performTransaction((content) async {
      try {
        final employee = content.employees.firstWhere((e) => e.id == id);
        content.employees.removeWhere((e) => e.id == id);
        content.pendingOperations.add(SyncOperation.delete(employee: employee));
      } catch (_) {}
    });
  }

  Future<List<SyncOperation>> loadPendingOperations() async {
    final content = await loadContent();
    return content.pendingOperations;
  }

  Future<void> addSyncOperation(SyncOperation operation) async {
    await performTransaction((content) async {
      content.pendingOperations.add(operation);
    });
  }

  Future<void> savePendingOperations(List<SyncOperation> operations) async {
    await performTransaction((content) async {
      content.pendingOperations = operations;
    });
  }

  Future<List<Employee>> mergeWithPendingOperations(
    List<Employee> serverEmployees,
  ) async {
    return await performTransaction((content) async {
      final result = List<Employee>.from(serverEmployees);

      for (final operation in content.pendingOperations) {
        switch (operation.type) {
          case SyncOperationType.create:
            result.add(operation.employee);
            break;
          case SyncOperationType.update:
            final index = result.indexWhere(
              (e) => e.id == operation.employee.id,
            );
            if (index != -1) {
              result[index] = operation.employee;
            }
            break;
          case SyncOperationType.delete:
            result.removeWhere((e) => e.id == operation.employee.id);
            break;
        }
      }

      content.employees = result;

      return result;
    });
  }
}
