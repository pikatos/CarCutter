import 'package:flutter/material.dart';
import 'employee_repository.dart';
import 'employee_model.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _salaryController = TextEditingController();
  final _ageController = TextEditingController();
  final EmployeeRepository _repository = EmployeeRepository();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _salaryController.text = widget.employee!.salary;
      _ageController.text = widget.employee!.age;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (widget.employee != null) {
          final updatedEmployee = Employee(
            id: widget.employee!.id,
            name: _nameController.text,
            salary: _salaryController.text,
            age: _ageController.text,
            profileImage: widget.employee!.profileImage,
          );
          final result = await _repository.updateEmployee(updatedEmployee);
          if (mounted) {
            Navigator.pop(context, result);
          }
        } else {
          final result = await _repository.createEmployee(
            name: _nameController.text,
            salary: _salaryController.text,
            age: _ageController.text,
          );
          if (mounted) {
            Navigator.pop(context, result);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Employee' : 'New Employee')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a salary';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEmployee,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(isEditing ? 'Update' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
