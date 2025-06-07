# Dokumentacja projektu test_test

Ten projekt to aplikacja Flutter wyświetlająca galerię zdjęć pobieranych z lokalnego serwera `json-server`. Dane są cache'owane w `SharedPreferences`, a obrazy korzystają z `CachedNetworkImage` oraz wstępnego pobierania do `ImageCache`.

## Wymagania wstępne

- [Flutter](https://flutter.dev) w wersji zgodnej z plikiem `pubspec.yaml` (SDK ^3.7.2).
- [Node.js](https://nodejs.org/) z pakietem `json-server` do uruchomienia lokalnego API.

## Konfiguracja serwera API

1. Zainstaluj `json-server` globalnie:
   ```bash
   npm install -g json-server
   ```
2. Uruchom serwer w katalogu `flutter-gallery-api`:
   ```bash
   json-server --watch db.json --port 3000
   ```
3. API będzie dostępne pod adresem `http://localhost:3000/gallery`.

## Uruchamianie aplikacji

Po upewnieniu się, że serwer API działa, uruchom aplikację Flutter na wybranej platformie:

```bash
flutter run
```

Aplikacja obsługuje Androida, iOS, Web oraz platformy desktopowe (Linux, macOS, Windows).

## Funkcje aplikacji

- **Pobieranie i cache** – pełne dane galerii są pobierane z API i zapisywane w `SharedPreferences`. Przy ponownym uruchomieniu aplikacja wczytuje dane z pamięci podręcznej.
- **Galeria w układzie masonry** – główny ekran wyświetla miniatury zdjęć w układzie `MasonryGridView`.
- **Szczegóły zdjęcia** – po kliknięciu miniatury otwiera się ekran z pełnym zdjęciem i rozwijanymi sekcjami (wideo, metadane, tagi, komentarze, dane Exif, lokalizacja, surowy JSON).
- **Prefetch obrazów** – pełne zdjęcia są pobierane z wyprzedzeniem dzięki `precacheImage`.

## Testy

W katalogu `test/` znajduje się przykładowy test widgetu, który można uruchomić poleceniem:

```bash
flutter test
```

## Struktura katalogów

- `lib/` – kod źródłowy aplikacji (głównie `main.dart`).
- `flutter-gallery-api/` – przykładowa baza danych `json-server` (plik `db.json`).
- `android/`, `ios/`, `linux/`, `macos/`, `windows/` – konfiguracje poszczególnych platform.
- `web/` – pliki wymagane do uruchomienia aplikacji w przeglądarce.

## Czyszczenie pamięci podręcznej

W razie potrzeby cache galerii można wyczyścić, wywołując:

```dart
await ApiService.clearCache();
```

lub usuwając klucz `gallery_cache` z `SharedPreferences`.

