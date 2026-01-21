import 'package:flutter/foundation.dart';
import 'employee_api.dart';
import 'employee_local_storage.dart';
import 'employee_model.dart';

class EmployeeRepository with ChangeNotifier {
  final EmployeeApiInterface _api;
  final EmployeeLocalStorage _localStorage;

  EmployeeRepository({
    EmployeeApiInterface? api,
    EmployeeLocalStorage? localStorage,
  }) : _api = api ?? EmployeeApi(),
       _localStorage = localStorage ?? EmployeeLocalStorage();

  Future<List<Employee>> fetchEmployees() async {
    try {
      final response = await _api.getAllEmployees();
      final serverEmployees = response.data ?? [];
      final operations = await _localStorage.getAllPendingOperations();
      final merged = _mergeEmployees(serverEmployees, operations);
      await _localStorage.saveEmployees(merged);
      return merged;
    } catch (e) {
      return await _localStorage.loadEmployees();
    }
  }

  List<Employee> _mergeEmployees(
    List<Employee> serverEmployees,
    List<SyncOperation> operations,
  ) {
    final result = List<Employee>.from(serverEmployees);

    for (final op in operations) {
      switch (op.type) {
        case SyncOperationType.create:
          result.add(op.employee);
          break;
        case SyncOperationType.update:
          final index = result.indexWhere((e) => e.id == op.employee.id);
          if (index != -1) {
            result[index] = op.employee;
          }
          break;
        case SyncOperationType.delete:
          result.removeWhere((e) => e.id == op.employee.id);
          break;
      }
    }

    return result;
  }

  Future<Employee> getEmployee(int id) async {
    try {
      final response = await _api.getEmployee(id);
      final employee = response.data!.first;
      await _localStorage.updateEmployee(employee);
      return employee;
    } catch (e) {
      final employee = await _localStorage.loadEmployee(id);
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
    final employee = await _localStorage.addEmployeeOffline(
      name: name,
      salary: salary,
      age: age,
    );
    await syncPendingOperations();
    return employee;
  }

  Future<Employee> updateEmployee(Employee employee) async {
    await _localStorage.updateEmployeeOffline(employee);
    await syncPendingOperations();
    return employee;
  }

  Future<void> deleteEmployee(int id) async {
    final employee = await _localStorage.loadEmployee(id);
    if (employee != null) {
      await _localStorage.deleteEmployeeOffline(id);
    }
    await syncPendingOperations();
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
            final created = response.data!.first;

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
  }
}
