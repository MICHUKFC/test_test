# test_test

Przykładowa aplikacja Flutter prezentująca galerię zdjęć pobieranych z lokalnego API. Pełna dokumentacja dostępna jest w pliku [docs/README.md](docs/README.md).

## Szybki start

1. Zainstaluj zależności Fluttera:
   ```bash
   flutter pub get
   ```
2. Uruchom lokalny `json-server` na porcie 3000:
   ```bash
   npm install -g json-server
   json-server --watch flutter-gallery-api/db.json --port 3000
   ```
3. Włącz aplikację na wybranym urządzeniu lub emulatorze:
   ```bash
   flutter run
   ```

Więcej informacji, w tym opis działania aplikacji, znajduje się w [docs/README.md](docs/README.md).
