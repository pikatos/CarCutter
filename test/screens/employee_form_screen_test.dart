import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carcutter/features/employees/employee_form_screen.dart';
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
    final employee = Employee(
      id: 1,
      name: name,
      salary: salary,
      age: age,
      profileImage: '',
    );
    return EmployeeResponse(status: 'success', data: [employee], message: 'OK');
  }

  @override
  Future<EmployeeResponse> updateEmployee(Employee employee) async {
    if (_nextException != null) throw _nextException!;
    return EmployeeResponse(status: 'success', data: [employee], message: 'OK');
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

  Widget createFormWidget({Employee? employee}) {
    final repository = EmployeeRepository(api: stubApi);
    return MultiProvider(
      providers: [Provider<EmployeeRepository>.value(value: repository)],
      child: MaterialApp(home: EmployeeFormScreen(employee: employee)),
    );
  }

  group('EmployeeFormScreen create mode', () {
    testWidgets('shows New Employee title', (WidgetTester tester) async {
      await tester.pumpWidget(createFormWidget());
      expect(find.text('New Employee'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('shows Update button when editing', (
      WidgetTester tester,
    ) async {
      final employee = Employee(
        id: 1,
        name: 'John',
        salary: '5000',
        age: '30',
        profileImage: '',
      );
      await tester.pumpWidget(createFormWidget(employee: employee));
      await tester.pump();
      expect(find.text('Edit Employee'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('pre-fills form with employee data in edit mode', (
      WidgetTester tester,
    ) async {
      final employee = Employee(
        id: 1,
        name: 'John',
        salary: '5000',
        age: '30',
        profileImage: '',
      );
      await tester.pumpWidget(createFormWidget(employee: employee));
      await tester.pump();
      expect(find.text('John'), findsOneWidget);
      expect(find.text('5000'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('form shows validation errors', (WidgetTester tester) async {
      await tester.pumpWidget(createFormWidget());
      await tester.tap(find.text('Create'));
      await tester.pump();
      expect(find.text('Please enter a name'), findsOneWidget);
    });
  });

  group('EmployeeFormScreen with API responses', () {
    testWidgets('successful create navigates back', (
      WidgetTester tester,
    ) async {
      stubApi.setResponse(
        EmployeeResponse(
          status: 'success',
          data: [
            Employee(
              id: 1,
              name: 'John',
              salary: '5000',
              age: '30',
              profileImage: '',
            ),
          ],
          message: 'OK',
        ),
      );
      await tester.pumpWidget(createFormWidget());
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), 'John');
      await tester.enterText(find.byType(TextField).at(1), '5000');
      await tester.enterText(find.byType(TextField).at(2), '30');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsNothing);
    });

    testWidgets('shows error snackbar on failure', (WidgetTester tester) async {
      stubApi.setException(Exception('Create Failed'));
      await tester.pumpWidget(createFormWidget());
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), 'John');
      await tester.enterText(find.byType(TextField).at(1), '5000');
      await tester.enterText(find.byType(TextField).at(2), '30');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(
        find.text('Failed to save: Exception: Create Failed'),
        findsOneWidget,
      );
    });
  });
}
