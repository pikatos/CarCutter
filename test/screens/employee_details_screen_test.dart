import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carcutter/features/employees/employee_api.dart';
import 'package:carcutter/features/employees/employee_details_screen.dart';
import 'package:carcutter/features/employees/employee_list_state.dart';
import 'package:carcutter/features/employees/employee_local_storage.dart';
import 'package:carcutter/features/employees/employee_model.dart';
import 'package:carcutter/features/employees/employee_repository.dart';

class StubEmployeeApi implements EmployeeApiInterface {
  EmployeeResponse? _nextResponse;
  Exception? _nextException;

  void setResponse(EmployeeResponse response) {
    _nextResponse = response;
    _nextException = null;
  }

  void setException(Exception exception) {
    _nextException = exception;
  }

  @override
  Future<EmployeeResponse> getAllEmployees() async {
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }

  @override
  Future<EmployeeResponse> getEmployee(int id) async {
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }

  @override
  Future<EmployeeResponse> createEmployee({
    required String name,
    required String salary,
    required String age,
  }) async {
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }

  @override
  Future<EmployeeResponse> updateEmployee(Employee employee) async {
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }

  @override
  Future<EmployeeResponse> deleteEmployee(int id) async {
    if (_nextException != null) throw _nextException!;
    return _nextResponse!;
  }
}

class StubLocalStorage extends EmployeeLocalStorage {
  List<Employee> _employees = [];
  int _nextLocalId = -1;

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

  Widget createDetailsWidget(Employee employee) {
    final repository = EmployeeRepository(
      api: stubApi,
      localStorage: stubStorage,
    );
    final listKey = GlobalKey<AnimatedListState>();
    return MultiProvider(
      providers: [
        Provider<EmployeeRepository>.value(value: repository),
        ChangeNotifierProvider(
          create: (_) =>
              EmployeeListState(repository: repository, listKey: listKey),
        ),
      ],
      child: MaterialApp(home: EmployeeDetailsScreen(employee: employee)),
    );
  }

  group('EmployeeDetailsScreen', () {
    final testEmployee = Employee(
      id: 1,
      name: 'John',
      salary: '5000',
      age: '30',
      profileImage: '',
    );

    testWidgets('displays employee details', (WidgetTester tester) async {
      await tester.pumpWidget(createDetailsWidget(testEmployee));
      expect(find.text('Employee Details'), findsOneWidget);
      expect(find.text('John'), findsOneWidget);
      expect(find.text('\$5000'), findsOneWidget);
      expect(find.text('30 years'), findsOneWidget);
    });

    testWidgets('shows employee initial in avatar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDetailsWidget(testEmployee));
      final avatar = find.byType(CircleAvatar).first;
      expect(avatar, findsOneWidget);
    });

    testWidgets('edit FAB opens form', (WidgetTester tester) async {
      await tester.pumpWidget(createDetailsWidget(testEmployee));
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      expect(find.text('Edit Employee'), findsOneWidget);
      expect(find.text('John'), findsOneWidget);
    });

    testWidgets('has edit FAB', (WidgetTester tester) async {
      await tester.pumpWidget(createDetailsWidget(testEmployee));
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('displays employee name in details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDetailsWidget(testEmployee));
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('John'), findsOneWidget);
    });

    testWidgets('displays employee salary in details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDetailsWidget(testEmployee));
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('\$5000'), findsOneWidget);
    });

    testWidgets('displays employee age in details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createDetailsWidget(testEmployee));
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('30 years'), findsOneWidget);
    });
  });
}
