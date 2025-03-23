import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'fileDisplayScreen.dart';

class ScanScreen extends StatefulWidget {
  @override
  State<ScanScreen> createState() => _ScanScreen();
}

class _ScanScreen extends State<ScanScreen> {
  String folderPath = "";
  String folderName = ""; // Store folder name after first entry
  XFile? _image;
  String recognizedText = "";
  final TextEditingController _folderNameController = TextEditingController();

  // Function to pick an image
  Future<void> getImage(bool isCamera) async {
    XFile? image;
    if (isCamera) {
      image = await ImagePicker().pickImage(source: ImageSource.camera);
    } else {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    }

    if (image != null) {
      setState(() {
        _image = image;
      });

      // If folder name is already set, save directly, otherwise ask for a folder name
      if (folderName.isEmpty) {
        _showFolderNameDialog(image);
      } else {
        _createFolderAndSaveImage(image);
      }
    }
  }

  // Function to create folder and save image
  Future<void> _createFolderAndSaveImage(XFile image) async {
    try {
      if (folderName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a folder name')),
        );
        return;
      }

      // Get external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) return;

      folderPath = '${directory.path}/$folderName';

      // Create the folder if it doesn't exist
      final folder = Directory(folderPath);
      if (!(await folder.exists())) {
        await folder.create(recursive: true);
        debugPrint("Folder created at: $folderPath");
      }

      // Save the image in the folder
      String filePath =
          '$folderPath/${DateTime.now().millisecondsSinceEpoch}.png';
      await File(image.path).copy(filePath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image saved to $filePath')));

      // Perform text recognition
      _recognizeText(filePath);
    } catch (e) {
      debugPrint('Error creating folder or saving image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save image')));
    }
  }

  // Function to recognize text using ML Kit
  Future<void> _recognizeText(String imagePath) async {
    try {
      debugPrint("Starting text recognition on: $imagePath");
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedTextResult =
          await textRecognizer.processImage(inputImage);

      setState(() {
        recognizedText = recognizedTextResult.text;
      });

      textRecognizer.close();
      debugPrint("Recognized Text: $recognizedText");
    } catch (e) {
      debugPrint("Error during text recognition: $e");
    }
  }

  // Function to show dialog to get folder name
  void _showFolderNameDialog(XFile image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Folder Name'),
        content: TextField(
          controller: _folderNameController,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                folderName = _folderNameController.text;
              });

              Navigator.of(context).pop();
              _createFolderAndSaveImage(image); // Create folder & save image
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cancel action
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Study Buddy"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Button to capture from camera
            IconButton(
              onPressed: () => getImage(true),
              icon: const Icon(Icons.camera_alt_rounded, size: 100),
            ),
            const SizedBox(height: 20),
            // Button to select from gallery
            IconButton(
              onPressed: () => getImage(false),
              icon: const Icon(Icons.image, size: 100),
            ),
            const SizedBox(height: 20),
            // Recognized text display
            if (recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Extracted Text: \n$recognizedText",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 96, 123, 255),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FileDisplayScreen(folderPath: folderPath),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 20),
                  const Text("NEXT", style: TextStyle(color: Colors.white)),
                  const Icon(Icons.arrow_circle_right_rounded, color: Colors.white),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
