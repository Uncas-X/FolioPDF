# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · **Nederlands** · [Polski](README.pl.md)
<!-- languages:end -->

Een native macOS-app om van afbeeldingen boeken te maken en PDF-bladwijzers te bewerken. Opnieuw ontwikkeld op basis van de productvereisten van FreePic2Pdf, met een eigen SwiftUI-interface en Apple-systeemframeworks. Geen runtime van derden, geen uploads naar het netwerk en geen API-sleutel nodig.

## Gebruik

Download `FolioPDF-1.3-macOS.zip` via [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest), pak het bestand uit en open `FolioPDF.app`. Je kunt de app ook naar de map ‘Apps’ slepen. **macOS 14 of nieuwer** is vereist. Een lokaal gebouwde app staat in `dist/FolioPDF.app`.

Versie 1.3 wordt geleverd als `FolioPDF-1.3-macOS.zip` en `FolioPDF-1.3-source.zip`. De app in de ZIP heet altijd `FolioPDF.app`. Het [validatieverslag](../validation/VALIDATION.nl.md) beschrijft de validatiestatus en testomgeving en bevat echte schermafbeeldingen. De broncoderepository bevat geen buildcache of app-binaries; installatiepakketten staan in Releases.

1. Voeg in ‘PDF maken’ afbeeldingen toe, sleep bestanden naar het venster of voeg een of meer mappen toe. Kies vóór het importeren in de instellingen rechts of submappen moeten worden doorzocht.
2. Klik op een afbeelding om deze te selecteren; gebruik Command-klik voor meerdere afbeeldingen. Sleep een afbeelding op een andere om de volgorde te wijzigen, of gebruik de knoppen voor vooruit/achteruit onderaan. Dubbelklik voor een voorvertoning. Je kunt schakelen tussen miniaturen en een lijst.
3. Kies rechts één samengevoegde PDF, een PDF per bronbestand of een PDF per map. Stel papier, marges, DPI, compressie, OCR en documentinformatie in.
4. Voor wachtwoordbeveiliging scrol je in het rechter instellingenpaneel naar ‘PDF-versleuteling’, na ‘Documentgegevens’. Dit onderdeel is standaard ingeklapt; na uitklappen zijn de instellingen direct zichtbaar. ‘Openingswachtwoord’ en ‘Bewerkingswachtwoord’ hebben elk een eigen schakelaar. Vul na inschakelen het betreffende wachtwoord en de bevestiging in. De onderstaande tabel beschrijft de rechten. Elke PDF in een batch gebruikt dezelfde instellingen.
5. Klik op ‘PDF maken’. Bestaande uitvoerbestanden worden niet overschreven; bij een naamconflict wordt automatisch een genummerde bestandsnaam gebruikt. Elke pagina of elk frame van een TIFF/GIF met meerdere pagina’s wordt achtereenvolgens een PDF-pagina. ‘Eén PDF per afbeeldingsbestand’ splitst één bronbestand niet op in meerdere PDF’s.
6. In de werkruimte ‘Bladwijzers’ kun je een niet-versleutelde PDF openen, inhoudsopgaven toevoegen, bewerken, verplaatsen en inspringen, bestemmingen in de voorvertoning bekijken, TXT, JSON of compatibele interfacebestanden importeren en exporteren, en ten slotte een kopie opslaan.

De volledige kopregel van inklapbare onderdelen zoals ‘Documentgegevens’, ‘PDF-versleuteling’ en ‘Marges en resolutie’ is klikbaar, inclusief de lege ruimte naast de titel. Ook de werkruimtenavigatie links reageert op de hele rij. ‘PDF-versleuteling’ is standaard ingeklapt en scrolt na uitklappen mee met het rechter instellingenpaneel.

⌘N toont het hoofdvenster, ⌘O voegt afbeeldingen toe, ⌘⇧O voegt mappen toe, ⌘E exporteert en ⌘, opent de instellingen. Het sluiten en opnieuw openen van het hoofdvenster behoudt de huidige sessie. Bij het afsluiten van de app worden bladwijzerconcepten niet automatisch opgeslagen; sla eerst een kopie op.

### Openingswachtwoord en bewerkingswachtwoord

| Ingeschakelde beveiliging | Wachtwoordlengte | Lees- en bewerkingsrechten |
|---|---|---|
| Alleen openingswachtwoord | Openingswachtwoord: 1–32 tekens | Een wachtwoord is vereist om de PDF te openen. Na openen met het juiste wachtwoord zijn alle bewerkingen toegestaan |
| Alleen bewerkingswachtwoord | Bewerkingswachtwoord: 1–32 tekens | Lezen kan zonder wachtwoord. Gewone lezers mogen de inhoud niet wijzigen, annotaties maken, formulieren invullen of pagina’s invoegen, verwijderen of draaien. Het bewerkingswachtwoord geeft alle rechten |
| Beide wachtwoorden | Openingswachtwoord: 1–16 tekens; bewerkingswachtwoord: 1–32 tekens | Het openingswachtwoord geeft beperkte leesrechten. Het bewerkingswachtwoord geeft alle rechten en kan de PDF ook rechtstreeks openen |

Wanneer beide wachtwoorden zijn ingeschakeld, moeten ze verschillen. Afdrukken, kopiëren en toegankelijkheid zijn altijd toegestaan. Bewerkingsbeperkingen werken alleen als de PDF-lezer de ingestelde rechten respecteert; ze garanderen niet dat de inhoud onmogelijk kan worden gewijzigd.

Alleen afdrukbare ASCII-tekens zijn toegestaan: Engelse letters, cijfers, symbolen en spaties. De lengtelimieten staan in de tabel. Bij gebruik van beide wachtwoorden toont de interface de limiet van 16 tekens voor het openingswachtwoord. Te lange wachtwoorden worden vóór export geweigerd, zonder afkappen of automatisch verwijderen van spaties aan het begin of einde.

Wachtwoorden blijven alleen tijdens de huidige app-sessie in het geheugen en worden niet in instellingen, geschiedenis of logs opgeslagen. Het uitschakelen van een wachtwoord wist dat wachtwoord en de bevestiging; het herstellen van de instellingen wist beide groepen. Ongeldige wachtwoorden of bevestigingen blokkeren de export. Als beide schakelaars uitstaan, wordt een gewone PDF geëxporteerd.

De interfacetaal volgt standaard het systeem. In de instellingen kun je zonder herstart op elk moment een van deze **16 talen** kiezen:

简体中文 · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · **Nederlands** · Polski

Arabisch gebruikt een interface van rechts naar links. Afbeeldingen en PDF-inhoud blijven ongewijzigd; de TAB-teksteditor voor bladwijzers behoudt de structuur van links naar rechts. Het uiterlijk kan het systeem volgen of licht of donker zijn. macOS-componenten zoals bestandskiezers gebruiken de systeemtaal. De interfacetaal en OCR-herkenningstaal worden afzonderlijk ingesteld; de beschikbare OCR-talen hangen af van Vision op deze Mac.

## Geïmplementeerde functies

| Functie | Implementatie |
|---|---|
| Afbeeldingen importeren | JPEG, PNG, TIFF, GIF, BMP, HEIC/HEIF, JPEG 2000 en andere formaten die ImageIO kan decoderen. Andere door het systeem ondersteunde extensies worden dynamisch ontdekt. RAW-ondersteuning hangt af van de lokale systeemdecoder; niet alle cameramodellen zijn gegarandeerd |
| Bestanden organiseren | Duplicaten verwijderen, sorteren op bestandsnaam of laatste getal, handmatige volgorde, sorteren op gangbare e-bookvoorvoegsels, submappen doorzoeken en de hoofdmap wel of niet meenemen |
| Batchuitvoer | Eén samengevoegde PDF, één PDF per bronbestand of één PDF per directe bovenliggende map. Diepere mappen worden afzonderlijk gegroepeerd; afbeeldingen uit onderliggende mappen worden niet nogmaals bij de bovenliggende map geteld |
| Pagina’s | Originele afbeeldingsgrootte, vaste breedte, A3/A4/A5/B5/Letter/Legal, aangepaste afmetingen in millimeters, liggend formaat, vier marges, kleine afbeeldingen vergroten en voorrang voor DPI-metadata |
| Compressie | Verliesloze verwerking en JPEG-kwaliteitsregeling. JPEG’s met de normale oorspronkelijke oriëntatie kunnen hun oorspronkelijke DCT-datastroom behouden. Andere formaten en oriëntaties worden via ImageIO correct gedecodeerd en geplaatst; behoud van de datastroom byte voor byte wordt niet voor elk bronformaat beloofd |
| Transparantie | Transparantie behouden of een witte achtergrond gebruiken. JPEG kan geen alfa opslaan; bij behoud van transparantie wordt automatisch verliesloze codering gebruikt, met een toelichting |
| OCR | Nauwkeurige lokale herkenning met Apple Vision, met automatische of handmatige keuze uit lokaal ondersteunde talen. Maakt verborgen tekst die kan worden doorzocht en gekopieerd. Als de GPU-verwerking mislukt, wordt de CPU geprobeerd. Pagina’s waarop herkenning mislukt behouden hun afbeelding en worden expliciet gemeld |
| Documenteigenschappen | Titel, auteur, onderwerp en trefwoorden; leesindelingen voor één pagina, doorlopend of twee pagina’s |
| PDF-versleuteling | Native PDFKit AES-128, met onafhankelijk openingswachtwoord, bewerkingswachtwoord of beide. Met alleen een openingswachtwoord wordt een willekeurig owner-wachtwoord gegenereerd. Een ingesteld bewerkingswachtwoord verleent volledige owner-rechten. Publicatie volgt pas na controle van vergrendeling, wachtwoorden, reader-/owner-rechten en paginatal voor de gekozen modus. Bij fouten wordt geen onversleuteld alternatief geëxporteerd. De voorvertoning in de app ondersteunt wachtwoordinvoer |
| Bladwijzers | Automatische bronbestandbladwijzers, geneste inhoudsopgaven, paginanummers, omrekening met een basispagina, bewerkbare tekst en JSON, en native PDF-voorvertoning van bestemmingen |
| Interfacecompatibiliteit | `FreePic2Pdf.itf` en `FreePic2Pdf_bkmk.txt`, UTF-8/UTF-16LE en relevante oudere coderingen; afzonderlijke paginanummering voor inhoudsopgave en hoofdtekst, metadata, toevoegen van doorzoekbare tekstpagina’s en weergave-instellingen voor bladwijzers |
| Stabiliteit | Achtergrondtaken, vrijgeven van afbeeldingen per pagina, voortgang, annuleren, logs, tijdelijke bestanden en atomair publiceren, automatische nummering bij naamconflicten, en behoud en opsomming van voltooide resultaten als een batch tussentijds mislukt |

### Expliciete verschillen met de oude versie

- OCR gebruikt Apple Vision in plaats van MODI. Office of Windows is niet nodig. De oude opties voor het opruimen van diagrammen, CJK-lettertypen en herkenning per teken of regel zijn niet overgenomen.
- De huidige compressieopties zijn verliesloos en JPEG. JBIG2-, CCITT G4- en JPEG 2000-encoders zijn niet opnieuw geïmplementeerd. De kernfuncties werken, maar omvangrijke zwart-witboeken kunnen groter uitvallen dan met gespecialiseerde JBIG2-tools.
- De oude correctietools om OCR-tekst te tonen/verbergen of scanbeelden fysiek te verwijderen ontbreken. Er is ook geen beeldherstel of volledige editor voor PDF-inhoud.
- De meerlaagse samenstelling via `[Images]` en `MinWidth` in compatibele interfacebestanden zijn nog niet geïmplementeerd. Bij detectie volgt een melding; de app beweert niet dat ze zijn toegepast. Als de handmatige bestandsvolgorde niet overeenkomt met absolute paginanummers uit het interfacebestand, moet de gebruiker de bladwijzerbestemmingen controleren.
- Gewone lokale paginanummers, sommige standaard benoemde acties en URL-bestemmingen werken. Externe PDF-bestemmingen die PDFKit niet betrouwbaar kan opslaan en niet-oplosbare benoemde of speciale bestemmingen worden expliciet gemarkeerd en niet stilzwijgend opgeslagen. Je kunt ze in de editor vervangen door geldige lokale paginanummers. JSON/TXT kunnen bestemmingsgegevens bewaren. Versleutelde PDF’s kunnen niet op bladwijzers worden bewerkt.
- Versleuteling behoudt bladwijzers, OCR-tekst, metadata, leesindeling en gewone paginanummering in secties. Native PDFKit behoudt geen paginalabels; de app herstelt alleen labels zonder tekstvoorvoegsels op een veilige manier. Interfacebestanden met aangepaste tekstvoorvoegsels blokkeren versleutelde export expliciet. Verwijder de voorvoegsels of schakel versleuteling uit.
- ‘E-bookvolgorde’ gebruikt de gangbare groepen cov, bok, leg, fow, !, toc, numerieke hoofdtekst, att, ins en bac; de overige komen daarna. Er wordt niet beweerd dat dit exact overeenkomt met de niet-gepubliceerde regels van de oude software.
- Bij annuleren of een fout blijven al gemaakte PDF’s uit de batch behouden. De nog onvoltooide tijdelijke PDF wordt verwijderd. Hervatten vanaf een onderbrekingspunt wordt niet ondersteund.

## Ontwikkeling en bouwen

De broncode is een Swift Package. Open `Package.swift` in Xcode. Xcode met de macOS SDK en Swift 5.9 of nieuwer zijn vereist. De validatieomgeving is macOS 15.7.9 / Xcode Swift 6.2.4; het compatibiliteitsdoel is macOS 14.

```sh
# In debugmodus uitvoeren
swift run FolioPDF

# Tests en controle van de 16 interfacetalen
bash scripts/test.sh

# Universele .app en ZIP voor Intel + Apple Silicon bouwen
bash scripts/build-app.sh

# Alleen voor de architectuur van deze machine bouwen
bash scripts/build-app.sh --host-only
```

De echte OCR-tests in `scripts/test.sh` vereisen normale toegang tot macOS-diensten zoals Vision en CoreVideo. In een uitvoeringssandbox die hardware of systeemdiensten beperkt, kan het aanmaken van een CVPixelBuffer mislukken. In een normale systeemomgeving moeten de tests worden uitgevoerd en slagen; overslaan vervangt geen validatie.

De app wordt lokaal ad-hoc ondertekend en bevat geen Developer ID-notarisatie. Ze kan lokaal worden uitgevoerd. Voor formele distributie naar andere Macs zijn een ontwikkelaarscertificaat en notarisatie nodig.

### Code-indeling

```text
Sources/FolioCore/       Afbeeldingen, geometrie, conversie, OCR, bladwijzers en interfacebestanden
Sources/FolioPDF/        SwiftUI-werkruimten, statusbeheer, native voorvertoning en talen
Tests/FolioCoreTests/    Tests met echte afbeeldingen/PDF/OCR, bladwijzerrondgangen en grensgevallen
scripts/                Tests, pakketten, pictogrammen en voorbeeldafbeeldingen genereren
packaging/Info.plist     macOS-appinformatie
docs/                   Validatieverslagen en gerenderde echte vensters
dist/                   Uitvoerbare .app en distributie-ZIP’s (gegenereerd bij bouwen)
```

## Documentatietalen

De README en het validatieverslag zijn beschikbaar in dezelfde 16 talen als de interface. Wissel via de taallinks bovenaan de documenten. Functies, wachtwoordlimieten, bekende verschillen en bouwstappen zijn in alle taalversies gelijk. Test-, build- en vensterscreenshotlogs zijn machinaal gegenereerd bronmateriaal en behouden de oorspronkelijke tooluitvoer. Het validatieverslag biedt de toelichtingen in meerdere talen.

## Technische basis

Gebruikt Apples [Vision-interface voor taaldetectie](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage), [PDFKit-documenteigenschappen](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) en [ImageIO-parameter voor JPEG-kwaliteit](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality). De implementatie is daarnaast gecontroleerd aan de hand van lokale SDK-declaraties en tests met echte bestanden. Het oorspronkelijke FreePic2Pdf-programma, de pictogrammen en de oude interface zijn niet gekopieerd.
