import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:carcutter/features/employees/employee_api.dart';
import 'package:carcutter/features/employees/employee_model.dart';

class FakeHttpClient extends Fake implements http.Client {
  String? _nextResponseBody;
  int? _nextStatusCode;
  String? _lastMethod;
  Uri? _lastUri;
  Map<String, String>? _lastHeaders;
  dynamic _lastBody;

  void setResponse(String body, int statusCode) {
    _nextResponseBody = body;
    _nextStatusCode = statusCode;
  }

  String? get lastMethod => _lastMethod;
  Uri? get lastUri => _lastUri;
  Map<String, String>? get lastHeaders => _lastHeaders;
  dynamic get lastBody => _lastBody;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    _lastMethod = 'GET';
    _lastUri = url;
    _lastHeaders = headers;
    return http.Response(_nextResponseBody ?? '', _nextStatusCode ?? 200);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    body,
    Encoding? encoding,
  }) async {
    _lastMethod = 'POST';
    _lastUri = url;
    _lastHeaders = headers;
    _lastBody = body;
    return http.Response(_nextResponseBody ?? '', _nextStatusCode ?? 200);
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    body,
    Encoding? encoding,
  }) async {
    _lastMethod = 'PUT';
    _lastUri = url;
    _lastHeaders = headers;
    _lastBody = body;
    return http.Response(_nextResponseBody ?? '', _nextStatusCode ?? 200);
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    _lastMethod = 'DELETE';
    _lastUri = url;
    _lastHeaders = headers;
    return http.Response(_nextResponseBody ?? '', _nextStatusCode ?? 200);
  }
}

void main() {
  late FakeHttpClient fakeClient;
  late EmployeeApi api;

  setUp(() {
    fakeClient = FakeHttpClient();
    api = EmployeeApi(client: fakeClient);
  });

  group('EmployeeApi.getAllEmployees', () {
    test('returns list of employees on 200', () async {
      final responseBody = '''
        {
          "status": "success",
          "data": [
            {
              "id": 1,
              "employee_name": "John",
              "employee_salary": "5000",
              "employee_age": "30",
              "profile_image": ""
            },
            {
              "id": 2,
              "employee_name": "Jane",
              "employee_salary": "6000",
              "employee_age": "25",
              "profile_image": ""
            }
          ],
          "message": "Successfully!"
        }
      ''';
      fakeClient.setResponse(responseBody, 200);

      final response = await api.getAllEmployees();

      expect(response.status, 'success');
      expect(response.data, hasLength(2));
      expect(response.data![0].name, 'John');
      expect(response.data![1].name, 'Jane');
      expect(fakeClient.lastMethod, 'GET');
    });

    test('returns empty list when API returns empty data', () async {
      final responseBody = '''
        {
          "status": "success",
          "data": [],
          "message": "Successfully!"
        }
      ''';
      fakeClient.setResponse(responseBody, 200);

      final response = await api.getAllEmployees();

      expect(response.data, isEmpty);
    });

    test('throws exception on non-200 status', () async {
      fakeClient.setResponse('Error', 500);

      expect(() => api.getAllEmployees(), throwsException);
    });
  });

  group('EmployeeApi.getEmployee', () {
    test('returns single employee on 200', () async {
      final responseBody = '''
        {
          "status": "success",
          "data": {
            "id": 1,
            "employee_name": "John",
            "employee_salary": "5000",
            "employee_age": "30",
            "profile_image": ""
          },
          "message": "Successfully!"
        }
      ''';
      fakeClient.setResponse(responseBody, 200);

      final response = await api.getEmployee(1);

      expect(response.data, hasLength(1));
      expect(response.data![0].id, 1);
      expect(response.data![0].name, 'John');
    });

    test('throws exception on 404', () async {
      fakeClient.setResponse('Not Found', 404);

      expect(() => api.getEmployee(999), throwsException);
    });
  });

  group('EmployeeApi.createEmployee', () {
    test('returns created employee on 200', () async {
      final responseBody = '''
        {
          "status": "success",
          "data": {
            "id": 3,
            "name": "New Employee",
            "salary": "4000",
            "age": "22"
          },
          "message": "Successfully!"
        }
      ''';
      fakeClient.setResponse(responseBody, 200);

      final response = await api.createEmployee(
        name: 'New Employee',
        salary: '4000',
        age: '22',
      );

      expect(response.data, hasLength(1));
      expect(response.data![0].name, 'New Employee');
      expect(response.data![0].salary, '4000');
      expect(fakeClient.lastMethod, 'POST');
    });

    test('throws exception on failure', () async {
      fakeClient.setResponse('Error', 400);

      expect(
        () => api.createEmployee(name: 'Test', salary: '1000', age: '20'),
        throwsException,
      );
    });
  });

  group('EmployeeApi.updateEmployee', () {
    test('returns updated employee with injected ID', () async {
      final responseBody = '''
        {
          "status": "success",
          "data": {
            "name": "Updated",
            "salary": "7000",
            "age": "35"
          },
          "message": "Successfully!"
        }
      ''';
      fakeClient.setResponse(responseBody, 200);

      final employee = Employee(
        id: 42,
        name: 'Updated',
        salary: '7000',
        age: '35',
        profileImage: '',
      );
      final response = await api.updateEmployee(employee);

      expect(response.data, hasLength(1));
      expect(response.data![0].id, 42);
      expect(response.data![0].name, 'Updated');
      expect(fakeClient.lastMethod, 'PUT');
    });

    test('throws exception on failure', () async {
      fakeClient.setResponse('Error', 500);

      final employee = Employee(
        id: 1,
        name: 'Test',
        salary: '1000',
        age: '20',
        profileImage: '',
      );
      expect(() => api.updateEmployee(employee), throwsException);
    });
  });

  group('EmployeeApi.deleteEmployee', () {
    test('succeeds on 200', () async {
      fakeClient.setResponse(
        '{"status":"success","data":null,"message":"Successfully!"}',
        200,
      );

      await expectLater(api.deleteEmployee(1), completes);
      expect(fakeClient.lastMethod, 'DELETE');
    });

    test('throws exception on non-200', () async {
      fakeClient.setResponse('Error', 500);

      expect(() => api.deleteEmployee(1), throwsException);
    });
  });
}
