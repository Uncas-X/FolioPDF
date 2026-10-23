# FolioPDF 1.3 — Registro de validação

<!-- languages:start -->
[简体中文](../VALIDATION.md) · [English](VALIDATION.en.md) · [繁體中文](VALIDATION.zh-Hant.md) · [日本語](VALIDATION.ja.md) · [한국어](VALIDATION.ko.md) · [Français](VALIDATION.fr.md) · [Deutsch](VALIDATION.de.md) · [Español](VALIDATION.es.md) · [Italiano](VALIDATION.it.md) · **Português (Brasil)** · [Русский](VALIDATION.ru.md) · [العربية](VALIDATION.ar.md) · [हिन्दी](VALIDATION.hi.md) · [Türkçe](VALIDATION.tr.md) · [Nederlands](VALIDATION.nl.md) · [Polski](VALIDATION.pl.md)
<!-- languages:end -->

Status: **testes e compilação aprovados**. Data: 2026-10-23. Ambiente: Intel Mac, macOS 15.7.9, Swift 6.2.4 / Xcode. Versão mínima de implantação: macOS 14.

Esta versão adiciona senhas independentes de abertura e edição. As configurações de criptografia ficam em uma seção do painel direito, inicialmente recolhida e com a linha inteira clicável. Todos os 50 XCTest foram executados: 0 falhas e 0 testes ignorados. Foi confirmado que a interface nativa de gravação PDF deste Mac pode invalidar a senha owner quando a senha de abertura tem 17–31 caracteres. O aplicativo evita isso verificando o tamanho antes de exportar no modo de duas senhas; os limites seguros estão descritos abaixo. O log desta execução é `test-results.txt`.

## Entregáveis

- `dist/FolioPDF.app`: janelas AppKit nativas, interface SwiftUI e frameworks do sistema PDFKit / Vision / ImageIO. O nome do aplicativo não inclui versão; ela fica nos metadados.
- `dist/FolioPDF-1.3-macOS.zip`: aplicativo universal com x86_64 e arm64, conferido com `lipo -archs`.
- `dist/FolioPDF-1.3-source.zip`: código Swift Package que pode ser aberto no Xcode, incluindo testes, scripts, instruções e capturas da interface.
- O script de empacotamento usa assinatura ad-hoc local; `codesign --verify --deep --strict` passou. Não há notarização Developer ID. A versão interna é 1.3 (build 4); o arquivo continua sendo `FolioPDF.app`.

## Testes funcionais

Foi executado `bash scripts/test.sh`, com aprovação dos 50 XCTest. A saída detalhada está em `test-results.txt`. Os testes reais de OCR com Vision também foram executados, sem serem ignorados.

| Área | Quantidade | Conteúdo verificado |
|---|---:|---|
| Descoberta e ordenação de arquivos | 3 | Ordem numérica, prefixos de e-books, subpastas e exclusão da pasta superior, caminhos duplicados |
| Conversão PDF | 10 | Geometria e parâmetros inválidos, orientação EXIF, TIFF/GIF multipágina, metadados e marcadores, grupos por pasta, proteção contra sobrescrita, falhas parciais em lotes, codificação JPEG real, fluxo JPEG original preservado, texto Vision oculto e pesquisável, limpeza ao cancelar |
| Marcadores e arquivos de interface | 8 | Índice multinível, conversão BasePage, destinos inválidos, ações padrão e JSON, rejeição explícita de destinos externos, interface UTF-16 e numeração por seções, salvar cópia, páginas de texto pesquisável e rótulos existentes preservados |
| Localização | 3 | 16 idiomas e ordem, recursos completos, 18 mapeamentos regionais de idioma, alternativa para idiomas desconhecidos, prioridade da escolha manual e RTL somente para árabe |
| Criptografia PDF nativa | 14 | Dicionário real AESV2/128 bits, modos apenas abertura/apenas edição/ambas, separação reader/owner, senha errada sem elevação de permissões, senhas diferentes, owner aleatório, limites de uma ou duas senhas, rejeição de abertura longa antes da gravação, espaços iniciais/finais, metadados chineses, marcadores, texto oculto, rótulos comuns por seções e layout, rejeição explícita de prefixos de texto, proteção contra sobrescrita e limpeza em falhas |
| Integração da conversão criptografada | 7 | Saída combinada, por arquivo e por pasta, numeração automática, originais intactos, nenhuma saída com senha inválida, permissões de duas senhas e metadados preservados, busca OCR real do Vision e aparência mantida, cancelamento determinístico durante a conversão e limpeza das pastas |
| Estado da interface de criptografia | 5 | Validação de ambas as senhas e confirmações, limpeza independente pelos controles, isolamento de sessão e redefinição, exportação completa e contagem no histórico nos três modos, senhas ausentes de ajustes/histórico/logs |

Os testes OCR usam imagens de texto realmente geradas, verificam a extração do texto PDF e conferem que o texto oculto não altera a renderização. Precisam ser executados com acesso aos serviços macOS; erros do CoreVideo em uma sandbox restrita não contam como aprovação.

### Critérios de aceitação das duas senhas

| Modo | Leitor comum | Pessoa com a senha de edição |
|---|---|---|
| Apenas abertura | Senha vazia ou errada não abre o PDF; a correta permite todas as operações | Não há senha de edição separada |
| Apenas edição | Leitura sem senha; alterações de conteúdo, anotações, preenchimento de formulários e organização de páginas são bloqueados | A senha de edição concede todas as permissões owner |
| Ambas | A senha de abertura concede permissões user restritas | A senha de edição abre o arquivo diretamente e concede todas as permissões owner |

As duas senhas precisam ser diferentes. Impressão, cópia e acessibilidade são permitidas nos três modos. O modo restrito desabilita alterações de conteúdo, anotações, formulários e inserção, exclusão ou rotação de páginas. O leitor precisa respeitar as permissões; não há garantia de impossibilidade absoluta de modificação.

São aceitos apenas caracteres ASCII imprimíveis. Faixas seguras: apenas abertura, 1–32 caracteres; apenas edição, 1–32; com ambas, abertura de 1–16 e edição de 1–32. O limite condicional é mostrado na interface e aplicado na pré-validação da exportação. Valores fora da faixa produzem erro, sem truncar senhas, alterar espaços nas pontas ou gerar uma saída com proteção reduzida.

Em um PDF já aberto, `unlock(withPassword:)` pode retornar `true` mesmo com uma senha owner incorreta. A validação precisa conferir `permissionsStatus` e todos os bits: reader restrito user/51, owner owner/255 e reader do modo apenas abertura user/255. O PDF com apenas senha de edição abre automaticamente; obter o número de páginas para o histórico não exige desbloqueio owner.

## Interface e idiomas

- Há 292 textos de recursos × 16 idiomas e 281 textos efetivamente usados na interface. `check-localization.py` passou; os recursos de idioma do pacote são idênticos byte a byte aos arquivos de origem.
- O padrão acompanha o sistema, na ordem solicitada: 简体中文, English, 繁體中文, 日本語, 한국어, Français, Deutsch, Español, Italiano, Português (Brasil), Русский, العربية, हिन्दी, Türkçe, Nederlands, Polski.
- As janelas principal e de ajustes usam RTL para árabe. Nomes de arquivo, imagens e PDF ficam intactos. O editor TAB de marcadores mantém LTR para não alterar o significado da edição dos arquivos de interface.
- O aplicativo foi reiniciado e sua NSView real foi renderizada. Foram conferidos chinês claro com criptografia recolhida e duas senhas expandidas, alemão escuro com textos longos, árabe RTL e modo apenas edição. Campos e explicações quebram linhas corretamente; não foram observadas sobreposições ou caracteres ausentes. Conteúdo fora da área visível acompanha a rolagem do painel direito. As capturas estão abaixo.
- Os títulos «Informações do documento», «Criptografia de PDF» e «Margens e resolução» usam um Button de linha inteira. O rótulo ocupa a largura disponível e um retângulo define a região clicável. A navegação lateral e a entrada inferior de ajustes também ampliam a área de clique. A revisão do código cobriu espaços vazios e direções semânticas RTL; não foi feito um teste independente de automação do mouse. Foram verificados o início do aplicativo final e o fechamento e reabertura da janela principal; o log registra `reopen verified: true`.
- Durante a conversão, fechar a janela e encerrar o aplicativo são bloqueados. Marcadores não salvos geram confirmação ao fechar ou sair. Reabrir a janela mantém o rascunho da sessão.
- O botão de ajustes e ⌘, abrem a mesma janela nativa. ⌘N mostra a principal, ⌘O adiciona imagens, ⌘⇧O pastas e ⌘E exporta.
- «Criptografia de PDF» fica em uma seção independente depois de «Informações do documento», inicialmente recolhida e rolável com o painel direito. Expandir mostra diretamente os dois grupos de senha, sem painel flutuante. Cada grupo tem controle, campo de senha mascarado e confirmação próprios.
- Desabilitar um grupo limpa apenas sua senha e confirmação; redefinir limpa ambos. Senhas inválidas, confirmações divergentes ou senhas iguais impedem a exportação. Com os dois grupos desabilitados, sai um PDF normal. Recolher ou expandir não altera a proteção.
- As duas senhas ficam apenas no processo atual, sem gravação em ajustes, histórico ou logs. Intermediários sem criptografia de exportações protegidas ficam em uma pasta com permissões 0700, limpa nas rotas normais de cancelamento e erro. Só são publicados arquivos aprovados para o modo escolhido; uma falha nunca gera uma alternativa sem criptografia.
- Os idiomas OCR continuam dependendo do Vision local; sua quantidade não é inferida pelo número de idiomas da interface.

## Limites da validação

- A máquina de validação é um Intel Mac. As duas arquiteturas do pacote universal 1.3 foram compiladas com sucesso; não houve teste em hardware Apple Silicon real.
- O alvo mínimo é macOS 14; a execução real ocorreu no macOS 15.7.9.
- Não foram feitos benchmarks de livros digitalizados em grande escala e não se garante compatibilidade com todo RAW de câmera ou destino PDF não padrão.
- A criptografia usa Apple PDFKit, exige AESV2/128 bits e valida senhas e permissões conforme o modo. O problema nativo com senhas de abertura de 17–31 caracteres afeta a autenticação owner; por isso o modo com duas senhas limita uniformemente a abertura a 1–16 caracteres. A senha de edição e os dois modos de senha única aceitam 1–32. O aplicativo não corrige resultados criptográficos por conta própria; rejeita Unicode, caracteres de controle e entradas fora dos limites. Pré-validação, permissões owner e preservação de espaços nas pontas têm testes com arquivos reais; no modo duplo, aberturas de 17, 31 e 32 caracteres são rejeitadas antes da gravação.
- Rótulos de página com prefixos de texto personalizados não podem ser preservados de forma confiável pela rota nativa atual e geram erro explícito ao criptografar. Numeração alfabética, romana e numérica por seções, layout de leitura e metadados têm testes de ida e volta. A visualização interna aceita senha de abertura; arquivos com apenas senha de edição são visualizados diretamente. A edição de marcadores em arquivos criptografados continua indisponível.
- Diferenças do programa original, incluindo JBIG2/G4, correção OCR antiga, múltiplas camadas na interface e alguns destinos especiais de marcadores, estão em «Diferenças explícitas em relação ao programa original» no README.

## Capturas desta versão

| Estado | Captura da janela real |
|---|---|
| Chinês, criptografia inicialmente recolhida | [encryption-collapsed-zh.png](../screenshots/encryption-collapsed-zh.png) |
| Chinês, duas senhas expandidas | [encryption-inline-zh.png](../screenshots/encryption-inline-zh.png) |
| Alemão, escuro, duas senhas expandidas | [encryption-inline-de-dark.png](../screenshots/encryption-inline-de-dark.png) |
| Árabe, RTL, duas senhas expandidas | [encryption-inline-ar.png](../screenshots/encryption-inline-ar.png) |
| App universal final, chinês, apenas edição e reabertura da janela | [encryption-editing-only-zh.png](../screenshots/encryption-editing-only-zh.png) |

As capturas foram obtidas pela renderização da própria `NSView` do aplicativo, sem conteúdo de outros programas. `build-results.txt` registra a compilação de produção para as duas arquiteturas. `SHA256SUMS-1.3.txt`, nas [Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.3.0), contém os checksums dos ZIPs distribuídos. As capturas do layout antigo foram movidas para `screenshots/previous-layout/` e não servem como evidência da interface desta versão.

Os logs originais de testes, compilação e capturas são gerados pelas ferramentas. A saída original é mantida, substituindo caminhos locais do projeto por `<project>`; traduções de logs não são apresentadas como evidências originais. As 16 versões deste registro explicam os mesmos resultados, ambiente e limites. O código-fonte não inclui caches de compilação ou binários de distribuição; baixe os pacotes nas Releases do repositório privado.
