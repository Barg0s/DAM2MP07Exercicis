import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart';
class Arxius {
  bool _fileLoading = false;
  String _loadedFilePath = '';
  String _jsonContent = '';

  bool get isLoading => _fileLoading;
  String get loadedFilePath => _loadedFilePath;
  String get jsonContent => _jsonContent;

  Future<String> getDefaultDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }


  String getPath(){
    return loadedFilePath;
  }
  Future<void> loadFile(String path) async {
    _fileLoading = true;
    try {
      final file = File(path);
      if (kDebugMode) print("Intentando leer archivo desde: ${file.path}");

      if (await file.exists()) {
        _jsonContent = await file.readAsString();
        _loadedFilePath = path;
      } else {
        _jsonContent = '{}';
        if (kDebugMode) print("El archivo no existe");
      }
    } catch (e) {
      if (kDebugMode) print("Error leyendo archivo: $e");
    } finally {
      _fileLoading = false;
    }
  }

  Future<void> loadFileWithPicker() async {
    try {
      String defaultDirectory = await getDefaultDirectoryPath();
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        initialDirectory: defaultDirectory,
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        String? filePath = result.files.single.path;
        if (filePath != null) await loadFile(filePath);
      }
    } catch (e) {
      if (kDebugMode) print("Error seleccionando archivo: $e");
    }
  }
    Future<void> loadSSH() async {
    try {
      String defaultDirectory = await getDefaultDirectoryPath();
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        initialDirectory: defaultDirectory,
        type: FileType.custom,
        allowedExtensions: ['pub','pem'],
      );

      if (result != null) {
        String? filePath = result.files.single.path;
        if (filePath != null) await loadFile(filePath);
      }
    } catch (e) {
      if (kDebugMode) print("Error seleccionando archivo: $e");
    }
  }
}


