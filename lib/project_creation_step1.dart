import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'project_data.dart';

int _projectIdCounter = 0;

class ProjectCreationStep1 extends StatefulWidget {
  final Function(Project project) onNext;

  ProjectCreationStep1({Key? key, required this.onNext}) : super(key: key);

  @override
  _ProjectCreationStep1State createState() => _ProjectCreationStep1State();
}

class _ProjectCreationStep1State extends State<ProjectCreationStep1> {
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _navigateStep2() {
    // Check if the project name is entered
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the project name.')),
      );
      return;
    }

    // Create Project object
    Project newProject = Project(
      id: (++_projectIdCounter).toInt(),
      name: _nameController.text,
      creationDate: _selectedDate,
    );

    // Navigate to the next step
    widget.onNext(newProject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Step 1 - Project Naming')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Project Name'),
              ),
              ListTile(
                title: Text('Creation Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
              ElevatedButton(
                onPressed: _navigateStep2,
                child: Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
