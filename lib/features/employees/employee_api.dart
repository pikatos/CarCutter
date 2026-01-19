import 'dart:convert';
import 'package:http/http.dart' as http;
import 'employee_model.dart';

class EmployeeApi {
  static const String baseUrl = 'https://dummy.restapiexample.com/api/v1';

  static Future<EmployeeResponse> getAllEmployees() async {
    final response = await http.get(Uri.parse('$baseUrl/employees'));
    if (response.statusCode == 200) {
      return EmployeeResponse.fromJson(
        jsonDecode(response.body),
        Employee.fromListJson,
      );
    } else {
      throw Exception('Failed to load employees');
    }
  }

  static Future<EmployeeResponse> getEmployee(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/employee/$id'));
    if (response.statusCode == 200) {
      return EmployeeResponse.fromJson(
        jsonDecode(response.body),
        Employee.fromListJson,
      );
    } else {
      throw Exception('Failed to load employee');
    }
  }

  static Future<EmployeeResponse> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'salary': salary, 'age': age}),
    );
    if (response.statusCode == 200) {
      return EmployeeResponse.fromJson(
        jsonDecode(response.body),
        Employee.fromJson,
      );
    } else {
      throw Exception('Failed to create employee');
    }
  }

  static Future<EmployeeResponse> updateEmployee(Employee employee) async {
    final body = jsonEncode({
      'name': employee.name,
      'salary': employee.salary,
      'age': employee.age,
    });
    final response = await http.put(
      Uri.parse('$baseUrl/update/${employee.id}'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      return EmployeeResponse.fromJson(
        jsonDecode(response.body),
        Employee.fromJson,
      );
    } else {
      throw Exception('Failed to update employee');
    }
  }

  static Future<void> deleteEmployee(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/delete/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete employee');
    }
  }
}
