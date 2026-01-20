import 'package:flutter_test/flutter_test.dart';
import 'package:carcutter/features/employees/employee_api.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_repository.dart';
import 'package:carcutter/features/employees/offline_status_provider.dart';

class FakeEmployeeApi implements Fake {
  EmployeeResponse? _nextResponse;
  Exception? _nextException;
  String? _lastMethod;
  Map<String, dynamic>? _lastArgs;

  void setResponse(EmployeeResponse response) {
    _nextResponse = response;
    _nextException = null;
  }

  void setException(Exception exception) {
    _nextException = exception;
    _nextResponse = null;
  }

  String? get lastMethod => _lastMethod;
  Map<String, dynamic>? get lastArgs => _lastArgs;
}

class StubEmployeeApi implements EmployeeApiInterface {
  final FakeEmployeeApi _fake;

  StubEmployeeApi(this._fake);

  @override
  Future<EmployeeResponse> getAllEmployees() async {
    _fake._lastMethod = 'getAllEmployees';
    _fake._lastArgs = null;
    if (_fake._nextException != null) throw _fake._nextException!;
    return _fake._nextResponse!;
  }

  @override
  Future<EmployeeResponse> getEmployee(int id) async {
    _fake._lastMethod = 'getEmployee';
    _fake._lastArgs = {'id': id};
    if (_fake._nextException != null) throw _fake._nextException!;
    return _fake._nextResponse!;
  }

  @override
  Future<EmployeeResponse> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    _fake._lastMethod = 'createEmployee';
    _fake._lastArgs = {'name': name, 'salary': salary, 'age': age};
    if (_fake._nextException != null) throw _fake._nextException!;
    return _fake._nextResponse!;
  }

  @override
  Future<EmployeeResponse> updateEmployee(Employee employee) async {
    _fake._lastMethod = 'updateEmployee';
    _fake._lastArgs = {'employee': employee};
    if (_fake._nextException != null) throw _fake._nextException!;
    return _fake._nextResponse!;
  }

  @override
  Future<void> deleteEmployee(int id) async {
    _fake._lastMethod = 'deleteEmployee';
    _fake._lastArgs = {'id': id};
    if (_fake._nextException != null) throw _fake._nextException!;
  }
}

class StubLocalStorage extends EmployeeLocalStorage {
  List<Employee> _employees = [];
  List<SyncOperation> _operations = [];
  int _nextLocalId = -1;

  void setEmployees(List<Employee> employees) {
    _employees = List.from(employees);
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
    _operations.add(SyncOperation.delete(employeeId: id));
    _employees.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<SyncOperation>> loadPendingOperations() async {
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeEmployeeApi fakeApi;
  late StubEmployeeApi stubApi;
  late StubLocalStorage stubStorage;
  late OfflineStatus offlineStatus;
  late EmployeeRepository repository;

  setUp(() {
    fakeApi = FakeEmployeeApi();
    stubApi = StubEmployeeApi(fakeApi);
    stubStorage = StubLocalStorage();
    offlineStatus = OfflineStatus();
    repository = EmployeeRepository(
      api: stubApi,
      localStorage: stubStorage,
      offlineStatus: offlineStatus,
    );
  });

  group('EmployeeRepository.getAllEmployees', () {
    test('returns employees from API', () async {
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

      final result = await repository.getAllEmployees();

      expect(result, hasLength(1));
      expect(result[0].name, 'John');
      expect(fakeApi.lastMethod, 'getAllEmployees');
    });

    test('returns empty list when API returns empty', () async {
      fakeApi.setResponse(
        EmployeeResponse(status: 'success', data: [], message: 'OK'),
      );

      final result = await repository.getAllEmployees();

      expect(result, isEmpty);
    });
  });

  group('EmployeeRepository.getEmployee', () {
    test('returns single employee', () async {
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

      final result = await repository.getEmployee(1);

      expect(result.id, 1);
      expect(result.name, 'John');
      expect(fakeApi.lastArgs!['id'], 1);
    });
  });

  group('EmployeeRepository.createEmployee', () {
    test('returns created employee', () async {
      final mockResponse = EmployeeResponse(
        status: 'success',
        data: [
          Employee(
            id: 3,
            name: 'New Employee',
            salary: '4000',
            age: '22',
            profileImage: '',
          ),
        ],
        message: 'OK',
      );
      fakeApi.setResponse(mockResponse);

      final result = await repository.createEmployee(
        name: 'New Employee',
        salary: '4000',
        age: '22',
      );

      expect(result.name, 'New Employee');
      expect(result.id, 3);
      expect(fakeApi.lastArgs!['name'], 'New Employee');
    });
  });

  group('EmployeeRepository.updateEmployee', () {
    test('returns updated employee', () async {
      final employee = Employee(
        id: 1,
        name: 'Updated',
        salary: '7000',
        age: '35',
        profileImage: '',
      );
      final mockResponse = EmployeeResponse(
        status: 'success',
        data: [employee],
        message: 'OK',
      );
      fakeApi.setResponse(mockResponse);

      final result = await repository.updateEmployee(employee);

      expect(result.name, 'Updated');
      expect(result.id, 1);
      expect(fakeApi.lastMethod, 'updateEmployee');
    });
  });

  group('EmployeeRepository.deleteEmployee', () {
    test('completes successfully', () async {
      fakeApi.setResponse(
        EmployeeResponse(status: 'success', data: [], message: 'OK'),
      );

      await expectLater(repository.deleteEmployee(1), completes);
      expect(fakeApi.lastMethod, 'deleteEmployee');
      expect(fakeApi.lastArgs!['id'], 1);
    });
  });
}
