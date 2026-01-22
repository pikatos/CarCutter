import 'dart:convert';
import 'dart:io';
import 'package:carcutter/common/lock.dart';
import 'package:path_provider/path_provider.dart';
import 'employee_model.dart';

class EmployeeLocalStorageContent {
  List<Employee> employees;
  int localIdCounter;

  EmployeeLocalStorageContent({
    required this.employees,
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
      return EmployeeLocalStorageContent(employees: [], localIdCounter: -1);
    }

    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    return EmployeeLocalStorageContent(
      employees:
          (json['employees'] as List?)
              ?.map((e) => Employee.fromLocalJson(e as Map<String, dynamic>))
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
      'localIdCounter': content.localIdCounter,
    };

    await file.writeAsString(jsonEncode(json));
  }

  Future<List<Employee>> loadEmployees() async {
    final content = await loadContent();
    return content.employees;
  }

  Future<void> saveEmployees(List<Employee> employees) async {
    await performTransaction((content) async {
      content.employees = employees;
    });
  }

  Future<Employee?> loadEmployee(int id) async {
    final employees = await loadEmployees();
    try {
      return employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addEmployee(Employee employee) async {
    return await performTransaction((content) async {
      content.employees.add(employee);
      content.employees.sort(Employee.byName);
    });
  }

  Future<Employee> createEmployee({
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
      return employee;
    });
  }

  Future<void> replaceEmployee(
    Employee oldEmployee,
    Employee newEmployee,
  ) async {
    return await performTransaction((content) async {
      final index = content.employees.indexWhere((e) => e.id == oldEmployee.id);
      if (index == -1) {
        throw Exception(
          'LocalStorage failed to replace employee ${oldEmployee.id} by employee ${newEmployee.id}',
        );
      }
      content.employees[index] = newEmployee;
    });
  }

  // Return previous employee
  Future<Employee> updateEmployee(Employee employee) async {
    return await performTransaction((content) async {
      final index = content.employees.indexWhere((e) => e.id == employee.id);
      if (index == -1) {
        throw Exception(
          'LocalStorage failed to update employee ${employee.id}',
        );
      }
      final prevEmployee = content.employees[index];
      content.employees[index] = employee;
      return prevEmployee;
    });
  }

  // Return deleted employee
  Future<Employee> deleteEmployee(int id) async {
    return await performTransaction((content) async {
      final index = content.employees.indexWhere((e) => e.id == id);
      if (index == -1) {
        throw Exception('LocalStorage failed to delete employee $id');
      }
      final employee = content.employees[index];
      content.employees.removeAt(index);
      return employee;
    });
  }
}
