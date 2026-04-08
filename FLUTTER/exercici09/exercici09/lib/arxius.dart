  import 'dart:io';
  import 'package:file_picker/file_picker.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:flutter/foundation.dart';
  import 'package:encrypt/encrypt.dart';
  import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:encrypt/encrypt.dart' as enc;

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
        Future<void> loadPublicKey() async {
      try {
        String defaultDirectory = await getDefaultDirectoryPath();
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          initialDirectory: defaultDirectory,
          type: FileType.custom,
          allowedExtensions: ['rsa'],
        );

        if (result != null) {
          String? filePath = result.files.single.path;
          if (filePath != null) await loadFile(filePath);
        }
      } catch (e) {
        if (kDebugMode) print("Error seleccionando archivo: $e");
      }
    }

Future<void> encriptarArxiu(String clauPublicaPath, String arxiuPath) async {
  try {
    final fileBytes = await File(arxiuPath).readAsBytes();

    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = IV.fromSecureRandom(12);

    final encrypter = Encrypter(AES(aesKey, mode: AESMode.gcm));
    final encryptedData = encrypter.encryptBytes(fileBytes, iv: iv);

    final publicKeyPem = await File(clauPublicaPath).readAsString();

    final parser = RSAKeyParser();
    final RSAPublicKey publicKey = parser.parse(publicKeyPem) as RSAPublicKey;

    final cipher = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    final encryptedKey = cipher.process(aesKey.bytes);

    final basePath = arxiuPath;

    await File("$basePath.enc").writeAsBytes(encryptedData.bytes);
    await File("$basePath.key").writeAsBytes(encryptedKey);
    await File("$basePath.iv")
        .writeAsString(base64Encode(iv.bytes));

    if (kDebugMode) print("Xifrat");

  } catch (e) {
    if (kDebugMode) print("$e");
  }
}

  }


