import 'package:flutter_test/flutter_test.dart';
import 'package:carcutter/features/employees/employee_api.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_repository.dart';
import 'package:carcutter/features/employees/offline_status_provider.dart';

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
  Future<void> deleteEmployee(int id) async {
    _onCall?.call();
    if (_nextException != null) throw _nextException!;
  }
}

class StubLocalStorage extends EmployeeLocalStorage {
  List<Employee> _employees = [];
  final List<SyncOperation> _operations = [];
  int _nextLocalId = -1;

  void setEmployees(List<Employee> employees) {
    _employees = List.from(employees);
  }

  List<Employee> get savedEmployees => List.from(_employees);

  @override
  Future<List<Employee>> getAllEmployees() async {
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
    _operations.add(
      SyncOperation.delete(
        employee: Employee(
          id: id,
          name: '',
          salary: '',
          age: '',
          profileImage: '',
        ),
      ),
    );
    _employees.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<SyncOperation>> getAllPendingOperations() async {
    return List.from(_operations);
  }

  @override
  Future<void> addSyncOperation(SyncOperation operation) async {
    _operations.add(operation);
  }

  @override
  Future<void> clearPendingOperations() async {
    _operations.clear();
  }

  @override
  Future<int> getNextLocalId() async {
    final id = _nextLocalId;
    _nextLocalId--;
    return id;
  }
}

void main() {
  late FakeEmployeeApi fakeApi;
  late StubLocalStorage stubStorage;
  late OfflineStatus offlineStatus;
  late EmployeeRepository repository;

  setUp(() {
    fakeApi = FakeEmployeeApi();
    stubStorage = StubLocalStorage();
    offlineStatus = OfflineStatus();
    repository = EmployeeRepository(
      api: fakeApi,
      localStorage: stubStorage,
      offlineStatus: offlineStatus,
    );
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

      final employees = await repository.getAllEmployees();

      expect(employees, hasLength(1));
      expect(employees[0].name, 'John');
      expect(offlineStatus.isOffline, isFalse);
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

      await repository.getAllEmployees();
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

      final employees = await repository.getAllEmployees();

      expect(employees, hasLength(1));
      expect(employees[0].name, 'Offline');
      expect(offlineStatus.isOffline, isTrue);
    });
  });

  group('EmployeeRepository createEmployee', () {
    test('creates employee online', () async {
      final mockResponse = EmployeeResponse(
        status: 'success',
        data: [
          Employee(
            id: 3,
            name: 'New',
            salary: '3000',
            age: '25',
            profileImage: '',
          ),
        ],
        message: 'OK',
      );
      fakeApi.setResponse(mockResponse);

      final result = await repository.createEmployee(
        name: 'New',
        salary: '3000',
        age: '25',
      );

      expect(result.name, 'New');
      expect(result.id, 3);
    });

    test('queues operation when offline', () async {
      fakeApi.setException(Exception('Network Error'));

      final result = await repository.createEmployee(
        name: 'Offline Create',
        salary: '3000',
        age: '25',
      );

      expect(result.name, 'Offline Create');
      expect(result.id, isNegative);
      expect(offlineStatus.isOffline, isTrue);

      final operations = await stubStorage.getAllPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.create);
      expect(operations[0].employee.name, 'Offline Create');
      expect(operations[0].employee.id, result.id);
    });
  });

  group('EmployeeRepository updateEmployee', () {
    test('updates employee online', () async {
      final mockResponse = EmployeeResponse(
        status: 'success',
        data: [
          Employee(
            id: 1,
            name: 'Updated',
            salary: '7000',
            age: '35',
            profileImage: '',
          ),
        ],
        message: 'OK',
      );
      fakeApi.setResponse(mockResponse);

      final employee = Employee(
        id: 1,
        name: 'Updated',
        salary: '7000',
        age: '35',
        profileImage: '',
      );
      final result = await repository.updateEmployee(employee);

      expect(result.name, 'Updated');
    });

    test('queues operation when offline', () async {
      fakeApi.setException(Exception('Network Error'));

      final employee = Employee(
        id: 1,
        name: 'Offline Update',
        salary: '7000',
        age: '35',
        profileImage: '',
      );
      final result = await repository.updateEmployee(employee);

      expect(result.name, 'Offline Update');
      expect(offlineStatus.isOffline, isTrue);

      final operations = await stubStorage.getAllPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.update);
      expect(operations[0].employee.name, 'Offline Update');
    });
  });

  group('EmployeeRepository deleteEmployee', () {
    test('deletes employee online', () async {
      stubStorage.setEmployees([
        Employee(
          id: 1,
          name: 'ToDelete',
          salary: '5000',
          age: '30',
          profileImage: '',
        ),
      ]);
      fakeApi.setResponse(
        EmployeeResponse(status: 'success', data: [], message: 'OK'),
      );

      await repository.deleteEmployee(1);

      expect(stubStorage.savedEmployees, isEmpty);
    });

    test('queues operation when offline', () async {
      fakeApi.setException(Exception('Network Error'));

      await repository.deleteEmployee(42);

      expect(offlineStatus.isOffline, isTrue);

      final operations = await stubStorage.getAllPendingOperations();
      expect(operations, hasLength(1));
      expect(operations[0].type, SyncOperationType.delete);
      expect(operations[0].employee.id, 42);
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

      expect(await stubStorage.getAllPendingOperations(), isEmpty);
      expect(offlineStatus.isOffline, isFalse);
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

      final operations = await stubStorage.getAllPendingOperations();
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

      final operations = await stubStorage.getAllPendingOperations();
      expect(operations, isEmpty);
    });

    test('clears offline status on successful sync', () async {
      fakeApi.setException(Exception('Network Error'));
      await repository.createEmployee(name: 'Test', salary: '5000', age: '30');
      expect(offlineStatus.isOffline, isTrue);

      fakeApi.setResponse(
        EmployeeResponse(status: 'success', data: [], message: 'OK'),
      );
      await repository.syncPendingOperations();

      expect(offlineStatus.isOffline, isFalse);
    });
  });
}
