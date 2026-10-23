# Rapport de validation de FolioPDF 1.4

<!-- languages:start -->
[简体中文](../VALIDATION.md) · [English](VALIDATION.en.md) · [繁體中文](VALIDATION.zh-Hant.md) · [日本語](VALIDATION.ja.md) · [한국어](VALIDATION.ko.md) · **Français** · [Deutsch](VALIDATION.de.md) · [Español](VALIDATION.es.md) · [Italiano](VALIDATION.it.md) · [Português (Brasil)](VALIDATION.pt-BR.md) · [Русский](VALIDATION.ru.md) · [العربية](VALIDATION.ar.md) · [हिन्दी](VALIDATION.hi.md) · [Türkçe](VALIDATION.tr.md) · [Nederlands](VALIDATION.nl.md) · [Polski](VALIDATION.pl.md)
<!-- languages:end -->

État : **tests et compilations réussis**. Date du rapport : 2026-10-23. Environnement validé : Mac Intel, macOS 15.7.9, Swift 6.2.4 / Xcode. Version minimale de déploiement : macOS 14.

Cette version prend en charge les images JPEG XL via ImageIO natif sous macOS 14 ou version ultérieure, ainsi que des mots de passe indépendants pour l’ouverture et la modification. Les réglages de chiffrement occupent une section du panneau de droite, repliée par défaut et cliquable sur toute la ligne. La suite complète de 58 tests XCTest a été exécutée avec succès : 0 échec et 0 test ignoré. Il a été confirmé que l’interface native locale d’écriture PDF peut rendre le mot de passe owner invalide lorsque celui d’ouverture comporte 17–31 caractères. L’application évite ce problème par un contrôle préalable de longueur en mode double mot de passe ; les limites de sécurité sont détaillées plus bas. Le journal de cette exécution se trouve dans `test-results.txt`.

## Livrables

- `dist/FolioPDF.app` : fenêtre AppKit native, interface SwiftUI et frameworks système PDFKit / Vision / ImageIO. Le nom du fichier de l’application n’inclut pas de version ; celle-ci figure dans ses métadonnées.
- `dist/FolioPDF-1.4-macOS.zip` : paquet d’application universel contenant x86_64 et arm64, vérifié avec `lipo -archs`.
- `dist/FolioPDF-1.4-source.zip` : sources Swift Package ouvrables dans Xcode, avec tests, scripts, mode d’emploi et captures de l’interface.
- Le script d’empaquetage utilise une signature ad-hoc locale ; `codesign --verify --deep --strict` réussit. Aucune notarisation Developer ID n’est incluse. La version interne est 1.4 (build 5) et le fichier de l’application reste nommé `FolioPDF.app`.

## Tests fonctionnels

La commande `bash scripts/test.sh` a été exécutée ; les 58 tests XCTest ont tous réussi. La sortie détaillée est enregistrée dans `test-results.txt`. Les tests Vision OCR réels ont également été exécutés, sans aucun test ignoré.

| Domaine | Nombre | Vérifications |
|---|---:|---|
| Découverte et tri des ressources | 3 | Tri numérique, préfixes de livres numériques, sous-dossiers et exclusion du dossier racine, chemins en double |
| Conversion PDF | 10 | Géométrie des pages et paramètres incorrects, orientation EXIF, TIFF/GIF multipages, métadonnées et signets, regroupement par dossier, absence d’écrasement, échec partiel d’un lot, encodage JPEG réel, conservation du flux JPEG d’origine, texte masqué Vision et possibilité de recherche, nettoyage après annulation |
| Entrée JPEG XL | 8 | Correspondance des types natifs et extensions, détection dans les dossiers, RGB avec/sans perte, transparence RGBA, niveaux de gris sur 16 bits, vignettes et aperçu, dimensions et rendu PDF, sortie transparente/sur fond blanc, sortie d’animation selon les images exposées par le système, rejet des fichiers corrompus ou manquants |
| Signets et fichiers d’interface | 8 | Signets hiérarchiques, conversion BasePage, destinations incorrectes, actions standard et JSON, refus explicite des destinations externes, interfaces UTF-16 et numérotation par sections, enregistrement d’une copie, pages de texte interrogeable, conservation des étiquettes de page existantes |
| Localisation | 3 | 16 langues et leur ordre, chargement complet des ressources, 18 correspondances de langues régionales, langue de repli pour les langues inconnues, priorité du choix manuel, RTL uniquement pour l’arabe |
| Chiffrement PDF natif | 14 | Dictionnaire AESV2/128 bits réel, ouverture seule/modification seule/deux mots de passe, séparation des autorisations reader et owner, absence d’élévation de droits avec un mauvais mot de passe, exigence de mots de passe distincts, owner aléatoire, limites de longueur avec un ou deux mots de passe, refus avant écriture d’un mot de passe d’ouverture trop long, espaces de début et de fin, métadonnées chinoises, signets, texte masqué, numérotation ordinaire par sections et présentation, refus explicite des préfixes textuels, absence d’écrasement et nettoyage après échec |
| Intégration de la conversion chiffrée | 7 | Chiffrement fusionné, par fichier et par dossier, numérotation automatique, sources inchangées, absence de sortie avec un mot de passe invalide, autorisations à deux mots de passe et conservation des métadonnées, recherche Vision OCR réelle et conservation du rendu, annulation déterministe pendant la conversion et nettoyage des dossiers |
| État de l’interface de chiffrement | 5 | Validation des deux paires de mots de passe et confirmations, effacement indépendant par interrupteur, isolation de session et réinitialisation, export complet des trois modes et nombre de pages dans l’historique, absence de mots de passe dans les réglages/l’historique/les journaux |

Les tests OCR utilisent des images de texte réellement générées, vérifient que le texte du PDF produit peut être extrait et confirment que le texte masqué ne modifie pas le rendu de la page. Ils doivent s’exécuter dans un environnement donnant accès aux services système macOS. Une erreur CoreVideo dans un environnement d’exécution isolé et restreint n’est pas considérée comme une réussite.

### Critères d’acceptation des deux mots de passe

| Mode | Lecteur ordinaire | Détenteur du mot de passe de modification |
|---|---|---|
| Mot de passe d’ouverture uniquement | Un mot de passe vide ou incorrect ne permet pas d’ouvrir le fichier ; le bon mot de passe d’ouverture donne toutes les autorisations | Aucun mot de passe de modification distinct n’est défini |
| Mot de passe de modification uniquement | Lecture sans mot de passe ; modification du contenu, annotations, remplissage de formulaires et organisation des pages interdits | Le mot de passe de modification donne tous les droits owner |
| Les deux mots de passe | Le mot de passe d’ouverture donne des droits user restreints | Le mot de passe de modification ouvre directement le fichier avec tous les droits owner |

Les deux mots de passe doivent être différents lorsqu’ils sont activés ensemble. Les trois modes autorisent l’impression, la copie et l’accès par les outils d’accessibilité. Les modes restreints interdisent les modifications du contenu, les annotations, le remplissage de formulaires et l’insertion/suppression/rotation de pages. Ces restrictions exigent que le lecteur les respecte ; elles ne garantissent pas une impossibilité absolue de modification.

Seuls les caractères ASCII imprimables sont acceptés. Les plages prises en charge de manière sûre sont : 1–32 caractères pour un mot de passe d’ouverture seul, 1–32 pour un mot de passe de modification seul et, en mode double mot de passe, 1–16 pour l’ouverture et 1–32 pour la modification. La restriction conditionnelle du mode double est clairement affichée dans l’interface et appliquée lors du contrôle préalable à l’export. Tout dépassement produit directement une erreur, sans tronquer les mots de passe, modifier leurs espaces de début et de fin ou réduire la protection de la sortie.

Sur un PDF déjà ouvert, `unlock(withPassword:)` peut renvoyer `true` même si le mot de passe owner est incorrect. La validation doit donc vérifier `permissionsStatus` et tous les bits d’autorisation : un reader restreint est user/51 et un owner est owner/255 ; le reader avec mot de passe d’ouverture seul est user/255. Un fichier protégé uniquement contre la modification s’ouvre automatiquement ; la lecture du nombre de pages pour l’historique ne nécessite pas de déverrouillage owner.

## Interface et langues

- Les ressources comprennent actuellement 292 textes × 16 langues, dont 281 textes réellement utilisés dans l’interface. `check-localization.py` a réussi ; les ressources linguistiques du paquet sont identiques octet pour octet aux fichiers sources.
- La langue suit le système par défaut. L’ordre correspond à celui demandé : 简体中文, English, 繁體中文, 日本語, 한국어, Français, Deutsch, Español, Italiano, Português (Brasil), Русский, العربية, हिन्दी, Türkçe, Nederlands, Polski.
- Les fenêtres principale et de réglages utilisent toutes deux une présentation RTL en arabe. Les noms de fichiers, les images et le contenu des PDF restent inchangés. L’éditeur de texte à tabulations des signets conserve sa structure LTR afin de ne pas modifier le sens des données d’interface éditées.
- L’application a été relancée et les NSView réelles rendues pour vérifier le chinois clair avec chiffrement replié par défaut puis les deux mots de passe développés, l’allemand sombre avec ses textes longs, l’arabe RTL et le mode modification seule. Les champs et explications reviennent correctement à la ligne, sans chevauchement ni caractères manquants observés. Le contenu dépassant la fenêtre défile avec le panneau de droite. Les captures figurent dans le tableau ci-dessous.
- Les titres repliables « Informations du document », « Chiffrement PDF », « Marges et résolution » et les autres utilisent un Button couvrant toute la ligne. Leur libellé occupe toute la largeur et une zone rectangulaire définit la surface cliquable. Les éléments de navigation de gauche et l’accès aux réglages en bas ont aussi une zone cliquable élargie. La revue du code a couvert les espaces vides et la direction sémantique RTL ; aucun test distinct d’automatisation de la souris n’a été réalisé. Le lancement de l’application finale et la réouverture de sa fenêtre principale après fermeture ont été vérifiés ; le journal indique `reopen verified: true`.
- La fermeture de la fenêtre et la sortie de l’application sont bloquées pendant la conversion. Les signets non enregistrés déclenchent un avertissement à la fermeture ou à la sortie. Fermer puis rouvrir conserve le brouillon de la session actuelle.
- Le bouton de réglages et ⌘, ouvrent la même fenêtre de réglages native. ⌘N affiche la fenêtre principale, ⌘O ajoute des images, ⌘⇧O ajoute des dossiers et ⌘E exporte.
- « Chiffrement PDF » est une section indépendante, placée après « Informations du document » dans le panneau de droite. Elle est repliée par défaut et défile avec le panneau. La développer affiche directement les deux groupes de réglages, sans panneau contextuel. Les mots de passe d’ouverture et de modification disposent chacun d’un interrupteur, d’un champ de mot de passe masqué et d’un champ de confirmation.
- Désactiver un interrupteur efface uniquement son mot de passe et sa confirmation ; réinitialiser les réglages efface les deux paires. Un mot de passe invalide, une confirmation différente ou deux mots de passe identiques bloque l’export. Désactiver les deux options produit un PDF ordinaire. Replier ou développer la section ne change pas les réglages de protection.
- Les deux mots de passe restent dans le processus actuel et ne sont pas enregistrés dans les réglages persistants, l’historique ou les journaux. Les fichiers temporaires en clair d’un export chiffré sont placés dans un dossier avec des permissions 0700 et nettoyés lors d’une annulation normale ou d’une erreur. Seuls les fichiers chiffrés validés selon le mode choisi sont publiés ; un échec ne peut pas entraîner un remplacement non chiffré.
- Les langues de reconnaissance OCR dépendent toujours des possibilités de Vision sur le Mac ; leur nombre ne se déduit pas du nombre de langues de l’interface.

## Limites de la validation

- La machine de validation est un Mac Intel. Les deux architectures du paquet universel 1.4 ont été compilées avec succès, mais aucun test sur un Mac Apple Silicon physique n’a encore été effectué.
- La cible minimale de déploiement est macOS 14 ; l’environnement réellement utilisé pour cette validation est macOS 15.7.9.
- JPEG XL utilise le décodage natif d’ImageIO. Les 5 échantillons de test générés en interne couvrent le RGB avec perte, le RGB sans perte, la transparence RGBA, les niveaux de gris sur 16 bits et l’animation. Le système actuel ne renvoie que la première image animée ; l’importation image par image n’est donc pas garantie. L’application ne propose pas de sortie encodée en JXL et ne garantit pas la conservation à l’identique du flux original, des informations HDR ou de profondeur de couleur élevée dans le PDF.
- Aucun banc d’essai de performances n’a été réalisé sur de grands volumes de livres numérisés. La compatibilité avec tous les formats RAW d’appareils photo ou toutes les destinations PDF non standard n’est pas garantie.
- Le chiffrement utilise Apple PDFKit, exige une sortie AESV2/128 bits et vérifie les mots de passe et autorisations selon le mode choisi. Le problème de l’interface native locale avec les mots de passe d’ouverture de 17–31 caractères affecte l’authentification owner. Le mode double limite donc uniformément le mot de passe d’ouverture à 1–16 caractères ; le mot de passe de modification et chacun des deux modes à mot de passe unique acceptent 1–32 caractères. L’application ne corrige pas elle-même les résultats cryptographiques et refuse Unicode, les caractères de contrôle et les entrées hors des limites du mode choisi. Les contrôles de limites, les droits owner et la conservation des espaces de début et de fin sont vérifiés sur de vrais fichiers. En mode double, les mots de passe d’ouverture de 17, 31 et 32 caractères sont refusés avant l’écriture.
- Les étiquettes de page à préfixe textuel personnalisé ne peuvent pas être conservées de manière fiable par le chemin natif actuel : activer le chiffrement produit une erreur explicite. Les numérotations ordinaires alphabétiques/romaines/numériques par sections, la présentation de lecture et les métadonnées ont été soumises à des tests d’aller-retour. Les fichiers nécessitant un mot de passe d’ouverture permettent sa saisie dans l’aperçu intégré ; ceux avec uniquement un mot de passe de modification s’affichent directement. Les signets des fichiers chiffrés restent non modifiables.
- Les limites actuelles, notamment l’absence d’encodage JBIG2/G4, les fonctions de correction OCR, les interfaces multicouches et certaines destinations de signets spéciales, sont détaillées dans la section « Limites actuelles » du README.

## Captures de cette version

| État | Capture de la fenêtre réelle |
|---|---|
| Chinois, importation d’images JPEG XL statiques | [jpeg-xl-import-zh.png](../screenshots/jpeg-xl-import-zh.png) |
| Chinois, chiffrement replié par défaut | [encryption-collapsed-zh.png](../screenshots/encryption-collapsed-zh.png) |
| Chinois, deux mots de passe développés | [encryption-inline-zh.png](../screenshots/encryption-inline-zh.png) |
| Allemand, apparence sombre, deux mots de passe développés | [encryption-inline-de-dark.png](../screenshots/encryption-inline-de-dark.png) |
| Arabe, RTL, deux mots de passe développés | [encryption-inline-ar.png](../screenshots/encryption-inline-ar.png) |
| Application universelle finale, chinois, modification seule et réouverture après fermeture | [encryption-editing-only-zh.png](../screenshots/encryption-editing-only-zh.png) |

Les captures proviennent du rendu des `NSView` de l’application elle-même et ne contiennent aucune autre application. `build-results.txt` consigne la compilation de production pour les deux architectures ; `SHA256SUMS-1.4.txt`, dans [Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.4.0), contient les sommes de contrôle des ZIP distribués. Les captures de l’ancienne disposition ont été déplacées vers `screenshots/previous-layout/` et ne servent pas à valider l’interface de cette version.

Les journaux bruts des tests, de la compilation et des captures ont été produits par les outils. Leur sortie d’origine est conservée, avec le chemin local du projet remplacé par `<project>` ; une traduction des journaux n’est pas présentée comme une preuve brute. Les 16 versions linguistiques de ce rapport expliquent les mêmes résultats, environnements et limites. Les sources ne contiennent ni caches de compilation ni binaires de distribution ; téléchargez les paquets depuis Releases dans le dépôt.
