import 'dart:async';
import 'package:flutter/foundation.dart';
import 'employee_repository.dart';
import 'employee_model.dart';

class EmployeeListState with ChangeNotifier {
  final EmployeeRepository _repository;
  StreamSubscription? _changesSubscription;

  List<Employee> _employees = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;

  EmployeeListState({required EmployeeRepository repository})
    : _repository = repository {
    _changesSubscription = _repository.changes.asBroadcastStream().listen(
      (change) {
        switch (change) {
          case EmployeeChangeCreated(:final employee):
            if (!_employees.any((e) => e.id == employee.id)) {
              _employees.add(employee);
              _employees.sort(Employee.byName);
            }
          case EmployeeChangeUpdated(:final employee):
            final index = _employees.indexWhere((e) => e.id == employee.id);
            if (index != -1) {
              _employees[index] = employee;
            }
          case EmployeeChangeDeleted(:final employee):
            _employees.removeWhere((e) => e.id == employee.id);
        }
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
    loadEmployees();
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    super.dispose();
  }

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;

  Future<void> loadEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.fetchEmployees().forEach((employees) {
        _employees = employees;
        _isSyncing = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.fetchEmployees().forEach((employees) {
        _employees = employees;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEmployee(int id) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      _employees.removeAt(index);
      notifyListeners();
    }
    () async {
      try {
        await _repository.deleteEmployee(id);
      } catch (_) {}
    }();
  }
}
