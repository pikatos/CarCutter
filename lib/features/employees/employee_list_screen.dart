import 'package:flutter/material.dart';
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
  final EmployeeRepository _repository = EmployeeRepository();
  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final employees = await _repository.getAllEmployees();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEmployee(int id) async {
    try {
      await _repository.deleteEmployee(id);
      setState(() {
        _employees.removeWhere((e) => e.id == id);
      });
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
      setState(() {
        final index = _employees.indexWhere((e) => e.id == result.id);
        if (index != -1) {
          _employees[index] = result;
        }
      });
    } else {
      _fetchEmployees();
    }
  }

  void _navigateToCreate() async {
    final result = await Navigator.push<Employee>(
      context,
      MaterialPageRoute(builder: (context) => const EmployeeFormScreen()),
    );
    if (result != null) {
      setState(() {
        _employees.add(result);
      });
    } else {
      _fetchEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEmployees,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEmployees,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_employees.isEmpty) {
      return const Center(child: Text('No employees found'));
    }

    return ListView.builder(
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
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
}
