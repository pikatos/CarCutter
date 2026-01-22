import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carcutter/features/employees/employee_api.dart';
import 'package:carcutter/features/employees/employee_list_view.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_repository.dart';

class StubEmployeeApi implements EmployeeApiInterface {
  List<Employee> _employees = [];
  Exception? _exception;

  void setEmployees(List<Employee> employees) {
    _employees = employees;
  }

  void setException(Exception exception) {
    _exception = exception;
  }

  @override
  Future<EmployeeResponse> getAllEmployees() async {
    if (_exception != null) throw _exception!;
    return EmployeeResponse(status: 'success', data: _employees, message: 'OK');
  }

  @override
  Future<EmployeeResponse> getEmployee(int id) async {
    if (_exception != null) throw _exception!;
    final employee = _employees.firstWhere((e) => e.id == id);
    return EmployeeResponse(status: 'success', data: [employee], message: 'OK');
  }

  @override
  Future<EmployeeResponse> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    if (_exception != null) throw _exception!;
    final newEmployee = Employee(
      id: _employees.length + 1,
      name: name,
      salary: salary,
      age: age,
      profileImage: '',
    );
    _employees.add(newEmployee);
    return EmployeeResponse(
      status: 'success',
      data: [newEmployee],
      message: 'OK',
    );
  }

  @override
  Future<EmployeeResponse> updateEmployee(Employee employee) async {
    if (_exception != null) throw _exception!;
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _employees[index] = employee;
    }
    return EmployeeResponse(status: 'success', data: [employee], message: 'OK');
  }

  @override
  Future<EmployeeResponse> deleteEmployee(int id) async {
    if (_exception != null) throw _exception!;
    _employees.removeWhere((e) => e.id == id);
    return EmployeeResponse(status: 'success', data: null, message: 'OK');
  }
}

class StubLocalStorage extends EmployeeLocalStorage {
  List<Employee> _employees = [];
  int _nextLocalId = -1;

  void setEmployees(List<Employee> employees) {
    _employees = List.from(employees);
  }

  @override
  Future<EmployeeLocalStorageContent> loadContent() async {
    return EmployeeLocalStorageContent(
      employees: List.from(_employees),
      localIdCounter: _nextLocalId,
    );
  }

  @override
  Future<void> saveContent(EmployeeLocalStorageContent content) async {
    _employees = List.from(content.employees);
    _nextLocalId = content.localIdCounter;
  }

  @override
  Future<List<Employee>> loadEmployees() async {
    return List.from(_employees);
  }

  @override
  Future<void> saveEmployees(List<Employee> employees) async {
    _employees = List.from(employees);
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    _employees.add(employee);
  }

  @override
  Future<Employee?> loadEmployee(int id) async {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Employee> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    final localId = _nextLocalId;
    _nextLocalId--;
    final employee = Employee(
      id: localId,
      name: name,
      salary: salary,
      age: age,
      profileImage: '',
    );
    _employees.add(employee);
    return employee;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    final prevEmployee = index != -1 ? _employees[index] : employee;
    if (index != -1) {
      _employees[index] = employee;
    } else {
      _employees.add(employee);
    }
    return prevEmployee;
  }

  @override
  Future<Employee> deleteEmployee(int id) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final employee = _employees[index];
      _employees.removeAt(index);
      return employee;
    }
    throw Exception('Employee not found: $id');
  }
}

void main() {
  late StubEmployeeApi stubApi;
  late StubLocalStorage stubStorage;

  setUp(() {
    stubApi = StubEmployeeApi();
    stubStorage = StubLocalStorage();
  });

  Widget createWidgetWithRepository() {
    final repository = EmployeeRepository(
      api: stubApi,
      localStorage: stubStorage,
    );
    return MultiProvider(
      providers: [Provider<EmployeeRepository>.value(value: repository)],
      child: MaterialApp(home: EmployeeListView(repository: repository)),
    );
  }

  group('EmployeeListScreen initial state', () {
    testWidgets('shows loading indicator while fetching', (
      WidgetTester tester,
    ) async {
      stubApi.setEmployees([]);
      await tester.pumpWidget(createWidgetWithRepository());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no employees', (
      WidgetTester tester,
    ) async {
      stubApi.setEmployees([]);
      await tester.pumpWidget(createWidgetWithRepository());
      await tester.runAsync(() async {
        await Future.delayed(Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.text('No employees found'), findsOneWidget);
    });
  });

  group('EmployeeListScreen with employees', () {
    testWidgets('displays list of employees', (WidgetTester tester) async {
      stubApi.setEmployees([
        Employee(
          id: 1,
          name: 'John',
          salary: '5000',
          age: '30',
          profileImage: '',
        ),
        Employee(
          id: 2,
          name: 'Jane',
          salary: '6000',
          age: '25',
          profileImage: '',
        ),
      ]);
      await tester.pumpWidget(createWidgetWithRepository());
      await tester.runAsync(() async {
        await Future.delayed(Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('John'), findsOneWidget);
      expect(find.text('Jane'), findsOneWidget);
      expect(find.text('Age: 30'), findsOneWidget);
      expect(find.text('Age: 25'), findsOneWidget);
    });

    testWidgets('tapping employee navigates to details', (
      WidgetTester tester,
    ) async {
      stubApi.setEmployees([
        Employee(
          id: 1,
          name: 'John',
          salary: '5000',
          age: '30',
          profileImage: '',
        ),
      ]);
      await tester.pumpWidget(createWidgetWithRepository());
      await tester.runAsync(() async {
        await Future.delayed(Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('John'));
      await tester.pumpAndSettle();
      expect(find.text('Employee Details'), findsOneWidget);
    });
  });

  group('EmployeeListScreen navigation', () {
    testWidgets('FAB opens create form', (WidgetTester tester) async {
      stubApi.setEmployees([]);
      await tester.pumpWidget(createWidgetWithRepository());
      await tester.runAsync(() async {
        await Future.delayed(Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('New Employee'), findsOneWidget);
    });
  });
}
