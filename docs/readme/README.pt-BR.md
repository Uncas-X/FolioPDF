# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · **Português (Brasil)** · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- languages:end -->

Aplicativo nativo para macOS que cria livros em PDF a partir de imagens e edita marcadores de PDF. Reimplementa os requisitos do FreePic2Pdf com uma interface SwiftUI de design independente e frameworks do sistema Apple. Não exige runtime de terceiros, não envia arquivos pela rede e não requer configuração de chave de API.

## Como usar

Baixe `FolioPDF-1.3-macOS.zip` em [GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest), descompacte e abra `FolioPDF.app`. Você também pode arrastar o aplicativo para a pasta Aplicativos. É necessário **macOS 14 ou posterior**. O aplicativo compilado localmente fica em `dist/FolioPDF.app`.

Os pacotes da versão 1.3 são `FolioPDF-1.3-macOS.zip` e `FolioPDF-1.3-source.zip`; o aplicativo dentro do ZIP sempre se chama `FolioPDF.app`. O [registro de validação](../validation/VALIDATION.pt-BR.md) apresenta o estado das verificações, o ambiente de execução e capturas da interface real. O repositório de código-fonte não inclui caches de compilação nem binários do aplicativo; os instaladores estão nas Releases.

1. Em «Criar PDF», adicione imagens, arraste arquivos ou adicione uma ou mais pastas. A busca recursiva em pastas deve ser configurada no painel direito antes da importação.
2. Clique para selecionar uma imagem e use Command-clique para selecionar várias. Arraste uma imagem sobre outra para mudar a ordem ou use os botões inferiores para mover para frente ou para trás. Clique duas vezes para visualizar. É possível alternar entre miniaturas e lista.
3. À direita, escolha um PDF combinado, um PDF por arquivo de origem ou um PDF por pasta. Ajuste papel, margens, DPI, compactação, OCR e informações do documento.
4. Para proteger com senha, role o painel direito para baixo e expanda «Criptografia de PDF», depois de «Informações do documento». A seção começa recolhida e mostra as configurações diretamente ao ser expandida. «Senha de abertura» e «Senha de edição» têm controles independentes. Preencha e confirme cada senha habilitada; a tabela abaixo explica as permissões. Todos os PDFs do lote usam essas configurações.
5. Clique em «Criar PDF». Arquivos existentes não são sobrescritos: nomes repetidos geram automaticamente um novo arquivo numerado. Cada página ou quadro de um TIFF/GIF com várias páginas vira, em sequência, uma página PDF. «Um PDF por arquivo de imagem» não divide o mesmo arquivo de origem em vários PDFs.
6. Na área «Marcadores», abra PDFs sem criptografia, adicione, edite, mova ou recue entradas do índice, confira destinos na visualização, importe e exporte TXT, JSON ou arquivos de interface compatíveis e salve uma cópia.

Toda a linha de título das seções expansíveis, como «Informações do documento», «Criptografia de PDF» e «Margens e resolução», é clicável, incluindo o espaço vazio ao lado do título. A navegação das áreas de trabalho à esquerda também aceita cliques na linha inteira. «Criptografia de PDF» começa recolhida e, quando expandida, acompanha a rolagem do painel direito.

⌘N mostra a janela principal, ⌘O adiciona imagens, ⌘⇧O adiciona pastas, ⌘E exporta e ⌘, abre os ajustes. Fechar e reabrir a janela principal mantém a sessão atual. Encerrar o aplicativo não salva automaticamente rascunhos de marcadores; salve uma cópia antes de sair.

### Senhas de abertura e edição

| Opção habilitada | Tamanho da senha | Permissões de leitura e uso |
|---|---|---|
| Apenas senha de abertura | Abertura: 1–32 caracteres | É preciso informar a senha para abrir o PDF; a senha correta libera todas as operações |
| Apenas senha de edição | Edição: 1–32 caracteres | A leitura não exige senha. Para o leitor comum, ficam restritos alterações de conteúdo, anotações, preenchimento de formulários e inserção, exclusão ou rotação de páginas. A senha de edição concede todas as permissões |
| Ambas as senhas | Abertura: 1–16 caracteres; edição: 1–32 caracteres | A senha de abertura concede permissões restritas de leitura. A senha de edição concede todas as permissões e também abre o PDF diretamente |

Quando as duas senhas estão habilitadas, elas precisam ser diferentes. Impressão, cópia e acesso de acessibilidade continuam permitidos. As restrições de edição dependem de o leitor PDF respeitar as permissões; elas não garantem que seja absolutamente impossível modificar o conteúdo.

Só são aceitos caracteres ASCII imprimíveis: letras sem acento, números, símbolos e espaços. Valem os tamanhos indicados na tabela. Quando as duas senhas estão ativas, a interface informa o limite de 16 caracteres para a senha de abertura. Entradas acima do limite são rejeitadas antes da exportação; as senhas não são truncadas e espaços no início ou no fim não são removidos automaticamente.

As senhas ficam apenas na sessão atual do aplicativo, sem serem gravadas em ajustes, histórico ou logs. Desabilitar uma opção apaga a senha e a confirmação correspondentes; redefinir os ajustes limpa os dois grupos. Senhas ou confirmações inválidas impedem a exportação. Com as duas opções desabilitadas, é gerado um PDF normal.

Por padrão, o idioma da interface acompanha o sistema. Você pode escolher manualmente entre estes **16 idiomas** a qualquer momento, sem reiniciar:

**简体中文** · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · Türkçe · Nederlands · Polski

O árabe usa um layout da direita para a esquerda. Imagens e conteúdo PDF permanecem inalterados; o editor de texto de marcadores com TAB mantém a estrutura da esquerda para a direita. A aparência pode seguir o sistema, ser clara ou escura. Controles do macOS, como os seletores de arquivos do sistema, usam o idioma configurado no sistema. O idioma da interface e o de OCR são ajustados separadamente; as opções de OCR dependem do suporte do Vision neste Mac.

## Recursos implementados

| Recurso | Implementação |
|---|---|
| Entrada de imagens | JPEG, PNG, TIFF, GIF, BMP, HEIC/HEIF, JPEG 2000 e outros formatos decodificáveis pelo ImageIO; descoberta dinâmica de outras extensões suportadas pelo sistema atual. O suporte RAW depende do decodificador local e não é garantido para todos os modelos de câmera |
| Organização de arquivos | Remoção de duplicatas, ordem por nome ou número final, ordem manual, prefixos comuns de e-books, busca recursiva e inclusão opcional da pasta superior |
| Saída em lote | Um PDF combinado, um por arquivo de origem ou um por pasta pai imediata. Pastas mais profundas são agrupadas separadamente, sem contabilizar novamente suas imagens na pasta superior |
| Páginas | Tamanho original, largura fixa, A3/A4/A5/B5/Letter/Legal, medidas personalizadas em milímetros, paisagem, quatro margens, ampliação de imagens pequenas e prioridade aos metadados DPI |
| Compactação | Caminho sem perdas e controle de qualidade JPEG. JPEGs com orientação original normal podem preservar o fluxo DCT original. Outros formatos e orientações são decodificados e diagramados corretamente pelo ImageIO; não se garante a preservação byte a byte do fluxo de todos os formatos de origem |
| Transparência | Preservar transparência ou aplicar fundo branco. JPEG não armazena alfa; ao preservar transparência, a codificação sem perdas é usada automaticamente e um aviso é exibido |
| OCR | Reconhecimento local preciso com Apple Vision, idioma automático ou selecionado entre os disponíveis e texto oculto pesquisável e copiável. Se a execução pela GPU falhar, tenta a CPU. Páginas com falha de reconhecimento mantêm a imagem e o erro é informado explicitamente |
| Propriedades do documento | Título, autor, assunto e palavras-chave; layout de leitura em página única, contínuo ou em duas páginas |
| Criptografia de PDF | AES-128 nativo do PDFKit, com senha de abertura, de edição ou ambas. Se houver apenas senha de abertura, é gerada uma senha owner aleatória; a senha de edição, quando definida, concede privilégios owner completos. O arquivo só é publicado após verificar bloqueio, senhas, permissões reader/owner e número de páginas conforme o modo. Falhas não produzem um substituto sem criptografia. A visualização no aplicativo aceita senhas |
| Marcadores | Marcadores automáticos dos arquivos de origem, índice multinível, números de página, conversão de página-base, texto editável e JSON, além de visualização nativa dos destinos PDF |
| Compatibilidade de interface | `FreePic2Pdf.itf` e `FreePic2Pdf_bkmk.txt`, UTF-8/UTF-16LE e codificações legadas pertinentes; numeração separada para sumário e corpo, metadados, páginas de texto pesquisável anexadas e configurações de exibição de marcadores |
| Estabilidade | Tarefas em segundo plano, liberação de imagens por página, progresso, cancelamento, logs, temporários e publicação atômica, numeração automática para nomes repetidos e preservação com listagem dos resultados prontos quando um lote falha |

### Diferenças explícitas em relação ao programa original

- O OCR usa Apple Vision no lugar de MODI e não exige Office ou Windows. Não reproduz a limpeza de gráficos, fontes CJK ou opções por palavra/linha do programa original.
- A compactação atual oferece sem perdas e JPEG; os codificadores JBIG2, CCITT G4 e JPEG 2000 não foram reproduzidos. Os recursos principais estão disponíveis, mas livros grandes em preto e branco podem ficar maiores que com ferramentas JBIG2 especializadas.
- Não inclui as ferramentas originais de revisão para mostrar/ocultar texto OCR ou excluir fisicamente imagens digitalizadas. Também não fornece restauração de imagens nem um editor completo de conteúdo PDF.
- A composição multicamada `[Images]` e `MinWidth` da interface compatível ainda não foram implementados. Quando encontrados, são informados sem alegar que foram aplicados. Se a ordem manual dos arquivos não corresponder às páginas absolutas da interface, é necessário conferir os destinos do índice.
- São aceitos destinos de páginas locais comuns, algumas ações padronizadas com nome e URLs. Destinos em PDFs externos que o PDFKit não consegue salvar de forma confiável e destinos especiais ou nomeados não resolvidos são marcados explicitamente e impedem um salvamento silencioso. Eles podem ser substituídos no editor por páginas locais válidas. JSON/TXT podem preservar os dados dos destinos. PDFs criptografados não permitem edição de marcadores.
- A criptografia preserva marcadores, texto OCR, metadados, layout de leitura e numeração comum por seções. O PDFKit nativo não preserva rótulos de página; o aplicativo restaura com segurança apenas os que não têm prefixos de texto. Arquivos de interface com prefixos personalizados bloqueiam explicitamente a exportação criptografada: remova os prefixos ou desative a criptografia.
- A ordem de e-books usa grupos comuns de prefixos: cov, bok, leg, fow, !, toc, corpo numérico, att, ins e bac; os demais vêm depois. Não se afirma equivalência exata com regras não publicadas do programa original.
- Em caso de cancelamento ou erro, os PDFs já gerados no lote são mantidos e o PDF temporário incompleto atual é removido. Não há retomada a partir de um ponto de interrupção.

## Desenvolvimento e compilação

O código é um Swift Package; abra `Package.swift` no Xcode. É necessário Xcode com macOS SDK e Swift 5.9 ou posterior. O ambiente validado é macOS 15.7.9 / Xcode Swift 6.2.4, com compatibilidade de execução a partir do macOS 14.

```sh
# Executar em modo de depuração
swift run FolioPDF

# Testes e verificação dos textos nos 16 idiomas
bash scripts/test.sh

# Gerar .app universal e ZIP para Intel + Apple Silicon
bash scripts/build-app.sh

# Compilar somente para a arquitetura desta máquina
bash scripts/build-app.sh --host-only
```

Os testes reais de OCR de `scripts/test.sh` precisam de acesso normal aos serviços macOS, incluindo Vision e CoreVideo. Uma sandbox de execução que limite hardware ou serviços pode causar falhas na criação de CVPixelBuffer. Em um ambiente normal, os testes devem ser executados e aprovados; ignorá-los não substitui a validação.

Os pacotes usam assinatura ad-hoc local e não incluem notarização Developer ID. Podem ser executados localmente; uma distribuição oficial para outros Macs requer certificado de desenvolvedor e o processo de notarização.

### Estrutura do código

```text
Sources/FolioCore/       Imagens, geometria, conversão, OCR, marcadores e arquivos de interface
Sources/FolioPDF/        Áreas SwiftUI, estado, visualização nativa e idiomas
Tests/FolioCoreTests/    Testes reais de ida e volta e limites de imagens/PDF/OCR/marcadores
scripts/                Testes, pacotes, ícone e geração de imagens de exemplo
packaging/Info.plist     Informações do aplicativo macOS
docs/                   Registros de validação e renderizações de janelas reais
dist/                   .app executável e ZIPs de distribuição (gerados na compilação)
```

## Idiomas da documentação

O README e o registro de validação estão disponíveis nos mesmos 16 idiomas da interface. Use os links de idioma no início do documento para alternar. Descrições de recursos, limites de senha, diferenças conhecidas e etapas de compilação são consistentes em todas as versões. Logs de testes, compilação e captura de janelas são evidências originais geradas por ferramentas e permanecem no idioma de origem. As explicações correspondentes são traduzidas no registro de validação.

## Referências técnicas

São usados a [API de detecção de idioma do Vision](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage), os [atributos de documento do PDFKit](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) e o [parâmetro de qualidade JPEG do ImageIO](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality) da Apple. A implementação também é verificada com declarações do SDK local e testes em arquivos reais. O programa FreePic2Pdf original, seus ícones e sua interface não foram copiados.
