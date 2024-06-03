import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'my_page.dart';
import 'project_data.dart';

class ProjectCreationStep4 extends StatefulWidget {
  final Project project;
  final String? imagePath;
  final Function onComplete;

  const ProjectCreationStep4({
    Key? key,
    required this.project,
    this.imagePath,
    required this.onComplete,
  }) : super(key: key);

  @override
  _ProjectCreationStep4State createState() => _ProjectCreationStep4State();
}

class _ProjectCreationStep4State extends State<ProjectCreationStep4> {
  bool _isLoading = false;
  bool _isButtonDisabled = false;

  void uploadImage() async {
    if (widget.imagePath == null) return;

    setState(() {
      _isLoading = true;
      _isButtonDisabled = true;
    });

    // 준비된 JSON 데이터
    var linesJsonData = jsonEncode({
      'lines': widget.project.linesData,
    });

    // 터미널에 JSON 데이터 출력
    print('Uploading JSON data: $linesJsonData');
    print('Uploading JSON data: ${widget.project.knownDistance}');

    Uri uri = Uri.parse('http://10.32.36.214:8080/upload');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', widget.imagePath!))
      ..fields['line_data'] = linesJsonData // 좌표 데이터
      ..fields['knownDistance'] = widget.project.knownDistance ?? ""; // 거리값 보정 매개변수

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await http.Response.fromStream(response);
      var data = jsonDecode(responseBody.body);
      String? processedImageUrl = data['processed_image_url'];
      if (processedImageUrl != null) {
        // Processed 이미지 다운로드 및 로컬 저장소에 저장
        await _downloadAndSaveImage(processedImageUrl);
      }
      setState(() {
        _isLoading = false;
        widget.project.meanR = double.tryParse(data['mean_R'].toString());
        widget.project.meanG = double.tryParse(data['mean_G'].toString());
        widget.project.meanB = double.tryParse(data['mean_B'].toString());
        widget.project.greenPixelCount = double.tryParse(data['green_pixel_count'].toString());
        widget.project.distances = List<double>.from(data['distances'].map((x) => x.toDouble()));
      });
    } else {
      setState(() {
        _isLoading = false;
        _isButtonDisabled = false;
        print('Server error: ${response.statusCode}');
      });
    }
  }

  Future<void> _downloadAndSaveImage(String url) async {
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Directory appDir = await getApplicationDocumentsDirectory();
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
        File file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          widget.project.processedImageUrl = file.path;
        });
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
  }

  void saveProjectAndGoToMyPage() async {
    await Provider.of<ProjectData>(context, listen: false).addProject(widget.project);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => MyPage()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Processing'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: saveProjectAndGoToMyPage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: _isButtonDisabled ? null : uploadImage,
                child: Text('Upload Image to Server'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonDisabled ? Colors.grey : Colors.blue,
                ),
              ),
            ),
            if (widget.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Center(
                  child: Image.file(
                    File(widget.imagePath!),
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (_isLoading) CircularProgressIndicator() else Container(),
            if (widget.project.processedImageUrl != null)
              Center(
                child: Image.file(
                  File(widget.project.processedImageUrl!),
                  height: 500,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 20),
            buildColorMetricsTable(),
            SizedBox(height: 20),
            cameraSensorWidthTable(),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: buildCoordinatesTable(),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildColorMetricsTable() {
    return DataTable(
      columnSpacing: 20,
      columns: [
        DataColumn(
          label: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Value', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
      rows: [
        DataRow(cells: [
          DataCell(Text('Mean R')),
          DataCell(Text('${widget.project.meanR?.toStringAsFixed(2) ?? 'N/A'}'))
        ]),
        DataRow(cells: [
          DataCell(Text('Mean G')),
          DataCell(Text('${widget.project.meanG?.toStringAsFixed(2) ?? 'N/A'}'))
        ]),
        DataRow(cells: [
          DataCell(Text('Mean B')),
          DataCell(Text('${widget.project.meanB?.toStringAsFixed(2) ?? 'N/A'}'))
        ]),
        DataRow(cells: [
          DataCell(Text('Green Pixel Count')),
          DataCell(Text('${widget.project.greenPixelCount?.toString() ?? 'N/A'}'))
        ]),
      ],
    );
  }

  Widget cameraSensorWidthTable() {
    return DataTable(
      columnSpacing: 20,
      columns: [
        DataColumn(
          label: Text('CameraSensorWidth', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
      rows: [
        DataRow(cells: [
          DataCell(Text('${widget.project.knownDistance?.toString() ?? 'N/A'}')),
        ]),
      ],
    );
  }

  Widget buildCoordinatesTable() {
    return DataTable(
      columnSpacing: 38,
      columns: [
        DataColumn(
          label: Expanded(
            child: Text(
              'Line Number',
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              'Start Point',
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              'End Point',
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataColumn(
          label: Expanded(
            child: Text(
              'Distances (mm)',
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
      rows: widget.project.linesData.asMap().entries.map<DataRow>((entry) {
        var lineData = entry.value;
        var index = entry.key;
        var distanceDisplay = widget.project.distances != null && index < widget.project.distances!.length
            ? widget.project.distances![index].toStringAsFixed(2)
            : 'N/A';
        return DataRow(cells: [
          DataCell(Text('Line ${lineData['lineNumber']}')),
          DataCell(Text(
            '(${lineData['start']['x'].toStringAsFixed(2)}, ${lineData['start']['y'].toStringAsFixed(2)})',
          )),
          DataCell(Text(
            '(${lineData['end']['x'].toStringAsFixed(2)}, ${lineData['end']['y'].toStringAsFixed(2)})',
          )),
          DataCell(Text(distanceDisplay)),
        ]);
      }).toList(),
    );
  }
}
