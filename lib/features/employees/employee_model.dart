class Employee {
  final int id;
  final String name;
  final String salary;
  final String age;
  final String profileImage;

  Employee({
    required this.id,
    required this.name,
    required this.salary,
    required this.age,
    required this.profileImage,
  });

  factory Employee.fromListJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      name: json['employee_name'] as String,
      salary: json['employee_salary'] as String,
      age: json['employee_age'] as String,
      profileImage: json['profile_image'] as String,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      name: json['name'] as String,
      salary: json['salary'] as String,
      age: json['age'] as String,
      profileImage: json['profile_image'] as String? ?? '',
    );
  }

  factory Employee.fromLocalJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      name: json['employee_name'] as String,
      salary: json['employee_salary'] as String,
      age: json['employee_age'] as String,
      profileImage: json['profile_image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_name': name,
      'employee_salary': salary,
      'employee_age': age,
      'profile_image': profileImage,
    };
  }
}

class EmployeeResponse {
  final String status;
  final List<Employee> data;
  final String message;

  EmployeeResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory EmployeeResponse.fromJson(
    Map<String, dynamic> json,
    Employee Function(Map<String, dynamic>) decodeEmployee,
  ) {
    final data = json['data'];
    final employees = (data is List ? data : [data])
        .map((e) => decodeEmployee(e as Map<String, dynamic>))
        .toList();

    return EmployeeResponse(
      status: json['status'] as String,
      data: employees,
      message: json['message'] as String,
    );
  }
}

enum SyncOperationType { create, update, delete }

class SyncOperation {
  final SyncOperationType type;
  final Employee employee;
  final DateTime timestamp;

  SyncOperation.create({required this.employee})
    : type = SyncOperationType.create,
      timestamp = DateTime.now();

  SyncOperation.update({required this.employee})
    : type = SyncOperationType.update,
      timestamp = DateTime.now();

  SyncOperation.delete({required this.employee})
    : type = SyncOperationType.delete,
      timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'employee': employee.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    final type = SyncOperationType.values[json['type'] as int];
    switch (type) {
      case SyncOperationType.create:
        return SyncOperation.create(
          employee: Employee.fromLocalJson(
            json['employee'] as Map<String, dynamic>,
          ),
        );
      case SyncOperationType.update:
        return SyncOperation.update(
          employee: Employee.fromLocalJson(
            json['employee'] as Map<String, dynamic>,
          ),
        );
      case SyncOperationType.delete:
        return SyncOperation.delete(
          employee: Employee.fromLocalJson(
            json['employee'] as Map<String, dynamic>,
          ),
        );
    }
  }
}
