import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const String _historyKey = 'compression_history';
  static const String _showAnimationsKey = 'show_animations';
  static const String _saveHistoryKey = 'save_history';
  static const String _compressionQualityKey = 'compression_quality';
  static const String _outputDirectoryKey = 'output_directory';

  static final ValueNotifier<int> historyChangeNotifier = ValueNotifier<int>(0);
  
  static Future<bool> requestHistoryStoragePermission() async {
    if (Platform.isAndroid) {
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        return true;
      }

      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'showAnimations': prefs.getBool(_showAnimationsKey) ?? true,
      'saveHistory': prefs.getBool(_saveHistoryKey) ?? false,
      'compressionQuality': prefs.getString(_compressionQualityKey) ?? 'Medium',
      'outputDirectory': prefs.getString(_outputDirectoryKey),
    };
  }

  static Future<void> setShowAnimations(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAnimationsKey, value);
  }

  static Future<bool> getShowAnimations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showAnimationsKey) ?? true;
  }

  static Future<void> setSaveHistory(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_saveHistoryKey, value);
  }

  static Future<bool> getSaveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_saveHistoryKey) ?? false;
  }

  static Future<void> setCompressionQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_compressionQualityKey, quality);
  }

  static Future<String> getCompressionQuality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_compressionQualityKey) ?? 'Medium';
  }

  static Future<void> setOutputDirectory(String? directoryPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (directoryPath == null || directoryPath.trim().isEmpty) {
      await prefs.remove(_outputDirectoryKey);
      return;
    }

    final normalized = directoryPath.trim();
    final dir = Directory(normalized);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await prefs.setString(_outputDirectoryKey, normalized);
  }

  static Future<String> getOutputDirectoryPath() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_outputDirectoryKey);
    if (custom != null && custom.trim().isNotEmpty) {
      final customDir = Directory(custom.trim());
      if (!await customDir.exists()) {
        await customDir.create(recursive: true);
      }
      return customDir.path;
    }

    Directory defaultDir;
    if (Platform.isAndroid) {
      defaultDir = Directory('/storage/emulated/0/JPEG-Lite-Compressor');
      try {
        if (!await defaultDir.exists()) {
          await defaultDir.create(recursive: true);
        }
        return defaultDir.path;
      } catch (_) {
        final appDocDir = await getApplicationDocumentsDirectory();
        defaultDir = Directory('${appDocDir.path}/JPEG-Lite-Compressor');
      }
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      defaultDir = Directory('${appDocDir.path}/JPEG-Lite-Compressor');
    }

    if (!await defaultDir.exists()) {
      await defaultDir.create(recursive: true);
    }
    return defaultDir.path;
  }
  
  static Future<Map<String, Directory>> getAppDirectories() async {
    final String basePath = await getOutputDirectoryPath();
    final Directory jpegLiteDir = Directory(basePath);
    final Directory originalDir = Directory('${jpegLiteDir.path}/original');
    final Directory compressedDir = Directory('${jpegLiteDir.path}/compressed');

    if (!await jpegLiteDir.exists()) {
      await jpegLiteDir.create(recursive: true);
    }
    if (!await originalDir.exists()) {
      await originalDir.create(recursive: true);
    }
    if (!await compressedDir.exists()) {
      await compressedDir.create(recursive: true);
    }

    debugPrint('JPEG-Lite directories created at: ${jpegLiteDir.path}');

    return {
      'main': jpegLiteDir,
      'original': originalDir,
      'compressed': compressedDir,
    };
  }
  
  static String generateFilename() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    return 'IMG_${formatter.format(now)}.jpg';
  }
  
  static Future<String> copyOriginalImage(String sourcePath) async {
    try {
      final directories = await getAppDirectories();
      final originalDir = directories['original']!;
      final filename = generateFilename();
      final destinationPath = '${originalDir.path}/$filename';
      
      final sourceFile = File(sourcePath);
      
      if (!await sourceFile.exists()) {
        throw Exception('Source image not found: $sourcePath');
      }

      await sourceFile.copy(destinationPath);
      
      debugPrint('Image copied to: $destinationPath');
      
      return destinationPath;
    } catch (e) {
      debugPrint('Error copying image: $e');
      rethrow;
    }
  }
  
  static Future<String> saveCompressedImage(String originalPath, File compressedFile) async {
    final directories = await getAppDirectories();
    final compressedDir = directories['compressed']!;
    
    final filename = originalPath.split('/').last;
    final destinationPath = '${compressedDir.path}/$filename';
    
    await compressedFile.copy(destinationPath);
    
    debugPrint('Compressed image saved to: $destinationPath');
    
    return destinationPath;
  }
  
  static Future<void> saveCompressionRecord({
    required String originalPath,
    required String compressedPath,
    required int originalSize,
    required int compressedSize,
    required double compressionRatio,
  }) async {
    if (!await getSaveHistory()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);
    
    final record = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'originalPath': originalPath,
      'compressedPath': compressedPath,
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'compressionRatio': compressionRatio,
      'date': DateTime.now().toIso8601String(),
    };
    
    history.insert(0, record);
    await prefs.setString(_historyKey, jsonEncode(history));

    historyChangeNotifier.value++;
    debugPrint('Compression record saved to history');
  }

  static Future<List<Map<String, dynamic>>> loadCompressionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);
    
    return history.map((item) => Map<String, dynamic>.from(item)).toList();
  }
  
  static Future<void> deleteCompressionRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);
    
    Map<String, dynamic>? record;
    for (final item in history) {
      if (item is Map && item['id'] == id) {
        record = Map<String, dynamic>.from(item);
        break;
      }
    }

    if (record != null) {
      try {
        final originalFile = File(record['originalPath'] as String);
        final compressedFile = File(record['compressedPath'] as String);
        
        if (await originalFile.exists()) await originalFile.delete();
        if (await compressedFile.exists()) await compressedFile.delete();
      } catch (e) {
        debugPrint('Error deleting files: $e');
      }
    }
    
    history.removeWhere((item) => item['id'] == id);
    await prefs.setString(_historyKey, jsonEncode(history));
    historyChangeNotifier.value++;
  }

  static Future<void> clearCompressionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);

    for (final item in history) {
      if (item is Map) {
        final originalPath = item['originalPath'];
        final compressedPath = item['compressedPath'];
        if (originalPath is String) {
          final file = File(originalPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
        if (compressedPath is String) {
          final file = File(compressedPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    }

    await prefs.setString(_historyKey, '[]');
    historyChangeNotifier.value++;
  }

  static Future<int> getFileSize(String path) async {
    final file = File(path);
    return await file.length();
  }
}
