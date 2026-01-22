import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carcutter/features/employees/employee_api_invalid_response.dart';
import 'package:carcutter/common/invalid_http_response.dart';
import 'employee_model.dart';

abstract class EmployeeApiInterface {
  Future<EmployeeResponse> getAllEmployees();
  Future<EmployeeResponse> getEmployee(int id);
  Future<EmployeeResponse> createEmployee({
    required String name,
    required String salary,
    required String age,
  });
  Future<EmployeeResponse> updateEmployee(Employee employee);
  Future<EmployeeResponse> deleteEmployee(int id);
}

class EmployeeApi implements EmployeeApiInterface {
  static const String baseUrl = 'https://dummy.restapiexample.com/api/v1';
  final http.Client _client;

  EmployeeApi({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<EmployeeResponse> getAllEmployees() async {
    final response = await _client.get(Uri.parse('$baseUrl/employees'));
    if (response.statusCode == 200) {
      final employeeResponse = EmployeeResponse.fromJson(
        jsonDecode(response.body),
        Employee.fromListJson,
      );
      if (employeeResponse.status != 'success') {
        throw EmployeeApiInvalidResponse(employeeResponse);
      }
      return employeeResponse;
    } else {
      throw InvalidHttpResponse(response);
    }
  }

  @override
  Future<EmployeeResponse> getEmployee(int id) async {
    final response = await _client.get(Uri.parse('$baseUrl/employee/$id'));
    if (response.statusCode == 200) {
      final employeeResponse = EmployeeResponse.fromJson(
        jsonDecode(response.body),
        Employee.fromListJson,
      );
      if (employeeResponse.status != 'success') {
        throw EmployeeApiInvalidResponse(employeeResponse);
      }
      return employeeResponse;
    } else {
      throw InvalidHttpResponse(response);
    }
  }

  @override
  Future<EmployeeResponse> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'salary': salary, 'age': age}),
    );
    if (response.statusCode != 200) {
      throw InvalidHttpResponse(response);
    }

    final employeeResponse = EmployeeResponse.fromJson(
      jsonDecode(response.body),
      Employee.fromJson,
    );
    if (employeeResponse.status != 'success') {
      throw EmployeeApiInvalidResponse(employeeResponse);
    }
    return employeeResponse;
  }

  @override
  Future<EmployeeResponse> updateEmployee(Employee employee) async {
    final body = jsonEncode({
      'name': employee.name,
      'salary': employee.salary,
      'age': employee.age,
    });
    final response = await _client.put(
      Uri.parse('$baseUrl/update/${employee.id}'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode != 200) {
      throw InvalidHttpResponse(response);
    }
    dynamic json = jsonDecode(response.body);
    json['data']['id'] =
        employee.id; // API doesn't return ID, inject from request

    final employeeResponse = EmployeeResponse.fromJson(json, Employee.fromJson);
    if (employeeResponse.status != 'success') {
      throw EmployeeApiInvalidResponse(employeeResponse);
    }
    return employeeResponse;
  }

  @override
  Future<EmployeeResponse> deleteEmployee(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/delete/$id'));
    if (response.statusCode != 200) {
      throw InvalidHttpResponse(response);
    }
    final employeeResponse = EmployeeResponse.fromJson(
      jsonDecode(response.body),
      Employee.fromListJson,
    );
    if (employeeResponse.status != 'success') {
      throw EmployeeApiInvalidResponse(employeeResponse);
    }
    return employeeResponse;
  }
}
