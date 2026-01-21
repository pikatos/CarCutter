import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'employee_repository.dart';
import 'employee_model.dart';
import 'employee_details_screen.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  Future<List<Employee>>? _employeesFuture;

  @override
  void initState() {
    super.initState();
    _employeesFuture = _fetchEmployees();
  }

  Future<List<Employee>> _fetchEmployees() {
    final repository = context.read<EmployeeRepository>();
    return repository.fetchEmployees();
  }

  void _refresh() {
    setState(() {
      _employeesFuture = _fetchEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [Expanded(child: _buildBody())]),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Employee>>(
      future: _employeesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          );
        }

        final employees = snapshot.data ?? [];

        if (employees.isEmpty) {
          return const Center(child: Text('No employees found'));
        }

        return ListView.builder(
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return ListTile(
              leading: CircleAvatar(child: Text(employee.name[0])),
              title: Text(employee.name),
              subtitle: Text('Age: ${employee.age}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(employee),
              ),
              onTap: () => _navigateToDetails(employee),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEmployee(employee.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmployee(int id) async {
    try {
      final repository = context.read<EmployeeRepository>();
      await repository.deleteEmployee(id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  void _navigateToDetails(Employee employee) async {
    final result = await Navigator.push<Employee>(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailsScreen(employee: employee),
      ),
    );
    if (result != null) {
      _refresh();
    }
  }

  void _navigateToCreate() async {
    final result = await Navigator.push<Employee>(
      context,
      MaterialPageRoute(builder: (context) => const EmployeeFormScreen()),
    );
    if (result != null) {
      _refresh();
    }
  }
}
