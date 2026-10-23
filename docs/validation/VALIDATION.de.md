# FolioPDF 1.4 – Validierungsbericht

<!-- languages:start -->
[简体中文](../VALIDATION.md) · [English](VALIDATION.en.md) · [繁體中文](VALIDATION.zh-Hant.md) · [日本語](VALIDATION.ja.md) · [한국어](VALIDATION.ko.md) · [Français](VALIDATION.fr.md) · **Deutsch** · [Español](VALIDATION.es.md) · [Italiano](VALIDATION.it.md) · [Português (Brasil)](VALIDATION.pt-BR.md) · [Русский](VALIDATION.ru.md) · [العربية](VALIDATION.ar.md) · [हिन्दी](VALIDATION.hi.md) · [Türkçe](VALIDATION.tr.md) · [Nederlands](VALIDATION.nl.md) · [Polski](VALIDATION.pl.md)
<!-- languages:end -->

Status: **Tests und Build erfolgreich**. Stand: 2026-10-23. Prüfumgebung: Intel Mac, macOS 15.7.9, Swift 6.2.4 / Xcode. Minimales Deploymentziel: macOS 14.

Diese Version unterstützt JPEG-XL-Eingaben über natives ImageIO unter macOS 14 oder neuer sowie unabhängige Öffnungs- und Bearbeitungspasswörter. Die Verschlüsselungseinstellungen liegen in einem anfangs eingeklappten Abschnitt rechts, dessen ganze Kopfzeile anklickbar ist. Alle 58 XCTest-Tests wurden vollständig ausgeführt: 0 Fehler, 0 übersprungene Tests. Es wurde bestätigt, dass die native PDF-Schreibschnittstelle dieses Macs bei einem Öffnungspasswort mit 17–31 Zeichen das owner-Passwort unwirksam machen kann. Die App vermeidet dies durch eine Längenprüfung vor dem Export im Modus mit zwei Passwörtern; die unterstützten Grenzen sind unten beschrieben. Das Protokoll dieser Prüfung heißt `test-results.txt`.

## Lieferumfang

- `dist/FolioPDF.app`: native AppKit-Fenster, SwiftUI-Oberfläche und die Systemframeworks PDFKit / Vision / ImageIO. Der Dateiname der App enthält keine Versionsnummer; diese steht in den App-Metadaten.
- `dist/FolioPDF-1.4-macOS.zip`: universelles Anwendungspaket mit x86_64 und arm64, geprüft mit `lipo -archs`.
- `dist/FolioPDF-1.4-source.zip`: in Xcode zu öffnender Swift-Package-Quellcode mit Tests, Skripten, Anleitung und Oberflächenaufnahmen.
- Das Build-Skript verwendet eine lokale ad-hoc-Signatur; `codesign --verify --deep --strict` war erfolgreich. Keine Developer-ID-Notarisierung. Die interne Version ist 1.4 (build 5); die App-Datei heißt weiterhin `FolioPDF.app`.

## Funktionstests

`bash scripts/test.sh` wurde ausgeführt; alle 58 XCTest-Tests bestanden. Die vollständige Ausgabe ist in `test-results.txt` gespeichert. Auch die echten Vision-OCR-Tests wurden ohne Überspringen ausgeführt.

| Bereich | Anzahl | Geprüfte Inhalte |
|---|---:|---|
| Materialsuche und Sortierung | 3 | Numerische Sortierung, E-Book-Präfixe, Unterordner und Ausschluss des obersten Ordners, doppelte Pfade |
| PDF-Konvertierung | 10 | Seitengeometrie und ungültige Parameter, EXIF-Ausrichtung, mehrseitige TIFF/GIF, Metadaten und Lesezeichen, Gruppierung nach Ordnern, Schutz vor Überschreiben, teilweise Stapelfehler, echte JPEG-Kodierung, Erhalt des ursprünglichen JPEG-Datenstroms, unsichtbarer und durchsuchbarer Vision-Text, Bereinigung bei Abbruch |
| JPEG-XL-Eingabe | 8 | Zuordnung nativer Typen und Dateiendungen, Ordnererkennung, verlustbehaftetes/verlustfreies RGB, RGBA-Transparenz, 16-Bit-Graustufen, Miniaturen und Vorschau, PDF-Abmessungen und Darstellung, transparente Ausgabe/weißer Hintergrund, Animationsausgabe anhand der vom System bereitgestellten Bilder, Ablehnung beschädigter und fehlender Dateien |
| Lesezeichen und Schnittstellendateien | 8 | Mehrstufige Gliederung, BasePage-Umrechnung, ungültige Ziele, Standardaktionen und JSON, ausdrückliches Ablehnen externer Ziele, UTF-16-Schnittstelle und abschnittsweise Seitennummerierung, Speichern als Kopie, durchsuchbare Textseiten, Erhalt vorhandener Seitenlabels |
| Lokalisierung | 3 | 16 Sprachen und ihre Reihenfolge, vollständiges Laden der Ressourcen, 18 Zuordnungen regionaler Sprachvarianten, Rückfall bei unbekannten Sprachen, Vorrang manueller Auswahl, RTL nur für Arabisch |
| Native PDF-Verschlüsselung | 14 | Tatsächliches AESV2-/128-Bit-Dictionary, nur Öffnungs-/nur Bearbeitungs-/zwei Passwörter, getrennte reader-/owner-Rechte, kein Rechtegewinn durch falsche Passwörter, unterschiedliche Passwörter, zufälliger owner, Längengrenzen für ein oder zwei Passwörter, Abweisung zu langer Öffnungspasswörter vor dem Schreiben, führende/nachgestellte Leerzeichen, chinesische Metadaten, Lesezeichen, unsichtbarer Text, normale abschnittsweise Seitenlabels und Layout, ausdrückliches Ablehnen von Textpräfixen, Schutz vor Überschreiben und Bereinigung bei Fehlern |
| Integration der verschlüsselten Konvertierung | 7 | Gemeinsame PDF sowie Ausgabe pro Datei und Ordner, automatische Nummerierung, unveränderte Quelldateien, keine Ausgabe bei ungültigen Passwörtern, Erhalt von Berechtigungen und Metadaten bei zwei Passwörtern, echte Vision-OCR-Suche und unveränderte Darstellung, deterministischer Abbruch während der Konvertierung und Ordnerbereinigung |
| Zustand der Verschlüsselungsoberfläche | 5 | Passwörter und Bestätigungen für beide Gruppen, unabhängiges Leeren beim Ausschalten, Sitzungsisolation und Zurücksetzen, vollständiger Export und Seitenzahlen im Verlauf in allen drei Modi, keine Passwörter in Einstellungen, Verlauf oder Protokollen |

Die OCR-Tests verwenden tatsächlich erzeugte Textbilder, prüfen die Extraktion des PDF-Texts und stellen sicher, dass unsichtbarer Text die Seitendarstellung nicht verändert. Die Tests müssen Zugriff auf macOS-Systemdienste haben. CoreVideo-Fehler einer eingeschränkten Ausführungs-Sandbox gelten nicht als bestandene Prüfung.

### Abnahmekriterien für zwei Passwörter

| Modus | Normaler Leser | Inhaber des Bearbeitungspassworts |
|---|---|---|
| Nur Öffnungspasswort | Leeres oder falsches Passwort öffnet die Datei nicht; das richtige Öffnungspasswort erlaubt alle Aktionen | Kein separates Bearbeitungspasswort eingerichtet |
| Nur Bearbeitungspasswort | Lesen ohne Passwort; Änderungen am Inhalt, Anmerkungen, Formularausfüllen und Seitenorganisation sind untersagt | Das Bearbeitungspasswort gewährt volle owner-Rechte |
| Beide Passwörter | Das Öffnungspasswort gewährt eingeschränkte user-Rechte | Das Bearbeitungspasswort öffnet die Datei direkt und gewährt volle owner-Rechte |

Beide Passwörter müssen unterschiedlich sein. Drucken, Kopieren und barrierefreier Zugriff sind in allen drei Modi erlaubt. Der eingeschränkte Modus deaktiviert Inhaltsänderungen, Anmerkungen, Formularausfüllen und das Einfügen, Löschen oder Drehen von Seiten. Der Reader muss die Berechtigungen beachten; sie garantieren keine absolute Unveränderbarkeit.

Akzeptiert werden nur druckbare ASCII-Zeichen. Der sicher unterstützte Bereich ist: nur Öffnungspasswort 1–32 Zeichen; nur Bearbeitungspasswort 1–32 Zeichen; bei zwei Passwörtern Öffnungspasswort 1–16 Zeichen und Bearbeitungspasswort 1–32 Zeichen. Die bedingte Grenze wird in der Oberfläche angezeigt und vor dem Export geprüft. Überschreitungen führen zu einem Fehler; es gibt weder Abschneiden noch Änderung von Rand-Leerzeichen oder eine Ausgabe mit schwächerem Schutz.

Bei einer bereits geöffneten PDF kann `unlock(withPassword:)` auch mit falschem owner-Passwort `true` zurückgeben. Deshalb prüft die Abnahme `permissionsStatus` und alle Berechtigungsbits: eingeschränkter reader user/51, owner owner/255 und reader bei ausschließlichem Öffnungspasswort user/255. PDFs mit ausschließlich Bearbeitungspasswort öffnen sich automatisch; für die Seitenzahl im Verlauf ist keine owner-Freigabe nötig.

## Oberfläche und Sprachen

- Es gibt 292 Ressourcentexte × 16 Sprachen und 281 tatsächlich verwendete Oberflächentexte. `check-localization.py` bestand; die Sprachressourcen im Paket sind bytegleich mit den Quelldateien.
- Standardmäßig gilt die Systemsprache. Die Reihenfolge entspricht der Vorgabe: 简体中文, English, 繁體中文, 日本語, 한국어, Français, Deutsch, Español, Italiano, Português (Brasil), Русский, العربية, हिन्दी, Türkçe, Nederlands, Polski.
- Haupt- und Einstellungsfenster verwenden für Arabisch RTL. Dateinamen, Bilder und PDF-Inhalte bleiben unverändert. Der TAB-Texteditor für Lesezeichen bleibt LTR, damit sich die Bedeutung der Schnittstellendateien beim Bearbeiten nicht ändert.
- Die App wurde erneut gestartet und ihre echte NSView gerendert. Geprüft wurden Chinesisch im hellen Modus mit anfangs eingeklapptem und aufgeklapptem Zweipasswortbereich, lange deutsche Texte im dunklen Modus, arabisches RTL und ausschließlich Bearbeitungspasswort. Felder und Hinweise umbrechen korrekt; keine Überlagerungen oder fehlenden Zeichen wurden beobachtet. Inhalte außerhalb des sichtbaren Bereichs scrollen mit der rechten Seitenleiste. Aufnahmen stehen unten.
- Kopfzeilen wie „Dokumentinformationen“, „PDF-Verschlüsselung“ und „Ränder und Auflösung“ verwenden jeweils einen Button über die ganze Zeile. Nach dem Ausdehnen des Labels auf volle Breite definiert ein Rechteck den Klickbereich. Auch Arbeitsbereichsnavigation und Einstellungszugang unten haben größere Klickflächen. Die Quellcodeprüfung umfasste freie Flächen und semantische RTL-Richtungen; eine separate Mausautomatisierung wurde nicht eingesetzt. Start und erneutes Öffnen des Hauptfensters der finalen App wurden geprüft; das Protokoll enthält `reopen verified: true`.
- Während der Konvertierung sind Schließen und Beenden gesperrt. Bei ungespeicherten Lesezeichen erscheint beim Schließen oder Beenden eine Nachfrage. Erneutes Öffnen behält den Sitzungsentwurf.
- Einstellungsschaltfläche und ⌘, öffnen dasselbe native Einstellungsfenster. ⌘N zeigt das Hauptfenster, ⌘O fügt Bilder hinzu, ⌘⇧O Ordner und ⌘E exportiert.
- „PDF-Verschlüsselung“ ist ein eigener Abschnitt nach „Dokumentinformationen“ im rechten Einstellungsbereich, anfangs eingeklappt und gemeinsam scrollbar. Aufklappen zeigt beide Passwortgruppen direkt, ohne Popover. Jede Gruppe hat einen eigenen Schalter, ein maskiertes Passwortfeld und eine Bestätigung.
- Ausschalten einer Gruppe löscht nur ihr Passwort und ihre Bestätigung; Zurücksetzen löscht beide. Ungültige Passwörter, nicht übereinstimmende Bestätigungen oder identische Passwörter verhindern den Export. Sind beide Gruppen aus, entsteht eine normale PDF. Auf- und Zuklappen verändert den Schutz nicht.
- Beide Passwörter bleiben nur im aktuellen Prozess und werden weder in Einstellungen noch Verlauf oder Protokollen gespeichert. Unverschlüsselte Zwischendateien eines geschützten Exports liegen in einem Ordner mit Berechtigung 0700 und werden bei regulärem Abbruch oder Fehler entfernt. Veröffentlicht werden nur Dateien, die die Modusprüfung bestehen; bei Fehlern gibt es keinen Rückfall auf unverschlüsselte Ausgabe.
- OCR-Sprachen hängen weiterhin von der lokalen Vision-Unterstützung ab. Aus der Zahl der Oberflächensprachen wird keine OCR-Sprachzahl abgeleitet.

## Grenzen der Validierung

- Die Prüfmaschine ist ein Intel Mac. Beide Architekturen des universellen 1.4-Pakets wurden erfolgreich gebaut; ein Test auf echter Apple-Silicon-Hardware steht aus.
- Minimales Deploymentziel ist macOS 14; tatsächlich ausgeführt wurde auf macOS 15.7.9.
- JPEG XL wird nativ durch ImageIO dekodiert. 5 selbst erzeugte Testdateien decken verlustbehaftetes RGB, verlustfreies RGB, RGBA-Transparenz, 16-Bit-Graustufen und Animation ab. Das aktuelle System liefert nur das erste Animationsbild zurück; daher wird kein Import aller Einzelbilder garantiert. Die App bietet keine JXL-Kodierung als Ausgabe und garantiert nicht, dass der ursprüngliche Bitstrom, HDR-Informationen oder Informationen mit hoher Bittiefe unverändert in der PDF erhalten bleiben.
- Es gibt keinen Leistungsbenchmark für sehr große gescannte Bücher und keine Zusage für jedes Kamera-RAW-Format oder jedes nicht standardisierte PDF-Ziel.
- Die Verschlüsselung verwendet Apple PDFKit, verlangt AESV2/128 Bit und prüft Passwörter und Berechtigungen passend zum Modus. Das lokale Problem bei Öffnungspasswörtern mit 17–31 Zeichen betrifft die owner-Authentifizierung. Deshalb ist das Öffnungspasswort bei zwei Passwörtern einheitlich auf 1–16 Zeichen begrenzt; Bearbeitungspasswörter sowie beide Einpasswortmodi unterstützen 1–32 Zeichen. Die App korrigiert kryptografische Ergebnisse nicht selbst. Unicode, Steuerzeichen und für den gewählten Modus zu lange Eingaben werden abgewiesen. Grenzprüfungen, owner-Rechte und Rand-Leerzeichen sind durch echte Dateitests abgedeckt; Öffnungspasswörter mit 17, 31 und 32 Zeichen werden im Zweipasswortmodus vor dem Schreiben abgewiesen.
- Seitenlabels mit eigenen Textpräfixen können über den aktuellen nativen Weg nicht zuverlässig erhalten bleiben und führen bei Verschlüsselung zu einer ausdrücklichen Fehlermeldung. Normale alphabetische, römische und numerische Abschnitte, Leselayout und Metadaten sind durch Rundlauftests abgedeckt. Für PDFs mit Öffnungspasswort kann dieses in der App-Vorschau eingegeben werden; PDFs mit ausschließlich Bearbeitungspasswort lassen sich direkt ansehen. Lesezeichenbearbeitung verschlüsselter Dateien bleibt ausgeschlossen.
- Aktuelle Einschränkungen, darunter fehlende JBIG2/G4-Kodierung, OCR-Korrekturwerkzeuge, Schnittstellenebenen und bestimmte spezielle Lesezeichenziele, stehen im Abschnitt „Aktuelle Einschränkungen“ der Projekt-README.

## Aufnahmen dieser Version

| Zustand | Aufnahme des tatsächlichen Fensters |
|---|---|
| Chinesisch, Import statischer JPEG-XL-Bilder | [jpeg-xl-import-zh.png](../screenshots/jpeg-xl-import-zh.png) |
| Chinesisch, Verschlüsselung anfangs eingeklappt | [encryption-collapsed-zh.png](../screenshots/encryption-collapsed-zh.png) |
| Chinesisch, beide Passwortgruppen aufgeklappt | [encryption-inline-zh.png](../screenshots/encryption-inline-zh.png) |
| Deutsch, dunkler Modus, beide Passwortgruppen aufgeklappt | [encryption-inline-de-dark.png](../screenshots/encryption-inline-de-dark.png) |
| Arabisch, RTL, beide Passwortgruppen aufgeklappt | [encryption-inline-ar.png](../screenshots/encryption-inline-ar.png) |
| Finale universelle App, Chinesisch, nur Bearbeitungspasswort und erneutes Öffnen des Fensters | [encryption-editing-only-zh.png](../screenshots/encryption-editing-only-zh.png) |

Die Aufnahmen stammen aus dem Rendering der eigenen `NSView` der App und enthalten keine Inhalte anderer Anwendungen. `build-results.txt` protokolliert den Produktionsbuild beider Architekturen. `SHA256SUMS-1.4.txt` unter [Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.4.0) enthält die Prüfsummen der Vertriebs-ZIPs. Aufnahmen der alten Anordnung wurden nach `screenshots/previous-layout/` verschoben und gelten nicht als Oberflächennachweis dieser Version.

Die ursprünglichen Test-, Build- und Aufnahmeprotokolle werden von Werkzeugen erzeugt. Ihre Ausgabe bleibt erhalten; lokale Projektpfade werden durch `<project>` ersetzt. Übersetzte Protokolle werden nicht als Originalbelege ausgegeben. Alle 16 Sprachfassungen dieses Berichts erläutern dieselben Testergebnisse, Umgebungen und Grenzen. Das Quellcode-Repository enthält keine Build-Caches oder Vertriebsbinärdateien; die Pakete können aus den Releases des Repositorys heruntergeladen werden.
