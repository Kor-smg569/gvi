import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'project_data.dart';

class ProjectDetailPage extends StatelessWidget {
  final int projectId;

  ProjectDetailPage({Key? key, required this.projectId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project Details'),
      ),
      backgroundColor: Colors.grey[300],
      body: FutureBuilder<Project>(
        future: Provider.of<ProjectData>(context, listen: false).getProjectById(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading project data: ${snapshot.error}'));
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
              project.name,
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 5.0),
            child: Text(
              'Creation Date: ${DateFormat.yMMMd().format(project.creationDate)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
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
            ),
          ),
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
            ),
          ),
          Container(
            margin: EdgeInsets.all(5.0),
            child: project.processedImageUrl != null
                ? Image.file(File(project.processedImageUrl!),
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
        child: DataTable(
          dataRowHeight: 80,
          columns: const [
            DataColumn(
              label: Text(
                'Metric',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Value',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: [
            DataRow(cells: [
              DataCell(Text('Mean R Values')),
              DataCell(Text(project.meanR?.toStringAsFixed(10) ?? 'N/A')),
            ]),
            DataRow(cells: [
              DataCell(Text('Mean G Values')),
              DataCell(Text(project.meanG?.toStringAsFixed(10) ?? 'N/A')),
            ]),
            DataRow(cells: [
              DataCell(Text('Mean B Values')),
              DataCell(Text(project.meanB?.toStringAsFixed(10) ?? 'N/A')),
            ]),
            DataRow(cells: [
              DataCell(Text('Green Pixel Count')),
              DataCell(Text(project.greenPixelCount?.toString() ?? 'N/A')),
            ]),
            DataRow(cells: [
              DataCell(Text('Lines Data')),
              DataCell(Text(_formatLinesData(project.linesData))),
            ]),
            DataRow(cells: [
              DataCell(Text('Distances')),
              DataCell(Text(project.distances?.join(', ') ?? 'N/A')),
            ]),
          ],
        ),
      ),
    );
  }

  String _formatLinesData(List<Map<String, dynamic>> linesData) {
    if (linesData.isEmpty) return 'N/A';
    return linesData
        .map((line) => 'Start: (${line['start']['x']}, ${line['start']['y']}), \n End: (${line['end']['x']}, ${line['end']['y']})')
        .join('\n');
  }
}
