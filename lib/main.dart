import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database_helper.dart';
import 'my_page.dart';
import 'project_data.dart';

void main() {
  final databaseHelper = DatabaseHelper();
  runApp(MyApp(databaseHelper: databaseHelper));
}

class MyApp extends StatelessWidget {
  final DatabaseHelper databaseHelper;
  MyApp({required this.databaseHelper});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProjectData(databaseHelper: databaseHelper),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'G-VISION',
        theme: ThemeData(
          useMaterial3: false,
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff4CAF50)),
        ),
        home: MyPage(),
      ),
    );
  }
}