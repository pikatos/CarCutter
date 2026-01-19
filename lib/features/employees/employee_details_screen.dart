import 'package:flutter/material.dart';
import 'employee_model.dart';
import 'employee_form_screen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  late Employee _employee;
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeFormScreen(employee: _employee),
      ),
    );
    if (result is Employee && mounted) {
      setState(() {
        _employee = result;
        _hasUpdated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasUpdated && result == null) {
          Navigator.of(context).pop(_employee);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Employee Details')),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToEdit,
          child: const Icon(Icons.edit),
        ),
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
                    _employee.name[0],
                    style: const TextStyle(fontSize: 40, color: Colors.white),
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
