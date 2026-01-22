import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';

class MockLocalStorage extends EmployeeLocalStorage {
  final Map<String, String> _files = {};
  final int _localIdCounter = -1;

  Future<Directory> createTempDir() async {
    final dir = Directory.systemTemp.createTempSync('test_');
    return dir;
  }

  int get localIdCounter => _localIdCounter;

  @override
  Future<EmployeeLocalStorageContent> loadContent() async {
    final storageJson = _files['storage.json'];
    if (storageJson == null) {
      return EmployeeLocalStorageContent(employees: [], localIdCounter: -1);
    }
    final json = jsonDecode(storageJson) as Map<String, dynamic>;
    return EmployeeLocalStorageContent(
      employees:
          (json['employees'] as List?)
              ?.map((e) => Employee.fromLocalJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      localIdCounter: json['localIdCounter'] as int? ?? -1,
    );
  }

  @override
  Future<void> saveContent(EmployeeLocalStorageContent content) async {
    final json = {
      'employees': content.employees.map((e) => e.toJson()).toList(),
      'localIdCounter': content.localIdCounter,
    };
    _files['storage.json'] = jsonEncode(json);
  }

  @override
  Future<List<Employee>> loadEmployees() async {
    final content = await loadContent();
    return content.employees;
  }

  @override
  Future<void> saveEmployees(List<Employee> employees) async {
    final content = await loadContent();
    content.employees = employees;
    await saveContent(content);
  }

  @override
  Future<Employee?> loadEmployee(int id) async {
    final employees = await loadEmployees();
    try {
      return employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}

void main() {
  late MockLocalStorage storage;

  setUp(() {
    storage = MockLocalStorage();
  });

  group('EmployeeLocalStorage loadEmployees', () {
    test('returns empty list when no data stored', () async {
      final employees = await storage.loadEmployees();
      expect(employees, isEmpty);
    });

    test('returns stored employees', () async {
      final employees = [
        Employee(
          id: 1,
          name: 'John',
          salary: '5000',
          age: '30',
          profileImage: '',
        ),
        Employee(
          id: 2,
          name: 'Jane',
          salary: '6000',
          age: '25',
          profileImage: '',
        ),
      ];
      await storage.saveEmployees(employees);

      final loaded = await storage.loadEmployees();
      expect(loaded, hasLength(2));
      expect(loaded[0].name, 'John');
      expect(loaded[1].name, 'Jane');
    });
  });

  group('EmployeeLocalStorage saveEmployees', () {
    test('saves employees list', () async {
      final employees = [
        Employee(
          id: 1,
          name: 'Test',
          salary: '4000',
          age: '35',
          profileImage: '',
        ),
      ];
      await storage.saveEmployees(employees);

      final loaded = await storage.loadEmployees();
      expect(loaded, hasLength(1));
      expect(loaded[0].name, 'Test');
    });
  });

  group('EmployeeLocalStorage createEmployee', () {
    test('creates employee with local ID', () async {
      final employee = await storage.createEmployee(
        name: 'New',
        salary: '3000',
        age: '25',
      );

      expect(employee.id, isNegative);
      expect(employee.name, 'New');
      expect(employee.salary, '3000');
      expect(employee.age, '25');

      final employees = await storage.loadEmployees();
      expect(employees, hasLength(1));
      expect(employees[0].id, employee.id);
    });

    test('decrements local ID counter', () async {
      await storage.createEmployee(name: 'First', salary: '1000', age: '20');
      await storage.createEmployee(name: 'Second', salary: '2000', age: '25');
      await storage.createEmployee(name: 'Third', salary: '3000', age: '30');

      final employees = await storage.loadEmployees();
      expect(employees[0].id, -1);
      expect(employees[1].id, -2);
      expect(employees[2].id, -3);
    });
  });

  group('EmployeeLocalStorage updateEmployee', () {
    test('updates existing employee', () async {
      final original = Employee(
        id: 1,
        name: 'Original',
        salary: '5000',
        age: '30',
        profileImage: '',
      );
      await storage.addEmployee(original);

      final updated = Employee(
        id: 1,
        name: 'Updated',
        salary: '7000',
        age: '35',
        profileImage: '',
      );
      final prevEmployee = await storage.updateEmployee(updated);

      expect(prevEmployee.name, 'Original');
      final employees = await storage.loadEmployees();
      expect(employees[0].name, 'Updated');
    });

    test('throws when employee not found', () async {
      final employee = Employee(
        id: 999,
        name: 'Missing',
        salary: '5000',
        age: '30',
        profileImage: '',
      );

      expect(() => storage.updateEmployee(employee), throwsException);
    });
  });

  group('EmployeeLocalStorage deleteEmployee', () {
    test('deletes existing employee and returns it', () async {
      final employee = Employee(
        id: 1,
        name: 'ToDelete',
        salary: '5000',
        age: '30',
        profileImage: '',
      );
      await storage.addEmployee(employee);

      final deleted = await storage.deleteEmployee(1);

      expect(deleted.name, 'ToDelete');
      final employees = await storage.loadEmployees();
      expect(employees, isEmpty);
    });

    test('throws when employee not found', () async {
      expect(() => storage.deleteEmployee(999), throwsException);
    });
  });

  group('EmployeeLocalStorage addEmployee', () {
    test('adds employee to list', () async {
      final employee = Employee(
        id: 1,
        name: 'Added',
        salary: '5000',
        age: '30',
        profileImage: '',
      );

      await storage.addEmployee(employee);

      final employees = await storage.loadEmployees();
      expect(employees, hasLength(1));
      expect(employees[0].name, 'Added');
    });
  });

  group('EmployeeLocalStorage replaceEmployee', () {
    test('replaces employee with new one', () async {
      final oldEmployee = Employee(
        id: -1,
        name: 'Old',
        salary: '5000',
        age: '30',
        profileImage: '',
      );
      await storage.addEmployee(oldEmployee);

      final newEmployee = Employee(
        id: 10,
        name: 'New',
        salary: '6000',
        age: '35',
        profileImage: '',
      );

      await storage.replaceEmployee(oldEmployee, newEmployee);

      final employees = await storage.loadEmployees();
      expect(employees, hasLength(1));
      expect(employees[0].id, 10);
      expect(employees[0].name, 'New');
    });

    test('throws when old employee not found', () async {
      final oldEmployee = Employee(
        id: 999,
        name: 'Missing',
        salary: '5000',
        age: '30',
        profileImage: '',
      );
      final newEmployee = Employee(
        id: 10,
        name: 'New',
        salary: '6000',
        age: '35',
        profileImage: '',
      );

      expect(
        () => storage.replaceEmployee(oldEmployee, newEmployee),
        throwsException,
      );
    });
  });
}
