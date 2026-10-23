# FolioPDF 1.4 — Validatieverslag

<!-- languages:start -->
[简体中文](../VALIDATION.md) · [English](VALIDATION.en.md) · [繁體中文](VALIDATION.zh-Hant.md) · [日本語](VALIDATION.ja.md) · [한국어](VALIDATION.ko.md) · [Français](VALIDATION.fr.md) · [Deutsch](VALIDATION.de.md) · [Español](VALIDATION.es.md) · [Italiano](VALIDATION.it.md) · [Português (Brasil)](VALIDATION.pt-BR.md) · [Русский](VALIDATION.ru.md) · [العربية](VALIDATION.ar.md) · [हिन्दी](VALIDATION.hi.md) · [Türkçe](VALIDATION.tr.md) · **Nederlands** · [Polski](VALIDATION.pl.md)
<!-- languages:end -->

Status: **tests en build geslaagd**. Datum: 2026-10-23. Validatieomgeving: Intel Mac, macOS 15.7.9, Swift 6.2.4 / Xcode. Minimale implementatieversie: macOS 14.

Deze versie voegt JPEG XL-invoer toe via native ImageIO-decodering op macOS 14 en nieuwer, met behoud van onafhankelijke openings- en bewerkingswachtwoorden. De versleutelingsinstellingen staan in het rechterpaneel, zijn standaard ingeklapt en hebben een volledig klikbare kopregel. Alle 58 XCTest-tests zijn volledig uitgevoerd en geslaagd: 0 mislukt, 0 overgeslagen. Er is bevestigd dat de native PDF-schrijfinterface op deze Mac bij openingswachtwoorden van 17–31 tekens het owner-wachtwoord onbruikbaar kan maken. De app voorkomt dit met een lengtecontrole vóór export in de modus met twee wachtwoorden; de veiligheidsgrenzen staan hieronder. Het log van deze testronde staat in `test-results.txt`.

## Opgeleverde bestanden

- `dist/FolioPDF.app`: native AppKit-venster, SwiftUI-interface en de systeemframeworks PDFKit / Vision / ImageIO. De app-bestandsnaam bevat geen versienummer; de versie staat in de app-metadata.
- `dist/FolioPDF-1.4-macOS.zip`: universele app met x86_64 en arm64, gecontroleerd met `lipo -archs`.
- `dist/FolioPDF-1.4-source.zip`: Swift Package-broncode die in Xcode kan worden geopend, inclusief tests, scripts, gebruiksinstructies en schermafbeeldingen.
- Het verpakkingsscript gebruikt lokale ad-hoc-ondertekening. `codesign --verify --deep --strict` is geslaagd. Developer ID-notarisatie ontbreekt. De interne versie is 1.4 (build 5); de app-bestandsnaam blijft `FolioPDF.app`.

## Functionele tests

`bash scripts/test.sh` is uitgevoerd. Alle 58 XCTest-tests zijn geslaagd; de gedetailleerde uitvoer staat in `test-results.txt`. Ook de echte Vision OCR-tests zijn uitgevoerd, zonder tests over te slaan.

| Onderdeel | Aantal | Gecontroleerd |
|---|---:|---|
| Bestandsdetectie en sortering | 3 | Numerieke sortering, e-bookvoorvoegsels, submappen en uitsluiten van de hoofdmap, dubbele paden |
| PDF-conversie | 10 | Paginageometrie en ongeldige parameters, EXIF-oriëntatie, TIFF/GIF met meerdere pagina’s, metadata en bladwijzers, groepering per map, niet overschrijven, gedeeltelijk mislukte batches, echte JPEG-codering, behoud van oorspronkelijke JPEG-datastromen, verborgen Vision-tekst en doorzoekbaarheid, opruimen bij annuleren |
| JPEG XL-invoer | 8 | Native typen en extensietoewijzing, detectie in mappen, RGB met/zonder kwaliteitsverlies, RGBA-transparantie, 16-bits grijstinten, miniaturen en voorvertoning, PDF-afmetingen en rendering, transparante uitvoer/witte achtergrond, animatie-uitvoer volgens de door het systeem beschikbare frames, weigering van beschadigde en ontbrekende bestanden |
| Bladwijzers en interfacebestanden | 8 | Geneste bladwijzers, BasePage-omrekening, ongeldige bestemmingen, standaardacties en JSON, expliciete weigering van externe bestemmingen, UTF-16-interfacebestanden en sectiepaginanummering, een kopie opslaan, doorzoekbare tekstpagina’s, behoud van bestaande paginalabels |
| Lokalisatie | 3 | De 16 talen en hun volgorde, volledig laden van resources, 18 regionale taaltoewijzingen, terugval bij onbekende talen, voorrang van handmatige taalkeuze en RTL uitsluitend voor Arabisch |
| Native PDF-versleuteling | 14 | Echte AESV2/128-bits-dictionary, alleen openen/alleen bewerken/twee wachtwoorden, scheiding van reader- en owner-rechten, geen rechtenverhoging door een verkeerd wachtwoord, vereiste verschillende wachtwoorden, willekeurige owner, lengtegrenzen voor één of twee wachtwoorden, weigeren van te lange openingswachtwoorden vóór schrijven, begin- en eindspaties, Chinese metadata, bladwijzers, verborgen tekst, gewone sectiepaginanummering en indeling, expliciete weigering van tekstvoorvoegsels, niet overschrijven en opruimen na fouten |
| Integratie van versleutelde conversie | 7 | Versleutelde samengevoegde uitvoer en uitvoer per bestand en map, automatische nummering, ongewijzigde bronbestanden, geen uitvoer met ongeldige wachtwoorden, rechten bij twee wachtwoorden en behoud van metadata, echte Vision OCR-zoekfunctie en behoud van het beeld, deterministisch annuleren tijdens conversie en opruimen van mappen |
| Interface-status voor versleuteling | 5 | Controle van beide wachtwoorden en bevestigingen, afzonderlijk wissen bij uitschakelen, sessie-isolatie en reset, volledige export in de drie modi en paginatallen in de geschiedenis, geen wachtwoorden in instellingen/geschiedenis/logs |

De OCR-tests gebruiken echt gegenereerde tekstafbeeldingen. Ze controleren dat tekst uit de uitvoer-PDF kan worden geëxtraheerd en dat verborgen tekst de gerenderde pagina niet verandert. De tests moeten toegang hebben tot macOS-systeemdiensten; CoreVideo-fouten in een beperkte uitvoeringssandbox gelden niet als geslaagde tests.

### Acceptatiecriteria voor twee wachtwoorden

| Modus | Gewone lezer | Houder van het bewerkingswachtwoord |
|---|---|---|
| Alleen openingswachtwoord | Een leeg of verkeerd wachtwoord opent het bestand niet. Het juiste openingswachtwoord geeft alle bewerkingsrechten | Geen afzonderlijk bewerkingswachtwoord ingesteld |
| Alleen bewerkingswachtwoord | Lezen zonder wachtwoord; inhoud wijzigen, annotaties maken, formulieren invullen en pagina’s ordenen zijn verboden | Het bewerkingswachtwoord geeft volledige owner-rechten |
| Beide wachtwoorden | Het openingswachtwoord geeft beperkte user-rechten | Het bewerkingswachtwoord opent het bestand rechtstreeks en geeft volledige owner-rechten |

Bij gebruik van beide wachtwoorden moeten ze verschillen. Alle drie de modi staan afdrukken, kopiëren en toegankelijkheid toe. Beperkte modi blokkeren inhoudswijzigingen, annotaties, formulieren en het invoegen, verwijderen of draaien van pagina’s. De lezer moet deze rechten respecteren; ze garanderen niet dat wijzigen absoluut onmogelijk is.

Alleen afdrukbare ASCII-tekens zijn toegestaan. Het veilig ondersteunde bereik is: alleen openingswachtwoord 1–32 tekens; alleen bewerkingswachtwoord 1–32 tekens; met beide wachtwoorden een openingswachtwoord van 1–16 en een bewerkingswachtwoord van 1–32 tekens. Deze voorwaardelijke limiet wordt duidelijk in de interface vermeld en vóór export gecontroleerd. Overschrijding geeft direct een fout, zonder afkappen, wijzigen van begin- of eindspaties of terugvallen op zwakkere uitvoer.

Bij een al geopende PDF kan `unlock(withPassword:)` ook met een verkeerd owner-wachtwoord `true` retourneren. Acceptatie controleert daarom `permissionsStatus` en alle rechtenbits: een beperkte reader is user/51, een owner is owner/255 en een reader met alleen een openingswachtwoord is user/255. Bestanden met alleen een bewerkingswachtwoord openen automatisch. Het lezen van paginatallen voor de geschiedenis vereist geen owner-ontgrendeling.

## Interface en talen

- De resources bevatten momenteel 292 teksten × 16 talen; de daadwerkelijke interface gebruikt 281 teksten. `check-localization.py` is geslaagd. De taalresources in het app-pakket zijn byte voor byte gelijk aan de bronbestanden.
- De taal volgt standaard het systeem. De volgorde is gelijk aan de gebruikersspecificatie: 简体中文, English, 繁體中文, 日本語, 한국어, Français, Deutsch, Español, Italiano, Português (Brasil), Русский, العربية, हिन्दी, Türkçe, Nederlands, Polski.
- Het hoofdvenster en het instellingenvenster gebruiken in het Arabisch RTL. Bestandsnamen, afbeeldingen en PDF-inhoud blijven ongewijzigd. De TAB-teksteditor voor bladwijzers behoudt LTR, zodat de betekenis van interfacebestanden bij het bewerken niet verandert.
- De app is opnieuw gestart en de daadwerkelijke NSView is gerenderd voor controle van de Chinese lichte interface met standaard ingeklapte instellingen en uitgeklapte dubbele wachtwoorden, lange Duitse teksten in donker uiterlijk, Arabisch RTL en alleen een bewerkingswachtwoord. Velden en toelichtingen lopen correct om; er zijn geen overlappingen of ontbrekende tekens gezien. Inhoud buiten het zichtbare gebied scrolt mee in het rechterpaneel. Zie de schermafbeeldingen hieronder.
- Inklapbare kopregels zoals ‘Documentgegevens’, ‘PDF-versleuteling’ en ‘Marges en resolutie’ gebruiken een Button over de hele rij. Het label vult de breedte en het klikgebied is rechthoekig. Ook de werkruimtenavigatie links en de instellingenknop onderaan hebben grotere klikgebieden. Broncodecontrole omvatte lege gebieden en semantische RTL-richting; er is geen afzonderlijke muisautomatiseringstest uitgevoerd. De uiteindelijke release-app is gecontroleerd op opstarten en opnieuw openen na sluiten van het hoofdvenster; het log bevat `reopen verified: true`.
- Tijdens conversie zijn het sluiten van het venster en afsluiten van de app geblokkeerd. Bij niet-opgeslagen bladwijzers verschijnt bij sluiten of afsluiten een melding. Na sluiten en opnieuw openen blijft het huidige sessieconcept behouden.
- De instellingenknop en ⌘, openen hetzelfde native instellingenvenster. ⌘N toont het hoofdvenster, ⌘O voegt afbeeldingen toe, ⌘⇧O voegt mappen toe en ⌘E exporteert.
- ‘PDF-versleuteling’ staat zelfstandig na ‘Documentgegevens’ in het rechter instellingenpaneel, is standaard ingeklapt en scrolt mee. Uitklappen toont beide wachtwoordgroepen direct, zonder popover. Het openings- en bewerkingswachtwoord hebben elk een eigen schakelaar en gemaskeerde invoer- en bevestigingsvelden.
- Het uitschakelen van één schakelaar wist alleen die groep en de bevestiging. Reset wist beide groepen. Ongeldige wachtwoorden, afwijkende bevestigingen of gelijke dubbele wachtwoorden blokkeren export. Als beide groepen uitstaan, wordt een gewone PDF geëxporteerd. In- of uitklappen verandert de beveiligingsinstellingen niet.
- Beide wachtwoorden blijven alleen in het huidige proces en worden niet in permanente instellingen, geschiedenis of logs geschreven. Onversleutelde tijdelijke bestanden tijdens versleutelde export staan in een map met rechten 0700 en worden bij normale annulering of fouten opgeruimd. Alleen versleutelde bestanden die de controle voor de gekozen modus doorstaan worden gepubliceerd. Bij fouten mag niet worden teruggevallen op onversleutelde uitvoer.
- De beschikbare OCR-talen hangen nog steeds af van Vision op de lokale machine. Het aantal interfacetalen bepaalt niet het aantal OCR-talen.

## Grenzen van de validatie

- De testmachine is een Intel Mac. Beide architecturen van het universele 1.4-pakket zijn succesvol gecompileerd, maar er is nog niet getest op echte Apple Silicon-hardware.
- Het minimale implementatiedoel is macOS 14; deze tests zijn uitgevoerd op macOS 15.7.9.
- JPEG XL wordt met native ImageIO gedecodeerd. De 5 zelf gegenereerde testbestanden omvatten RGB met kwaliteitsverlies, verliesloos RGB, RGBA-transparantie, 16-bits grijstinten en animatie. Het huidige systeem geeft alleen het eerste animatieframe terug; import van alle afzonderlijke frames wordt daarom niet gegarandeerd. De app biedt geen JXL-codering als uitvoer en garandeert geen ongewijzigd behoud van de oorspronkelijke datastroom, HDR of informatie met een hoge bitdiepte in de PDF.
- Er zijn geen grootschalige prestatiebenchmarks met gescande boeken uitgevoerd. Compatibiliteit met elk RAW-cameraformaat of elke niet-standaard PDF-bestemming wordt niet gegarandeerd.
- Versleuteling gebruikt Apple PDFKit, vereist AESV2/128-bits-uitvoer en controleert wachtwoorden en rechten volgens de gekozen modus. Het probleem met openingswachtwoorden van 17–31 tekens in de lokale native schrijfinterface beïnvloedt owner-authenticatie. Daarom beperkt de modus met twee wachtwoorden het openingswachtwoord tot 1–16 tekens. Het bewerkingswachtwoord en beide modi met slechts één wachtwoord ondersteunen elk 1–32 tekens. De app past cryptografische resultaten niet zelf aan en weigert Unicode, controletekens en invoer buiten de lengtegrenzen. De voorafgaande grenscontrole, owner-rechten en het behoud van begin- en eindspaties zijn met echte bestanden getest. Openingswachtwoorden van 17, 31 en 32 tekens worden in de modus met twee wachtwoorden vóór het schrijven geweigerd.
- Paginalabels met aangepaste tekstvoorvoegsels kunnen niet betrouwbaar worden behouden via de huidige native route. Bij ingeschakelde versleuteling geeft dit een expliciete fout. Gewone alfabetische, Romeinse en numerieke sectiepaginanummers, leesindelingen en metadata hebben rondgangtests doorstaan. Bij voorvertoning in de app kan het openingswachtwoord worden ingevoerd; bestanden met alleen een bewerkingswachtwoord kunnen direct worden bekeken. Bladwijzerbewerking van versleutelde bestanden blijft niet ondersteund.
- Beperkingen rond JBIG2/G4-codering, OCR-correctie, meerlaagse interfacebestanden en bepaalde speciale bladwijzerbestemmingen staan onder ‘Huidige beperkingen’ in de README.

## Schermafbeeldingen van deze versie

| Status | Echte vensterscreenshot |
|---|---|
| Chinees, import van statische JPEG XL-afbeeldingen | [jpeg-xl-import-zh.png](../screenshots/jpeg-xl-import-zh.png) |
| Chinees, versleuteling standaard ingeklapt | [encryption-collapsed-zh.png](../screenshots/encryption-collapsed-zh.png) |
| Chinees, beide wachtwoorden uitgeklapt | [encryption-inline-zh.png](../screenshots/encryption-inline-zh.png) |
| Duits, donker, beide wachtwoorden uitgeklapt | [encryption-inline-de-dark.png](../screenshots/encryption-inline-de-dark.png) |
| Arabisch, RTL, beide wachtwoorden uitgeklapt | [encryption-inline-ar.png](../screenshots/encryption-inline-ar.png) |
| Uiteindelijke universele app, Chinees, alleen bewerkingswachtwoord en heropenen na sluiten | [encryption-editing-only-zh.png](../screenshots/encryption-editing-only-zh.png) |

De screenshots zijn verkregen door de eigen `NSView` van de app te renderen en bevatten geen inhoud van andere apps. `build-results.txt` documenteert de productiebuild voor beide architecturen. `SHA256SUMS-1.4.txt` in [Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.4.0) bevat de controlesommen van de distributie-ZIP’s. Screenshots van de oude indeling zijn verplaatst naar `screenshots/previous-layout/` en gelden niet als acceptatiebewijs voor deze versie.

De oorspronkelijke test-, build- en screenshotlogs zijn door tools gegenereerd. De uitvoer is behouden, met het lokale projectpad vervangen door `<project>`. Logs worden niet vertaald en vervolgens als origineel bewijs gepresenteerd. Alle 16 taalversies van dit verslag beschrijven dezelfde testresultaten, omgeving en grenzen. De broncodedistributie bevat geen buildcache of release-binaries; download releasepakketten via Releases in de repository.
