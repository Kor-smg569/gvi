import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;

import 'project_data.dart';
import 'project_detail_page.dart';
import 'my_page.dart';

class SharePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int _currentIndex = 1; // SharePage에서 시작할 때 인덱스 설정

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Projects',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        elevation: 0.0,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _showShareModal(context),
          ),
        ],
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

  void _showShareModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShareModal();
      },
    );
  }

  void _deleteSharedProject(BuildContext context, int index) {
    final projectData = Provider.of<ProjectData>(context, listen: false);
    final project = projectData.sharedProjects[index];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Project'),
          content: Text('Are you sure you want to delete ${project.name}?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                projectData.removeSharedProject(project.id!); // 공유된 프로젝트 삭제 메소드 호출
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopupMenuButton(BuildContext context, int index) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        if (value == 'delete') {
          _deleteSharedProject(context, index);
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Project'),
            ),
          ),
        ];
      },
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
              _buildPopupMenuButton(context, index),
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

class ShareModal extends StatefulWidget {
  @override
  _ShareModalState createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  bool _csvSelected = false;
  bool _pdfSelected = false;

  void _onCheckboxChanged(int checkboxIndex, bool? value) {
    setState(() {
      if (checkboxIndex == 1) {
        _csvSelected = value ?? false;
        if (_csvSelected) _pdfSelected = false;
      } else if (checkboxIndex == 2) {
        _pdfSelected = value ?? false;
        if (_pdfSelected) _csvSelected = false;
      }
    });
  }

  void _onSharePressed(BuildContext context) async {
    if (!_csvSelected && !_pdfSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one option'),
        ),
      );
    } else {
      if (_csvSelected) {
        await _shareProjectsAsCSV(context);
      }
      if (_pdfSelected) {
        await _shareProjectsAsPDF(context);
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _shareProjectsAsCSV(BuildContext context) async {
    final projectData = Provider.of<ProjectData>(context, listen: false);
    final projects = projectData.sharedProjects;

    String csvData = _generateCSV(projects);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/shared_projects.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(path)],
      text: 'Shared Projects',
    );
  }

  String _generateCSV(List<Project> projects) {
    List<List<String>> rows = [
      [
        'ID',
        'Name',
        'Creation Date',
        'Image Path',
        'Mean R',
        'Mean G',
        'Mean B',
        'Green Pixel Count',
        'Processed Image URL',
        'Lines Data',
        'Distances',
      ]
    ];

    for (var project in projects) {
      rows.add([
        project.id.toString(),
        project.name,
        DateFormat.yMMMd().format(project.creationDate),
        project.imagePath ?? '',
        project.meanR?.toString() ?? '',
        project.meanG?.toString() ?? '',
        project.meanB?.toString() ?? '',
        project.greenPixelCount?.toString() ?? '',
        project.processedImageUrl ?? '',
        jsonEncode(project.linesData),
        jsonEncode(project.distances),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<void> _shareProjectsAsPDF(BuildContext context) async {
    final projectData = Provider.of<ProjectData>(context, listen: false);
    final projects = projectData.sharedProjects;

    final pdf = pw.Document();
    for (var project in projects) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(project.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 10),
                pw.Text('Creation Date: ${DateFormat.yMMMd().format(project.creationDate)}', textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 10),
                pw.Text('Original Image:', textAlign: pw.TextAlign.center),
                project.imagePath != null
                    ? pw.Image(pw.MemoryImage(File(project.imagePath!).readAsBytesSync()), width: 200, height: 150, fit: pw.BoxFit.cover)
                    : pw.Text('No Image', textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 10),
                pw.Text('Processed Image:', textAlign: pw.TextAlign.center),
                project.processedImageUrl != null
                    ? pw.Image(pw.MemoryImage(File(project.processedImageUrl!).readAsBytesSync()), width: 200, height: 150, fit: pw.BoxFit.cover)
                    : pw.Text('No Image', textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    _buildTableRow('Mean R', project.meanR?.toStringAsFixed(10) ?? 'N/A'),
                    _buildTableRow('Mean G', project.meanG?.toStringAsFixed(10) ?? 'N/A'),
                    _buildTableRow('Mean B', project.meanB?.toStringAsFixed(10) ?? 'N/A'),
                    _buildTableRow('Green Pixel Count', project.greenPixelCount?.toString() ?? 'N/A'),
                    _buildTableRow('Lines Data', _formatLinesData(project.linesData)),
                    _buildTableRow('Distances', project.distances?.join(', ') ?? 'N/A'),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/shared_projects.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    // PDF 공유
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Shared Projects',
    );
  }

  pw.TableRow _buildTableRow(String key, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4.0),
          child: pw.Text(key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4.0),
          child: pw.Text(value, textAlign: pw.TextAlign.center),
        ),
      ],
    );
  }

  String _formatLinesData(List<Map<String, dynamic>> linesData) {
    if (linesData.isEmpty) return 'N/A';
    return linesData
        .map((line) => 'Start: (${line['start']['x']}, ${line['start']['y']}), End: (${line['end']['x']}, ${line['end']['y']})')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share Project'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Checkbox(
                value: _csvSelected,
                onChanged: (bool? value) {
                  _onCheckboxChanged(1, value);
                },
              ),
              Text('Project to CSV'),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _pdfSelected,
                onChanged: (bool? value) {
                  _onCheckboxChanged(2, value);
                },
              ),
              Text('Project to PDF'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Share'),
          onPressed: () => _onSharePressed(context),
        ),
        TextButton(
          child: Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
