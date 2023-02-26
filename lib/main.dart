import 'dart:convert';
import 'dart:typed_data';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'File Upload Example',
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
  String _responseText = '';

  Future<void> _openFilePicker() async {
    final input = FileUploadInputElement();
    input.multiple = true; // Allow user to select multiple files
    input.click();

    await input.onChange.first;
    final files = input.files!;
    if (files.isNotEmpty) {
      _uploadFile(files.first); // Upload the first selected file
    }
  }

  Future<void> _uploadFile(File file) async {
    const url = 'http://d825-35-231-54-111.ngrok.io/predict';
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

    final response = await request.send();
    final responseStream = await response.stream.bytesToString();
    final responseData = jsonDecode(responseStream);

    setState(() {
      _responseText = responseData.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Upload Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _openFilePicker,
              child: const Text('Select File'),
            ),
            const SizedBox(height: 16),
            Text(_responseText),
          ],
        ),
      ),
    );
  }
}