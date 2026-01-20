import 'package:flutter_test/flutter_test.dart';
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
  Future<void> deleteEmployee(int id) async {
    _fake._lastMethod = 'deleteEmployee';
    _fake._lastArgs = {'id': id};
    if (_fake._nextException != null) throw _fake._nextException!;
  }
}

void main() {
  late FakeEmployeeApi fakeApi;
  late EmployeeRepository repository;

  setUp(() {
    fakeApi = FakeEmployeeApi();
    repository = EmployeeRepository(api: StubEmployeeApi(fakeApi));
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

    test('propagates exception from API', () async {
      fakeApi.setException(Exception('API Error'));

      expect(() => repository.getAllEmployees(), throwsException);
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

    test('propagates exception on failure', () async {
      fakeApi.setException(Exception('Create Failed'));

      expect(
        () =>
            repository.createEmployee(name: 'Test', salary: '1000', age: '20'),
        throwsException,
      );
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

    test('propagates exception', () async {
      fakeApi.setException(Exception('Delete Failed'));

      expect(() => repository.deleteEmployee(1), throwsException);
    });
  });
}
