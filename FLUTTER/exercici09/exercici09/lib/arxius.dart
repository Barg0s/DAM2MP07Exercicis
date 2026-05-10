import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/api.dart';

class Arxius {
  String _loadedFilePath = '';

  String getPath() => _loadedFilePath;

  Future<void> loadFileWithPicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      _loadedFilePath = result.files.single.path!;
    }
  }

  Future<void> loadPublicKey() async => await loadFileWithPicker();

  Future<void> encriptarArxiu(String clauPublicaPath, String arxiuPath) async {
    try {
      final fileContent = await File(arxiuPath).readAsString();
      final publicKeyPem = await File(clauPublicaPath).readAsString();
      final parser = enc.RSAKeyParser();
      final publicKey = parser.parse(publicKeyPem) as RSAPublicKey;
      final encriptador = enc.Encrypter(enc.RSA(publicKey: publicKey));
      final encrypted = encriptador.encrypt(fileContent);
      await File('$arxiuPath.enc').writeAsBytes(encrypted.bytes);

      if (kDebugMode) print("✔ Encriptado con RSA directo");
    } catch (e) {
      if (kDebugMode) print("❌ Error: RSA directo tiene un límite de caracteres muy pequeño. $e");
    }
  }

  Future<void> desencriptarArxiu(
    String clauPrivadaPath,
    String arxiuEncPath,
    String keyPath,
    String ivPath,
    String outputPath,
  ) async {
    try {
      final privateKeyPem = await File(clauPrivadaPath).readAsString();
      final parser = enc.RSAKeyParser();
      final RSAPrivateKey privateKey = parser.parse(privateKeyPem) as RSAPrivateKey;

      final rsa = PKCS1Encoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      final encryptedKey = await File(keyPath).readAsBytes();
      final aesKeyBytes = rsa.process(encryptedKey);
      final aesKey = enc.Key(aesKeyBytes);

      final ivString = await File(ivPath).readAsString();
      final iv = enc.IV.fromBase64(ivString);

      final encryptedBytes = await File(arxiuEncPath).readAsBytes();
      final encryptedData = enc.Encrypted(encryptedBytes);

      final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.gcm));
      
      final decryptedBytes = encrypter.decryptBytes(encryptedData, iv: iv);

      await File(outputPath).writeAsBytes(decryptedBytes);

      if (kDebugMode) print("✔ Desencriptado correctamente en: $outputPath");
    } catch (e) {
      if (kDebugMode) print("❌ Error decrypt: $e");
    }
  }
}