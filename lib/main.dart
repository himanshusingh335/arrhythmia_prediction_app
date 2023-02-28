import 'dart:convert';
import 'dart:typed_data';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Arrhythmia Predictor',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _fileName;
  String _responseText = '';

  Future<void> _openFilePicker() async {
    final input = FileUploadInputElement();
    input.multiple = true; // Allow user to select multiple files
    input.click();

    await input.onChange.first;
    final files = input.files!;
    if (files.isNotEmpty) {
      await _uploadFile(files.first); // Upload the first selected file
    }
  }

  Future<void> _uploadFile(File file) async {
    const url = 'http://c586-34-86-120-168.ngrok.io/predict';
    final request = http.MultipartRequest('POST', Uri.parse(url));

    final reader = FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final fileBytes = reader.result as Uint8List;
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
      print(e);
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
