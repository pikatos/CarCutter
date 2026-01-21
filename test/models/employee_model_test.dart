import 'package:flutter_test/flutter_test.dart';
import 'package:carcutter/features/employees/employee_model.dart';

void main() {
  group('Employee.fromListJson', () {
    test('parses full employee data', () {
      final json = {
        'id': 1,
        'employee_name': 'John',
        'employee_salary': '5000',
        'employee_age': '30',
        'profile_image': 'http://example.com/image.jpg',
      };
      final employee = Employee.fromListJson(json);
      expect(employee.id, 1);
      expect(employee.name, 'John');
      expect(employee.salary, '5000');
      expect(employee.age, '30');
      expect(employee.profileImage, 'http://example.com/image.jpg');
    });

    test('parses employee with empty profile image', () {
      final json = {
        'id': 2,
        'employee_name': 'Jane',
        'employee_salary': '6000',
        'employee_age': '25',
        'profile_image': '',
      };
      final employee = Employee.fromListJson(json);
      expect(employee.id, 2);
      expect(employee.name, 'Jane');
      expect(employee.profileImage, '');
    });
  });

  group('Employee.fromJson', () {
    test('parses create/update response format', () {
      final json = {'id': 1, 'name': 'John', 'salary': '5000', 'age': '30'};
      final employee = Employee.fromJson(json);
      expect(employee.id, 1);
      expect(employee.name, 'John');
      expect(employee.salary, '5000');
      expect(employee.age, '30');
      expect(employee.profileImage, '');
    });

    test('parses with injected ID from update response', () {
      final json = {'id': 42, 'name': 'Updated', 'salary': '7000', 'age': '35'};
      final employee = Employee.fromJson(json);
      expect(employee.id, 42);
      expect(employee.name, 'Updated');
    });
  });

  group('Employee.toJson', () {
    test('converts to API format', () {
      final employee = Employee(
        id: 1,
        name: 'John',
        salary: '5000',
        age: '30',
        profileImage: 'http://example.com/image.jpg',
      );
      final json = employee.toJson();
      expect(json['id'], 1);
      expect(json['employee_name'], 'John');
      expect(json['employee_salary'], '5000');
      expect(json['employee_age'], '30');
      expect(json['profile_image'], 'http://example.com/image.jpg');
    });

    test('roundtrip serialization preserves data', () {
      final original = Employee(
        id: 1,
        name: 'John',
        salary: '5000',
        age: '30',
        profileImage: 'http://example.com/image.jpg',
      );
      final json = original.toJson();
      final restored = Employee.fromListJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.salary, original.salary);
      expect(restored.age, original.age);
      expect(restored.profileImage, original.profileImage);
    });
  });

  group('EmployeeResponse.fromJson', () {
    test('parses empty list response', () {
      final json = {
        'status': 'success',
        'data': [],
        'message': 'Successfully!',
      };
      final response = EmployeeResponse.fromJson(json, Employee.fromListJson);
      expect(response.status, 'success');
      expect(response.data, isEmpty);
      expect(response.message, 'Successfully!');
    });

    test('parses single item as list', () {
      final json = {
        'status': 'success',
        'data': {
          'id': 1,
          'employee_name': 'John',
          'employee_salary': '5000',
          'employee_age': '30',
          'profile_image': '',
        },
        'message': 'Successfully!',
      };
      final response = EmployeeResponse.fromJson(json, Employee.fromListJson);
      expect(response.data, hasLength(1));
      expect(response.data![0].name, 'John');
    });

    test('parses list of items', () {
      final json = {
        'status': 'success',
        'data': [
          {
            'id': 1,
            'employee_name': 'John',
            'employee_salary': '5000',
            'employee_age': '30',
            'profile_image': '',
          },
          {
            'id': 2,
            'employee_name': 'Jane',
            'employee_salary': '6000',
            'employee_age': '25',
            'profile_image': '',
          },
        ],
        'message': 'Successfully!',
      };
      final response = EmployeeResponse.fromJson(json, Employee.fromListJson);
      expect(response.data, hasLength(2));
      expect(response.data![0].name, 'John');
      expect(response.data![1].name, 'Jane');
    });

    test('parses create response with fromJson decoder', () {
      final json = {
        'status': 'success',
        'data': {
          'id': 1,
          'name': 'New Employee',
          'salary': '4000',
          'age': '22',
        },
        'message': 'Successfully!',
      };
      final response = EmployeeResponse.fromJson(json, Employee.fromJson);
      expect(response.data, hasLength(1));
      expect(response.data![0].name, 'New Employee');
      expect(response.data![0].salary, '4000');
    });
  });
}
