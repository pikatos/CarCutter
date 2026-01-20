import 'employee_api.dart';
import 'employee_model.dart';

class EmployeeRepository {
  final EmployeeApiInterface _api;

  EmployeeRepository({EmployeeApiInterface? api}) : _api = api ?? EmployeeApi();

  Future<List<Employee>> getAllEmployees() async {
    final response = await _api.getAllEmployees();
    return response.data;
  }

  Future<Employee> getEmployee(int id) async {
    final response = await _api.getEmployee(id);
    return response.data.first;
  }

  Future<Employee> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    final response = await _api.createEmployee(
      name: name,
      salary: salary,
      age: age,
    );
    return response.data.first;
  }

  Future<Employee> updateEmployee(Employee employee) async {
    final response = await _api.updateEmployee(employee);
    return response.data.first;
  }

  Future<void> deleteEmployee(int id) async {
    await _api.deleteEmployee(id);
  }
}
