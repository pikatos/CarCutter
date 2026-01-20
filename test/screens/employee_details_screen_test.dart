import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carcutter/features/employees/employee_api.dart';
import 'package:carcutter/features/employees/employee_details_screen.dart';
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
  Future<void> deleteEmployee(int id) async {
    if (_nextException != null) throw _nextException!;
  }
}

void main() {
  late StubEmployeeApi stubApi;

  setUp(() {
    stubApi = StubEmployeeApi();
  });

  Widget createDetailsWidget(Employee employee) {
    final repository = EmployeeRepository(api: stubApi);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EmployeeRepository>.value(value: repository),
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
