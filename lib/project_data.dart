import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'dart:convert';

class Project {
  int? id;
  String name;
  String? imagePath;
  DateTime creationDate;
  double? meanR;
  double? meanG;
  double? meanB;
  double? greenPixelCount;
  String? processedImageUrl;
  List<Map<String, dynamic>> linesData = [];
  List<double>? distances;
  String? knownDistance;

  Project({
    this.id,
    required this.name,
    required this.creationDate,
    this.imagePath,
    this.meanR,
    this.meanG,
    this.meanB,
    this.greenPixelCount,
    this.processedImageUrl,
    this.linesData = const [],
    this.distances,
    this.knownDistance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'date': creationDate.toIso8601String(),
      'meanR': meanR,
      'meanG': meanG,
      'meanB': meanB,
      'greenPixelCount': greenPixelCount,
      'processedImageUrl': processedImageUrl,
      'linesData': jsonEncode(linesData),
      'distances': jsonEncode(distances),
    };
  }

  static Project fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
      creationDate: DateTime.parse(map['date']),
      meanR: map['meanR'],
      meanG: map['meanG'],
      meanB: map['meanB'],
      greenPixelCount: map['greenPixelCount'],
      processedImageUrl: map['processedImageUrl'],
      linesData: (jsonDecode(map['linesData']) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      distances: (jsonDecode(map['distances']) as List)
          .map((d) => double.parse(d.toString()))
          .toList(),
    );
  }
}

class ProjectData with ChangeNotifier {
  List<Project> _projects = [];
  List<Project> _sharedProjects = [];
  List<Project> get projects => _projects;
  List<Project> get sharedProjects => _sharedProjects;

  DatabaseHelper databaseHelper;

  ProjectData({required this.databaseHelper}) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    _projects = (await databaseHelper.getProjectsDB())
        .map((projectDB) => Project.fromMap(projectDB.toMap()))
        .toList();
    notifyListeners();
  }

  Future<void> addProject(Project project) async {
    int id = await databaseHelper.insertProjectDB(ProjectDB(
      name: project.name,
      creationDate: project.creationDate,
      imagePath: project.imagePath,
      meanR: project.meanR,
      meanG: project.meanG,
      meanB: project.meanB,
      greenPixelCount: project.greenPixelCount,
      processedImageUrl: project.processedImageUrl,
      linesData: project.linesData,
      distances: project.distances,
    ));
    project.id = id;
    _projects.add(project);
    notifyListeners();
  }

  Future<void> editProjectName(int index, String newName) async {
    if (index >= 0 && index < _projects.length) {
      _projects[index].name = newName;
      await databaseHelper.updateProjectDB(ProjectDB(
        id: _projects[index].id,
        name: _projects[index].name,
        creationDate: _projects[index].creationDate,
        imagePath: _projects[index].imagePath,
        meanR: _projects[index].meanR,
        meanG: _projects[index].meanG,
        meanB: _projects[index].meanB,
        greenPixelCount: _projects[index].greenPixelCount,
        processedImageUrl: _projects[index].processedImageUrl,
        linesData: _projects[index].linesData,
        distances: _projects[index].distances,
      ));
      notifyListeners();
    }
  }

  Future<void> deleteProject(int index) async {
    if (index >= 0 && index < _projects.length) {
      int id = _projects[index].id!;
      _projects.removeAt(index);
      await databaseHelper.deleteProjectDB(id);
      notifyListeners();
    }
  }

  Future<void> updateProjectWithProcessingResults(int projectId,
      {double? meanR, double? meanG, double? meanB, double? greenPixelCount, String? processedImageUrl, List<double>? distances}) async {
    var project = _projects.firstWhere((project) => project.id == projectId);
    project.meanR = meanR;
    project.meanG = meanG;
    project.meanB = meanB;
    project.greenPixelCount = greenPixelCount;
    project.processedImageUrl = processedImageUrl;
    project.distances = distances;

    await databaseHelper.updateProjectDB(ProjectDB(
      id: project.id,
      name: project.name,
      creationDate: project.creationDate,
      imagePath: project.imagePath,
      meanR: project.meanR,
      meanG: project.meanG,
      meanB: project.meanB,
      greenPixelCount: project.greenPixelCount,
      processedImageUrl: project.processedImageUrl,
      linesData: project.linesData,
      distances: project.distances,
    ));

    notifyListeners();
  }

  Future<Project> getProjectById(int id) async {
    var projectDB = await databaseHelper.getProjectById(id);
    return Project.fromMap(projectDB.toMap());
  }

  void shareProject(int index) {
    if (index >= 0 && index < _projects.length) {
      Project project = _projects[index];
      _sharedProjects.add(Project(
        id: project.id,
        name: project.name,
        creationDate: project.creationDate,
        imagePath: project.imagePath,
        meanR: project.meanR,
        meanG: project.meanG,
        meanB: project.meanB,
        greenPixelCount: project.greenPixelCount,
        processedImageUrl: project.processedImageUrl,
        linesData: List<Map<String, dynamic>>.from(project.linesData),
        distances: List<double>.from(project.distances ?? []),
      ));
      notifyListeners();
    }
  }
}
