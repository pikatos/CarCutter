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
      profileImage: '',
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
