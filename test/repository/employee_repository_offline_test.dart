import 'package:flutter_test/flutter_test.dart';
import 'package:carcutter/features/employees/employee_api.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_repository.dart';

class FakeEmployeeApi implements EmployeeApiInterface {
  EmployeeResponse? _nextResponse;
  Exception? _nextException;

  void setResponse(EmployeeResponse response) {
    _nextResponse = response;
    _nextException = null;
  }

  void setException(Exception? exception) {
    _nextException = exception;
    _nextResponse = null;
  }

  void Function()? _onCall;

  void setOnCall(void Function()? onCall) {
    _onCall = onCall;
  }

  @override
  Future<EmployeeResponse> getAllEmployees() async {
    _onCall?.call();
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }

  @override
  Future<EmployeeResponse> getEmployee(int id) async {
    _onCall?.call();
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }

  @override
  Future<EmployeeResponse> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    _onCall?.call();
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }

  @override
  Future<EmployeeResponse> updateEmployee(Employee employee) async {
    _onCall?.call();
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }

  @override
  Future<EmployeeResponse> deleteEmployee(int id) async {
    _onCall?.call();
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }
}

class StubLocalStorage extends EmployeeLocalStorage {
  List<Employee> _employees = [];
  List<SyncOperation> _operations = [];
  int _nextLocalId = -1;

  void setEmployees(List<Employee> employees) {
    _employees = List.from(employees);
  }

  List<Employee> get savedEmployees => List.from(_employees);

  @override
  Future<EmployeeLocalStorageContent> loadContent() async {
    return EmployeeLocalStorageContent(
      employees: List.from(_employees),
      pendingOperations: List.from(_operations),
      localIdCounter: _nextLocalId,
    );
  }

  @override
  Future<void> saveContent(EmployeeLocalStorageContent content) async {
    _employees = List.from(content.employees);
    _operations = List<SyncOperation>.from(content.pendingOperations);
    _nextLocalId = content.localIdCounter;
  }

  @override
  Future<List<Employee>> loadEmployees() async {
    return List.from(_employees);
  }

  @override
  Future<void> saveEmployees(List<Employee> employees) async {
    _employees = List.from(employees);
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    _employees.add(employee);
  }

  @override
  Future<Employee> addEmployeeOffline({
    required String name,
    required String salary,
    required String age,
  }) async {
    final localId = _nextLocalId;
    _nextLocalId--;
    final employee = Employee(
      id: localId,
      name: name,
      salary: salary,
      age: age,
      profileImage: '',
    );
    _operations.add(SyncOperation.create(employee: employee));
    _employees.add(employee);
    return employee;
  }

  @override
  Future<Employee?> loadEmployee(int id) async {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _employees[index] = employee;
    } else {
      _employees.add(employee);
    }
  }

  @override
  Future<void> updateEmployeeOffline(Employee employee) async {
    _operations.add(SyncOperation.update(employee: employee));
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _employees[index] = employee;
    } else {
      _employees.add(employee);
    }
  }

  @override
  Future<void> deleteEmployee(int id) async {
    _employees.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> deleteEmployeeOffline(int id) async {
    try {
      final employee = _employees.firstWhere((e) => e.id == id);
      _employees.removeWhere((e) => e.id == id);
      _operations.add(SyncOperation.delete(employee: employee));
    } catch (_) {}
  }

  @override
  Future<List<SyncOperation>> loadPendingOperations() async {
    return List<SyncOperation>.from(_operations);
  }

  @override
  Future<void> addSyncOperation(SyncOperation operation) async {
    _operations.add(operation);
  }

  @override
  Future<void> savePendingOperations(List<SyncOperation> operations) async {
    _operations = List<SyncOperation>.from(operations);
  }
}

void main() {
  late FakeEmployeeApi fakeApi;
  late StubLocalStorage stubStorage;
  late EmployeeRepository repository;

  setUp(() {
    fakeApi = FakeEmployeeApi();
    stubStorage = StubLocalStorage();
    repository = EmployeeRepository(api: fakeApi, localStorage: stubStorage);
  });

  group('EmployeeRepository getAllEmployees online', () {
    test('fetches from API when online', () async {
      final mockResponse = EmployeeResponse(
        status: 'success',
        data: [
          Employee(
            id: 1,
            name: 'John',
            salary: '5000',
            age: '30',
            profileImage: '',
          ),
        ],
        message: 'OK',
      );
      fakeApi.setResponse(mockResponse);

      final employees = await repository.fetchEmployees();

      expect(employees, hasLength(1));
      expect(employees[0].name, 'John');
    });

    test('caches employees locally', () async {
      final mockResponse = EmployeeResponse(
        status: 'success',
        data: [
          Employee(
            id: 1,
            name: 'Cached',
            salary: '5000',
            age: '30',
            profileImage: '',
          ),
        ],
        message: 'OK',
      );
      fakeApi.setResponse(mockResponse);

      await repository.fetchEmployees();
      expect(stubStorage.savedEmployees, hasLength(1));
    });

    test('falls back to cached data when offline', () async {
      stubStorage.setEmployees([
        Employee(
          id: 1,
          name: 'Offline',
          salary: '4000',
          age: '25',
          profileImage: '',
        ),
      ]);
      fakeApi.setException(Exception('Network Error'));

      final employees = await repository.fetchEmployees();

      expect(employees, hasLength(1));
      expect(employees[0].name, 'Offline');
    });
  });

  group('EmployeeRepository createEmployee', () {
    test('creates employee and queues operation', () async {
      final result = await repository.createEmployee(
        name: 'New',
        salary: '3000',
        age: '25',
      );

      expect(result.name, 'New');
      expect(result.id, isNegative);

      final operations = await stubStorage.loadPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.create);
      expect(operations[0].employee.name, 'New');
    });
  });

  group('EmployeeRepository updateEmployee', () {
    test('updates employee and queues operation', () async {
      final employee = Employee(
        id: 1,
        name: 'Updated',
        salary: '7000',
        age: '35',
        profileImage: '',
      );
      final result = await repository.updateEmployee(employee);

      expect(result.name, 'Updated');

      final operations = await stubStorage.loadPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.update);
      expect(operations[0].employee.name, 'Updated');
    });
  });

  group('EmployeeRepository deleteEmployee', () {
    test('deletes employee and queues operation', () async {
      stubStorage.setEmployees([
        Employee(
          id: 1,
          name: 'ToDelete',
          salary: '5000',
          age: '30',
          profileImage: '',
        ),
      ]);

      await stubStorage.deleteEmployeeOffline(1);
      final operations = await stubStorage.loadPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.delete);
      expect(operations[0].employee.id, 1);
    });

    test('does not queue operation for non-existent employee', () async {
      await repository.deleteEmployee(42);

      final operations = await stubStorage.loadPendingOperations();
      expect(operations, isEmpty);
    });
  });

  group('EmployeeRepository syncPendingOperations', () {
    test('syncs pending create operations', () async {
      final mockResponse = EmployeeResponse(
        status: 'success',
        data: [
          Employee(
            id: 10,
            name: 'Synced',
            salary: '5000',
            age: '30',
            profileImage: '',
          ),
        ],
        message: 'OK',
      );
      fakeApi.setResponse(mockResponse);

      await stubStorage.addSyncOperation(
        SyncOperation.create(
          employee: Employee(
            id: -1,
            name: 'Synced',
            salary: '5000',
            age: '30',
            profileImage: '',
          ),
        ),
      );

      await repository.syncPendingOperations();

      expect(await stubStorage.loadPendingOperations(), isEmpty);
      expect(stubStorage.savedEmployees, hasLength(1));
      expect(stubStorage.savedEmployees[0].id, 10);
    });

    test('syncs pending update operations', () async {
      fakeApi.setResponse(
        EmployeeResponse(status: 'success', data: [], message: 'OK'),
      );

      await stubStorage.addSyncOperation(
        SyncOperation.update(
          employee: Employee(
            id: 1,
            name: 'SyncedUpdate',
            salary: '6000',
            age: '35',
            profileImage: '',
          ),
        ),
      );

      await repository.syncPendingOperations();

      final operations = await stubStorage.loadPendingOperations();
      expect(operations, isEmpty);
    });

    test('syncs pending delete operations', () async {
      fakeApi.setResponse(
        EmployeeResponse(status: 'success', data: [], message: 'OK'),
      );

      await stubStorage.addSyncOperation(
        SyncOperation.delete(
          employee: Employee(
            id: 5,
            name: '',
            salary: '',
            age: '',
            profileImage: '',
          ),
        ),
      );

      await repository.syncPendingOperations();

      final operations = await stubStorage.loadPendingOperations();
      expect(operations, isEmpty);
    });

    test('clears offline status on successful sync', () async {
      fakeApi.setException(Exception('Network Error'));
      await repository.createEmployee(name: 'Test', salary: '5000', age: '30');

      fakeApi.setResponse(
        EmployeeResponse(
          status: 'success',
          data: [
            Employee(
              id: 10,
              name: 'Test',
              salary: '5000',
              age: '30',
              profileImage: '',
            ),
          ],
          message: 'OK',
        ),
      );
      await repository.syncPendingOperations();

      final operations = await stubStorage.loadPendingOperations();
      expect(operations, isEmpty);
    });
  });

  group('getAllEmployees merges server data with pending operations', () {
    test('includes pending creates alongside server employees', () async {
      fakeApi.setResponse(
        EmployeeResponse(
          status: 'success',
          data: [
            Employee(
              id: 1,
              name: 'Server Employee',
              salary: '5000',
              age: '30',
              profileImage: '',
            ),
          ],
          message: 'OK',
        ),
      );

      await stubStorage.addSyncOperation(
        SyncOperation.create(
          employee: Employee(
            id: -1,
            name: 'Local Create',
            salary: '4000',
            age: '25',
            profileImage: '',
          ),
        ),
      );

      final employees = await repository.fetchEmployees();

      expect(employees, hasLength(2));
      expect(employees[0].name, 'Server Employee');
      expect(employees[1].name, 'Local Create');
      expect(employees[1].id, isNegative);
    });

    test('overrides server data with pending updates', () async {
      fakeApi.setResponse(
        EmployeeResponse(
          status: 'success',
          data: [
            Employee(
              id: 1,
              name: 'Original',
              salary: '5000',
              age: '30',
              profileImage: '',
            ),
          ],
          message: 'OK',
        ),
      );

      await stubStorage.addSyncOperation(
        SyncOperation.update(
          employee: Employee(
            id: 1,
            name: 'Updated',
            salary: '6000',
            age: '35',
            profileImage: '',
          ),
        ),
      );

      final employees = await repository.fetchEmployees();

      expect(employees, hasLength(1));
      expect(employees[0].name, 'Updated');
      expect(employees[0].salary, '6000');
    });

    test('removes deleted employees from server data', () async {
      fakeApi.setResponse(
        EmployeeResponse(
          status: 'success',
          data: [
            Employee(
              id: 1,
              name: 'To Delete',
              salary: '5000',
              age: '30',
              profileImage: '',
            ),
            Employee(
              id: 2,
              name: 'To Keep',
              salary: '6000',
              age: '25',
              profileImage: '',
            ),
          ],
          message: 'OK',
        ),
      );

      await stubStorage.addSyncOperation(
        SyncOperation.delete(
          employee: Employee(
            id: 1,
            name: 'To Delete',
            salary: '5000',
            age: '30',
            profileImage: '',
          ),
        ),
      );

      final employees = await repository.fetchEmployees();

      expect(employees, hasLength(1));
      expect(employees[0].name, 'To Keep');
    });
  });
}
