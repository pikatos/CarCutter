import 'dart:async';
import 'employee_api.dart';
import 'employee_local_storage.dart';
import 'employee_model.dart';

sealed class EmployeeChange {
  final Employee employee;
  const EmployeeChange._(this.employee);
}

class EmployeeChangeCreated extends EmployeeChange {
  const EmployeeChangeCreated(super.employee) : super._();
}

class EmployeeChangeUpdated extends EmployeeChange {
  const EmployeeChangeUpdated(super.employee) : super._();
}

class EmployeeChangeDeleted extends EmployeeChange {
  const EmployeeChangeDeleted(super.employee) : super._();
}

class EmployeeRepository {
  final EmployeeApiInterface _api;
  final EmployeeLocalStorage _localStorage;
  final _changesController = StreamController<EmployeeChange>.broadcast();

  EmployeeRepository({
    EmployeeApiInterface? api,
    EmployeeLocalStorage? localStorage,
  }) : _api = api ?? EmployeeApi(),
       _localStorage = localStorage ?? EmployeeLocalStorage();

  Stream<EmployeeChange> get changes => _changesController.stream;

  Stream<List<Employee>> fetchEmployees() async* {
    yield await _localStorage.loadEmployees();
    final response = await _api.getAllEmployees();
    final employees = response.data ?? [];
    employees.sort(Employee.byName);
    await _localStorage.saveEmployees(employees);
    yield employees;
  }

  Stream<Employee?> fetchEmployee(int id) async* {
    yield await _localStorage.loadEmployee(id);
    final response = await _api.getEmployee(id);
    final employee = response.data?.firstOrNull;
    if (employee != null) {
      await _localStorage.updateEmployee(employee);
    }
    yield employee;
  }

  Future<Employee> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    final localEmployee = await _localStorage.createEmployee(
      name: name,
      salary: salary,
      age: age,
    );
    _changesController.add(EmployeeChangeCreated(localEmployee));
    try {
      final response = await _api.createEmployee(
        name: name,
        salary: salary,
        age: age,
      );
      final serverEmployee = response.data!.first;
      await _localStorage.replaceEmployee(localEmployee, serverEmployee);
      _changesController.add(EmployeeChangeUpdated(serverEmployee));
      return serverEmployee;
    } catch (e) {
      await _localStorage.deleteEmployee(localEmployee.id);
      _changesController.add(EmployeeChangeDeleted(localEmployee));
      _changesController.addError(Exception("Failed to create emplyee $name"));
      rethrow;
    }
  }

  Future<Employee> updateEmployee(Employee employee) async {
    final prevLocalEmployee = await _localStorage.updateEmployee(employee);
    _changesController.add(EmployeeChangeUpdated(employee));
    try {
      final response = await _api.updateEmployee(employee);
      final serverEmployee = response.data!.first;
      await _localStorage.updateEmployee(serverEmployee);
      _changesController.add(EmployeeChangeUpdated(serverEmployee));
      return serverEmployee;
    } catch (e) {
      await _localStorage.updateEmployee(prevLocalEmployee);
      _changesController.add(EmployeeChangeUpdated(prevLocalEmployee));
      _changesController.addError(
        Exception("Failed to update emplyee ${employee.name}"),
      );
      rethrow;
    }
  }

  Future<void> deleteEmployee(int id) async {
    final employee = await _localStorage.deleteEmployee(id);
    _changesController.add(EmployeeChangeDeleted(employee));
    try {
      await _api.deleteEmployee(id);
    } catch (e) {
      await _localStorage.addEmployee(employee);
      _changesController.add(EmployeeChangeCreated(employee));
      _changesController.addError(
        Exception("Failed to delete emplyee ${employee.name}"),
      );
      rethrow;
    }
  }
}
