import 'package:flutter_test/flutter_test.dart';
import 'package:carcutter/features/employees/employee_api.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_repository.dart';

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
  Future<EmployeeResponse> deleteEmployee(int id) async {
    _fake._lastMethod = 'deleteEmployee';
    _fake._lastArgs = {'id': id};
    if (_fake._nextException != null) throw _fake._nextException!;
    return _fake._nextResponse!;
  }
}

class StubLocalStorage extends EmployeeLocalStorage {
  List<Employee> _employees = [];
  int _nextLocalId = -1;

  void setEmployees(List<Employee> employees) {
    _employees = List.from(employees);
  }

  List<Employee> get savedEmployees => List.from(_employees);

  @override
  Future<EmployeeLocalStorageContent> loadContent() async {
    return EmployeeLocalStorageContent(
      employees: List.from(_employees),
      localIdCounter: _nextLocalId,
    );
  }

  @override
  Future<void> saveContent(EmployeeLocalStorageContent content) async {
    _employees = List.from(content.employees);
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
  Future<Employee?> loadEmployee(int id) async {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Employee> createEmployee({
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
    _employees.add(employee);
    return employee;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    final prevEmployee = index != -1 ? _employees[index] : employee;
    if (index != -1) {
      _employees[index] = employee;
    } else {
      _employees.add(employee);
    }
    return prevEmployee;
  }

  @override
  Future<Employee> deleteEmployee(int id) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final employee = _employees[index];
      _employees.removeAt(index);
      return employee;
    }
    throw Exception('Employee not found: $id');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeEmployeeApi fakeApi;
  late StubEmployeeApi stubApi;
  late StubLocalStorage stubStorage;
  late EmployeeRepository repository;

  setUp(() {
    fakeApi = FakeEmployeeApi();
    stubApi = StubEmployeeApi(fakeApi);
    stubStorage = StubLocalStorage();
    repository = EmployeeRepository(api: stubApi, localStorage: stubStorage);
  });

  group('EmployeeRepository.fetchEmployees', () {
    test('yields local then server employees', () async {
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

      final results = await repository.fetchEmployees().toList();

      expect(results, hasLength(2));
      expect(results[0], isA<List<Employee>>());
      expect(results[1], isA<List<Employee>>());
      expect(fakeApi.lastMethod, 'getAllEmployees');
    });

    test('yields empty list when API returns empty', () async {
      fakeApi.setResponse(
        EmployeeResponse(status: 'success', data: [], message: 'OK'),
      );

      final results = await repository.fetchEmployees().toList();

      expect(results, hasLength(2));
      expect(results[0], isEmpty);
      expect(results[1], isEmpty);
    });
  });

  group('EmployeeRepository.fetchEmployee', () {
    test('yields local then server employee', () async {
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

      final results = await repository.fetchEmployee(1).toList();

      expect(results, hasLength(2));
      expect(results[0], isA<Employee?>());
      expect(results[1], isA<Employee?>());
      expect(fakeApi.lastArgs!['id'], 1);
    });
  });

  group('EmployeeRepository.createEmployee', () {
    test('creates employee locally and returns server result', () async {
      final createdEmployee = Employee(
        id: 10,
        name: 'New Employee',
        salary: '4000',
        age: '22',
        profileImage: '',
      );
      fakeApi.setResponse(
        EmployeeResponse(
          status: 'success',
          data: [createdEmployee],
          message: 'OK',
        ),
      );

      final result = await repository.createEmployee(
        name: 'New Employee',
        salary: '4000',
        age: '22',
      );

      expect(result.name, 'New Employee');
      expect(result.id, 10);
      expect(fakeApi.lastArgs!['name'], 'New Employee');
      expect(stubStorage.savedEmployees, hasLength(1));
      expect(stubStorage.savedEmployees[0].id, 10);
    });
  });

  group('EmployeeRepository.updateEmployee', () {
    test('updates employee locally and returns server result', () async {
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
      stubStorage.setEmployees([employee]);

      final result = await repository.updateEmployee(employee);

      expect(result.name, 'Updated');
      expect(result.id, 1);
      expect(fakeApi.lastMethod, 'updateEmployee');
      expect(stubStorage.savedEmployees, hasLength(1));
      expect(stubStorage.savedEmployees[0].name, 'Updated');
    });
  });

  group('EmployeeRepository.deleteEmployee', () {
    test('deletes employee locally and completes', () async {
      stubStorage.setEmployees([
        Employee(
          id: 1,
          name: 'Test',
          salary: '5000',
          age: '30',
          profileImage: '',
        ),
      ]);
      fakeApi.setResponse(
        EmployeeResponse(status: 'success', data: [], message: 'OK'),
      );

      await repository.deleteEmployee(1);

      expect(fakeApi.lastMethod, 'deleteEmployee');
      expect(stubStorage.savedEmployees, isEmpty);
    });
  });
}
