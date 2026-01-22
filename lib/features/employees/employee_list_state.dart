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
  String? _message;
  int? _scrollToIndex;

  EmployeeListState({required EmployeeRepository repository})
    : _repository = repository {
    _changesSubscription = _repository.changes.listen(
      (change) {
        switch (change) {
          case EmployeeChangeCreated(:final employee):
            if (!_employees.any((e) => e.id == employee.id)) {
              _employees.add(employee);
              _employees.sort(Employee.byName);
              _scrollToIndex = _employees.indexWhere(
                (e) => e.id == employee.id,
              );
            }
            _message = 'Employee ${employee.name} created';
          case EmployeeChangeUpdated(:final employee):
            final index = _employees.indexWhere((e) => e.id == employee.id);
            if (index != -1) {
              _employees[index] = employee;
              _scrollToIndex = index;
            }
            _message = 'Employee ${employee.name} updated';
          case EmployeeChangeDeleted(:final employee):
            _employees.removeWhere((e) => e.id == employee.id);
            _message = 'Employee ${employee.name} deleted';
        }
        _error = null;
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
  String? get message => _message;
  int? get scrollToIndex => _scrollToIndex;

  void clearScrollTarget() {
    _scrollToIndex = null;
  }

  void clearMessage() {
    _message = null;
  }

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

  void deleteEmployee(int id) {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      _employees.removeAt(index);
      _error = null;
      notifyListeners();
    }
    _repository.deleteEmployee(id).ignore();
  }
}
