import 'package:flutter/material.dart';
import 'employee_model.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple,
                child: Text(
                  employee.employeeName[0],
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailTile(
              icon: Icons.badge,
              label: 'Name',
              value: employee.employeeName,
            ),
            _buildDetailTile(
              icon: Icons.attach_money,
              label: 'Salary',
              value: '\$${employee.employeeSalary}',
            ),
            _buildDetailTile(
              icon: Icons.cake,
              label: 'Age',
              value: '${employee.employeeAge} years',
            ),
            if (employee.profileImage.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Profile Image',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Image.network(employee.profileImage),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(value, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
