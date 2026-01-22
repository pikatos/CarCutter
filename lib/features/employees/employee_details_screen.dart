import 'dart:async';
import 'package:carcutter/features/employees/employee_list_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'employee_repository.dart';
import 'employee_model.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  late Employee _employee;
  StreamSubscription<EmployeeChange>? _changesSubscription;

  void _subscribeToChanges() {
    final repository = context.read<EmployeeRepository>();
    _changesSubscription = repository.changes.listen(
      (change) {
        if (change is EmployeeChangeUpdated &&
            change.employee.id == _employee.id) {
          if (mounted) {
            setState(() => _employee = change.employee);
          }
        }
      },
      onError: (e) {
        // Handle error silently or show UI feedback
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Details')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.navigateToEditEmployee(_employee),
        child: const Icon(Icons.edit),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        _employee.name[0],
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailTile(
                    icon: Icons.badge,
                    label: 'Name',
                    value: _employee.name,
                  ),
                  _buildDetailTile(
                    icon: Icons.attach_money,
                    label: 'Salary',
                    value: '\$${_employee.salary}',
                  ),
                  _buildDetailTile(
                    icon: Icons.cake,
                    label: 'Age',
                    value: '${_employee.age} years',
                  ),
                  if (_employee.profileImage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Profile Image',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Image.network(_employee.profileImage),
                  ],
                ],
              ),
            ),
          ),
        ],
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
