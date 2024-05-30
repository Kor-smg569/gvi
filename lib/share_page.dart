import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'project_data.dart';
import 'project_detail_page.dart';
import 'my_page.dart';

class SharePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int _currentIndex = 1; // SharePage에서 시작할 때 인덱스 설정

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Projects'),
      ),
      backgroundColor: Colors.grey[300],
      body: Consumer<ProjectData>(
        builder: (context, projectData, child) {
          return ListView.builder(
            itemCount: projectData.sharedProjects.length,
            itemBuilder: (context, index) {
              final project = projectData.sharedProjects[index];
              return _buildProjectCard(context, project, index);
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'Project List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.unarchive),
            label: 'Archive',
          ),
        ],
        selectedItemColor: Colors.green,
        onTap: (int index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyPage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project, int index) {
    return InkWell(
      onTap: () {
        if (project.id != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ProjectDetailPage(projectId: project.id!),
          ));
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          width: double.infinity,
          height: 120.0,
          alignment: Alignment.center,
          child: Row(
            children: [
              _buildImageContainer(project),
              _buildProjectInfo(project),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContainer(Project project) {
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.all(10.0),
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: Colors.grey[200],
      ),
      child: project.imagePath != null
          ? AspectRatio(
        aspectRatio: 1.0,
        child: Image.file(File(project.imagePath!), fit: BoxFit.cover),
      )
          : const SizedBox(),
    );
  }

  Widget _buildProjectInfo(Project project) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              project.name,
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Creation Date: ${DateFormat.yMMMd().format(project.creationDate)}',
            ),
          ],
        ),
      ),
    );
  }
}
