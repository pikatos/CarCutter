import 'employee_api.dart';
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
  Future<void> deleteEmployee(int id);
}

class _EmployeeApiImpl implements EmployeeApiInterface {
  @override
  Future<EmployeeResponse> getAllEmployees() => EmployeeApi.getAllEmployees();

  @override
  Future<EmployeeResponse> getEmployee(int id) => EmployeeApi.getEmployee(id);

  @override
  Future<EmployeeResponse> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) => EmployeeApi.createEmployee(name: name, salary: salary, age: age);

  @override
  Future<EmployeeResponse> updateEmployee(Employee employee) =>
      EmployeeApi.updateEmployee(employee);

  @override
  Future<void> deleteEmployee(int id) => EmployeeApi.deleteEmployee(id);
}

class EmployeeRepository {
  final EmployeeApiInterface _api;

  EmployeeRepository({EmployeeApiInterface? api})
    : _api = api ?? _EmployeeApiImpl();

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
