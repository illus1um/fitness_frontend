import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

/// Сервис для управления GIF файлами, которые хранятся на сервере
class GifService {
  // Делаем переменную изменяемой
  static String apiBasePath = '/static/assets/gifs'; // Путь на сервере, где хранятся GIF
  
  /// Получает URL для GIF-файла по его имени
  static String getGifUrl(String gifName) {
    // Если имя уже содержит полный URL, просто вернем его
    if (gifName.startsWith('http')) {
      return gifName;
    }
    
    // В противном случае формируем URL из базового URL API и имени файла
    return '${ApiService.baseUrl}$apiBasePath/$gifName';
  }
  
  /// Получает альтернативные пути к гифкам на сервере
  static List<String> getAlternativeGifUrls(String gifName) {
    // Если имя уже содержит полный URL, просто вернем его
    if (gifName.startsWith('http')) {
      return [gifName];
    }
    
    // Возвращаем разные варианты путей для проверки
    return [
      '${ApiService.baseUrl}/static/assets/gifs/$gifName', // Стандартный путь
      '${ApiService.baseUrl}/assets/gifs/$gifName',  // Без static
      '${ApiService.baseUrl}/gifs/$gifName',         // Прямой путь
      '${ApiService.baseUrl}/static/gifs/$gifName',  // Альтернативный путь
    ];
  }
  
  /// Проверяет доступность гифки на сервере
  static Future<bool> checkGifAvailability(String gifName) async {
    try {
      final urls = getAlternativeGifUrls(gifName);
      
      for (final url in urls) {
        try {
          final response = await http.head(Uri.parse(url));
          if (response.statusCode == 200) {
            print('GIF found at URL: $url');
            // Обновляем базовый путь, если найден работающий URL
            if (url.contains('/static/assets/gifs/')) {
              // Стандартный путь работает
            } else if (url.contains('/assets/gifs/')) {
              // Нужно обновить путь без /static
              apiBasePath = '/assets/gifs';
            } else if (url.contains('/static/gifs/')) {
              // Обновляем на альтернативный путь
              apiBasePath = '/static/gifs';
            } else if (url.contains('/gifs/')) {
              // Обновляем на прямой путь
              apiBasePath = '/gifs';
            }
            return true;
          }
        } catch (e) {
          // Пробуем следующий URL
          print('Failed to check URL: $url, error: $e');
        }
      }
      
      // Ни один URL не работает
      print('GIF not found on server: $gifName');
      return false;
    } catch (e) {
      print('Error checking GIF availability: $e');
      return false;
    }
  }
  
  /// Загружает и кэширует GIF, возвращает виджет для отображения
  static Widget loadNetworkGif({
    required String gifName,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool checkAvailability = false,
  }) {
    // Увеличиваем счетчик загрузок
    _incrementLoadCount(gifName);
    
    final url = getGifUrl(gifName);
    
    // Если нужно, проверим доступность гифки
    if (checkAvailability) {
      checkGifAvailability(gifName).then((available) {
        if (!available) {
          print('WARNING: GIF not available: $gifName');
        }
      });
    }
    
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? 
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC7A97F)),
            ),
          ),
      errorWidget: (context, url, error) {
        print('Error loading GIF from URL: $url, Error: $error');
        // Пробуем загрузить локальный ассет как запасной вариант
        try {
          final localAssetPath = 'assets/gifs/$gifName';
          return Image.asset(
            localAssetPath,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => 
              errorWidget ?? Icon(Icons.error, color: Colors.red),
          );
        } catch (e) {
          return errorWidget ?? Icon(Icons.error, color: Colors.red);
        }
      },
    );
  }
  
  // Храним статистику загрузок
  static final Map<String, int> _loadCounters = {};
  
  // Увеличиваем счетчик для гифки
  static void _incrementLoadCount(String gifName) {
    _loadCounters[gifName] = (_loadCounters[gifName] ?? 0) + 1;
  }
  
  /// Получает статистику по загруженным гифкам
  static Map<String, int> getLoadStatistics() {
    return Map.from(_loadCounters);
  }
  
  /// Сбрасывает статистику загрузок
  static void resetLoadStatistics() {
    _loadCounters.clear();
  }
  
  /// Предварительно загружает GIF в кэш для более быстрого доступа позже
  static Future<void> preloadGif(String gifName) async {
    final url = getGifUrl(gifName);
    await DefaultCacheManager().getSingleFile(url);
  }
  
  /// Предварительно загружает несколько GIF в кэш
  static Future<void> preloadGifs(List<String> gifNames) async {
    for (final gifName in gifNames) {
      await preloadGif(gifName);
    }
  }
  
  /// Очищает кэш GIF файлов
  static Future<void> clearCache() async {
    await DefaultCacheManager().emptyCache();
  }
  
  /// Очищает кэш и возвращает размер до и после очистки
  static Future<Map<String, String>> clearCacheAndGetStats() async {
    final beforeSize = await getFormattedCacheSize();
    await clearCache();
    
    // Даем время кэшу очиститься
    await Future.delayed(Duration(milliseconds: 500));
    
    final afterSize = await getFormattedCacheSize();
    return {
      'before': beforeSize,
      'after': afterSize,
    };
  }
  
  /// Получает размер кэша в байтах
  static Future<int> getCacheSize() async {
    try {
      // Получаем директорию кэша 
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');
      
      // Проверяем существование директории
      if (!await cacheDir.exists()) {
        // Если стандартное расположение кэша не найдено, попробуем использовать
        // другие возможные пути для кэша CachedNetworkImage
        try {
          // Проверим стандартные пути для кэша
          final possibleCacheDirs = [
            Directory('${tempDir.path}/cached_image_data'),
            Directory('${tempDir.path}/.image_cache'),
            Directory('${tempDir.path}/image_cache'),
          ];
          
          for (var dir in possibleCacheDirs) {
            if (await dir.exists()) {
              return _calculateDirSize(dir);
            }
          }
        } catch (e) {
          print('Error accessing alternative cache directories: $e');
        }
        return 0;
      }
      
      return _calculateDirSize(cacheDir);
    } catch (e) {
      print('Error calculating cache size: $e');
      return 0;
    }
  }
  
  /// Возвращает форматированный размер кэша в МБ
  static Future<String> getFormattedCacheSize() async {
    final sizeInBytes = await getCacheSize();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }
  
  /// Вспомогательный метод для расчета размера директории
  static Future<int> _calculateDirSize(Directory directory) async {
    int totalSize = 0;
    try {
      // Рекурсивно обходим все файлы
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            // Игнорируем ошибки для отдельных файлов
          }
        }
      }
    } catch (e) {
      print('Error during directory traversing: $e');
    }
    return totalSize;
  }
} 