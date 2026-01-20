import 'package:flutter/foundation.dart';
import 'employee_api.dart';
import 'employee_local_storage.dart';
import 'employee_model.dart';
import 'offline_status_provider.dart';

class EmployeeRepository with ChangeNotifier {
  final EmployeeApiInterface _api;
  final EmployeeLocalStorage _localStorage;
  final OfflineStatus _offlineStatus;

  EmployeeRepository({
    EmployeeApiInterface? api,
    EmployeeLocalStorage? localStorage,
    OfflineStatus? offlineStatus,
  }) : _api = api ?? EmployeeApi(),
       _localStorage = localStorage ?? EmployeeLocalStorage(),
       _offlineStatus = offlineStatus ?? OfflineStatus();

  Future<List<Employee>> getAllEmployees() async {
    try {
      final response = await _api.getAllEmployees();
      final employees = response.data;
      await _localStorage.saveEmployees(employees);
      _offlineStatus.setOffline(false);
      return employees;
    } catch (e) {
      _offlineStatus.setOffline(true);
      return await _localStorage.getAllEmployees();
    }
  }

  Future<Employee> getEmployee(int id) async {
    try {
      final response = await _api.getEmployee(id);
      return response.data.first;
    } catch (e) {
      final employee = await _localStorage.getEmployee(id);
      if (employee != null) {
        return employee;
      }
      throw Exception('Employee not found');
    }
  }

  Future<Employee> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    try {
      final response = await _api.createEmployee(
        name: name,
        salary: salary,
        age: age,
      );
      final created = response.data.first;

      await _localStorage.addEmployee(created);

      return created;
    } catch (e) {
      _offlineStatus.setOffline(true);

      return await _localStorage.addEmployeeOffline(
        name: name,
        salary: salary,
        age: age,
      );
    }
  }

  Future<Employee> updateEmployee(Employee employee) async {
    try {
      final response = await _api.updateEmployee(employee);
      final updated = response.data.first;

      await _localStorage.updateEmployee(updated);

      return updated;
    } catch (e) {
      _offlineStatus.setOffline(true);

      await _localStorage.updateEmployeeOffline(employee);
      return employee;
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _api.deleteEmployee(id);

      await _localStorage.deleteEmployee(id);
    } catch (e) {
      _offlineStatus.setOffline(true);

      await _localStorage.deleteEmployeeOffline(id);
    }
  }

  Future<void> syncPendingOperations() async {
    final operations = await _localStorage.getAllPendingOperations();
    if (operations.isEmpty) return;

    final failedOperations = <SyncOperation>[];

    for (final operation in operations) {
      try {
        switch (operation.type) {
          case SyncOperationType.create:
            final response = await _api.createEmployee(
              name: operation.employee.name,
              salary: operation.employee.salary,
              age: operation.employee.age,
            );
            final created = response.data.first;

            await _localStorage.updateEmployee(created);
            break;
          case SyncOperationType.update:
            await _api.updateEmployee(operation.employee);
            break;
          case SyncOperationType.delete:
            await _api.deleteEmployee(operation.employee.id);
            break;
        }
      } catch (e) {
        failedOperations.add(operation);
      }
    }

    await _localStorage.savePendingOperations(failedOperations);

    if (failedOperations.isEmpty) {
      _offlineStatus.setOffline(false);
    }
  }
}
