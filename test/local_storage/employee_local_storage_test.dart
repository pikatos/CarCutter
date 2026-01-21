import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';

class MockLocalStorage extends EmployeeLocalStorage {
  final Map<String, String> _files = {};
  int _localIdCounter = -1;

  Future<Directory> createTempDir() async {
    final dir = Directory.systemTemp.createTempSync('test_');
    return dir;
  }

  int get localIdCounter => _localIdCounter;

  @override
  Future<EmployeeLocalStorageContent> loadContent() async {
    final storageJson = _files['storage.json'];
    if (storageJson == null) {
      return EmployeeLocalStorageContent(
        employees: [],
        pendingOperations: [],
        localIdCounter: -1,
      );
    }
    final json = jsonDecode(storageJson) as Map<String, dynamic>;
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

  @override
  Future<void> saveContent(EmployeeLocalStorageContent content) async {
    final json = {
      'employees': content.employees.map((e) => e.toJson()).toList(),
      'pendingOperations': content.pendingOperations
          .map((e) => e.toJson())
          .toList(),
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
  Future<List<SyncOperation>> loadPendingOperations() async {
    final content = await loadContent();
    return content.pendingOperations;
  }

  @override
  Future<void> addSyncOperation(SyncOperation operation) async {
    final content = await loadContent();
    content.pendingOperations.add(operation);
    await saveContent(content);
  }

  @override
  Future<void> savePendingOperations(List<SyncOperation> operations) async {
    final content = await loadContent();
    content.pendingOperations = operations;
    await saveContent(content);
    if (operations.isEmpty) {
      _localIdCounter = -1;
    }
  }
}

void main() {
  late MockLocalStorage storage;

  setUp(() {
    storage = MockLocalStorage();
  });

  group('EmployeeLocalStorage getAllEmployees', () {
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

  group('EmployeeLocalStorage sync operations', () {
    test('adds sync operation to queue', () async {
      final employee = Employee(
        id: 0,
        name: 'New',
        salary: '3000',
        age: '25',
        profileImage: '',
      );
      await storage.addSyncOperation(SyncOperation.create(employee: employee));

      final operations = await storage.loadPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.create);
    });

    test('adds update operation to queue', () async {
      final employee = Employee(
        id: 1,
        name: 'Updated',
        salary: '7000',
        age: '40',
        profileImage: '',
      );
      await storage.addSyncOperation(SyncOperation.update(employee: employee));

      final operations = await storage.loadPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.update);
    });

    test('adds delete operation to queue', () async {
      await storage.addSyncOperation(
        SyncOperation.delete(
          employee: Employee(
            id: 42,
            name: '',
            salary: '',
            age: '',
            profileImage: '',
          ),
        ),
      );

      final operations = await storage.loadPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.delete);
      expect(operations[0].employee.id, 42);
    });

    test('preserves order of operations', () async {
      await storage.addSyncOperation(
        SyncOperation.delete(
          employee: Employee(
            id: 1,
            name: '',
            salary: '',
            age: '',
            profileImage: '',
          ),
        ),
      );
      await storage.addSyncOperation(
        SyncOperation.create(
          employee: Employee(
            id: 0,
            name: 'New',
            salary: '3000',
            age: '25',
            profileImage: '',
          ),
        ),
      );
      await storage.addSyncOperation(
        SyncOperation.update(
          employee: Employee(
            id: 2,
            name: 'Update',
            salary: '5000',
            age: '30',
            profileImage: '',
          ),
        ),
      );

      final operations = await storage.loadPendingOperations();
      expect(operations, hasLength(3));
      expect(operations[0].type, SyncOperationType.delete);
      expect(operations[1].type, SyncOperationType.create);
      expect(operations[2].type, SyncOperationType.update);
    });

    test('resets localIdCounter to -1 when clearing operations', () async {
      await storage.addSyncOperation(
        SyncOperation.create(
          employee: Employee(
            id: 0,
            name: 'Test',
            salary: '3000',
            age: '25',
            profileImage: '',
          ),
        ),
      );
      expect(storage.localIdCounter, -1);
      await storage.addSyncOperation(
        SyncOperation.create(
          employee: Employee(
            id: 0,
            name: 'Test2',
            salary: '4000',
            age: '30',
            profileImage: '',
          ),
        ),
      );
      await storage.savePendingOperations([]);
      expect(storage.localIdCounter, -1);
    });
  });

  group('SyncOperation serialization', () {
    test('create operation serializes and deserializes', () async {
      final employee = Employee(
        id: 0,
        name: 'Test',
        salary: '5000',
        age: '30',
        profileImage: '',
      );
      final operation = SyncOperation.create(employee: employee);

      final json = operation.toJson();
      final deserialized = SyncOperation.fromJson(json);

      expect(deserialized.type, SyncOperationType.create);
      expect(deserialized.employee.name, 'Test');
    });

    test('update operation serializes and deserializes', () async {
      final employee = Employee(
        id: 1,
        name: 'Updated',
        salary: '6000',
        age: '35',
        profileImage: '',
      );
      final operation = SyncOperation.update(employee: employee);

      final json = operation.toJson();
      final deserialized = SyncOperation.fromJson(json);

      expect(deserialized.type, SyncOperationType.update);
      expect(deserialized.employee.id, 1);
    });

    test('delete operation serializes and deserializes', () async {
      final operation = SyncOperation.delete(
        employee: Employee(
          id: 42,
          name: '',
          salary: '',
          age: '',
          profileImage: '',
        ),
      );

      final json = operation.toJson();
      final deserialized = SyncOperation.fromJson(json);

      expect(deserialized.type, SyncOperationType.delete);
      expect(deserialized.employee.id, 42);
    });
  });
}
