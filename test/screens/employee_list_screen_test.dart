import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carcutter/features/employees/employee_api.dart';
import 'package:carcutter/features/employees/employee_list_screen.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_repository.dart';
import 'package:carcutter/features/employees/offline_status_provider.dart';

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
  Future<void> deleteEmployee(int id) async {
    if (_exception != null) throw _exception!;
    _employees.removeWhere((e) => e.id == id);
  }
}

class StubLocalStorage extends EmployeeLocalStorage {
  List<Employee> _employees = [];
  final List<SyncOperation> _operations = [];

  void setEmployees(List<Employee> employees) {
    _employees = List.from(employees);
  }

  @override
  Future<List<Employee>> getAllEmployees() async {
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
  Future<void> updateEmployee(Employee employee) async {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _employees[index] = employee;
    }
  }

  @override
  Future<void> deleteEmployee(int id) async {
    _employees.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<SyncOperation>> loadPendingOperations() async {
    return List.from(_operations);
  }

  @override
  Future<void> addSyncOperation(SyncOperation operation) async {
    _operations.add(operation);
  }

  @override
  Future<void> clearPendingOperations() async {
    _operations.clear();
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
    final offlineStatus = OfflineStatus();
    final repository = EmployeeRepository(
      api: stubApi,
      localStorage: stubStorage,
      offlineStatus: offlineStatus,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EmployeeRepository>.value(value: repository),
        ChangeNotifierProvider<OfflineStatus>.value(value: offlineStatus),
      ],
      child: const MaterialApp(home: EmployeeListScreen()),
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
      await tester.pumpAndSettle();
      expect(find.text('No employees found'), findsOneWidget);
    });

    testWidgets('shows offline state on exception', (
      WidgetTester tester,
    ) async {
      stubApi.setException(Exception('Network Error'));
      await tester.pumpWidget(createWidgetWithRepository());
      await tester.pumpAndSettle();
      expect(find.text('No employees found'), findsOneWidget);
      expect(
        find.text('Offline - changes will sync when connected'),
        findsOneWidget,
      );
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
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('John'));
      await tester.pumpAndSettle();
      expect(find.text('Employee Details'), findsOneWidget);
    });

    testWidgets('delete icon removes employee', (WidgetTester tester) async {
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
      await tester.pumpAndSettle();
      expect(find.text('John'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(find.text('Delete Employee'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('No employees found'), findsOneWidget);
    });
  });

  group('EmployeeListScreen navigation', () {
    testWidgets('FAB opens create form', (WidgetTester tester) async {
      stubApi.setEmployees([]);
      await tester.pumpWidget(createWidgetWithRepository());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('New Employee'), findsOneWidget);
    });
  });
}
