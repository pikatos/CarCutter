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
      return await _localStorage.loadEmployees();
    }
  }

  Future<Employee> getEmployee(int id) async {
    try {
      final response = await _api.getEmployee(id);
      return response.data.first;
    } catch (e) {
      final employees = await _localStorage.loadEmployees();
      return employees.firstWhere((e) => e.id == id);
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

      final cached = await _localStorage.loadEmployees();
      cached.add(created);
      await _localStorage.saveEmployees(cached);

      return created;
    } catch (e) {
      _offlineStatus.setOffline(true);

      final localId = await _localStorage.getNextLocalId();
      final employee = Employee(
        id: localId,
        name: name,
        salary: salary,
        age: age,
        profileImage: '',
      );

      await _localStorage.addSyncOperation(
        SyncOperation.create(employee: employee, localId: localId),
      );

      final cached = await _localStorage.loadEmployees();
      cached.add(employee);
      await _localStorage.saveEmployees(cached);

      return employee;
    }
  }

  Future<Employee> updateEmployee(Employee employee) async {
    try {
      final response = await _api.updateEmployee(employee);
      final updated = response.data.first;

      final cached = await _localStorage.loadEmployees();
      final index = cached.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        cached[index] = updated;
      }
      await _localStorage.saveEmployees(cached);

      return updated;
    } catch (e) {
      _offlineStatus.setOffline(true);

      await _localStorage.addSyncOperation(
        SyncOperation.update(employee: employee),
      );

      final cached = await _localStorage.loadEmployees();
      final index = cached.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        cached[index] = employee;
        await _localStorage.saveEmployees(cached);
      }

      return employee;
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _api.deleteEmployee(id);

      final cached = await _localStorage.loadEmployees();
      cached.removeWhere((e) => e.id == id);
      await _localStorage.saveEmployees(cached);
    } catch (e) {
      _offlineStatus.setOffline(true);

      await _localStorage.addSyncOperation(
        SyncOperation.delete(employeeId: id),
      );

      final cached = await _localStorage.loadEmployees();
      final index = cached.indexWhere((e) => e.id == id);
      if (index != -1) {
        cached.removeAt(index);
        await _localStorage.saveEmployees(cached);
      }
    }
  }

  Future<void> syncPendingOperations() async {
    final operations = await _localStorage.loadPendingOperations();
    if (operations.isEmpty) return;

    for (final operation in operations) {
      try {
        switch (operation.type) {
          case SyncOperationType.create:
            final response = await _api.createEmployee(
              name: operation.employee!.name,
              salary: operation.employee!.salary,
              age: operation.employee!.age,
            );
            final created = response.data.first;

            if (operation.localId != null) {
              final cached = await _localStorage.loadEmployees();
              final index = cached.indexWhere((e) => e.id == operation.localId);
              if (index != -1) {
                cached[index] = created;
              } else {
                cached.add(created);
              }
              await _localStorage.saveEmployees(cached);
            }
            break;
          case SyncOperationType.update:
            await _api.updateEmployee(operation.employee!);
            break;
          case SyncOperationType.delete:
            await _api.deleteEmployee(operation.employeeId!);
            break;
        }
      } catch (e) {
        continue;
      }
    }

    await _localStorage.clearPendingOperations();
    _offlineStatus.setOffline(false);
  }
}
