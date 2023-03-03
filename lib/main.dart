import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Arrhythmia Predictor',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _fileName;
  String _responseText = '';
  late PlatformFile csvFile;

  Future<void> _openFilePicker() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = result.files.first;
      setState(() {
        _fileName = file.name;
        _responseText = '';
        csvFile = file;
      });
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    print(file);
    const url = 'https://c706-35-188-82-2.ngrok.io/predict';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    final fileBytes = file.bytes!;
    final fileField = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: file.name,
    );
    request.files.add(fileField);

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseStream = await response.stream.bytesToString();
        final responseData = await jsonDecode(responseStream);

        setState(() {
          _responseText = responseData['arrhythmia class'].toString();
          _fileName = file.name;
        });
      } else {
        setState(() {
          _responseText =
              'Error: HTTP ${response.statusCode}: ${response.reasonPhrase}';
          _fileName = "Wrong file uploaded";
        });
      }
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
        _fileName = "Please check your server connection";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrhythmia Predictor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_fileName == null)
              const Text('No file selected.')
            else
              Column(
                children: [
                  const Text(
                    'File Name:',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    _fileName!,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _uploadFile(csvFile);
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Predict'),
                  ),
                  Text(
                    _responseText,
                    style: TextStyle(
                      fontSize: 16,
                      color: _responseText.startsWith('Error')
                          ? Colors.red
                          : Colors.black,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFilePicker,
        tooltip: 'Upload file',
        child: const Icon(Icons.upload),
      ),
    );
  }
}
