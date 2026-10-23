# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · **Deutsch** · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- languages:end -->

Eine native macOS-App zum Erstellen von PDF-Büchern aus Bildern und zum Bearbeiten von PDF-Lesezeichen. Sie setzt die Produktanforderungen von FreePic2Pdf neu um, mit einer eigenständig gestalteten SwiftUI-Oberfläche und Apple-Systemframeworks. Keine Laufzeitumgebung von Drittanbietern, keine Uploads ins Netzwerk und kein API-Schlüssel erforderlich.

## Verwendung

Laden Sie `FolioPDF-1.3-macOS.zip` von [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest) herunter, entpacken Sie die Datei und öffnen Sie `FolioPDF.app`. Sie können die App auch in den Ordner „Programme“ ziehen. Erforderlich ist **macOS 14 oder neuer**. Ein lokal gebautes Programm liegt unter `dist/FolioPDF.app`.

Die Pakete für Version 1.3 heißen `FolioPDF-1.3-macOS.zip` und `FolioPDF-1.3-source.zip`; die Anwendung im ZIP heißt immer `FolioPDF.app`. Der [Validierungsbericht](../validation/VALIDATION.de.md) enthält den Prüfstatus, die Laufzeitumgebung und Aufnahmen der tatsächlichen Oberfläche. Das Quellcode-Repository enthält weder Build-Caches noch Anwendungsbinärdateien; Installationspakete sind unter Releases verfügbar.

1. Fügen Sie im Arbeitsbereich „PDF erstellen“ Bilder hinzu, ziehen Sie Dateien hinein oder wählen Sie einen oder mehrere Ordner. Die rekursive Ordnersuche wird rechts in den Einstellungen vor dem Import aktiviert.
2. Klicken Sie auf ein Bild, um es auszuwählen; mit gedrückter Command-Taste wählen Sie mehrere aus. Ziehen Sie ein Bild auf ein anderes, um die Reihenfolge zu ändern, oder verwenden Sie unten die Schaltflächen zum Vor- und Zurückverschieben. Ein Doppelklick öffnet die Vorschau. Sie können zwischen Miniaturansicht und Liste wechseln.
3. Wählen Sie rechts eine gemeinsame PDF, eine PDF pro Quelldatei oder eine PDF pro Ordner. Passen Sie Papier, Ränder, DPI, Komprimierung, OCR und Dokumentinformationen an.
4. Für den Passwortschutz scrollen Sie im rechten Einstellungsbereich nach unten und öffnen den Abschnitt „PDF-Verschlüsselung“ hinter „Dokumentinformationen“. Er ist anfangs eingeklappt und zeigt seine Einstellungen direkt nach dem Aufklappen. „Passwort zum Öffnen“ und „Passwort zum Bearbeiten“ haben getrennte Schalter. Tragen Sie für jede aktivierte Option das Passwort und seine Bestätigung ein; die Berechtigungen stehen in der folgenden Tabelle. Alle PDFs eines Stapels verwenden diese Einstellungen.
5. Klicken Sie auf „PDF erstellen“. Vorhandene Ausgabedateien werden nicht überschrieben; bei Namenskonflikten wird automatisch eine neue Datei mit Nummer angelegt. Jede Seite bzw. jedes Einzelbild einer mehrseitigen TIFF-/GIF-Datei wird der Reihe nach zu einer PDF-Seite. „Eine PDF pro Bilddatei“ teilt dieselbe Quelldatei nicht auf mehrere PDFs auf.
6. Im Arbeitsbereich „Lesezeichen“ können Sie unverschlüsselte PDFs öffnen, Gliederungseinträge hinzufügen, bearbeiten, verschieben und einrücken, Sprungziele in der Vorschau prüfen, TXT, JSON oder kompatible Schnittstellendateien importieren und exportieren und das Ergebnis als Kopie speichern.

Die gesamte Kopfzeile aufklappbarer Abschnitte wie „Dokumentinformationen“, „PDF-Verschlüsselung“ und „Ränder und Auflösung“ ist anklickbar, einschließlich des freien Bereichs neben dem Titel. Auch die Arbeitsbereichsnavigation links reagiert auf Klicks in der ganzen Zeile. „PDF-Verschlüsselung“ ist anfangs eingeklappt und scrollt aufgeklappt mit dem rechten Einstellungsbereich.

⌘N zeigt das Hauptfenster, ⌘O fügt Bilder hinzu, ⌘⇧O fügt Ordner hinzu, ⌘E exportiert und ⌘, öffnet die Einstellungen. Beim Schließen und erneuten Öffnen des Hauptfensters bleibt die aktuelle Sitzung erhalten. Beim Beenden der App werden Lesezeichenentwürfe nicht automatisch gespeichert; speichern Sie zuvor eine Kopie.

### Öffnungs- und Bearbeitungspasswort

| Aktivierung | Passwortlänge | Lese- und Bearbeitungsrechte |
|---|---|---|
| Nur Öffnungspasswort | Öffnungspasswort: 1–32 Zeichen | Zum Öffnen der PDF ist ein Passwort erforderlich. Nach Eingabe des richtigen Passworts sind alle Aktionen erlaubt |
| Nur Bearbeitungspasswort | Bearbeitungspasswort: 1–32 Zeichen | Lesen ist ohne Passwort möglich. Änderungen am Inhalt, Anmerkungen, das Ausfüllen von Formularen sowie Einfügen, Löschen und Drehen von Seiten sind für normale Leser eingeschränkt. Das Bearbeitungspasswort gewährt volle Rechte |
| Beide Passwörter | Öffnungspasswort: 1–16 Zeichen; Bearbeitungspasswort: 1–32 Zeichen | Das Öffnungspasswort gewährt eingeschränkte Leserrechte. Das Bearbeitungspasswort gewährt volle Rechte und kann die PDF auch direkt öffnen |

Wenn beide Passwörter aktiviert sind, müssen sie unterschiedlich sein. Drucken, Kopieren und barrierefreier Zugriff bleiben erlaubt. Bearbeitungseinschränkungen setzen voraus, dass der PDF-Reader die Berechtigungen beachtet; sie garantieren keine absolute Unveränderbarkeit.

Passwörter dürfen nur druckbare ASCII-Zeichen enthalten: lateinische Buchstaben ohne Akzente, Zahlen, Symbole und Leerzeichen. Es gelten die Längen aus der Tabelle. Bei zwei aktivierten Passwörtern weist die Oberfläche auf die Grenze von 16 Zeichen für das Öffnungspasswort hin. Zu lange Eingaben werden vor dem Export abgewiesen; Passwörter werden weder abgeschnitten noch automatisch von führenden oder nachgestellten Leerzeichen bereinigt.

Passwörter bleiben ausschließlich in der aktuellen App-Sitzung und werden nicht in Einstellungen, Verlauf oder Protokollen gespeichert. Das Ausschalten einer Option löscht ihr Passwort und die Bestätigung; das Zurücksetzen der Einstellungen löscht beide Gruppen. Ungültige Passwörter oder Bestätigungen verhindern den Export. Sind beide Optionen ausgeschaltet, wird eine normale PDF erstellt.

Die Sprache der Oberfläche folgt standardmäßig dem System. Sie können jederzeit ohne Neustart zwischen diesen **16 Sprachen** wählen:

**简体中文** · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · Nederlands · Polski

Arabisch verwendet eine Oberfläche von rechts nach links. Bilder und PDF-Inhalte bleiben unverändert; der TAB-Texteditor für Lesezeichen behält seine Struktur von links nach rechts. Das Erscheinungsbild kann dem System folgen oder hell bzw. dunkel sein. macOS-Steuerelemente wie Systemdateidialoge verwenden die Systemsprache. Oberflächen- und OCR-Sprache werden getrennt eingestellt; die OCR-Auswahl richtet sich nach der auf diesem Mac verfügbaren Vision-Unterstützung.

## Funktionsumfang

| Funktion | Umsetzung |
|---|---|
| Bildeingabe | JPEG, PNG, TIFF, GIF, BMP, HEIC/HEIF, JPEG 2000 und andere von ImageIO lesbare Formate; weitere vom aktuellen System unterstützte Dateiendungen werden dynamisch ermittelt. RAW-Unterstützung hängt vom lokalen Systemdecoder ab; nicht alle Kameramodelle sind garantiert |
| Dateiorganisation | Duplikaterkennung, Sortierung nach Dateiname oder abschließender Zahl, manuelle Reihenfolge, gängige E-Book-Präfixe, rekursive Ordnersuche und optionales Einbeziehen des obersten Ordners |
| Stapelausgabe | Eine gemeinsame PDF, eine PDF pro Quelldatei oder pro direktem übergeordnetem Ordner. Tiefere Ordner werden getrennt gruppiert; Bilder aus Unterordnern werden nicht erneut dem übergeordneten Ordner zugerechnet |
| Seiten | Originalbildgröße, feste Breite, A3/A4/A5/B5/Letter/Legal, eigene Maße in Millimetern, Querformat, vier Seitenränder, Vergrößerung kleiner Bilder und bevorzugte DPI-Metadaten |
| Komprimierung | Verlustfreier Verarbeitungspfad und JPEG-Qualitätssteuerung. Bei JPEGs mit normaler Originalausrichtung kann der ursprüngliche DCT-Datenstrom erhalten bleiben. Andere Formate und Ausrichtungen werden mit ImageIO korrekt dekodiert und angeordnet; eine bytegenaue Erhaltung aller Quelldatenströme wird nicht zugesichert |
| Transparenz | Transparenz erhalten oder weiß hinterlegen. JPEG kann keinen Alphakanal speichern; bei erhaltener Transparenz wird automatisch verlustfrei kodiert und ein Hinweis ausgegeben |
| OCR | Genaue lokale Erkennung mit Apple Vision, automatische oder manuelle Auswahl unterstützter Sprachen und unsichtbarer, durchsuchbarer und kopierbarer Text. Schlägt der GPU-Pfad fehl, wird die CPU versucht. Bei Erkennungsfehlern bleibt das Seitenbild erhalten und der Fehler wird ausdrücklich gemeldet |
| Dokumenteigenschaften | Titel, Autor, Thema und Schlüsselwörter; Einzelseiten-, fortlaufende oder Doppelseitenansicht |
| PDF-Verschlüsselung | Natives PDFKit AES-128 mit separatem Öffnungs- oder Bearbeitungspasswort oder beiden. Bei ausschließlichem Öffnungspasswort wird ein zufälliges owner-Passwort erzeugt; andernfalls gewährt das Bearbeitungspasswort volle owner-Rechte. Erst nach Prüfung von Sperrstatus, Passwörtern, reader-/owner-Rechten und Seitenzahl für den gewählten Modus wird die Datei veröffentlicht. Bei Fehlern wird keine unverschlüsselte Ersatzdatei ausgegeben. Die Vorschau in der App unterstützt die Passworteingabe |
| Lesezeichen | Automatische Lesezeichen für Quelldateien, mehrstufige Gliederung, Seitenzahlen, Umrechnung der Basisseite, bearbeitbarer Text und JSON sowie native Vorschau von PDF-Sprungzielen |
| Schnittstellenkompatibilität | `FreePic2Pdf.itf` und `FreePic2Pdf_bkmk.txt`, UTF-8/UTF-16LE und entsprechende ältere Kodierungen; getrennte Seitennummerierungsabschnitte für Inhaltsverzeichnis und Haupttext, Metadaten, angehängte durchsuchbare Textseiten und Anzeigeeinstellungen für Lesezeichen |
| Zuverlässigkeit | Hintergrundaufgaben, seitenweise Freigabe von Bildern, Fortschritt, Abbruch, Protokolle, temporäre Dateien und atomare Veröffentlichung, automatische Nummerierung bei Namenskonflikten sowie Erhalt und Auflistung fertiger Ergebnisse bei Stapelfehlern |

### Bewusste Unterschiede zur ursprünglichen Software

- OCR verwendet Apple Vision statt MODI und benötigt weder Office noch Windows. Die frühere Diagrammbereinigung, CJK-Schriften und Wort-/Zeilen-Schalter werden nicht übernommen.
- Die Komprimierung bietet derzeit verlustfrei und JPEG. JBIG2-, CCITT-G4- und JPEG-2000-Encoder wurden nicht nachgebildet. Die Kernfunktionen sind verfügbar, große Schwarzweißbücher können jedoch größer ausfallen als mit spezialisierten JBIG2-Werkzeugen.
- Die früheren Korrekturwerkzeuge zum Ein-/Ausblenden von OCR-Text oder zum physischen Löschen gescannter Bilder sind nicht enthalten. Ebenso wenig gibt es Bildrestaurierung oder einen vollständigen PDF-Inhaltseditor.
- Mehrschichtige Zusammenstellung über `[Images]` und `MinWidth` sind in der kompatiblen Schnittstelle noch nicht umgesetzt. Beim Erkennen erscheint ein Hinweis; die App behauptet nicht, diese Einstellungen angewendet zu haben. Weicht die manuelle Dateireihenfolge von absoluten Schnittstellenseitenzahlen ab, müssen die Gliederungsziele überprüft werden.
- Normale lokale Seitenziele, einige standardisierte benannte Aktionen und URL-Ziele werden unterstützt. Externe PDF-Ziele, die PDFKit nicht zuverlässig speichern kann, sowie unauflösbare benannte oder spezielle Ziele werden ausdrücklich markiert; stilles Speichern ist blockiert. Sie können im Editor in gültige lokale Seitenziele geändert werden. JSON/TXT können Zieldaten erhalten. Lesezeichen verschlüsselter PDFs lassen sich nicht bearbeiten.
- Verschlüsselung erhält Lesezeichen, OCR-Text, Metadaten, Leselayout und gewöhnliche abschnittsweise Seitennummerierung. Natives PDFKit erhält Seitenlabels nicht; die App ergänzt ausschließlich Labels ohne Textpräfix sicher wieder. Schnittstellendateien mit eigenen Textpräfixen verhindern den verschlüsselten Export ausdrücklich. Entfernen Sie die Präfixe oder deaktivieren Sie die Verschlüsselung.
- Die E-Book-Reihenfolge verwendet gängige Präfixgruppen: cov, bok, leg, fow, !, toc, numerischer Haupttext, att, ins, bac; andere folgen danach. Eine vollständige Übereinstimmung mit unveröffentlichten Regeln der Originalsoftware wird nicht behauptet.
- Bei Abbruch oder Fehler bleiben bereits erzeugte PDFs des Stapels erhalten; die aktuelle unfertige temporäre PDF wird entfernt. Eine Fortsetzung an einem gespeicherten Zwischenstand gibt es nicht.

## Entwicklung und Build

Der Quellcode ist ein Swift Package; öffnen Sie `Package.swift` in Xcode. Erforderlich sind Xcode mit macOS SDK und Swift 5.9 oder neuer. Geprüft wurde mit macOS 15.7.9 / Xcode Swift 6.2.4; das Laufzeitziel ist macOS 14.

```sh
# Im Debug-Modus starten
swift run FolioPDF

# Tests und Prüfung der Texte in 16 Sprachen
bash scripts/test.sh

# Universelle .app und ZIP für Intel + Apple Silicon erstellen
bash scripts/build-app.sh

# Nur für die Architektur dieses Macs bauen
bash scripts/build-app.sh --host-only
```

Die echten OCR-Tests in `scripts/test.sh` benötigen regulären Zugriff auf macOS-Systemdienste wie Vision und CoreVideo. In einer Ausführungs-Sandbox, die Hardware oder Systemdienste einschränkt, kann die Erstellung eines CVPixelBuffer scheitern. In einer normalen Systemumgebung müssen die Tests ausgeführt werden und bestehen; Überspringen ersetzt keine Prüfung.

Die Pakete sind lokal ad-hoc signiert und nicht mit Developer ID notarisiert. Sie können lokal ausgeführt werden; eine reguläre Veröffentlichung für andere Macs erfordert ein Entwicklerzertifikat und den Notarisierungsprozess.

### Quellcodestruktur

```text
Sources/FolioCore/       Bilder, Geometrie, Konvertierung, OCR, Lesezeichen und Schnittstellendateien
Sources/FolioPDF/        SwiftUI-Arbeitsbereiche, Zustand, native Vorschau und Sprachen
Tests/FolioCoreTests/    Echte Bild-/PDF-/OCR-/Lesezeichen-Rundlauf- und Grenztests
scripts/                Tests, Paketierung, Symbole und Beispielbilder
packaging/Info.plist     Informationen zur macOS-Anwendung
docs/                   Validierungsberichte und gerenderte echte Fenster
dist/                   Ausführbare .app und Vertriebs-ZIPs (beim Build erzeugt)
```

## Dokumentationssprachen

README und Validierungsbericht sind in denselben 16 Sprachen wie die Oberfläche verfügbar. Die Sprachlinks am Dokumentanfang ermöglichen den Wechsel. Funktionsbeschreibungen, Passwortgrenzen, bekannte Unterschiede und Build-Schritte stimmen in allen Sprachversionen überein. Test-, Build- und Fensteraufnahmeprotokolle sind maschinell erzeugte Originalbelege und bleiben in der Sprache der Werkzeuge. Die Erläuterungen im Validierungsbericht sind mehrsprachig.

## Technische Grundlagen

Die App verwendet Apples [Vision-Schnittstelle zur Spracherkennung](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage), [PDFKit-Dokumentattribute](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) und [ImageIO-Parameter für JPEG-Qualität](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality). Die Umsetzung wird zusätzlich anhand des lokalen SDK und tatsächlicher Dateitests geprüft. Das ursprüngliche FreePic2Pdf-Programm, seine Symbole und seine Oberfläche wurden nicht kopiert.
