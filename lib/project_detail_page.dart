import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'project_data.dart';
import 'database_helper.dart';

class ProjectDetailPage extends StatelessWidget {
  final int projectId;

  ProjectDetailPage({Key? key, required this.projectId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Project Details')
      ),
      backgroundColor: Colors.grey[300],
      body: FutureBuilder<Project>(
        future: Provider.of<ProjectData>(context, listen: false).getProjectById(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading project data'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('Project not found'));
          } else {
            final project = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _projectName(project),
                  SizedBox(height: 3),
                  _buildOriginalImageSection(project),
                  SizedBox(height: 3),
                  _buildProcessedImageSection(project),
                  SizedBox(height: 3),
                  _buildProcessedDataSection(project),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _projectName(Project project) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 0.0),
            child: Text(
              '${project.name}',
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 5.0),
            child: Text(
                'Creation Date: ${DateFormat.yMMMd().format(
                    project.creationDate)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalImageSection(Project project) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(5.0, 3.0, 0.0, 0.0),
              child: const Text(
                "Original Image",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              )),
          Container(
            margin: EdgeInsets.all(5.0),
            child: project.imagePath != null
                ? Image.file(File(project.imagePath!),
                height: 200, fit: BoxFit.cover)
                : Text('No Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedImageSection(Project project) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(5.0, 3.0, 0.0, 0.0),
              child: const Text(
                "Processed Image",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              )),
          Container(
            margin: EdgeInsets.all(5.0),
            child: project.processedImageUrl != null
                ? Image.network(project.processedImageUrl!,
                height: 200, fit: BoxFit.cover)
                : Text('No Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedDataSection(Project project) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Mean R Values: ${project.meanR?.toStringAsFixed(2) ?? 'N/A'}',
              style: TextStyle(fontSize: 20),),
            SizedBox(height: 3),
            Text('Mean G Values: ${project.meanG?.toStringAsFixed(2) ?? 'N/A'}',
              style: TextStyle(fontSize: 20),),
            SizedBox(height: 3),
            Text('Mean B Values: ${project.meanB?.toStringAsFixed(2) ?? 'N/A'}',
              style: TextStyle(fontSize: 20),),
            SizedBox(height: 3),
            Text('Green Pixel Count: ${project.greenPixelCount?.toString() ??
                'N/A'}', style: TextStyle(fontSize: 20),),
          ],
        ),
      ),
    );
  }
}
