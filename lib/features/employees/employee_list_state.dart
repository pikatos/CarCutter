import 'dart:async';
import 'package:flutter/material.dart';
import 'employee_repository.dart';
import 'employee_model.dart';
import '../../common/animated_list_model.dart';

class EmployeeListState with ChangeNotifier {
  final EmployeeRepository _repository;
  final GlobalKey<AnimatedListState> _listKey;
  StreamSubscription? _changesSubscription;

  List<Employee> _employees = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  String? _message;

  late final ListModel<Employee> _listModel;

  EmployeeListState({
    required EmployeeRepository repository,
    required GlobalKey<AnimatedListState> listKey,
  }) : _repository = repository,
       _listKey = listKey {
    _listModel = ListModel<Employee>(
      listKey: _listKey,
      initialItems: _employees,
      removeItemBuilder: _buildRemovedItem,
    );
    _changesSubscription = _repository.changes.listen(
      (change) {
        switch (change) {
          case EmployeeChangeCreated(:final employee):
            if (!_employees.any((e) => e.id == employee.id)) {
              _employees.add(employee);
              _employees.sort(Employee.byName);
              final newIndex = _employees.indexWhere(
                (e) => e.id == employee.id,
              );
              _listModel.insert(newIndex, employee);
            }
            _message = 'Employee ${employee.name} created';
          case EmployeeChangeUpdated(:final employee):
            final oldIndex = _employees.indexWhere((e) => e.id == employee.id);
            if (oldIndex != -1) {
              final item = _employees[oldIndex];
              _employees[oldIndex] = employee;
              _employees.sort(Employee.byName);
              final newIndex = _employees.indexWhere(
                (e) => e.id == employee.id,
              );
              if (oldIndex == newIndex) {
                _listModel.updateItem(newIndex, employee);
              } else {
                _listModel.removeAt(oldIndex);
                _listModel.insert(newIndex, item);
              }
            }
            _message = 'Employee ${employee.name} updated';
          case EmployeeChangeDeleted(:final employee):
            final index = _employees.indexWhere((e) => e.id == employee.id);
            if (index != -1) {
              _listModel.removeAt(index);
              _employees.removeAt(index);
            }
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

  static Widget _buildRemovedItem(
    BuildContext context,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: const ListTile(
          leading: CircleAvatar(child: Text('')),
          title: Text(''),
          subtitle: Text(''),
        ),
      ),
    );
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
        _listModel.replaceAll(employees);
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
        _listModel.replaceAll(employees);
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
      _listModel.removeAt(index);
      _employees.removeAt(index);
      _error = null;
      notifyListeners();
    }
    _repository.deleteEmployee(id).ignore();
  }
}
