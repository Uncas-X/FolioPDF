# Raport walidacji FolioPDF 1.3

<!-- languages:start -->
[简体中文](../VALIDATION.md) · [English](VALIDATION.en.md) · [繁體中文](VALIDATION.zh-Hant.md) · [日本語](VALIDATION.ja.md) · [한국어](VALIDATION.ko.md) · [Français](VALIDATION.fr.md) · [Deutsch](VALIDATION.de.md) · [Español](VALIDATION.es.md) · [Italiano](VALIDATION.it.md) · [Português (Brasil)](VALIDATION.pt-BR.md) · [Русский](VALIDATION.ru.md) · [العربية](VALIDATION.ar.md) · [हिन्दी](VALIDATION.hi.md) · [Türkçe](VALIDATION.tr.md) · [Nederlands](VALIDATION.nl.md) · **Polski**
<!-- languages:end -->

Stan: **testy i kompilacja zakończone powodzeniem**. Data: 2026-10-23. Środowisko: Intel Mac, macOS 15.7.9, Swift 6.2.4 / Xcode. Minimalna wersja wdrożeniowa: macOS 14.

Ta wersja dodaje niezależne hasło otwierania i hasło edycji. Ustawienia szyfrowania umieszczono w domyślnie zwiniętej sekcji prawego panelu, z klikalnym całym nagłówkiem. Uruchomiono wszystkie 50 testów XCTest: wszystkie przeszły, 0 niepowodzeń, 0 pominiętych. Potwierdzono, że lokalny natywny interfejs zapisu PDF przy haśle otwierania o długości 17–31 znaków może powodować nieskuteczność hasła owner. Aplikacja zapobiega temu przez wstępną kontrolę długości w trybie dwóch haseł. Granice bezpieczeństwa opisano poniżej. Dziennik tej sesji to `test-results.txt`.

## Pliki wynikowe

- `dist/FolioPDF.app`: natywne okno AppKit, interfejs SwiftUI i systemowe PDFKit / Vision / ImageIO. Nazwa pliku aplikacji nie zawiera wersji; zapisano ją w metadanych aplikacji.
- `dist/FolioPDF-1.3-macOS.zip`: uniwersalna aplikacja zawierająca x86_64 i arm64, zweryfikowana przez `lipo -archs`.
- `dist/FolioPDF-1.3-source.zip`: źródła Swift Package otwierane w Xcode, z testami, skryptami, instrukcjami i zrzutami interfejsu.
- Skrypt pakujący używa lokalnego podpisu ad-hoc; `codesign --verify --deep --strict` zakończyło się powodzeniem. Brak notaryzacji Developer ID. Wersja wewnętrzna to 1.3 (build 4), a nazwa pliku nadal brzmi `FolioPDF.app`.

## Testy funkcjonalne

Uruchomiono `bash scripts/test.sh`; wszystkie 50 testów XCTest przeszło. Szczegółowe wyniki zapisano w `test-results.txt`. Wykonano także rzeczywiste testy Vision OCR, bez pomijania.

| Zakres | Liczba | Sprawdzone elementy |
|---|---:|---|
| Wykrywanie i sortowanie zasobów | 3 | Sortowanie liczbowe, prefiksy e-booków, podfoldery i wykluczanie folderu głównego, powielone ścieżki |
| Konwersja PDF | 10 | Geometria stron i błędne parametry, orientacja EXIF, wielostronicowe TIFF/GIF, metadane i zakładki, grupowanie po folderach, brak nadpisywania, częściowe błędy partii, rzeczywiste kodowanie JPEG, zachowanie źródłowego strumienia JPEG, ukryty tekst Vision i wyszukiwanie, sprzątanie po anulowaniu |
| Zakładki i pliki interfejsu | 8 | Zakładki wielopoziomowe, przeliczanie BasePage, nieprawidłowe cele, akcje standardowe i JSON, jawne odrzucanie celów zewnętrznych, interfejs UTF-16 i numeracja sekcyjna, zapis kopii, przeszukiwalne strony tekstowe, zachowanie istniejących etykiet stron |
| Lokalizacja | 3 | 16 języków i kolejność, pełne ładowanie zasobów, 18 mapowań regionalnych, język zastępczy przy nieznanym języku, pierwszeństwo wyboru ręcznego, RTL wyłącznie dla arabskiego |
| Natywne szyfrowanie PDF | 14 | Rzeczywisty słownik AESV2/128 bitów, tylko otwieranie/tylko edycja/dwa hasła, rozdzielenie uprawnień reader i owner, brak podniesienia uprawnień błędnym hasłem, wymóg różnych haseł, losowy owner, granice długości jednego i dwóch haseł, odrzucanie zbyt długiego hasła otwierania przed zapisem, spacje początkowe/końcowe, chińskie metadane, zakładki, ukryty tekst, zwykła numeracja sekcyjna i układ, jawne odrzucanie prefiksów tekstowych, brak nadpisywania i sprzątanie po błędach |
| Integracja szyfrowanej konwersji | 7 | Szyfrowanie scalone, na plik i na folder, automatyczne numerowanie, niezmienność źródeł, brak wyjścia przy błędnym haśle, uprawnienia dwóch haseł i zachowanie metadanych, rzeczywiste wyszukiwanie Vision OCR i zachowanie wyglądu, deterministyczne anulowanie konwersji i sprzątanie folderów |
| Stan interfejsu szyfrowania | 5 | Sprawdzanie obu haseł i potwierdzeń, niezależne czyszczenie przełącznikami, izolacja sesji i reset, pełny eksport w trzech trybach i liczba stron w historii, brak haseł w ustawieniach/historii/dziennikach |

Testy OCR korzystają z rzeczywiście wygenerowanych obrazów tekstu. Sprawdzają możliwość wyodrębnienia tekstu z wynikowego PDF i to, że ukryty tekst nie zmienia renderowania strony. Testy wymagają dostępu do usług systemowych macOS; błędy CoreVideo w ograniczonej piaskownicy nie są uznawane za sukces.

### Kryteria akceptacji dwóch haseł

| Tryb | Zwykły czytelnik | Posiadacz hasła edycji |
|---|---|---|
| Tylko hasło otwierania | Puste i błędne hasła nie otwierają pliku; prawidłowe hasło otwierania daje wszystkie uprawnienia operacyjne | Nie ustawiono osobnego hasła edycji |
| Tylko hasło edycji | Odczyt bez hasła; zabroniona zmiana treści, adnotacje, formularze i organizacja stron | Hasło edycji daje pełne uprawnienia owner |
| Oba hasła | Hasło otwierania daje ograniczone uprawnienia user | Hasło edycji otwiera plik bezpośrednio i daje pełne uprawnienia owner |

Dwa jednocześnie włączone hasła muszą być różne. Wszystkie trzy tryby pozwalają drukować, kopiować i korzystać z dostępności. Tryby ograniczone wyłączają modyfikację treści, adnotacje, formularze oraz wstawianie/usuwanie/obracanie stron. Czytnik musi respektować te uprawnienia; nie stanowią gwarancji „całkowitej niemożności modyfikacji”.

Akceptowane są tylko drukowalne znaki ASCII. Bezpiecznie obsługiwane zakresy: samo hasło otwierania 1–32 znaki, samo hasło edycji 1–32 znaki, w trybie dwóch haseł hasło otwierania 1–16, a hasło edycji 1–32 znaki. Warunkowe ograniczenie jest wyraźnie podane w interfejsie i egzekwowane podczas kontroli przed eksportem. Przekroczenie zakresu daje błąd, bez obcinania hasła, zmiany spacji brzegowych lub obniżenia poziomu ochrony wyjścia.

Dla otwartego PDF wywołanie `unlock(withPassword:)` może zwrócić `true` nawet przy błędnym haśle owner. Dlatego akceptacja sprawdza `permissionsStatus` i wszystkie bity uprawnień: ograniczony reader to user/51, owner to owner/255, a reader z samym hasłem otwierania to user/255. Pliki z samym hasłem edycji otwierają się automatycznie; odczyt liczby stron do historii nie wymaga odblokowania owner.

## Interfejs i języki

- Obecne zasoby zawierają 292 teksty × 16 języków, a rzeczywisty interfejs używa 281 tekstów. `check-localization.py` przeszło pomyślnie; zasoby językowe w pakiecie są identyczne bajt po bajcie z plikami źródłowymi.
- Domyślnie używany jest język systemowy. Kolejność odpowiada żądaniu użytkownika: 简体中文, English, 繁體中文, 日本語, 한국어, Français, Deutsch, Español, Italiano, Português (Brasil), Русский, العربية, हिन्दी, Türkçe, Nederlands, Polski.
- Arabskie główne okno i okno ustawień używają RTL. Nazwy plików, obrazy i treść PDF pozostają bez zmian. Edytor TAB zakładek zachowuje strukturę LTR, aby nie zmieniać znaczenia edycji plików interfejsu.
- Ponownie uruchomiono aplikację i wyrenderowano rzeczywisty NSView, sprawdzając jasny chiński interfejs ze zwiniętymi ustawieniami i rozwiniętymi dwoma hasłami, długie niemieckie teksty w ciemnym wyglądzie, arabski RTL oraz samo hasło edycji. Pola i objaśnienia zawijają się poprawnie; nie zauważono nakładania ani brakujących znaków. Treść poza obszarem widocznym przewija się w prawym panelu. Zrzuty są w tabeli poniżej.
- Rozwijane nagłówki „Szczegóły dokumentu”, „Szyfrowanie PDF” oraz „Marginesy i rozdzielczość” używają Button na cały wiersz; etykieta wypełnia szerokość, a obszar kliknięcia jest prostokątny. Powiększono też obszary kliknięcia nawigacji po lewej i dolnego przycisku ustawień. Przegląd kodu objął puste obszary i semantyczny kierunek RTL; nie wykonano osobnego testu automatyzacji myszy. Końcową aplikację wydaniową sprawdzono pod kątem uruchamiania i ponownego otwierania po zamknięciu głównego okna; log zawiera `reopen verified: true`.
- Podczas konwersji zablokowane są zamykanie okna i kończenie aplikacji. Niezapisane zakładki powodują ostrzeżenie przy zamykaniu/kończeniu. Po ponownym otwarciu pozostaje szkic bieżącej sesji.
- Przycisk ustawień i ⌘, używają tego samego natywnego okna ustawień. ⌘N pokazuje główne okno, ⌘O dodaje obrazy, ⌘⇧O foldery, ⌘E eksportuje.
- „Szyfrowanie PDF” jest osobną sekcją prawego panelu po „Informacjach o dokumencie”, domyślnie zwiniętą i przewijaną wraz z panelem. Rozwinięcie od razu pokazuje obie grupy haseł, bez panelu wyskakującego. Hasło otwierania i edycji mają osobne przełączniki, maskowane pola hasła i potwierdzenia.
- Wyłączenie jednego przełącznika czyści tylko dane hasło i potwierdzenie; reset czyści obie grupy. Błędne hasła, niezgodne potwierdzenia albo jednakowe dwa hasła blokują eksport. Gdy obie grupy są wyłączone, powstaje zwykły PDF. Zwijanie sekcji nie zmienia ustawień ochrony.
- Oba hasła są przechowywane tylko w bieżącym procesie, nie w trwałych ustawieniach, historii ani dziennikach. Jawne pliki tymczasowe szyfrowanego eksportu znajdują się w katalogu z uprawnieniami 0700 i są usuwane po zwykłym anulowaniu lub błędach. Publikowany jest wyłącznie zaszyfrowany plik, który przeszedł kontrolę wybranego trybu; błąd nie może prowadzić do niezaszyfrowanego wyjścia.
- Języki OCR nadal zależą od lokalnego Vision; liczby języków OCR nie należy wywodzić z liczby języków interfejsu.

## Granice walidacji

- Testowano na Intel Mac. Obie architektury uniwersalnego pakietu 1.3 skompilowano pomyślnie, ale nie testowano jeszcze na fizycznym Apple Silicon.
- Minimalny cel wdrożenia to macOS 14; rzeczywiste środowisko tej sesji to macOS 15.7.9.
- Nie przeprowadzono wielkoskalowych benchmarków wydajności dla skanowanych książek. Nie gwarantuje się zgodności z każdym RAW aparatu ani każdym niestandardowym celem PDF.
- Szyfrowanie używa Apple PDFKit, wymaga AESV2/128 bitów i sprawdza hasła oraz uprawnienia dla wybranego trybu. Problem natywnego zapisu przy hasłach otwierania o długości 17–31 znaków wpływa na uwierzytelnienie owner, więc tryb dwóch haseł ogranicza hasło otwierania do 1–16 znaków. Hasło edycji i oba tryby pojedynczego hasła obsługują po 1–32 znaki. Aplikacja nie naprawia samodzielnie wyników kryptograficznych; odrzuca Unicode, znaki sterujące i długości poza granicą trybu. Wstępna kontrola granic, uprawnienia owner i zachowanie spacji brzegowych mają testy rzeczywistych plików. Hasła otwierania o długości 17, 31 i 32 znaków w trybie dwóch haseł są odrzucane przed zapisem.
- Etykiet stron z własnymi prefiksami tekstowymi nie można niezawodnie zachować przez obecną ścieżkę natywną; przy szyfrowaniu zgłaszany jest wyraźny błąd. Zwykłą numerację sekcyjną literami/cyframi rzymskimi/liczbami, układ czytania i metadane sprawdzono przez zapis i ponowny odczyt. Podgląd w aplikacji pozwala podać hasło otwierania; pliki tylko z hasłem edycji można oglądać bezpośrednio. Edycja zakładek zaszyfrowanych plików pozostaje nieobsługiwana.
- Różnice względem starego programu, m.in. kodowanie JBIG2/G4, dawna korekta OCR, wielowarstwowe pliki interfejsu i część specjalnych celów zakładek, opisano w README w sekcji „Wyraźne różnice względem starszej wersji”.

## Zapis interfejsu tej wersji

| Stan | Rzeczywisty zrzut okna |
|---|---|
| Chiński, szyfrowanie domyślnie zwinięte | [encryption-collapsed-zh.png](../screenshots/encryption-collapsed-zh.png) |
| Chiński, dwa hasła rozwinięte | [encryption-inline-zh.png](../screenshots/encryption-inline-zh.png) |
| Niemiecki, ciemny wygląd, dwa hasła rozwinięte | [encryption-inline-de-dark.png](../screenshots/encryption-inline-de-dark.png) |
| Arabski, RTL, dwa hasła rozwinięte | [encryption-inline-ar.png](../screenshots/encryption-inline-ar.png) |
| Końcowa uniwersalna aplikacja, chiński, samo hasło edycji oraz ponowne otwarcie okna | [encryption-editing-only-zh.png](../screenshots/encryption-editing-only-zh.png) |

Zrzuty pochodzą z renderowania własnego `NSView` aplikacji i nie zawierają innych aplikacji. `build-results.txt` zapisuje produkcyjną kompilację obu architektur. Plik `SHA256SUMS-1.3.txt` w [Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.3.0) zawiera sumy kontrolne dystrybucyjnych ZIP-ów. Zrzuty starego układu przeniesiono do `screenshots/previous-layout/`; nie są dowodem akceptacji interfejsu tej wersji.

Oryginalne dzienniki testów, kompilacji i zrzutów wygenerowały narzędzia. Zachowano oryginalne wyjście, zastępując lokalną ścieżkę projektu przez `<project>`. Dzienników nie tłumaczy się i nie przedstawia jako oryginalnych dowodów. Wszystkie 16 wersji językowych tego raportu opisuje te same wyniki, środowisko i granice. Dystrybucja źródłowa nie zawiera pamięci podręcznej kompilacji ani binariów wydania; pakiety pobieraj z Releases prywatnego repozytorium.
