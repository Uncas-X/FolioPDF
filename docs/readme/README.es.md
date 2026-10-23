# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · **Español** · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- languages:end -->

Aplicación nativa de macOS para crear libros PDF a partir de imágenes y editar marcadores PDF. FolioPDF utiliza una interfaz SwiftUI de diseño independiente y frameworks del sistema Apple. No necesita entornos de ejecución de terceros, no sube archivos a la red y no requiere configurar una clave de API.

## Uso

Descarga `FolioPDF-1.4-macOS.zip` desde [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest), descomprímelo y abre `FolioPDF.app`. También puedes arrastrarla a la carpeta Aplicaciones. Requiere **macOS 14 o posterior**. La aplicación compilada localmente se encuentra en `dist/FolioPDF.app`.

Los paquetes de la versión 1.4 son `FolioPDF-1.4-macOS.zip` y `FolioPDF-1.4-source.zip`; la aplicación incluida siempre se llama `FolioPDF.app`. El [registro de validación](../validation/VALIDATION.es.md) recoge el estado de las comprobaciones, el entorno de ejecución y capturas de la interfaz real. El repositorio de código fuente no incluye cachés de compilación ni binarios de la aplicación; los paquetes de instalación están en Releases.

1. En «Crear PDF», añade imágenes, arrastra archivos o añade una o varias carpetas. La búsqueda recursiva en carpetas se configura en el panel derecho antes de importar.
2. Haz clic para seleccionar una imagen y usa Command-clic para seleccionar varias. Arrastra una imagen sobre otra para cambiar el orden o utiliza los botones inferiores de avanzar y retroceder. Haz doble clic para obtener una vista previa. Puedes alternar entre miniaturas y lista.
3. En el panel derecho, elige una salida combinada, un PDF por archivo de origen o un PDF por carpeta. Ajusta papel, márgenes, DPI, compresión, OCR e información del documento.
4. Para proteger con contraseña, desplázate hacia abajo en el panel derecho y despliega «Cifrado de PDF», después de «Información del documento». La sección está contraída inicialmente y muestra los ajustes directamente al desplegarse. «Contraseña de apertura» y «Contraseña de edición» tienen interruptores independientes. Introduce y confirma cada contraseña activada; los permisos se detallan en la tabla siguiente. Todos los PDF del lote utilizan estos ajustes.
5. Pulsa «Crear PDF». No se sobrescriben archivos existentes: si el nombre coincide, se crea automáticamente otro archivo numerado. Cada página o fotograma de un TIFF/GIF multipágina se convierte, por orden, en una página PDF. «Un PDF por archivo de imagen» no divide un mismo archivo de origen en varios PDF.
6. En «Marcadores», abre PDF sin cifrar, añade, edita, mueve o sangra entradas del índice, comprueba los destinos en la vista previa, importa y exporta TXT, JSON o archivos de interfaz compatibles y guarda una copia.

Se puede pulsar toda la cabecera de secciones desplegables como «Información del documento», «Cifrado de PDF» y «Márgenes y resolución», incluido el espacio en blanco junto al título. La navegación de espacios de trabajo de la izquierda también admite clics en toda la fila. «Cifrado de PDF» está contraída inicialmente y se desplaza con el panel derecho al desplegarse.

⌘N muestra la ventana principal, ⌘O añade imágenes, ⌘⇧O añade carpetas, ⌘E exporta y ⌘, abre los ajustes. Cerrar y volver a abrir la ventana principal conserva la sesión actual. Salir de la aplicación no guarda automáticamente los borradores de marcadores; guarda antes una copia.

### Contraseñas de apertura y edición

| Activación | Longitud | Permisos de lectura y operación |
|---|---|---|
| Solo contraseña de apertura | Apertura: 1–32 caracteres | Se necesita contraseña para abrir el PDF; la contraseña correcta permite todas las operaciones |
| Solo contraseña de edición | Edición: 1–32 caracteres | Se puede leer sin contraseña. Para el lector normal se restringen los cambios de contenido, las anotaciones, el rellenado de formularios y la inserción, eliminación o rotación de páginas. La contraseña de edición concede todos los permisos |
| Ambas contraseñas | Apertura: 1–16 caracteres; edición: 1–32 caracteres | La contraseña de apertura concede permisos de lectura restringidos. La de edición concede todos los permisos y también permite abrir directamente el PDF |

Cuando se activan ambas contraseñas, deben ser diferentes. Imprimir, copiar y el acceso de accesibilidad siguen permitidos. Las restricciones de edición dependen de que el lector PDF respete los permisos; no garantizan que sea absolutamente imposible modificar el contenido.

Solo se aceptan caracteres ASCII imprimibles: letras sin acentos, números, símbolos y espacios. Se aplican las longitudes de la tabla. Al activar ambas contraseñas, la interfaz indica el límite de 16 caracteres para la de apertura. Las entradas demasiado largas se rechazan antes de exportar: no se truncan contraseñas ni se eliminan automáticamente espacios iniciales o finales.

Las contraseñas solo se conservan durante la sesión actual y no se escriben en ajustes, historial ni registros. Desactivar un interruptor borra su contraseña y confirmación; restablecer los ajustes borra ambas parejas. Una contraseña o confirmación no válida impide exportar. Con ambos interruptores desactivados se genera un PDF normal.

El idioma de la interfaz sigue al sistema de forma predeterminada. Puedes elegir manualmente entre estos **16 idiomas** en cualquier momento, sin reiniciar:

**简体中文** · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · Nederlands · Polski

La interfaz árabe se dispone de derecha a izquierda. Las imágenes y el contenido PDF permanecen intactos; el editor de texto de marcadores con TAB conserva la estructura de izquierda a derecha. La apariencia admite sistema, claro y oscuro. Los controles de macOS, como los selectores de archivos del sistema, utilizan el idioma del sistema. El idioma de interfaz y el de OCR se configuran por separado; las opciones de OCR dependen del soporte de Vision en ese Mac.

## Funciones implementadas

| Función | Implementación |
|---|---|
| Entrada de imágenes | JPEG, PNG, TIFF, GIF, BMP, HEIC/HEIF, JPEG 2000, JPEG XL (`.jxl`) y otros formatos que ImageIO puede decodificar. JPEG XL usa la decodificación nativa de ImageIO en macOS 14 o posterior. Se detectan dinámicamente otras extensiones compatibles con el sistema actual. El soporte RAW depende del decodificador del sistema local y no se garantiza para todas las cámaras |
| Organización de archivos | Eliminación de duplicados, orden por nombre o número final, orden manual, prefijos habituales de libros electrónicos, carpetas recursivas e inclusión opcional de la carpeta superior |
| Salida por lotes | Un PDF combinado, uno por archivo de origen o uno por carpeta superior inmediata. Las carpetas más profundas se agrupan por separado, sin contar de nuevo sus imágenes en la carpeta superior |
| Páginas | Tamaño original, ancho fijo, A3/A4/A5/B5/Letter/Legal, medidas personalizadas en milímetros, horizontal, cuatro márgenes, ampliación de imágenes pequeñas y prioridad de metadatos DPI |
| Compresión | Ruta sin pérdida y control de calidad JPEG. Los JPEG con orientación original normal pueden conservar su flujo DCT original. Otros formatos y orientaciones se decodifican y componen correctamente con ImageIO; no se promete conservar byte a byte el flujo de todos los formatos de origen |
| Transparencia | Conservar transparencia o poner fondo blanco. JPEG no admite alfa; si se conserva la transparencia se utiliza automáticamente codificación sin pérdida y se informa de ello |
| OCR | Reconocimiento local preciso con Apple Vision, selección automática o manual de idiomas disponibles y texto oculto que se puede buscar y copiar. Si falla la ruta GPU se intenta la CPU. Las páginas cuyo reconocimiento falla conservan su imagen y se informa explícitamente |
| Propiedades | Título, autor, asunto y palabras clave; lectura de página única, continua o a doble página |
| Cifrado de PDF | AES-128 nativo de PDFKit con contraseña de apertura, de edición o ambas. Si solo se define la de apertura, se genera una contraseña owner aleatoria; si hay contraseña de edición, esta concede todos los permisos owner. El archivo solo se publica tras comprobar bloqueo, contraseñas, permisos reader/owner y número de páginas según el modo. Un error no produce un sustituto sin cifrar. La vista previa admite introducir contraseñas |
| Marcadores | Marcadores automáticos por archivo de origen, índice multinivel, números de página, conversión de página base, texto editable y JSON, y vista previa nativa de destinos PDF |
| Archivos de interfaz de marcadores | Archivos genéricos de interfaz de marcadores ITF (`.itf`) y `TXT`, UTF-8/UTF-16LE y codificaciones antiguas pertinentes; numeración por secciones de índice y cuerpo, metadatos, páginas de texto buscable añadidas y ajustes de visualización de marcadores |
| Estabilidad | Tareas en segundo plano, liberación de imágenes por página, progreso, cancelación, registros, temporales y publicación atómica, numeración automática ante nombres repetidos y conservación y listado de resultados completados si falla un lote |

JPEG XL permite importar imágenes estáticas con pérdida, sin pérdida, transparentes y en escala de grises de 16 bits, además de generar miniaturas, previsualizarlas y convertirlas a PDF. Para JXL animado solo se garantiza el primer fotograma que el sistema pueda decodificar; no se garantiza importar toda la secuencia fotograma a fotograma. ImageIO en el entorno de validación actual solo devuelve el primer fotograma. La aplicación no ofrece salida codificada en JXL ni garantiza conservar sin cambios el flujo JXL original, HDR o la información de alta profundidad de bits en el PDF.

### Limitaciones actuales

- OCR usa Apple Vision de forma local, sin necesitar Office ni Windows. No se ofrecen limpieza de gráficos, controles específicos de fuentes CJK ni interruptores por palabra o línea.
- La compresión actual ofrece sin pérdida y JPEG; no se admite la codificación JBIG2, CCITT G4 o JPEG 2000. Las funciones principales están disponibles, pero los libros extensos en blanco y negro pueden ocupar más que con herramientas JBIG2 especializadas.
- No se incluyen herramientas de corrección para mostrar u ocultar texto OCR o borrar físicamente imágenes escaneadas. Tampoco se ofrece restauración de imágenes ni un editor completo del contenido PDF.
- La composición multicapa `[Images]` y `MinWidth` de la interfaz compatible aún no están implementados. Si se detectan, se muestra un aviso sin afirmar que se hayan aplicado. Si el orden manual de archivos no coincide con las páginas absolutas de la interfaz, hay que revisar los destinos del índice.
- Se admiten páginas locales normales, algunas acciones con nombre estándar y destinos URL. Los destinos PDF externos que PDFKit no puede guardar de forma fiable y los destinos especiales o con nombre no resueltos se señalan expresamente y no pueden guardarse silenciosamente. Se pueden sustituir en el editor por páginas locales válidas. JSON/TXT pueden conservar los datos del destino. No se editan marcadores de PDF cifrados.
- El cifrado conserva marcadores, texto OCR, metadatos, disposición de lectura y numeración ordinaria por secciones. PDFKit nativo no conserva las etiquetas de página; la aplicación solo restaura de forma segura las que no contienen prefijos de texto. Los archivos de interfaz con prefijos personalizados bloquean explícitamente la exportación cifrada: elimina los prefijos o desactiva el cifrado.
- El orden de libros electrónicos aplica los grupos habituales de prefijos cov, bok, leg, fow, !, toc, cuerpo numérico, att, ins y bac; el resto va después.
- Al cancelar o producirse un error se conservan los PDF ya generados del lote y se elimina el PDF temporal incompleto actual. No existe reanudación desde un punto de control.

## Desarrollo y compilación

El código es un Swift Package; abre `Package.swift` con Xcode. Necesitas Xcode con macOS SDK y Swift 5.9 o posterior. El entorno validado es macOS 15.7.9 / Xcode Swift 6.2.4; el destino de ejecución es macOS 14.

```sh
# Ejecutar en modo de depuración
swift run FolioPDF

# Pruebas y comprobación de textos en 16 idiomas
bash scripts/test.sh

# Crear .app universal y ZIP para Intel + Apple Silicon
bash scripts/build-app.sh

# Compilar solo para la arquitectura del equipo actual
bash scripts/build-app.sh --host-only
```

Las pruebas OCR reales de `scripts/test.sh` necesitan acceso normal a servicios de macOS como Vision y CoreVideo. Una sandbox de ejecución que limite hardware o servicios puede provocar errores al crear CVPixelBuffer. Las pruebas deben ejecutarse y superarse en un entorno normal; omitirlas no sustituye la validación.

Los paquetes utilizan firma ad-hoc local, sin notarización Developer ID. Pueden ejecutarse localmente; una distribución formal a otros Mac requiere certificado de desarrollador y el proceso de notarización.

### Estructura del código

```text
Sources/FolioCore/       Imágenes, geometría, conversión, OCR, marcadores y archivos de interfaz
Sources/FolioPDF/        Espacios SwiftUI, estado, vista previa nativa e idiomas
Tests/FolioCoreTests/    Pruebas reales de ida y vuelta y límites de imágenes/PDF/OCR/marcadores
scripts/                Pruebas, paquetes, icono y generación de imágenes de ejemplo
packaging/Info.plist     Información de la aplicación macOS
docs/                   Registros de validación y renderizados de ventanas reales
dist/                   .app ejecutable y ZIP de distribución (generados al compilar)
```

## Idiomas de la documentación

El README y el registro de validación están disponibles en los mismos 16 idiomas que la interfaz. Puedes cambiar mediante los enlaces de idioma al principio del documento. Las funciones, los límites de contraseña, las limitaciones conocidas y los pasos de compilación coinciden entre versiones. Los registros de pruebas, compilación y capturas son pruebas originales generadas por herramientas y se conservan en su idioma original. Sus explicaciones se ofrecen en varios idiomas en el registro de validación.

## Referencias técnicas

Se utilizan la [API de detección de idioma de Vision](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage), los [atributos de documento de PDFKit](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) y el [parámetro de calidad JPEG de ImageIO](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality) de Apple. La implementación también se comprueba con las declaraciones del SDK local y pruebas de archivos reales. FolioPDF combina una interfaz de diseño independiente con los frameworks nativos del sistema.
