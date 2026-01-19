import 'employee_api.dart';
import 'employee_model.dart';

class EmployeeRepository {
  Future<List<Employee>> getAllEmployees() async {
    final response = await EmployeeApi.getAllEmployees();
    return response.data;
  }

  Future<Employee> getEmployee(int id) async {
    final response = await EmployeeApi.getEmployee(id);
    return response.data.first;
  }

  Future<Employee> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    final response = await EmployeeApi.createEmployee(
      name: name,
      salary: salary,
      age: age,
    );
    return response.data.first;
  }

  Future<Employee> updateEmployee(Employee employee) async {
    final response = await EmployeeApi.updateEmployee(employee);
    return response.data.first;
  }

  Future<void> deleteEmployee(int id) async {
    await EmployeeApi.deleteEmployee(id);
  }
}
