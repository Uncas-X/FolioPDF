# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Français** · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- languages:end -->

Une application macOS native pour assembler des images en livres PDF et modifier leurs signets. Réimplémentée à partir des besoins fonctionnels de FreePic2Pdf, elle possède une interface SwiftUI indépendante et utilise les frameworks système d’Apple. Aucun environnement d’exécution tiers, aucun transfert réseau et aucune API Key à configurer.

## Utilisation

Téléchargez `FolioPDF-1.3-macOS.zip` depuis [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest), décompressez l’archive et ouvrez `FolioPDF.app`. Vous pouvez aussi glisser l’application dans le dossier « Applications ». **macOS 14 ou version ultérieure** est requis. L’application compilée localement se trouve dans `dist/FolioPDF.app`.

La version 1.3 est distribuée sous forme de `FolioPDF-1.3-macOS.zip` et de `FolioPDF-1.3-source.zip`. Dans le ZIP, l’application porte toujours le nom `FolioPDF.app`. Le [rapport de validation](../validation/VALIDATION.fr.md) présente l’état des vérifications, l’environnement d’exécution et les captures de l’interface réelle. Le dépôt source ne contient ni cache de compilation ni binaire de l’application ; les paquets d’installation sont disponibles dans Releases.

1. Dans « Créer un PDF », ajoutez des images, glissez des fichiers ou ajoutez un ou plusieurs dossiers. Les options de recherche dans les sous-dossiers se trouvent dans les réglages de droite et doivent être définies avant l’importation.
2. Cliquez sur une image pour la sélectionner, ou maintenez Command pour une sélection multiple. Glissez une image sur une autre pour modifier l’ordre, ou utilisez les boutons de déplacement vers l’avant/l’arrière en bas. Double-cliquez pour afficher un aperçu. Vous pouvez alterner entre les vignettes et la liste.
3. À droite, choisissez de fusionner les images, de produire un PDF par fichier source ou un PDF par dossier. Réglez le papier, les marges, la résolution DPI, la compression, l’OCR et les informations du document.
4. Pour protéger les fichiers par mot de passe, faites défiler le panneau de droite vers le bas et développez « Chiffrement PDF », après « Informations du document ». Cette section est repliée par défaut ; ses réglages s’affichent directement lorsqu’elle est développée. « Mot de passe d’ouverture » et « Mot de passe de modification » disposent chacun d’un interrupteur indépendant. Activez l’option souhaitée et saisissez le mot de passe avec sa confirmation. Les autorisations sont décrites dans le tableau ci-dessous. Chaque PDF du lot utilise ces réglages.
5. Cliquez sur « Créer un PDF ». Les fichiers de sortie existants ne sont pas écrasés : en cas de conflit de nom, un nouveau fichier numéroté est créé. Chaque page/image d’un TIFF/GIF multipage devient successivement une page PDF. Le mode « Un PDF par fichier image » ne répartit pas un même fichier source entre plusieurs PDF.
6. L’espace « Signets » permet d’ouvrir un PDF non chiffré, d’ajouter, modifier, déplacer ou indenter les entrées de sa table des matières, de prévisualiser les destinations et d’importer ou exporter des fichiers TXT, JSON ou d’interface compatible. Enregistrez ensuite une copie.

Toute la ligne de titre des sections repliables, notamment « Informations du document », « Chiffrement PDF » et « Marges et résolution », est cliquable, y compris l’espace vide à côté du titre. Les éléments de navigation de gauche sont également cliquables sur toute leur ligne. « Chiffrement PDF » est replié par défaut et défile avec le panneau de réglages de droite une fois développé.

⌘N affiche la fenêtre principale, ⌘O ajoute des images, ⌘⇧O ajoute des dossiers, ⌘E exporte et ⌘, ouvre les réglages. Fermer puis rouvrir la fenêtre principale conserve la session en cours. Quitter l’application n’enregistre pas automatiquement les brouillons de signets : enregistrez d’abord une copie.

### Mot de passe d’ouverture et mot de passe de modification

| Options activées | Longueur des mots de passe | Autorisations de lecture et d’opération |
|---|---|---|
| Mot de passe d’ouverture uniquement | Ouverture : 1–32 caractères | Un mot de passe est requis pour ouvrir le PDF ; le bon mot de passe donne ensuite accès à toutes les opérations |
| Mot de passe de modification uniquement | Modification : 1–32 caractères | La lecture ne nécessite aucun mot de passe. Pour un lecteur ordinaire, les modifications du contenu, les annotations, le remplissage de formulaires et l’insertion/suppression/rotation de pages sont restreints. Le mot de passe de modification donne toutes les autorisations |
| Les deux mots de passe | Ouverture : 1–16 caractères ; modification : 1–32 caractères | Le mot de passe d’ouverture donne un accès de lecture restreint ; celui de modification donne toutes les autorisations et peut aussi ouvrir directement le PDF |

Lorsque les deux mots de passe sont activés, ils doivent être différents. L’impression, la copie et l’accès par les outils d’accessibilité restent toujours autorisés. Les restrictions de modification dépendent du respect des autorisations par le lecteur PDF ; elles ne garantissent pas une impossibilité absolue de modifier le contenu.

Les mots de passe acceptent uniquement des caractères ASCII imprimables : lettres anglaises, chiffres, symboles et espaces. Leur longueur est limitée selon le tableau ci-dessus. Lorsque les deux options sont activées, l’interface indique la limite de 16 caractères pour le mot de passe d’ouverture. Une valeur trop longue est refusée avant l’export ; les mots de passe ne sont ni tronqués ni débarrassés automatiquement de leurs espaces de début et de fin.

Les mots de passe restent uniquement dans la session de l’application, sans être enregistrés dans les réglages, l’historique ou les journaux. Désactiver une option efface son mot de passe et sa confirmation ; réinitialiser les réglages efface les deux paires. Un mot de passe ou une confirmation incorrects bloque l’export. Lorsque les deux options sont désactivées, l’application exporte un PDF ordinaire.

Par défaut, la langue de l’interface suit celle du système. Dans les réglages, vous pouvez choisir à tout moment l’une des **16 langues** suivantes, sans redémarrage :

**简体中文** · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · Nederlands · Polski

L’arabe utilise une interface de droite à gauche. Les images et le contenu des PDF restent inchangés ; l’éditeur de texte à tabulations des signets conserve sa structure de gauche à droite. L’apparence peut suivre le système, être claire ou sombre. Les contrôles macOS, comme le sélecteur de fichiers système, utilisent la langue configurée dans le système. La langue de l’interface et celle de reconnaissance OCR se règlent séparément ; les choix OCR dépendent des langues prises en charge par Vision sur le Mac.

## Fonctionnalités implémentées

| Fonction | Implémentation |
|---|---|
| Images en entrée | Formats décodables par ImageIO, dont JPEG, PNG, TIFF, GIF, BMP, HEIC/HEIF et JPEG 2000 ; découverte dynamique des autres extensions prises en charge par le système. La compatibilité RAW dépend du décodeur système local et n’est pas garantie pour tous les appareils photo |
| Organisation des fichiers | Déduplication, tri par nom/numéro final, ordre manuel, tri par préfixes courants de livres numériques, parcours des sous-dossiers et choix d’inclure le dossier racine |
| Export par lots | Un PDF fusionné, un PDF par fichier source ou un PDF par dossier parent direct. Les dossiers plus profonds sont regroupés séparément ; leurs images ne sont pas comptées une seconde fois dans les dossiers parents |
| Pages | Taille de l’image d’origine, largeur fixe, A3/A4/A5/B5/Letter/Legal, dimensions personnalisées en millimètres, orientation paysage, quatre marges, agrandissement des petites images et priorité aux métadonnées DPI |
| Compression | Traitement sans perte et réglage de qualité JPEG. Un JPEG dont l’orientation d’origine est normale peut conserver son flux DCT initial. Les autres formats/orientations sont correctement décodés et mis en page par ImageIO, sans garantie de conservation octet pour octet du flux de chaque format source |
| Transparence | Conservation de la transparence ou fond blanc. Le JPEG ne pouvant pas stocker de canal alpha, conserver la transparence entraîne automatiquement un encodage sans perte, accompagné d’une explication |
| OCR | Reconnaissance locale précise par Apple Vision, avec détection automatique ou choix manuel des langues prises en charge localement ; création d’un texte masqué permettant la recherche et la copie. En cas d’échec du traitement GPU, un traitement CPU est tenté. Les pages dont la reconnaissance échoue conservent leur image et font l’objet d’un signalement explicite |
| Propriétés du document | Titre, auteur, sujet, mots-clés ; présentation de lecture en page unique, en continu ou sur deux pages |
| Chiffrement PDF | AES-128 natif de PDFKit, avec mot de passe d’ouverture, de modification ou les deux. Si seul le mot de passe d’ouverture est défini, un mot de passe owner aléatoire est généré. Si un mot de passe de modification est défini, il accorde tous les droits owner. Le fichier final n’est publié qu’après vérification du verrouillage, des mots de passe, des autorisations reader/owner et du nombre de pages selon le mode choisi. Un échec ne produit aucun fichier de remplacement non chiffré. L’aperçu dans l’application permet de saisir un mot de passe |
| Signets | Signets automatiques des fichiers sources, table des matières hiérarchique, numéros de page, conversion à partir d’une page de référence, texte et JSON modifiables, aperçu natif de la destination PDF |
| Compatibilité des interfaces | `FreePic2Pdf.itf` et `FreePic2Pdf_bkmk.txt`, UTF-8/UTF-16LE et encodages historiques associés ; numérotation distincte pour la table des matières et le corps du document, métadonnées, ajout de pages de texte interrogeable et réglages d’affichage des signets |
| Stabilité | Tâches en arrière-plan, libération des images page par page, progression, annulation, journaux, fichiers temporaires et publication atomique, numérotation automatique en cas de conflit de nom, conservation et liste des résultats déjà terminés en cas d’échec partiel d’un lot |

### Différences explicites avec l’ancienne version

- L’OCR utilise Apple Vision à la place de MODI, sans nécessiter Office/Windows. Il ne reprend pas les options historiques de nettoyage des graphiques, de polices CJK ou de traitement par caractère/par ligne.
- Les options de compression actuelles sont le sans-perte et le JPEG. Les encodeurs JBIG2, CCITT G4 et JPEG 2000 n’ont pas été reproduits. Les fonctions principales sont disponibles, mais les gros ouvrages en noir et blanc peuvent produire des fichiers plus volumineux qu’avec un outil JBIG2 spécialisé.
- L’application ne propose pas les outils de correction de l’original permettant d’afficher/masquer le texte OCR ou de supprimer physiquement les images numérisées. Elle ne fournit pas non plus de restauration d’images ni d’éditeur complet de contenu PDF.
- L’assemblage multicouche `[Images]` et `MinWidth` des interfaces compatibles ne sont pas encore implémentés. Leur détection affiche une explication, sans prétendre les avoir appliqués. Si l’ordre manuel des fichiers ne correspond pas aux numéros de page absolus de l’interface, l’utilisateur doit vérifier les destinations de la table des matières.
- Les numéros de page locaux ordinaires, certaines actions nommées standard et les destinations URL sont pris en charge. Les destinations vers des PDF externes que PDFKit ne peut pas enregistrer de manière fiable, ainsi que les destinations nommées/spéciales non résolues, sont explicitement signalées et empêchent un enregistrement silencieux. Elles peuvent être remplacées dans l’éditeur par des numéros de page locaux valides. JSON/TXT peut conserver les données des destinations. La modification des signets n’est pas proposée pour les PDF chiffrés.
- Le chiffrement conserve les signets, le texte OCR, les métadonnées, la présentation de lecture et les numérotations ordinaires par sections. PDFKit ne conserve pas nativement les étiquettes de page : l’application ne rétablit de façon sûre que celles sans préfixe textuel. Un fichier d’interface comportant des préfixes textuels personnalisés bloque explicitement l’export chiffré ; il faut retirer ces préfixes ou désactiver le chiffrement.
- L’« ordre des livres numériques » utilise les groupes de préfixes courants cov, bok, leg, fow, !, toc, corps numéroté, att, ins, bac, puis place les autres éléments à la fin. Il ne prétend pas reproduire exactement les règles non publiées de l’ancien logiciel.
- Lors d’une interruption ou d’une erreur, les PDF déjà générés dans le lot sont conservés et le PDF temporaire inachevé est supprimé. La reprise au point d’interruption n’est pas disponible.

## Développement et compilation

Le code source est un Swift Package ; ouvrez `Package.swift` avec Xcode. Xcode avec le SDK macOS et Swift 5.9 ou version ultérieure sont nécessaires. L’environnement validé est macOS 15.7.9 / Xcode Swift 6.2.4, avec une cible de compatibilité macOS 14.

```sh
# Exécution en mode débogage
swift run FolioPDF

# Tests et vérification des textes dans les 16 langues
bash scripts/test.sh

# Compilation de l’application .app et du ZIP universels Intel + Apple Silicon
bash scripts/build-app.sh

# Compilation pour la seule architecture de la machine actuelle
bash scripts/build-app.sh --host-only
```

Les tests OCR réels de `scripts/test.sh` nécessitent un accès normal aux services système macOS, notamment Vision et CoreVideo. Un environnement d’exécution isolé qui limite l’accès au matériel ou aux services système peut entraîner un échec de création de CVPixelBuffer. Les tests doivent être exécutés et réussir dans un environnement système normal ; les ignorer ne remplace pas leur validation.

Le paquet utilise une signature ad-hoc locale et n’inclut pas de notarisation Developer ID. Il peut être exécuté localement ; une distribution officielle vers d’autres Mac nécessite un certificat de développeur et la procédure de notarisation.

### Organisation du code

```text
Sources/FolioCore/       Images, géométrie, conversion, OCR, signets et fichiers d’interface
Sources/FolioPDF/        Espaces SwiftUI, gestion d’état, aperçu natif et langues
Tests/FolioCoreTests/    Tests réels d’aller-retour et de limites pour images/PDF/OCR/signets
scripts/                Tests, empaquetage, génération d’icônes et d’images d’exemple
packaging/Info.plist     Informations de l’application macOS
docs/                   Rapports de validation et rendus des fenêtres réelles
dist/                   Application .app exécutable et ZIP de distribution (générés à la compilation)
```

## Langues de la documentation

Le README et le rapport de validation sont disponibles dans les mêmes 16 langues que l’interface. Les liens en haut des documents permettent de changer de langue. Les fonctionnalités, limites des mots de passe, différences connues et étapes de compilation sont identiques dans toutes les versions. Les journaux de test, de compilation et de capture des fenêtres constituent des preuves brutes produites par les outils et restent dans leur langue d’origine. Leurs explications sont traduites dans les rapports de validation.

## Références techniques

L’implémentation utilise l’[interface de détection de langue de Vision](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage), les [propriétés de document de PDFKit](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) et le [paramètre de qualité JPEG d’ImageIO](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality) d’Apple. Elle est également vérifiée à partir des déclarations du SDK local et de tests sur de vrais fichiers. Le programme FreePic2Pdf d’origine, ses icônes et son ancienne interface n’ont pas été copiés.
