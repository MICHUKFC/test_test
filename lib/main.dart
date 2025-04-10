import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
/// Przykładowo korzystamy z JSONPlaceholder (zdjęcia).
class Photo {
  final int id;
  final String title;
  final String url;           // pełny adres zdjęcia
  final String thumbnailUrl;  // miniaturka zdjęcia

  Photo({
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
  });

  // Fabryczna metoda do tworzenia obiektu z mapy JSON
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      title: json['title'],
      url: json['url'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}

/// Klasa serwisowa obsługująca pobieranie danych z API oraz cache w SharedPreferences.
class ApiService {
  // Stała z kluczem zapisu w SharedPreferences
  static const String _cacheKey = 'photos_cache';

  /// Metoda pobierająca listę obiektów Photo. Jeśli są zapisane
  /// w SharedPreferences, wczyta je najpierw. Jeśli nie ma zapisu
  /// lokalnego lub chcemy odświeżyć dane, pobieramy z internetu.
  static Future<List<Photo>> fetchPhotos() async {
    // 1. Odczyt z SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);

    // 2. Jeśli mamy dane w cache, możemy je zwrócić od razu,
    //    wczytując z JSON i parsując na listę obiektów.
    if (cachedData != null) {
      final List decoded = jsonDecode(cachedData);
      final photosFromCache = decoded.map((e) => Photo.fromJson(e)).toList();
      return photosFromCache;
    }

    // 3. Jeśli brak danych w cache, pobieramy z internetu
    //    (np. z JSONPlaceholder – 50 zdjęć w albumId=1).
    final url = Uri.parse('https://jsonplaceholder.typicode.com/photos?albumId=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Parsujemy listę obiektów
      final List decoded = jsonDecode(response.body);

      // Konwersja do listy Photo
      final photos = decoded.map((e) => Photo.fromJson(e)).toList();

      // Zapisujemy pobrany JSON w cache (SharedPreferences),
      // aby przy następnym uruchomieniu aplikacji nie pobierać z sieci.
      await prefs.setString(_cacheKey, response.body);

      return photos;
    } else {
      throw Exception('Błąd pobierania danych z API (status ${response.statusCode})');
    }
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
      appBar: AppBar(
        title: const Text('Flutter JSON List'),
      ),
      body: FutureBuilder<List<Photo>>(
        future: futurePhotos,
        builder: (context, snapshot) {
          // Jeśli jeszcze trwa pobieranie danych, pokażemy wskaźnik ładowania.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Jeśli wystąpił błąd (np. brak internetu), wyświetlamy komunikat.
          else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }
          // Jeśli brak danych (pusta lista) – informacja na ekranie.
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak danych do wyświetlenia.'));
          }
          // Jeśli wszystko OK, mamy gotową listę obiektów do wyświetlenia.
          else {
            final photos = snapshot.data!; // lista pobranych/keszeowanych obiektów

            // Wyświetlamy listę elementów w ListView
            return ListView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return ListTile(
                  // leading – miniaturka zdjęcia
                  leading: Image.network(
                    photo.thumbnailUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(photo.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    _showDetailsDialog(photo);
                  },
                );
              },
            );
          }
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
