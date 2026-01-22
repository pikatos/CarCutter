import 'package:flutter/foundation.dart';
import 'employee_repository.dart';
import 'employee_model.dart';

class EmployeeListState with ChangeNotifier {
  final EmployeeRepository _repository;

  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _error;

  EmployeeListState({required EmployeeRepository repository})
    : _repository = repository {
    loadEmployees();
  }

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _employees = await _repository.fetchEmployees();
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
      _employees = await _repository.fetchEmployees();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _repository.deleteEmployee(id);
      await refresh();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
