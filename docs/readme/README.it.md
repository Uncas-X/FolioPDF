# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · **Italiano** · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- languages:end -->

Un'app nativa per macOS che crea libri PDF da immagini e modifica i segnalibri PDF. Reimplementa i requisiti di FreePic2Pdf con un'interfaccia SwiftUI progettata in modo indipendente e i framework di sistema Apple. Non richiede runtime di terze parti, non carica file in rete e non necessita di una chiave API.

## Utilizzo

Scarica `FolioPDF-1.3-macOS.zip` da [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest), estrai l'archivio e apri `FolioPDF.app`. Puoi anche trascinare l'app nella cartella Applicazioni. È necessario **macOS 14 o successivo**. L'app compilata localmente si trova in `dist/FolioPDF.app`.

I pacchetti della versione 1.3 sono `FolioPDF-1.3-macOS.zip` e `FolioPDF-1.3-source.zip`; l'app contenuta nello ZIP si chiama sempre `FolioPDF.app`. Il [rapporto di verifica](../validation/VALIDATION.it.md) riporta lo stato dei controlli, l'ambiente di esecuzione e le schermate dell'interfaccia reale. Il repository sorgente non contiene cache di compilazione né binari dell'app; i pacchetti di installazione sono disponibili nelle Releases.

1. In «Crea PDF», aggiungi immagini, trascina file oppure aggiungi una o più cartelle. La ricerca ricorsiva nelle cartelle va impostata nel pannello destro prima dell'importazione.
2. Fai clic per selezionare un'immagine e Command-clic per selezionarne più di una. Trascina un'immagine sopra un'altra per riordinarle oppure usa i pulsanti inferiori per spostarle avanti e indietro. Il doppio clic apre l'anteprima. Puoi passare dalla vista miniature all'elenco.
3. A destra scegli un PDF unico, un PDF per file sorgente o un PDF per cartella. Regola carta, margini, DPI, compressione, OCR e informazioni del documento.
4. Per la protezione tramite password, scorri verso il basso nel pannello destro ed espandi «Crittografia PDF», dopo «Informazioni documento». La sezione è inizialmente chiusa e, una volta espansa, mostra direttamente le impostazioni. «Password di apertura» e «Password di modifica» hanno interruttori indipendenti. Inserisci e conferma ogni password abilitata; i permessi sono descritti nella tabella seguente. Tutti i PDF del lotto utilizzano queste impostazioni.
5. Fai clic su «Crea PDF». I file esistenti non vengono sovrascritti: in caso di nome uguale viene creato automaticamente un nuovo file numerato. Ogni pagina o fotogramma di un TIFF/GIF multipagina diventa, nell'ordine, una pagina PDF. «Un PDF per file immagine» non divide lo stesso file sorgente in più PDF.
6. Nell'area «Segnalibri» puoi aprire PDF non crittografati, aggiungere, modificare, spostare e rientrare voci dell'indice, controllare i collegamenti nell'anteprima, importare ed esportare TXT, JSON o file di interfaccia compatibili e salvare una copia.

L'intera intestazione delle sezioni espandibili, come «Informazioni documento», «Crittografia PDF» e «Margini e risoluzione», è cliccabile, compreso lo spazio vuoto accanto al titolo. Anche la navigazione delle aree di lavoro a sinistra risponde al clic sull'intera riga. «Crittografia PDF» è inizialmente chiusa e, una volta espansa, scorre insieme al pannello destro.

⌘N mostra la finestra principale, ⌘O aggiunge immagini, ⌘⇧O aggiunge cartelle, ⌘E esporta e ⌘, apre le impostazioni. Chiudere e riaprire la finestra principale conserva la sessione corrente. Uscire dall'app non salva automaticamente le bozze dei segnalibri: salva prima una copia.

### Password di apertura e di modifica

| Attivazione | Lunghezza | Permessi di lettura e operazione |
|---|---|---|
| Solo password di apertura | Apertura: 1–32 caratteri | Per aprire il PDF serve una password; dopo aver inserito quella corretta sono consentite tutte le operazioni |
| Solo password di modifica | Modifica: 1–32 caratteri | La lettura non richiede password. Per il lettore normale sono limitati modifica dei contenuti, annotazioni, compilazione dei moduli e inserimento, eliminazione o rotazione delle pagine. La password di modifica concede tutti i permessi |
| Entrambe le password | Apertura: 1–16 caratteri; modifica: 1–32 caratteri | La password di apertura concede permessi di lettura limitati. Quella di modifica concede tutti i permessi e può anche aprire direttamente il PDF |

Se sono abilitate entrambe, le password devono essere diverse. Stampa, copia e accessibilità restano consentite. Le limitazioni di modifica dipendono dal rispetto dei permessi da parte del lettore PDF; non garantiscono che il contenuto sia assolutamente impossibile da modificare.

Sono accettati solo caratteri ASCII stampabili: lettere non accentate, numeri, simboli e spazi. Valgono le lunghezze riportate nella tabella. Quando entrambe le password sono attive, l'interfaccia indica il limite di 16 caratteri per quella di apertura. Gli input troppo lunghi vengono rifiutati prima dell'esportazione: le password non vengono troncate e gli spazi iniziali o finali non vengono rimossi automaticamente.

Le password restano soltanto nella sessione corrente dell'app e non vengono scritte nelle impostazioni, nella cronologia o nei log. Disattivare un'opzione cancella la relativa password e la conferma; ripristinare le impostazioni cancella entrambe le coppie. Password o conferme non valide bloccano l'esportazione. Se entrambe le opzioni sono disattivate, viene generato un normale PDF.

La lingua dell'interfaccia segue il sistema per impostazione predefinita. Puoi scegliere manualmente fra queste **16 lingue** in qualsiasi momento, senza riavviare:

**简体中文** · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · Nederlands · Polski

L'arabo usa una disposizione da destra a sinistra. Immagini e contenuti PDF restano invariati; l'editor di testo dei segnalibri con TAB mantiene la struttura da sinistra a destra. L'aspetto può seguire il sistema oppure essere chiaro o scuro. I controlli macOS, come le finestre di selezione dei file, usano la lingua di sistema. Lingua dell'interfaccia e lingua OCR sono impostazioni distinte; le opzioni OCR dipendono dal supporto Vision presente sul Mac.

## Funzionalità implementate

| Funzione | Implementazione |
|---|---|
| Immagini in ingresso | JPEG, PNG, TIFF, GIF, BMP, HEIC/HEIF, JPEG 2000 e altri formati decodificabili da ImageIO; rilevamento dinamico delle altre estensioni supportate dal sistema. Il supporto RAW dipende dal decoder locale e non è garantito per ogni modello di fotocamera |
| Organizzazione dei file | Deduplicazione, ordine per nome o numero finale, ordine manuale, prefissi comuni degli e-book, ricorsione nelle cartelle e inclusione facoltativa della cartella superiore |
| Esportazione in blocco | Un PDF unico, uno per file sorgente o uno per cartella immediatamente superiore. Le cartelle più profonde sono raggruppate separatamente; le loro immagini non vengono ricontate nella cartella superiore |
| Pagine | Dimensioni originali, larghezza fissa, A3/A4/A5/B5/Letter/Legal, dimensioni personalizzate in millimetri, orizzontale, quattro margini, ingrandimento delle immagini piccole e priorità ai metadati DPI |
| Compressione | Percorso senza perdita e regolazione della qualità JPEG. I JPEG con orientamento originale normale possono conservare il flusso DCT originale. Gli altri formati e orientamenti sono decodificati e impaginati correttamente con ImageIO; non è garantita la conservazione byte per byte del flusso di ogni formato sorgente |
| Trasparenza | Conservazione della trasparenza o fondo bianco. JPEG non memorizza alfa; quando si conserva la trasparenza viene usata automaticamente una codifica senza perdita, con un avviso |
| OCR | Riconoscimento locale accurato con Apple Vision, lingua automatica o selezionata fra quelle disponibili e testo invisibile ricercabile e copiabile. Se il percorso GPU fallisce viene provata la CPU. Le pagine con errori OCR mantengono l'immagine e l'errore viene segnalato esplicitamente |
| Proprietà del documento | Titolo, autore, oggetto e parole chiave; lettura a pagina singola, continua o su due pagine |
| Crittografia PDF | AES-128 nativo di PDFKit con password di apertura, di modifica o entrambe. Con la sola password di apertura viene generata una password owner casuale; quando è impostata quella di modifica, essa concede pieni permessi owner. Il file viene pubblicato solo dopo aver verificato blocco, password, permessi reader/owner e numero di pagine secondo la modalità. Un errore non produce una copia sostitutiva non crittografata. L'anteprima interna consente di inserire la password |
| Segnalibri | Segnalibri automatici per file sorgente, indice multilivello, numeri di pagina, conversione della pagina base, testo modificabile e JSON, anteprima nativa delle destinazioni PDF |
| Compatibilità di interfaccia | `FreePic2Pdf.itf` e `FreePic2Pdf_bkmk.txt`, UTF-8/UTF-16LE e relative codifiche precedenti; numerazione separata per indice e testo principale, metadati, aggiunta di pagine di testo ricercabili e impostazioni di visualizzazione dei segnalibri |
| Affidabilità | Attività in background, rilascio delle immagini pagina per pagina, avanzamento, annullamento, log, file temporanei e pubblicazione atomica, numerazione automatica dei nomi duplicati e conservazione con elenco dei risultati già completati in caso di errore nel lotto |

### Differenze esplicite rispetto al programma originale

- OCR usa Apple Vision al posto di MODI e non richiede Office o Windows. Non riproduce la pulizia dei grafici, i font CJK o gli interruttori per parola/riga del programma originale.
- Le opzioni di compressione sono senza perdita e JPEG; non sono stati riprodotti gli encoder JBIG2, CCITT G4 o JPEG 2000. Le funzioni principali sono disponibili, ma i grandi libri in bianco e nero possono occupare più spazio rispetto a strumenti JBIG2 specializzati.
- Non sono disponibili gli strumenti originali per mostrare/nascondere il testo OCR o eliminare fisicamente le immagini scansionate. Non sono inclusi neppure restauro delle immagini o un editor completo dei contenuti PDF.
- La composizione multistrato `[Images]` e `MinWidth` dell'interfaccia compatibile non sono ancora implementati. Se rilevati, vengono segnalati senza affermare che siano stati applicati. Se l'ordine manuale dei file non coincide con le pagine assolute dell'interfaccia, occorre controllare le destinazioni dell'indice.
- Sono supportate normali pagine locali, alcune azioni standard con nome e destinazioni URL. Le destinazioni PDF esterne che PDFKit non può salvare affidabilmente e quelle speciali o con nome non risolte vengono indicate esplicitamente, impedendo un salvataggio silenzioso. Nell'editor possono essere sostituite con pagine locali valide. JSON/TXT possono conservare i dati delle destinazioni. I segnalibri dei PDF crittografati non sono modificabili.
- La crittografia conserva segnalibri, testo OCR, metadati, disposizione di lettura e normale numerazione per sezioni. PDFKit nativo non conserva le etichette delle pagine; l'app ripristina in sicurezza soltanto quelle prive di prefissi di testo. I file di interfaccia con prefissi personalizzati bloccano esplicitamente l'esportazione crittografata: rimuovi i prefissi o disattiva la crittografia.
- L'ordine e-book usa i gruppi di prefissi comuni cov, bok, leg, fow, !, toc, corpo numerico, att, ins e bac, seguiti dagli altri. Non dichiara una corrispondenza completa con le regole non pubblicate del programma originale.
- In caso di annullamento o errore, i PDF del lotto già generati vengono conservati e il PDF temporaneo incompleto viene eliminato. Non è prevista la ripresa da un punto di interruzione.

## Sviluppo e compilazione

Il codice è uno Swift Package: apri `Package.swift` con Xcode. Servono Xcode con macOS SDK e Swift 5.9 o successivo. L'ambiente verificato è macOS 15.7.9 / Xcode Swift 6.2.4; la compatibilità di esecuzione parte da macOS 14.

```sh
# Avvio in modalità debug
swift run FolioPDF

# Test e controllo dei testi nelle 16 lingue
bash scripts/test.sh

# Crea .app universale e ZIP per Intel + Apple Silicon
bash scripts/build-app.sh

# Compila solo per l'architettura del computer attuale
bash scripts/build-app.sh --host-only
```

I test OCR reali di `scripts/test.sh` richiedono normale accesso ai servizi macOS, fra cui Vision e CoreVideo. In una sandbox che limita hardware o servizi di sistema, la creazione di CVPixelBuffer può fallire. I test devono essere eseguiti e superati in un ambiente normale; saltarli non sostituisce la verifica.

I pacchetti usano una firma ad-hoc locale e non sono notarizzati con Developer ID. Possono essere eseguiti localmente; la distribuzione ufficiale ad altri Mac richiede un certificato sviluppatore e la procedura di notarizzazione.

### Struttura del codice

```text
Sources/FolioCore/       Immagini, geometria, conversione, OCR, segnalibri e file di interfaccia
Sources/FolioPDF/        Aree SwiftUI, stato, anteprima nativa e lingue
Tests/FolioCoreTests/    Test reali di round trip e limiti per immagini/PDF/OCR/segnalibri
scripts/                Test, pacchetti, icona e generazione di immagini di esempio
packaging/Info.plist     Informazioni dell'app macOS
docs/                   Rapporti di verifica e rendering di finestre reali
dist/                   .app eseguibile e ZIP di distribuzione (generati dalla compilazione)
```

## Lingue della documentazione

README e rapporto di verifica sono disponibili nelle stesse 16 lingue dell'interfaccia. Usa i collegamenti linguistici in cima al documento per cambiare versione. Descrizioni delle funzioni, limiti delle password, differenze note e istruzioni di compilazione sono coerenti fra le lingue. I log di test, compilazione e acquisizione delle schermate sono prove originali generate dagli strumenti e mantengono la lingua originale. Le relative spiegazioni sono tradotte nel rapporto di verifica.

## Riferimenti tecnici

L'app usa l'[interfaccia di rilevamento della lingua di Vision](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage), gli [attributi dei documenti PDFKit](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) e il [parametro di qualità JPEG di ImageIO](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality) di Apple. L'implementazione viene verificata anche con le dichiarazioni dell'SDK locale e test su file reali. Il programma FreePic2Pdf originale, le sue icone e la sua interfaccia non sono stati copiati.
