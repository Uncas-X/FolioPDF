# FolioPDF 1.3 — Rapporto di verifica

<!-- languages:start -->
[简体中文](../VALIDATION.md) · [English](VALIDATION.en.md) · [繁體中文](VALIDATION.zh-Hant.md) · [日本語](VALIDATION.ja.md) · [한국어](VALIDATION.ko.md) · [Français](VALIDATION.fr.md) · [Deutsch](VALIDATION.de.md) · [Español](VALIDATION.es.md) · **Italiano** · [Português (Brasil)](VALIDATION.pt-BR.md) · [Русский](VALIDATION.ru.md) · [العربية](VALIDATION.ar.md) · [हिन्दी](VALIDATION.hi.md) · [Türkçe](VALIDATION.tr.md) · [Nederlands](VALIDATION.nl.md) · [Polski](VALIDATION.pl.md)
<!-- languages:end -->

Stato: **test e compilazione superati**. Data: 2026-10-23. Ambiente: Intel Mac, macOS 15.7.9, Swift 6.2.4 / Xcode. Versione minima di distribuzione: macOS 14.

Questa versione aggiunge password indipendenti di apertura e modifica. La crittografia è configurata in una sezione del pannello destro inizialmente chiusa e con l'intera intestazione cliccabile. Sono stati eseguiti tutti i 50 XCTest: 0 errori e 0 test saltati. È stato confermato che l'interfaccia nativa di scrittura PDF di questo Mac può invalidare la password owner se la password di apertura ha 17–31 caratteri. L'app evita il problema controllando la lunghezza prima dell'esportazione con due password; i limiti sicuri sono descritti sotto. Il log dell'esecuzione è `test-results.txt`.

## Materiale distribuito

- `dist/FolioPDF.app`: finestre AppKit native, interfaccia SwiftUI e framework di sistema PDFKit / Vision / ImageIO. Il nome del file dell'app non contiene la versione, registrata nei metadati.
- `dist/FolioPDF-1.3-macOS.zip`: app universale con x86_64 e arm64, verificata con `lipo -archs`.
- `dist/FolioPDF-1.3-source.zip`: sorgente Swift Package apribile in Xcode, con test, script, istruzioni e schermate.
- Lo script di creazione dei pacchetti usa firma ad-hoc locale; `codesign --verify --deep --strict` è passato. Non è presente notarizzazione Developer ID. La versione interna è 1.3 (build 4); il nome resta `FolioPDF.app`.

## Test funzionali

È stato eseguito `bash scripts/test.sh`: tutti i 50 XCTest sono passati. L'output dettagliato è in `test-results.txt`. Anche i test OCR reali con Vision sono stati eseguiti, senza omissioni.

| Area | Numero | Controlli |
|---|---:|---|
| Ricerca e ordinamento del materiale | 3 | Ordine numerico, prefissi e-book, sottocartelle ed esclusione della cartella superiore, percorsi duplicati |
| Conversione PDF | 10 | Geometria e parametri non validi, orientamento EXIF, TIFF/GIF multipagina, metadati e segnalibri, gruppi per cartella, nessuna sovrascrittura, errori parziali del lotto, codifica JPEG reale, conservazione del flusso JPEG originale, testo Vision invisibile e ricercabile, pulizia dopo annullamento |
| Segnalibri e file di interfaccia | 8 | Indice multilivello, conversione BasePage, destinazioni non valide, azioni standard e JSON, rifiuto esplicito di destinazioni esterne, interfaccia UTF-16 e numerazione per sezioni, salvataggio di copie, pagine di testo ricercabili e conservazione di etichette esistenti |
| Localizzazione | 3 | 16 lingue e relativo ordine, caricamento completo delle risorse, 18 mappature regionali, ripiego per lingue sconosciute, priorità della selezione manuale e RTL solo per l'arabo |
| Crittografia PDF nativa | 14 | Dizionario effettivo AESV2/128 bit, modalità solo apertura/solo modifica/entrambe, separazione reader/owner, nessun aumento di privilegi con password errate, password diverse, owner casuale, limiti di lunghezza con una o due password, rifiuto di aperture troppo lunghe prima della scrittura, spazi iniziali/finali, metadati cinesi, segnalibri, testo nascosto, etichette ordinarie per sezioni e layout, rifiuto esplicito di prefissi testuali, nessuna sovrascrittura e pulizia dopo errori |
| Integrazione della conversione crittografata | 7 | Output unito, per file e per cartella, numerazione automatica, sorgenti invariati, nessun output con password non valide, permessi a doppia password e metadati conservati, ricerca OCR Vision reale e resa visiva invariata, annullamento deterministico durante la conversione e pulizia delle cartelle |
| Stato dell'interfaccia di crittografia | 5 | Validazione delle due password e conferme, cancellazione indipendente tramite interruttori, isolamento di sessione e ripristino, esportazione completa e pagine nella cronologia per le tre modalità, nessuna password in impostazioni/cronologia/log |

I test OCR usano immagini di testo realmente generate, verificano l'estrazione del testo PDF e controllano che il testo invisibile non alteri il rendering. Devono essere eseguiti con accesso ai servizi macOS. Gli errori CoreVideo in una sandbox limitata non equivalgono a un test superato.

### Criteri di accettazione delle due password

| Modalità | Lettore normale | Titolare della password di modifica |
|---|---|---|
| Solo apertura | Password vuota o errata non apre il file; quella corretta concede tutte le operazioni | Nessuna password di modifica separata |
| Solo modifica | Lettura senza password; contenuto, annotazioni, moduli e organizzazione delle pagine non sono modificabili | La password di modifica concede pieni permessi owner |
| Entrambe | La password di apertura concede permessi user limitati | La password di modifica apre direttamente il file e concede pieni permessi owner |

Le password devono essere diverse. Stampa, copia e accessibilità sono consentite in tutte e tre le modalità. La modalità limitata disabilita modifica dei contenuti, annotazioni, compilazione dei moduli e inserimento, eliminazione o rotazione delle pagine. Il lettore deve rispettare i permessi; non si garantisce un'impossibilità assoluta di modifica.

Sono accettati solo caratteri ASCII stampabili. Intervalli sicuri: sola apertura 1–32 caratteri; sola modifica 1–32; con entrambe, apertura 1–16 e modifica 1–32. Il limite condizionale viene indicato nell'interfaccia e controllato prima dell'esportazione. Gli input fuori intervallo producono un errore, senza troncamento, modifica degli spazi alle estremità o output con protezione ridotta.

Su un PDF già aperto, `unlock(withPassword:)` può restituire `true` anche con una password owner errata. La verifica deve quindi controllare `permissionsStatus` e tutti i bit: reader limitato user/51, owner owner/255 e reader della modalità solo apertura user/255. Un PDF con sola password di modifica si apre automaticamente; non serve lo sblocco owner per leggere il numero di pagine nella cronologia.

## Interfaccia e lingue

- Le risorse contengono 292 testi × 16 lingue; i testi effettivamente usati nell'interfaccia sono 281. `check-localization.py` è passato; le risorse linguistiche nel pacchetto coincidono byte per byte con i sorgenti.
- La lingua predefinita segue il sistema. L'ordine richiesto è: 简体中文, English, 繁體中文, 日本語, 한국어, Français, Deutsch, Español, Italiano, Português (Brasil), Русский, العربية, हिन्दी, Türkçe, Nederlands, Polski.
- Le finestre principale e delle impostazioni usano RTL per l'arabo. Nomi dei file, immagini e PDF non cambiano. L'editor TAB dei segnalibri mantiene LTR per non alterare il significato dei file di interfaccia durante la modifica.
- L'app è stata riavviata e la sua NSView effettiva è stata renderizzata. Sono stati controllati cinese chiaro con crittografia inizialmente chiusa e doppia password espansa, tedesco scuro con testi lunghi, arabo RTL e sola password di modifica. Campi e spiegazioni vanno a capo correttamente; non sono state osservate sovrapposizioni o lettere mancanti. Il contenuto fuori vista scorre con il pannello destro. Le schermate sono elencate sotto.
- Le intestazioni «Informazioni documento», «Crittografia PDF» e «Margini e risoluzione» usano un Button sull'intera riga. L'etichetta occupa tutta la larghezza e un rettangolo definisce l'area cliccabile. Anche navigazione laterale e accesso inferiore alle impostazioni hanno aree più ampie. La revisione del sorgente ha coperto spazi vuoti e direzioni semantiche RTL; non è stato eseguito un test separato di automazione del mouse. Avvio dell'app finale e riapertura della finestra principale sono stati verificati; il log riporta `reopen verified: true`.
- Durante la conversione sono bloccati chiusura della finestra e uscita. I segnalibri non salvati richiedono conferma quando si chiude o si esce. Riaprire la finestra conserva la bozza della sessione.
- Il pulsante impostazioni e ⌘, aprono la stessa finestra nativa. ⌘N mostra la principale, ⌘O aggiunge immagini, ⌘⇧O cartelle e ⌘E esporta.
- «Crittografia PDF» è una sezione separata dopo «Informazioni documento», inizialmente chiusa e scorrevole nel pannello destro. Espandendola appaiono direttamente le due password, senza pannello a comparsa. Ogni gruppo ha interruttore, campo password mascherato e conferma indipendenti.
- Disattivare un gruppo cancella soltanto la sua password e conferma; il ripristino cancella entrambi. Password non valide, conferme diverse o password uguali bloccano l'esportazione. Con entrambi i gruppi disattivati si genera un normale PDF. Espandere o chiudere la sezione non cambia la protezione.
- Le due password restano solo nel processo corrente, senza scritture in impostazioni, cronologia o log. I file intermedi non crittografati di un'esportazione protetta risiedono in una cartella con permessi 0700, ripulita nei normali percorsi di annullamento ed errore. Vengono pubblicati solo file che superano la verifica della modalità; gli errori non producono ripieghi non crittografati.
- Le lingue OCR dipendono sempre da Vision locale; il numero delle lingue dell'interfaccia non indica quello delle lingue OCR.

## Limiti della verifica

- Il computer di prova è un Intel Mac. Entrambe le architetture del pacchetto universale 1.3 sono state compilate; manca una prova su hardware Apple Silicon reale.
- Il deployment minimo è macOS 14; l'esecuzione effettiva è avvenuta su macOS 15.7.9.
- Non sono stati svolti benchmark su grandi raccolte di libri scansionati e non si garantisce ogni formato RAW di fotocamera o destinazione PDF non standard.
- La crittografia usa Apple PDFKit, richiede AESV2/128 bit e verifica password e permessi secondo la modalità. Il problema nativo con password di apertura di 17–31 caratteri influisce sull'autenticazione owner; per questo, con due password, quella di apertura è limitata uniformemente a 1–16 caratteri. La password di modifica e le due modalità a password singola supportano 1–32 caratteri. L'app non corregge autonomamente risultati crittografici. Rifiuta Unicode, caratteri di controllo e input fuori dai limiti. Prevalidazione, permessi owner e conservazione degli spazi sono coperti da test su file reali; con due password, lunghezze di apertura di 17, 31 e 32 vengono rifiutate prima della scrittura.
- Le etichette con prefissi testuali personalizzati non possono essere conservate affidabilmente con il percorso nativo attuale e producono un errore esplicito quando si cifra. Numerazione alfabetica, romana e numerica per sezioni, layout e metadati sono coperti da test di round trip. L'anteprima interna accetta la password di apertura; i file con sola password di modifica si visualizzano direttamente. Non è prevista la modifica dei segnalibri nei file crittografati.
- Le differenze dal programma originale, fra cui codifica JBIG2/G4, vecchia correzione OCR, composizione multistrato e alcune destinazioni speciali, sono descritte in «Differenze esplicite rispetto al programma originale» nel README.

## Schermate di questa versione

| Stato | Schermata della finestra reale |
|---|---|
| Cinese, crittografia inizialmente chiusa | [encryption-collapsed-zh.png](../screenshots/encryption-collapsed-zh.png) |
| Cinese, entrambe le password espanse | [encryption-inline-zh.png](../screenshots/encryption-inline-zh.png) |
| Tedesco, scuro, entrambe le password espanse | [encryption-inline-de-dark.png](../screenshots/encryption-inline-de-dark.png) |
| Arabo, RTL, entrambe le password espanse | [encryption-inline-ar.png](../screenshots/encryption-inline-ar.png) |
| App universale finale, cinese, sola password di modifica e riapertura della finestra | [encryption-editing-only-zh.png](../screenshots/encryption-editing-only-zh.png) |

Le schermate derivano dal rendering della `NSView` dell'app e non contengono altre applicazioni. `build-results.txt` registra la compilazione di produzione per entrambe le architetture. `SHA256SUMS-1.3.txt` nelle [Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.3.0) contiene i checksum degli ZIP distribuiti. Le schermate del vecchio layout sono state spostate in `screenshots/previous-layout/` e non costituiscono prova dell'interfaccia di questa versione.

I log originali di test, compilazione e schermate sono generati dagli strumenti. L'output viene conservato, sostituendo i percorsi locali del progetto con `<project>`; traduzioni dei log non vengono presentate come prove originali. Le 16 versioni linguistiche di questo rapporto spiegano gli stessi risultati, ambiente e limiti. I sorgenti non contengono cache o binari di distribuzione; i pacchetti vanno scaricati dalle Releases del repository privato.
