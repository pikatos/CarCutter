import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';

class MockLocalStorage extends EmployeeLocalStorage {
  final Map<String, String> _files = {};

  Future<Directory> createTempDir() async {
    final dir = Directory.systemTemp.createTempSync('test_');
    return dir;
  }

  @override
  Future<List<Employee>> loadEmployees() async {
    final employeesJson = _files['employees.json'];
    if (employeesJson == null) return [];
    final json = jsonDecode(employeesJson) as Map<String, dynamic>;
    final data = json['data'] as List;
    return data
        .map((e) => Employee.fromLocalJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveEmployees(List<Employee> employees) async {
    final json = {'data': employees.map((e) => e.toJson()).toList()};
    _files['employees.json'] = jsonEncode(json);
  }

  @override
  Future<List<SyncOperation>> loadPendingOperations() async {
    final opsJson = _files['sync_queue.json'];
    if (opsJson == null) return [];
    final json = jsonDecode(opsJson) as Map<String, dynamic>;
    final operations = json['operations'] as List;
    return operations
        .map((e) => SyncOperation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addSyncOperation(SyncOperation operation) async {
    final operations = await loadPendingOperations();
    operations.add(operation);
    await savePendingOperations(operations);
  }

  @override
  Future<void> savePendingOperations(List<SyncOperation> operations) async {
    final json = {'operations': operations.map((e) => e.toJson()).toList()};
    _files['sync_queue.json'] = jsonEncode(json);
  }

  @override
  Future<void> clearPendingOperations() async {
    _files.remove('sync_queue.json');
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
      await storage.addSyncOperation(SyncOperation.delete(employeeId: 42));

      final operations = await storage.loadPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.delete);
      expect(operations[0].employeeId, 42);
    });

    test('clears pending operations', () async {
      await storage.addSyncOperation(SyncOperation.delete(employeeId: 1));
      await storage.addSyncOperation(SyncOperation.delete(employeeId: 2));

      await storage.clearPendingOperations();

      final operations = await storage.loadPendingOperations();
      expect(operations, isEmpty);
    });

    test('preserves order of operations', () async {
      await storage.addSyncOperation(SyncOperation.delete(employeeId: 1));
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
      expect(deserialized.employee!.name, 'Test');
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
      expect(deserialized.employee!.id, 1);
    });

    test('delete operation serializes and deserializes', () async {
      final operation = SyncOperation.delete(employeeId: 42);

      final json = operation.toJson();
      final deserialized = SyncOperation.fromJson(json);

      expect(deserialized.type, SyncOperationType.delete);
      expect(deserialized.employeeId, 42);
    });
  });
}
