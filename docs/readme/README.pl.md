# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · **Polski**
<!-- languages:end -->

FolioPDF to natywna aplikacja macOS do tworzenia książek z obrazów i edycji zakładek PDF. Korzysta z niezależnie zaprojektowanego interfejsu SwiftUI i frameworków systemowych Apple. Nie wymaga środowisk uruchomieniowych innych firm ani klucza API i nie przesyła plików do sieci.

## Użytkowanie

Pobierz `FolioPDF-1.4-macOS.zip` z [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest), rozpakuj i otwórz `FolioPDF.app`. Możesz też przeciągnąć aplikację do folderu „Aplikacje”. Wymagany jest **macOS 14 lub nowszy**. Aplikacja zbudowana lokalnie znajduje się w `dist/FolioPDF.app`.

Pakiety wersji 1.4 to `FolioPDF-1.4-macOS.zip` i `FolioPDF-1.4-source.zip`. Aplikacja w archiwum ZIP zawsze nazywa się `FolioPDF.app`. [Raport walidacji](../validation/VALIDATION.pl.md) opisuje stan weryfikacji, środowisko uruchomieniowe i zawiera rzeczywiste zrzuty interfejsu. Repozytorium źródłowe nie zawiera pamięci podręcznej kompilacji ani plików binarnych aplikacji; pakiety instalacyjne są w Releases.

1. W obszarze „Utwórz PDF” dodaj obrazy, przeciągnij pliki lub dodaj jeden bądź kilka folderów. Opcja przeszukiwania podfolderów znajduje się w ustawieniach po prawej i należy ją wybrać przed importem.
2. Kliknij obraz, aby go zaznaczyć; Command-kliknięcie zaznacza wiele obrazów. Przeciągnij obraz na inny, aby zmienić kolejność, lub użyj dolnych przycisków przesuwania w przód/w tył. Dwukrotne kliknięcie otwiera podgląd. Można przełączać miniatury i listę.
3. Po prawej wybierz scalanie do jednego PDF, osobny PDF dla każdego pliku źródłowego lub folderu. Ustaw papier, marginesy, DPI, kompresję, OCR i informacje o dokumencie.
4. Aby włączyć ochronę hasłem, przewiń prawy panel ustawień i rozwiń „Szyfrowanie PDF” za „Szczegóły dokumentu”. Sekcja jest domyślnie zwinięta; po rozwinięciu ustawienia są od razu widoczne. „Hasło otwierania” i „Hasło edycji” mają osobne przełączniki. Po włączeniu wpisz odpowiednie hasło i potwierdzenie. Uprawnienia opisano w tabeli poniżej. Każdy PDF w eksporcie wsadowym korzysta z tych samych ustawień.
5. Kliknij „Utwórz PDF”. Istniejące pliki nie są nadpisywane; przy konflikcie nazw automatycznie powstaje plik z numerem. Każda strona/klatka wielostronicowego TIFF/GIF staje się kolejno stroną PDF. Opcja „Jeden PDF na plik obrazu” nie dzieli jednego pliku źródłowego na kilka PDF-ów.
6. Obszar „Zakładki” pozwala otwierać niezaszyfrowane PDF-y, dodawać, edytować, przenosić i wcinać pozycje spisu treści, sprawdzać przejścia w podglądzie, importować i eksportować TXT, JSON lub zgodne pliki interfejsu, a następnie zapisać kopię.

Cały wiersz nagłówka rozwijanych sekcji, takich jak „Szczegóły dokumentu”, „Szyfrowanie PDF” oraz „Marginesy i rozdzielczość”, jest klikalny, również puste miejsce obok tytułu. Nawigacja obszarów po lewej także obsługuje kliknięcie całego wiersza. „Szyfrowanie PDF” jest domyślnie zwinięte; po rozwinięciu przewija się wraz z prawym panelem.

⌘N pokazuje główne okno, ⌘O dodaje obrazy, ⌘⇧O dodaje foldery, ⌘E eksportuje, a ⌘, otwiera ustawienia. Zamknięcie i ponowne otwarcie głównego okna zachowuje bieżącą sesję. Zakończenie aplikacji nie zapisuje automatycznie szkiców zakładek; najpierw zapisz kopię.

### Hasło otwierania i hasło edycji

| Włączona ochrona | Długość hasła | Uprawnienia do odczytu i operacji |
|---|---|---|
| Tylko hasło otwierania | Hasło otwierania: 1–32 znaki | Do otwarcia PDF wymagane jest hasło; po podaniu prawidłowego hasła dostępne są wszystkie operacje |
| Tylko hasło edycji | Hasło edycji: 1–32 znaki | Odczyt nie wymaga hasła. Zwykli czytelnicy mają ograniczone modyfikowanie treści, adnotacje, wypełnianie formularzy oraz wstawianie/usuwanie/obracanie stron. Hasło edycji daje pełne uprawnienia |
| Oba hasła | Hasło otwierania: 1–16 znaków; hasło edycji: 1–32 znaki | Hasło otwierania daje ograniczone uprawnienia do odczytu. Hasło edycji daje pełne uprawnienia i może też bezpośrednio otworzyć PDF |

Gdy włączone są oba hasła, muszą być różne. Drukowanie, kopiowanie i dostępność są zawsze dozwolone. Ograniczenia edycji zależą od przestrzegania uprawnień przez czytnik PDF; nie oznaczają, że treści absolutnie nie da się zmienić.

Hasła mogą zawierać wyłącznie drukowalne znaki ASCII: litery angielskie, cyfry, symbole i spacje. Limity długości podano powyżej. Przy obu hasłach interfejs wskazuje limit 16 znaków hasła otwierania. Przekroczenie limitu powoduje odmowę przed eksportem, bez obcinania hasła ani automatycznego usuwania początkowych i końcowych spacji.

Hasła są przechowywane tylko w bieżącej sesji aplikacji, nie w ustawieniach, historii ani dziennikach. Wyłączenie przełącznika usuwa dane hasło i jego potwierdzenie, a reset ustawień usuwa obie grupy. Nieprawidłowe hasła lub potwierdzenia blokują eksport. Gdy oba przełączniki są wyłączone, eksportowany jest zwykły PDF.

Język interfejsu domyślnie odpowiada systemowemu. W ustawieniach można w dowolnym momencie wybrać jeden z **16 języków**, bez ponownego uruchamiania:

简体中文 · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · Nederlands · **Polski**

Arabski używa układu od prawej do lewej. Obrazy i treść PDF pozostają bez zmian; edytor tekstu TAB dla zakładek zachowuje strukturę od lewej do prawej. Wygląd może być systemowy, jasny lub ciemny. Elementy macOS, takie jak okna wyboru plików, korzystają z języka systemowego. Język interfejsu i rozpoznawania OCR ustawia się oddzielnie; dostępne języki OCR zależą od lokalnego Vision.

## Zakres implementacji

| Możliwość | Opis implementacji |
|---|---|
| Import obrazów | JPEG, JPEG XL (`.jxl`), PNG, TIFF, GIF, BMP, HEIC/HEIF, JPEG 2000 i inne formaty dekodowane przez ImageIO. JPEG XL jest natywnie obsługiwany przez ImageIO w macOS 14 i nowszych; pozostałe rozszerzenia obsługiwane przez system są wykrywane dynamicznie. Obsługa RAW zależy od lokalnego dekodera systemowego; nie gwarantuje się wszystkich modeli aparatów |
| Organizacja plików | Usuwanie duplikatów, sortowanie po nazwie/końcowej liczbie, kolejność ręczna, sortowanie według typowych prefiksów e-booków, przeszukiwanie podfolderów, wybór uwzględnienia folderu głównego |
| Eksport wsadowy | Jeden scalony PDF, jeden PDF na plik źródłowy albo na bezpośredni folder nadrzędny. Głębsze foldery są grupowane osobno; obrazy z potomnych folderów nie są ponownie wliczane do folderu nadrzędnego |
| Strony | Oryginalny rozmiar obrazu, stała szerokość, A3/A4/A5/B5/Letter/Legal, własne wymiary w milimetrach, orientacja pozioma, cztery marginesy, powiększanie małych obrazów, pierwszeństwo metadanych DPI |
| Kompresja | Przetwarzanie bezstratne i regulacja jakości JPEG. JPEG z prawidłową orientacją źródłową może zachować oryginalny strumień DCT. Inne formaty i orientacje są poprawnie dekodowane i rozmieszczane przez ImageIO; nie obiecuje się zachowania każdego strumienia źródłowego bajt po bajcie |
| Przezroczystość | Zachowanie przezroczystości lub białe tło. JPEG nie przechowuje alfa; przy zachowaniu przezroczystości automatycznie używane jest kodowanie bezstratne wraz z wyjaśnieniem |
| OCR | Dokładne lokalne rozpoznawanie Apple Vision, automatyczny lub ręczny wybór lokalnie obsługiwanych języków, ukryty tekst do wyszukiwania i kopiowania. Po niepowodzeniu ścieżki GPU próbowany jest CPU. Strony z nieudanym rozpoznaniem zachowują obraz i są wyraźnie zgłaszane |
| Właściwości dokumentu | Tytuł, autor, temat, słowa kluczowe; układ pojedynczej strony, ciągły lub dwustronicowy |
| Szyfrowanie PDF | Natywne PDFKit AES-128, niezależne hasło otwierania, hasło edycji lub oba. Przy samym haśle otwierania generowane jest losowe hasło owner; ustawione hasło edycji nadaje pełne uprawnienia owner. Plik publikowany jest dopiero po kontroli blokady, haseł, uprawnień reader/owner i liczby stron dla wybranego trybu. Błąd nie powoduje eksportu niezaszyfrowanego zamiennika. Podgląd w aplikacji umożliwia podanie hasła |
| Zakładki | Automatyczne zakładki plików źródłowych, wielopoziomowy spis treści, numery stron, przeliczanie strony bazowej, edytowalny tekst i JSON, natywny podgląd przejść PDF |
| Pliki interfejsu zakładek | Ogólne pliki ITF (`.itf`) i `TXT`, UTF-8/UTF-16LE oraz odpowiednie starsze kodowania; oddzielna numeracja spisu treści i tekstu głównego, metadane, dodawanie przeszukiwalnych stron tekstowych, ustawienia wyświetlania zakładek |
| Stabilność | Zadania w tle, zwalnianie obrazów po każdej stronie, postęp, anulowanie, dzienniki, pliki tymczasowe i atomowa publikacja, automatyczne numerowanie konfliktujących nazw, zachowanie i wykaz ukończonych wyników po częściowym niepowodzeniu partii |

JPEG XL obsługuje import, miniatury, podgląd i konwersję do PDF statycznych obrazów stratnych, bezstratnych, z przezroczystością i w 16-bitowej skali szarości. Dla animowanych JXL gwarantowana jest tylko pierwsza klatka dekodowana przez system, a nie import całej animacji klatka po klatce. ImageIO w sprawdzonym środowisku zwraca tylko pierwszą klatkę. Aplikacja nie koduje plików wyjściowych JXL i nie gwarantuje zachowania bez zmian w PDF oryginalnego strumienia JXL, HDR ani informacji o wysokiej głębi bitowej.

### Aktualne ograniczenia

- OCR korzysta z Apple Vision, bez Office/Windows. Nie udostępnia oczyszczania wykresów, ustawiania czcionek CJK ani przełączników rozpoznawania znak po znaku lub wiersz po wierszu.
- Obecne opcje kompresji to bezstratna i JPEG. Kodery JBIG2, CCITT G4 i JPEG 2000 nie są dostępne. Podstawowe funkcje działają, ale duże czarno-białe książki mogą zajmować więcej miejsca niż przy specjalistycznych narzędziach JBIG2.
- Nie ma narzędzi korekty do pokazywania/ukrywania tekstu OCR i fizycznego usuwania obrazów skanów. Nie ma też naprawy obrazów ani pełnego edytora treści PDF.
- Wielowarstwowe składanie `[Images]` i `MinWidth` w zgodnych plikach interfejsu nie zostały jeszcze zaimplementowane. Po ich wykryciu wyświetlane jest wyjaśnienie, bez sugerowania, że zostały zastosowane. Jeśli kolejność ręczna różni się od bezwzględnych numerów stron interfejsu, użytkownik musi sprawdzić cele spisu treści.
- Obsługiwane są zwykłe lokalne numery stron, część standardowych nazwanych akcji i cele URL. Zewnętrzne cele PDF, których PDFKit nie zapisuje niezawodnie, oraz nierozwiązywalne cele nazwane/specjalne są wyraźnie oznaczane i blokują ciche zapisanie. Można je zmienić w edytorze na poprawne lokalne numery stron. JSON/TXT mogą zachować dane celów. Zaszyfrowane PDF-y nie obsługują edycji zakładek.
- Szyfrowanie zachowuje zakładki, tekst OCR, metadane, układ czytania i zwykłą numerację sekcyjną. Natywne PDFKit nie zachowuje etykiet stron; aplikacja bezpiecznie przywraca tylko etykiety bez prefiksów tekstowych. Pliki interfejsu z własnymi prefiksami tekstowymi jawnie blokują szyfrowany eksport; należy usunąć prefiksy lub wyłączyć szyfrowanie.
- „Kolejność e-booka” stosuje popularne grupy prefiksów: cov, bok, leg, fow, !, toc, numeryczny tekst główny, att, ins, bac; pozostałe trafiają na koniec. Przy innych zasadach nazewnictwa sprawdź kolejność i w razie potrzeby popraw ją ręcznie.
- Po anulowaniu lub błędzie ukończone PDF-y z partii pozostają, a bieżący nieukończony plik tymczasowy jest usuwany. Wznawianie od punktu przerwania nie jest dostępne.

## Rozwój i kompilacja

Kod ma postać Swift Package; otwórz `Package.swift` w Xcode. Wymagane są Xcode z macOS SDK i Swift 5.9 lub nowszy. Środowisko walidacji to macOS 15.7.9 / Xcode Swift 6.2.4, a docelowa zgodność uruchomieniowa to macOS 14.

```sh
# Uruchomienie debugowe
swift run FolioPDF

# Testy i kontrola tekstów w 16 językach
bash scripts/test.sh

# Uniwersalna .app i ZIP dla Intel + Apple Silicon
bash scripts/build-app.sh

# Kompilacja tylko dla architektury bieżącego komputera
bash scripts/build-app.sh --host-only
```

Rzeczywiste testy OCR w `scripts/test.sh` wymagają normalnego dostępu do usług macOS, takich jak Vision i CoreVideo. W piaskownicy ograniczającej sprzęt/usługi systemowe tworzenie CVPixelBuffer może się nie powieść. W normalnym środowisku testy należy uruchomić i muszą przejść; pomijanie testów nie zastępuje walidacji.

Pakowanie używa lokalnego podpisu ad-hoc, bez notaryzacji Developer ID. Aplikacja może działać lokalnie. Oficjalna dystrybucja na inne Maki wymaga certyfikatu deweloperskiego i procesu notaryzacji.

### Układ kodu

```text
Sources/FolioCore/       Obrazy, geometria, konwersja, OCR, zakładki i pliki interfejsu
Sources/FolioPDF/        Obszary SwiftUI, zarządzanie stanem, natywny podgląd i języki
Tests/FolioCoreTests/    Testy rzeczywistych obrazów/PDF/OCR, zapisu i odczytu zakładek oraz granic
scripts/                Testy, pakowanie, generowanie ikon i przykładowych obrazów
packaging/Info.plist     Informacje aplikacji macOS
docs/                   Raporty walidacji i renderowane rzeczywiste okna
dist/                   Uruchamialna .app i dystrybucyjne ZIP-y (wynik kompilacji)
```

## Języki dokumentacji

README i raport walidacji są dostępne w tych samych 16 językach co interfejs. Wybierz język przez odnośniki u góry dokumentów. Opisy funkcji, ograniczenia haseł, aktualne ograniczenia i kroki kompilacji są spójne we wszystkich wersjach językowych. Dzienniki testów, kompilacji i zrzutów okien są automatycznie wygenerowanymi dowodami i zachowują oryginalne wyjście narzędzi. Odpowiednie objaśnienia mają wersje wielojęzyczne w raporcie walidacji.

## Podstawy techniczne

Wykorzystano [interfejs wykrywania języka Vision](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage), [właściwości dokumentów PDFKit](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) oraz [parametr jakości JPEG ImageIO](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality) firmy Apple. Implementację sprawdzono również względem deklaracji lokalnego SDK i testów rzeczywistych plików. FolioPDF łączy niezależnie zaprojektowany interfejs SwiftUI z natywnymi frameworkami systemowymi Apple.
