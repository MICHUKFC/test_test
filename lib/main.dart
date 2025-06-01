import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';


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
    // Mamy dostęp do `photo.raw` jako Map<String, dynamic>
    final raw = photo.raw;

    // Wyciągamy poszczególne pola (zabezpieczamy, jeśli pola mogłyby być nieobecne):
    final videoUrl = raw['videoUrl'] as String?;
    final metadata = raw['metadata'] as Map<String, dynamic>?;
    final tags = (raw['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final comments = (raw['comments'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final exif = raw['exif'] as Map<String, dynamic>?;
    final location = raw['location'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: Text(photo.title)),
      body: Column(
        children: [
          // PEŁNE zdjęcie na górze:
          Hero(
            tag: 'photo_${photo.id}',
            child: CachedNetworkImage(
              imageUrl: photo.url,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Icon(Icons.error),
            ),
          ),
          const SizedBox(height: 12),

          // Cała zawartość w pojedynczym scrollowalnym widoku:
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // ---------- 1) Sekcja wideo  ----------
                if (videoUrl != null && videoUrl.isNotEmpty)
                  ExpansionTile(
                    leading: const Icon(Icons.videocam),
                    title: const Text('Wideo'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            // Można tu np. otworzyć zewnętrzny odtwarzacz wideo.
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Otwieram wideo: $videoUrl')),
                            );
                          },
                          child: Text(
                            videoUrl,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                // ---------- 2) Sekcja Metadata ----------
                if (metadata != null)
                  ExpansionTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Metadata'),
                    children: [
                      if (metadata['author'] != null)
                        ListTile(
                          title: const Text('Autor'),
                          subtitle: Text(metadata['author'].toString()),
                        ),
                      if (metadata['likes'] != null)
                        ListTile(
                          title: const Text('Liczba polubień'),
                          subtitle: Text(metadata['likes'].toString()),
                        ),
                      if (metadata['camera'] != null && metadata['camera'] is Map)
                        ExpansionTile(
                          leading: const Icon(Icons.camera),
                          title: const Text('Dane aparatu'),
                          children: [
                            ListTile(
                              title: const Text('Make'),
                              subtitle: Text(
                                (metadata['camera'] as Map<String, dynamic>)['make']?.toString() ?? '-',
                              ),
                            ),
                            ListTile(
                              title: const Text('Model'),
                              subtitle: Text(
                                (metadata['camera'] as Map<String, dynamic>)['model']?.toString() ?? '-',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                // ---------- 3) Sekcja Tags  ----------
                if (tags.isNotEmpty)
                  ExpansionTile(
                    leading: const Icon(Icons.label),
                    title: const Text('Tagi'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Wrap(
                          spacing: 8,
                          children: tags.map((tag) {
                            return Chip(label: Text(tag));
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                // ---------- 4) Sekcja Comments ----------
                if (comments.isNotEmpty)
                  ExpansionTile(
                    leading: const Icon(Icons.comment),
                    title: const Text('Komentarze'),
                    children: comments.map((commentMap) {
                      final user = commentMap['user']?.toString() ?? 'Anonim';
                      final text = commentMap['text']?.toString() ?? '';
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user),
                        subtitle: Text(text),
                      );
                    }).toList(),
                  ),

                // ---------- 5) Sekcja Exif ----------
                if (exif != null)
                  ExpansionTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Dane Exif'),
                    children: [
                      if (exif['aperture'] != null)
                        ListTile(
                          title: const Text('Przysłona'),
                          subtitle: Text(exif['aperture'].toString()),
                        ),
                      if (exif['exposureTime'] != null)
                        ListTile(
                          title: const Text('Czas naświetlania'),
                          subtitle: Text(exif['exposureTime'].toString()),
                        ),
                      if (exif['iso'] != null)
                        ListTile(
                          title: const Text('ISO'),
                          subtitle: Text(exif['iso'].toString()),
                        ),
                    ],
                  ),

                // ---------- 6) Sekcja Location ----------
                if (location != null)
                  ExpansionTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Lokalizacja'),
                    children: [
                      ListTile(
                        title: const Text('Szerokość geograficzna'),
                        subtitle: Text(location['lat']?.toString() ?? '-'),
                      ),
                      ListTile(
                        title: const Text('Długość geograficzna'),
                        subtitle: Text(location['lng']?.toString() ?? '-'),
                      ),
                    ],
                  ),

                // ---------- 7) Surowy JSON (opcjonalnie) ----------
                ExpansionTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Surowy JSON'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        const JsonEncoder.withIndent('  ').convert(raw),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
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
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static const _cacheKey = 'gallery_cache'; // zmieniona nazwa, bo cache’ujemy całą galerię

  /// Pobiera pełne dane JSON z serwera lub z cache’a.
  /// Zwraca listę obiektów Photo.
  static Future<List<Photo>> fetchPhotos() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Spróbuj wczytać cały JSON z cache’a
    final cachedJson = prefs.getString(_cacheKey);
    Map<String, dynamic>? fullJsonMap;
    if (cachedJson != null) {
      try {
        fullJsonMap = jsonDecode(cachedJson) as Map<String, dynamic>;
      } catch (_) {
        fullJsonMap = null;
      }
    }

    if (fullJsonMap == null) {
      // 2) Cache jest pusty lub niepoprawny – pobierz z sieci
      final uri = Uri.parse('$_baseUrl/gallery');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Status ${response.statusCode}');
      }

      // Zakładam, że endpoint zwraca JSON w postaci: { "gallery": [ ... ] }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('gallery')) {
        fullJsonMap = decoded;
      } else if (decoded is List) {
        // Jeśli endpoint od razu zwraca tablicę zamiast obiektu z kluczem "gallery",
        // opakowujemy ją w mapę, żeby zachować spójną strukturę:
        fullJsonMap = {'gallery': decoded};
      } else {
        throw Exception('Nieoczekiwana struktura JSON: $decoded');
      }

      // 3) Cache’ujemy CAŁY obiekt JSON jako String
      await prefs.setString(_cacheKey, jsonEncode(fullJsonMap));
    }

    // 4) Z mapy pełnego JSON-a wyciągamy tablicę "gallery":
    final dynamic galleryField = fullJsonMap['gallery'];
    if (galleryField is! List) {
      throw Exception('Pole "gallery" nie jest tablicą');
    }
    final photosList = galleryField as List<dynamic>;

    // 5) Budujemy listę obiektów Photo, przekazując im również surową mapę:
    return photosList.map((e) {
      if (e is Map<String, dynamic>) {
        return Photo.fromJson(e);
      } else {
        throw Exception('Element listy nie jest Mapą JSON');
      }
    }).toList();
  }

  /// (Opcjonalnie) Funkcja pomocnicza, żeby wyczyścić cache:
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
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
    futurePhotos = ApiService.fetchPhotos();

    futurePhotos.then((photos) {
      // Dla każdego photo wywołujemy precacheImage.
      // To sprawi, że Flutter pobierze pełny plik JPEG i umieści go w ImageCache (pamięć RAM).
      for (var photo in photos) {
        precacheImage(
          CachedNetworkImageProvider(photo.url),
          context,
        );
      }
    }).catchError((e) {
      debugPrint('Błąd w prefetch: $e');
    });
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
            crossAxisCount: 4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
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
                      // Miniaturka i tak pobierze thumbnailUrl
                      imageUrl: photo.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, _) => Container(color: Colors.grey[300]),
                      errorWidget: (ctx, _, __) => const Icon(Icons.error),
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
}


