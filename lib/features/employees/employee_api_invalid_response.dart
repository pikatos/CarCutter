import 'package:carcutter/features/employees/employee_model.dart';

class EmployeeApiInvalidResponse implements Exception {
  final EmployeeResponse response;

  EmployeeApiInvalidResponse(this.response);

  @override
  String toString() => 'EmployeeApiInvalidResponse: ${response.message}';
}
