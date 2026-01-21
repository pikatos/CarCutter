import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:carcutter/common/invalid_http_response.dart';
import 'employee_api.dart';
import 'employee_api_invalid_response.dart';
import 'employee_local_storage.dart';
import 'employee_model.dart';

class EmployeeRepository with ChangeNotifier {
  final EmployeeApiInterface _api;
  final EmployeeLocalStorage _localStorage;
  SyncOperation? _pendingOperation;

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
    if (_pendingOperation != null) {
      return;
    }
    final pendingOperations = await _localStorage.loadPendingOperations();
    if (pendingOperations.isEmpty) {
      return;
    }
    final operation = pendingOperations.first;
    _pendingOperation = operation;
    try {
      switch (operation.type) {
        case SyncOperationType.create:
          final response = await _api.createEmployee(
            name: operation.employee.name,
            salary: operation.employee.salary,
            age: operation.employee.age,
          );
          final created = response.data!.first;
          _pendingOperation = await _localStorage.performTransaction((
            content,
          ) async {
            final index = content.employees.indexWhere(
              (e) => e.id == operation.employee.id,
            );
            if (index != -1) {
              content.employees[index] = created;
            }
            content.pendingOperations.removeAt(0);
            return content.pendingOperations.firstOrNull;
          });
          notifyListeners();
          break;
        case SyncOperationType.update:
          final response = await _api.updateEmployee(operation.employee);
          final updated = response.data!.first;
          _pendingOperation = await _localStorage.performTransaction((
            content,
          ) async {
            final index = content.employees.indexWhere(
              (e) => e.id == operation.employee.id,
            );
            if (index != -1) {
              content.employees[index] = updated;
            }
            content.pendingOperations.removeAt(0);
            return content.pendingOperations.firstOrNull;
          });
          notifyListeners();
          break;
        case SyncOperationType.delete:
          await _api.deleteEmployee(operation.employee.id);
          _pendingOperation = await _localStorage.performTransaction((
            content,
          ) async {
            content.pendingOperations.removeAt(0);
            return content.pendingOperations.firstOrNull;
          });
          notifyListeners();
          break;
      }
    } on InvalidHttpResponse catch (_) {
      // TODO: reschedule sync, if status == 429 wait (response.x-rate-limit-reset - response.date + 4)
      _pendingOperation = null;
      unawaited(() async {
        await Future.delayed(Duration(seconds: 60));
        unawaited(syncPendingOperations());
      }());
    } on EmployeeApiInvalidResponse catch (_) {
      // drop operation
      // TODO: alert user
      _pendingOperation = await _localStorage.performTransaction((
        content,
      ) async {
        content.pendingOperations.removeAt(0);
        return content.pendingOperations.firstOrNull;
      });
      notifyListeners();
      unawaited(syncPendingOperations());
    } catch (_) {
      // drop operation
      // TODO: alert user
      _pendingOperation = await _localStorage.performTransaction((
        content,
      ) async {
        content.pendingOperations.removeAt(0);
        return content.pendingOperations.firstOrNull;
      });
      notifyListeners();
      unawaited(syncPendingOperations());
    }
  }
}
