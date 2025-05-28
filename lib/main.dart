import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';



void main() {
  runApp(const MyApp());
}

/// Główny widget aplikacji.
/// Ustawia MaterialApp i uruchamia [MyHomePage] jako stronę startową.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter JSON Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

/// Model danych reprezentujący pojedynczy obiekt pobierany z API.
class Photo {
  final int id;
  final String title;
  final String url;
  final String thumbnailUrl;

  /// Trzymamy też surowe dane, żeby je później wyświetlić
  final Map<String, dynamic> raw;

  Photo({
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
    required this.raw,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    // parsujemy to co było
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : int.tryParse(rawId.toString()) ?? 0;

    return Photo(
      id: id,
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      raw: json,  // zachowujemy całą mapę
    );
  }
}

class PhotoDetailPage extends StatelessWidget {
  final Photo photo;
  const PhotoDetailPage({Key? key, required this.photo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Zamieniamy surowe dane Map<String,dynamic> na ładnie wcięty JSON
    final prettyJson = const JsonEncoder.withIndent('  ')
        .convert(photo.raw);

    return Scaffold(
      appBar: AppBar(title: Text(photo.title)),
      body: Column(
        children: [
          // 1) Obrazek – pełne zdjęcie
          Hero(
            tag: 'photo_${photo.id}',            // ten sam tag co wyżej
            child: CachedNetworkImage(
              imageUrl: photo.url,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Icon(Icons.error),
            ),
          ),
          const SizedBox(height: 12),

          // 2) Cały JSON w przewijanym widoku
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: SelectableText(
                  prettyJson,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Klasa serwisowa obsługująca pobieranie danych z API oraz cache w SharedPreferences.
class ApiService {
  static String get _baseUrl {
    if (kIsWeb) {
      // Flutter Web – działa w przeglądarce
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // Android emulator
      return 'http://10.0.2.2:3000';
    } else if (Platform.isIOS) {
      // iOS simulator / urządzenie
      return 'http://localhost:3000';
    } else {
      // Desktop albo inne
      return 'http://localhost:3000';
    }
  }
  static const _cacheKey  = 'photos_cache';

  /// Pobiera listę Photo:
  /// - najpierw próbuje z cache’u
  /// - jeśli nie ma cache’u, GET /gallery → wyciąga gallery.photos → zapisuje do cache’u
  static Future<List<Photo>> fetchPhotos() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) try cache
    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson != null) {
      final List<dynamic> decoded = jsonDecode(cachedJson);
      return decoded.map((e) => Photo.fromJson(e)).toList();
    }

    // 2) fetch z sieci
    final uri      = Uri.parse('$_baseUrl/gallery');      // albo '/gallery/photos'
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Status ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);

    // 3) wyciągamy tablicę photos niezależnie od struktury
    late final List<dynamic> photosList;
    if (decoded is Map<String, dynamic> && decoded.containsKey('gallery')) {
      final gallery = decoded['gallery'];
      if (gallery is Map<String, dynamic> && gallery['photos'] is List) {
        photosList = gallery['photos'] as List<dynamic>;
      } else {
        throw Exception('Brak pola "gallery.photos" w odpowiedzi');
      }
    } else if (decoded is List) {
      // jeśli endpoint od razu zwraca tablicę
      photosList = decoded;
    } else {
      throw Exception('Nieoczekiwana struktura JSON:\n$decoded');
    }

    // 4) cache’ujemy listę zdjęć i zwracamy model
    await prefs.setString(_cacheKey, jsonEncode(photosList));
    return photosList.map((e) {
      if (e is Map<String, dynamic>) {
        return Photo.fromJson(e);
      } else {
        throw Exception('Element listy nie jest Mapą JSON');
      }
    }).toList();
  }

}

/// Ekran główny aplikacji – wyświetla listę obiektów Photo pobranych z API lub z cache.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Photo>> futurePhotos;

  @override
  void initState() {
    super.initState();
    // Wywołujemy pobranie/keszeowanie danych w momencie startu ekranu.
    futurePhotos = ApiService.fetchPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masonry Gallery')),
      body: FutureBuilder<List<Photo>>(
        future: futurePhotos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }
          final photos = snapshot.data!;
          return MasonryGridView.count(
            padding: const EdgeInsets.all(4),
            crossAxisCount: 4,         // 4 kolumny „w szerokości”
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              // wysokość kafelka zależna od indexu (możesz podłożyć własne wartości)
              final tileHeight = (index % 5 + 1) * 100.0;

              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PhotoDetailPage(photo: photo),
                  ),
                ),
                child: Hero(
                  tag: 'photo_${photo.id}',
                  child: Container(
                    height: tileHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: CachedNetworkImage(
                      imageUrl: photo.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Funkcja pomocnicza – otwiera okno dialogowe ze szczegółami wybranego obiektu.
  void _showDetailsDialog(Photo photo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Photo ID: ${photo.id}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Większy obraz
                Image.network(photo.url),
                const SizedBox(height: 8),
                Text(
                  photo.title,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Zamknięcie dialogu
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
