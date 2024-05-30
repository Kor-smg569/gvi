import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class ProjectDB {
  int? id;
  String name;
  DateTime creationDate;
  String? imagePath;
  double? meanR;
  double? meanG;
  double? meanB;
  double? greenPixelCount;
  String? processedImageUrl;
  List<Map<String, dynamic>> linesData = [];
  List<double>? distances;
  String? knownDistance;

  ProjectDB({
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
      'knownDistance': knownDistance,
    };
  }

  static ProjectDB fromMap(Map<String, dynamic> map) {
    return ProjectDB(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
      creationDate: DateTime.parse(map['date']),
      meanR: map['meanR'],
      meanG: map['meanG'],
      meanB: map['meanB'],
      greenPixelCount: map['greenPixelCount'],
      processedImageUrl: map['processedImageUrl'],
      linesData: (map['linesData'] != null && map['linesData'] is String)
          ? (jsonDecode(map['linesData']!) as List?)
                  ?.map((item) => Map<String, dynamic>.from(item))
                  .toList() ??
              []
          : [],
      distances: (map['distances'] != null && map['distances'] is String)
          ? (jsonDecode(map['distances']!) as List?)
              ?.map((d) => double.parse(d.toString()))
              .toList()
          : [],
      knownDistance: map['knownDistance'],
    );
  }
}

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'projectdb.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE projectsdb(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            imagePath TEXT,
            date TEXT,
            meanR REAL,
            meanG REAL,
            meanB REAL,
            greenPixelCount REAL,
            processedImageUrl TEXT,
            linesData TEXT,
            distances TEXT,
            knownDistance TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS projectsdb'); // 기존 테이블 삭제
          await db.execute('''
            CREATE TABLE projectsdb(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              imagePath TEXT,
              date TEXT,
              meanR REAL,
              meanG REAL,
              meanB REAL,
              greenPixelCount REAL,
              processedImageUrl TEXT
              linesData TEXT,
              distances TEXT,
              knownDistance TEXT
            )
          '''); // 테이블 재생성
        }
      },
    );
  }

  Future<int> insertProjectDB(ProjectDB projectdb) async {
    Database db = await database;
    return await db.insert('projectsdb', projectdb.toMap());
  }

  Future<List<ProjectDB>> getProjectsDB() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('projectsdb');
    return maps.map((map) => ProjectDB.fromMap(map)).toList();
  }

  Future<void> updateProjectDB(ProjectDB projectdb) async {
    Database db = await database;
    await db.update(
      'projectsdb',
      projectdb.toMap(),
      where: 'id = ?',
      whereArgs: [projectdb.id],
    );
  }

  Future<void> deleteProjectDB(int id) async {
    Database db = await database;
    await db.delete(
      'projectsdb',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ProjectDB> getProjectById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'projectsdb',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ProjectDB.fromMap(maps.first);
    } else {
      throw Exception('Project not found');
    }
  }
}
