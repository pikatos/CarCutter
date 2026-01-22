import 'dart:async';

import 'package:carcutter/common/invalid_http_response.dart';
import 'employee_api.dart';
import 'employee_api_invalid_response.dart';
import 'employee_local_storage.dart';
import 'employee_model.dart';

class EmployeeRepository {
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
      return await _localStorage.mergeWithPendingOperations(serverEmployees);
    } catch (e) {
      return await _localStorage.loadEmployees();
    }
  }

  Future<Employee> fetchEmployee(int id) async {
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
    await _localStorage.deleteEmployeeOffline(id);
    await syncPendingOperations();
  }

  Future<void> syncPendingOperations() async {
    final pendingOperations = await _localStorage.loadPendingOperations();
    if (pendingOperations.isEmpty) {
      return;
    }
    final operation = pendingOperations.first;
    try {
      switch (operation.type) {
        case SyncOperationType.create:
          final response = await _api.createEmployee(
            name: operation.employee.name,
            salary: operation.employee.salary,
            age: operation.employee.age,
          );
          final created = response.data!.first;
          await _localStorage.performTransaction((content) async {
            final index = content.employees.indexWhere(
              (e) => e.id == operation.employee.id,
            );
            if (index != -1) {
              content.employees[index] = created;
            }
            content.pendingOperations.removeAt(0);
          });
          break;
        case SyncOperationType.update:
          final response = await _api.updateEmployee(operation.employee);
          final updated = response.data!.first;
          await _localStorage.performTransaction((content) async {
            final index = content.employees.indexWhere(
              (e) => e.id == operation.employee.id,
            );
            if (index != -1) {
              content.employees[index] = updated;
            }
            content.pendingOperations.removeAt(0);
          });
          break;
        case SyncOperationType.delete:
          await _api.deleteEmployee(operation.employee.id);
          await _localStorage.performTransaction((content) async {
            content.pendingOperations.removeAt(0);
          });
          break;
      }
    } on InvalidHttpResponse catch (_) {
      unawaited(() async {
        await Future.delayed(Duration(seconds: 60));
        unawaited(syncPendingOperations());
      }());
    } on EmployeeApiInvalidResponse catch (_) {
      await _localStorage.performTransaction((content) async {
        content.pendingOperations.removeAt(0);
      });
      unawaited(syncPendingOperations());
    } catch (_) {
      await _localStorage.performTransaction((content) async {
        content.pendingOperations.removeAt(0);
      });
      unawaited(syncPendingOperations());
    }
  }
}
