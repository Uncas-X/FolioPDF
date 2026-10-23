# FolioPDF 1.4: registro de validación

<!-- languages:start -->
[简体中文](../VALIDATION.md) · [English](VALIDATION.en.md) · [繁體中文](VALIDATION.zh-Hant.md) · [日本語](VALIDATION.ja.md) · [한국어](VALIDATION.ko.md) · [Français](VALIDATION.fr.md) · [Deutsch](VALIDATION.de.md) · **Español** · [Italiano](VALIDATION.it.md) · [Português (Brasil)](VALIDATION.pt-BR.md) · [Русский](VALIDATION.ru.md) · [العربية](VALIDATION.ar.md) · [हिन्दी](VALIDATION.hi.md) · [Türkçe](VALIDATION.tr.md) · [Nederlands](VALIDATION.nl.md) · [Polski](VALIDATION.pl.md)
<!-- languages:end -->

Estado: **pruebas y compilación superadas**. Fecha: 2026-10-23. Entorno: Intel Mac, macOS 15.7.9, Swift 6.2.4 / Xcode. Versión mínima de despliegue: macOS 14.

Esta versión admite imágenes JPEG XL mediante ImageIO nativo en macOS 14 o posterior, además de contraseñas independientes de apertura y edición. El cifrado se configura en una sección del panel derecho, contraída inicialmente y con toda la cabecera pulsable. Se ejecutaron los 58 XCTest completos: 0 fallos y 0 omitidos. Se confirmó que la interfaz nativa de escritura PDF de este Mac puede invalidar la contraseña owner cuando la contraseña de apertura tiene 17–31 caracteres. La aplicación lo evita comprobando la longitud antes de exportar con dos contraseñas; los límites seguros se describen más adelante. El registro de esta ejecución es `test-results.txt`.

## Entregables

- `dist/FolioPDF.app`: ventanas AppKit nativas, interfaz SwiftUI y frameworks del sistema PDFKit / Vision / ImageIO. El nombre de la aplicación no lleva versión; esta se guarda en sus metadatos.
- `dist/FolioPDF-1.4-macOS.zip`: aplicación universal con x86_64 y arm64, comprobada con `lipo -archs`.
- `dist/FolioPDF-1.4-source.zip`: código Swift Package que se puede abrir en Xcode, con pruebas, scripts, instrucciones y capturas de interfaz.
- El script de empaquetado usa firma ad-hoc local; `codesign --verify --deep --strict` se superó. No hay notarización Developer ID. La versión interna es 1.4 (build 5); el archivo sigue llamándose `FolioPDF.app`.

## Pruebas funcionales

Se ejecutó `bash scripts/test.sh` y se superaron los 58 XCTest. La salida detallada está en `test-results.txt`. También se ejecutaron las pruebas reales de OCR con Vision, sin omisiones.

| Área | Cantidad | Contenido verificado |
|---|---:|---|
| Descubrimiento y orden de archivos | 3 | Orden numérico, prefijos de libros electrónicos, subcarpetas y exclusión de la carpeta superior, rutas duplicadas |
| Conversión PDF | 10 | Geometría y parámetros inválidos, orientación EXIF, TIFF/GIF multipágina, metadatos y marcadores, agrupación por carpeta, no sobrescritura, fallos parciales de lotes, codificación JPEG real, conservación del flujo JPEG original, texto oculto y buscable de Vision, limpieza al cancelar |
| Entrada JPEG XL | 8 | Correspondencia de tipos nativos y extensiones, detección en carpetas, RGB con/sin pérdida, transparencia RGBA, escala de grises de 16 bits, miniaturas y vista previa, dimensiones y renderizado PDF, salida transparente/con fondo blanco, salida de animación según los fotogramas expuestos por el sistema, rechazo de archivos dañados o ausentes |
| Marcadores y archivos de interfaz | 8 | Índice multinivel, conversión BasePage, destinos inválidos, acciones estándar y JSON, rechazo explícito de destinos externos, interfaz UTF-16 y numeración por secciones, guardar copia, páginas de texto buscable y conservación de etiquetas de página existentes |
| Localización | 3 | 16 idiomas y orden, carga completa de recursos, 18 correspondencias regionales de idioma, alternativa para idiomas desconocidos, prioridad de selección manual y RTL solo para árabe |
| Cifrado de PDF nativo | 14 | Diccionario real AESV2/128 bits, modos solo apertura/solo edición/ambos, separación de permisos reader/owner, ausencia de elevación con contraseñas erróneas, contraseñas distintas, owner aleatorio, límites de longitud de una o dos contraseñas, rechazo de apertura demasiado larga antes de escribir, espacios iniciales/finales, metadatos chinos, marcadores, texto oculto, etiquetas por secciones y disposición, rechazo explícito de prefijos de texto, no sobrescritura y limpieza tras errores |
| Integración de conversión cifrada | 7 | Salida combinada, por archivo y por carpeta, numeración automática, originales intactos, ausencia de salida con contraseñas inválidas, permisos de doble contraseña y metadatos conservados, búsqueda OCR real de Vision y apariencia intacta, cancelación determinista durante la conversión y limpieza de carpetas |
| Estado de la interfaz de cifrado | 5 | Validación de ambas contraseñas y confirmaciones, borrado independiente con interruptores, aislamiento de sesión y restablecimiento, exportación completa y páginas del historial en los tres modos, ausencia de contraseñas en ajustes/historial/registros |

Las pruebas OCR usan imágenes de texto realmente generadas, verifican la extracción de texto del PDF y comprueban que la capa oculta no cambia el renderizado. Deben ejecutarse con acceso a los servicios de macOS; los errores CoreVideo de una sandbox restringida no cuentan como una prueba superada.

### Criterios de aceptación de dos contraseñas

| Modo | Lector normal | Titular de la contraseña de edición |
|---|---|---|
| Solo apertura | Una contraseña vacía o incorrecta no abre el PDF; la correcta concede todas las operaciones | No se define contraseña de edición independiente |
| Solo edición | Lectura sin contraseña; se impiden cambios de contenido, anotaciones, rellenado de formularios y organización de páginas | La contraseña de edición concede todos los permisos owner |
| Ambas | La contraseña de apertura concede permisos user restringidos | La contraseña de edición abre directamente el archivo y concede todos los permisos owner |

Las dos contraseñas deben ser distintas. Imprimir, copiar y accesibilidad están permitidos en los tres modos. El modo restringido desactiva modificaciones, anotaciones, formularios e inserción, eliminación o rotación de páginas. El lector debe respetar los permisos; no se garantiza una imposibilidad absoluta de modificación.

Solo se permiten caracteres ASCII imprimibles. Intervalos seguros: solo apertura, 1–32 caracteres; solo edición, 1–32; con ambas, apertura de 1–16 y edición de 1–32. La restricción condicional se muestra expresamente y se comprueba antes de exportar. Una longitud fuera del intervalo produce un error, sin truncar, modificar espacios de los extremos ni generar una salida con menor protección.

En un PDF ya abierto, `unlock(withPassword:)` puede devolver `true` incluso con un owner incorrecto. Por ello se comprueban `permissionsStatus` y todos los bits de permisos: reader restringido user/51, owner owner/255 y reader del modo solo apertura user/255. El modo solo edición se abre automáticamente y permite obtener las páginas del historial sin desbloqueo owner.

## Interfaz e idiomas

- Hay 292 textos de recursos × 16 idiomas y 281 textos usados en la interfaz. `check-localization.py` se superó; los recursos de idioma empaquetados coinciden byte a byte con las fuentes.
- Por defecto se sigue el sistema, en el orden solicitado: 简体中文, English, 繁體中文, 日本語, 한국어, Français, Deutsch, Español, Italiano, Português (Brasil), Русский, العربية, हिन्दी, Türkçe, Nederlands, Polski.
- Las ventanas principal y de ajustes usan RTL en árabe; nombres de archivo, imágenes y PDF permanecen intactos. El editor TAB de marcadores conserva LTR para no cambiar el significado de la edición de archivos de interfaz.
- Se reinició la aplicación y se renderizó su NSView real. Se revisaron chino claro con cifrado contraído y con ambas contraseñas desplegadas, alemán oscuro con textos largos, árabe RTL y modo solo edición. Campos y explicaciones ajustan las líneas correctamente, sin solapamientos ni caracteres ausentes observados. El contenido fuera de la ventana se desplaza con el panel derecho. Las capturas aparecen abajo.
- Las cabeceras «Información del documento», «Cifrado de PDF» y «Márgenes y resolución» usan un Button de fila completa. Tras extender la etiqueta al ancho disponible, un rectángulo define la zona pulsable. La navegación izquierda y el acceso inferior a ajustes también amplían su zona. La revisión del código cubrió espacios vacíos y direcciones semánticas RTL; no se realizó una prueba independiente de automatización del ratón. Se validaron el arranque de la app final y la reapertura de su ventana principal; el registro indica `reopen verified: true`.
- Durante la conversión se impide cerrar la ventana o salir. Los marcadores sin guardar generan una confirmación al cerrar o salir. Reabrir la ventana conserva el borrador de la sesión.
- El botón de ajustes y ⌘, abren la misma ventana nativa. ⌘N muestra la principal, ⌘O añade imágenes, ⌘⇧O añade carpetas y ⌘E exporta.
- «Cifrado de PDF» es una sección independiente después de «Información del documento», inicialmente contraída y desplazable con el panel derecho. Al desplegarla muestra directamente ambos grupos, sin ventana emergente. Cada contraseña tiene interruptor, campo de entrada oculto y confirmación propios.
- Desactivar un grupo solo borra su contraseña y confirmación; restablecer borra ambos. Contraseñas inválidas, confirmaciones distintas o ambas contraseñas idénticas impiden exportar. Desactivar los dos grupos genera un PDF normal. Contraer o desplegar no cambia la protección.
- Ambas contraseñas permanecen únicamente en el proceso actual, sin guardarse en ajustes, historial ni registros. Los temporales sin cifrar de exportaciones protegidas se guardan en un directorio con permisos 0700 y se eliminan en cancelaciones y errores normales. Solo se publican archivos que superan la validación del modo; un fallo nunca genera una alternativa sin cifrar.
- Los idiomas OCR siguen dependiendo de Vision local; no se deduce su cantidad a partir de los idiomas de interfaz.

## Límites de validación

- El equipo de pruebas es un Intel Mac. Ambas arquitecturas del paquete universal 1.4 se compilaron correctamente; no se ha probado en un equipo Apple Silicon real.
- El despliegue mínimo es macOS 14; la ejecución real fue en macOS 15.7.9.
- JPEG XL usa la decodificación nativa de ImageIO. Las 5 muestras de prueba generadas internamente abarcan RGB con pérdida, RGB sin pérdida, transparencia RGBA, escala de grises de 16 bits y animación. El sistema actual solo devuelve el primer fotograma animado, por lo que no se garantiza la importación fotograma a fotograma. La aplicación no ofrece salida codificada en JXL ni garantiza conservar sin cambios el flujo original, HDR o la información de alta profundidad de bits en el PDF.
- No hay pruebas de rendimiento a gran escala con libros escaneados ni garantía para cualquier formato RAW de cámara o destino PDF no estándar.
- El cifrado usa Apple PDFKit, exige AESV2/128 bits y comprueba contraseñas y permisos según el modo. El problema nativo con contraseñas de apertura de 17–31 caracteres afecta a la autenticación owner; por eso el modo doble limita uniformemente la apertura a 1–16 caracteres. La edición y ambos modos de contraseña única admiten 1–32. La aplicación no modifica por su cuenta resultados criptográficos; rechaza Unicode, controles y longitudes fuera de los límites. Se prueban con archivos reales la prevalidación, los permisos owner y los espacios de los extremos. En modo doble se rechazan antes de escribir longitudes de apertura de 17, 31 y 32.
- Las etiquetas de página con prefijos personalizados no se conservan de forma fiable por la ruta nativa actual y provocan un error explícito al cifrar. La numeración alfabética, romana y numérica por secciones, la disposición de lectura y los metadatos cuentan con pruebas de ida y vuelta. La vista previa permite introducir una contraseña de apertura; el modo solo edición se previsualiza directamente. No se editan marcadores de archivos cifrados.
- Las limitaciones actuales, como la falta de codificación JBIG2/G4, las herramientas de corrección OCR, la interfaz multicapa y algunos destinos especiales, se explican en «Limitaciones actuales» del README del proyecto.

## Capturas de esta versión

| Estado | Captura de la ventana real |
|---|---|
| Chino, importación de imágenes JPEG XL estáticas | [jpeg-xl-import-zh.png](../screenshots/jpeg-xl-import-zh.png) |
| Chino, cifrado inicialmente contraído | [encryption-collapsed-zh.png](../screenshots/encryption-collapsed-zh.png) |
| Chino, ambas contraseñas desplegadas | [encryption-inline-zh.png](../screenshots/encryption-inline-zh.png) |
| Alemán, oscuro, ambas contraseñas desplegadas | [encryption-inline-de-dark.png](../screenshots/encryption-inline-de-dark.png) |
| Árabe, RTL, ambas contraseñas desplegadas | [encryption-inline-ar.png](../screenshots/encryption-inline-ar.png) |
| App universal final, chino, solo edición y reapertura de ventana | [encryption-editing-only-zh.png](../screenshots/encryption-editing-only-zh.png) |

Las capturas se obtuvieron renderizando la `NSView` de la propia aplicación, sin contenido de otras apps. `build-results.txt` documenta la compilación de producción para ambas arquitecturas. `SHA256SUMS-1.4.txt`, disponible en [Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.4.0), contiene las sumas de comprobación de los ZIP. Las capturas antiguas se trasladaron a `screenshots/previous-layout/` y no se utilizan como prueba de la interfaz actual.

Los registros originales de pruebas, compilación y capturas son generados por herramientas. Se conserva la salida y se sustituyen las rutas locales del proyecto por `<project>`; no se presentan traducciones como pruebas originales. Las 16 versiones de este documento explican los mismos resultados, entorno y límites. El código fuente no contiene cachés de compilación ni binarios de distribución; descarga los paquetes desde Releases del repositorio.
