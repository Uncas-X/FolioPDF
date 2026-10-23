# FolioPDF

<!-- languages:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · **Türkçe** · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- languages:end -->

Görüntülerden kitap oluşturmak ve PDF yer imlerini düzenlemek için yerel bir macOS uygulaması. FreePic2Pdf ürün gereksinimleri temel alınarak, özgün bir SwiftUI arayüzü ve Apple sistem framework’leriyle yeniden geliştirildi. Üçüncü taraf çalışma zamanı içermez, ağa dosya yüklemez ve API anahtarı gerektirmez.

## Kullanım

[GitHub Releases](https://github.com/Uncas-X/FolioPDF/releases/latest) üzerinden `FolioPDF-1.3-macOS.zip` dosyasını indirin, arşivi açın ve `FolioPDF.app` uygulamasını çalıştırın. Uygulamayı “Uygulamalar” klasörüne de sürükleyebilirsiniz. **macOS 14 veya üzeri** gereklidir. Yerel olarak oluşturulan uygulama `dist/FolioPDF.app` konumundadır.

1.3 sürümünün paketleri `FolioPDF-1.3-macOS.zip` ve `FolioPDF-1.3-source.zip` dosyalarıdır. ZIP içindeki uygulamanın adı her zaman `FolioPDF.app` olur. [Doğrulama kaydı](../validation/VALIDATION.tr.md), doğrulama durumunu, çalışma ortamını ve gerçek arayüz görüntülerini içerir. Kaynak kod deposunda derleme önbelleği veya uygulama ikili dosyaları bulunmaz; kurulum paketleri Releases bölümündedir.

1. “PDF oluştur” bölümünde görüntü ekleyin, dosyaları sürükleyin veya bir ya da birden fazla klasör ekleyin. Alt klasörlerde arama seçeneği sağdaki ayarlardadır; içe aktarmadan önce seçilmelidir.
2. Görüntü seçmek için tıklayın; çoklu seçim için Command tuşuyla tıklayın. Sıralamayı değiştirmek için görüntüyü başka bir görüntünün üzerine sürükleyin veya alttaki ileri/geri taşıma düğmelerini kullanın. Önizleme için çift tıklayın. Küçük resim ve liste görünümleri arasında geçiş yapabilirsiniz.
3. Sağ tarafta tek PDF’de birleştirme, kaynak dosya başına veya klasör başına çıktı seçin; kâğıt, kenar boşlukları, DPI, sıkıştırma, OCR ve belge bilgilerini ayarlayın.
4. Parola koruması için sağ ayar panelini aşağı kaydırın ve “Belge ayrıntıları” bölümünden sonraki “PDF şifreleme” bölümünü açın. Bu bölüm varsayılan olarak daraltılmıştır; genişletildiğinde ayarlar doğrudan görünür. “Açma parolası” ve “Düzenleme parolası” ayrı anahtarlara sahiptir. Etkinleştirdikten sonra ilgili parolayı ve doğrulamasını girin. İzinler aşağıdaki tabloda açıklanmıştır. Toplu dışa aktarımdaki her PDF aynı ayarları kullanır.
5. “PDF oluştur” düğmesine tıklayın. Var olan çıktı dosyalarının üzerine yazılmaz; ad çakışmalarında numaralı yeni dosya oluşturulur. Çok sayfalı TIFF/GIF dosyalarının her sayfası/karesi sırayla bir PDF sayfası olur. “Her görüntü dosyası için bir PDF” seçeneği, aynı kaynak dosyayı birden fazla PDF’ye bölmez.
6. “Yer imleri” çalışma alanında şifrelenmemiş bir PDF açabilir; içindekiler öğeleri ekleyebilir, düzenleyebilir, taşıyabilir ve girintileyebilir; hedeflere geçişi önizleyebilir; TXT, JSON veya uyumlu arayüz dosyalarını içe/dışa aktarabilir ve sonunda bir kopya kaydedebilirsiniz.

“Belge ayrıntıları”, “PDF şifreleme” ve “Kenar boşlukları ve çözünürlük” gibi açılır bölümlerin başlık satırının tamamı, başlık yanındaki boşluklar dâhil tıklanabilir. Soldaki çalışma alanı gezintisinde de satırın tamamı tıklanabilir. “PDF şifreleme” varsayılan olarak daraltılmıştır; genişletildiğinde sağ ayar paneliyle birlikte kayar.

⌘N ana pencereyi gösterir, ⌘O görüntü ekler, ⌘⇧O klasör ekler, ⌘E dışa aktarır, ⌘, ayarları açar. Ana pencereyi kapatıp yeniden açmak mevcut oturumu korur. Uygulamadan çıkmak yer imi taslaklarını otomatik kaydetmez; önce bir kopya kaydedin.

### Açma parolası ve düzenleme parolası

| Etkin koruma | Parola uzunluğu | Okuma ve işlem izinleri |
|---|---|---|
| Yalnızca açma parolası | Açma parolası 1–32 karakter | PDF’yi açmak için parola gerekir; doğru parolayla açıldığında tüm işlemlere izin verilir |
| Yalnızca düzenleme parolası | Düzenleme parolası 1–32 karakter | Parolasız okunabilir; normal okuyucuların içerik değiştirme, açıklama ekleme, form doldurma ve sayfa ekleme/silme/döndürme işlemleri kısıtlanır. Düzenleme parolası tüm izinleri verir |
| Her iki parola | Açma parolası 1–16, düzenleme parolası 1–32 karakter | Açma parolası kısıtlı okuma izinleri verir; düzenleme parolası tüm izinleri sağlar ve PDF’yi doğrudan açmak için de kullanılabilir |

İki parola birlikte etkinleştirildiğinde farklı olmalıdır. Yazdırma, kopyalama ve erişilebilirlik her zaman serbesttir. Düzenleme kısıtlamaları PDF okuyucusunun izinlere uymasına bağlıdır; içeriğin kesinlikle değiştirilemeyeceği anlamına gelmez.

Parolalarda yalnızca yazdırılabilir ASCII karakterleri (İngilizce harfler, rakamlar, semboller ve boşluklar) kabul edilir. Uzunluk sınırları yukarıdaki tabloda belirtilmiştir. İki parola etkin olduğunda arayüz, açma parolasının 16 karakter sınırını gösterir. Sınırı aşan parolalar dışa aktarmadan önce reddedilir; parola kesilmez, baştaki veya sondaki boşluklar otomatik kaldırılmaz.

Parolalar yalnızca mevcut uygulama oturumunda tutulur; ayarlara, geçmişe veya günlüklere yazılmaz. Bir parola anahtarını kapatmak o parolayı ve doğrulamasını temizler; ayarları sıfırlamak her iki grubu da temizler. Geçersiz parola veya doğrulama değerleri dışa aktarmayı engeller. Her iki anahtar kapalıysa normal PDF dışa aktarılır.

Arayüz dili varsayılan olarak sistemi izler. Ayarlardan, yeniden başlatmadan istediğiniz zaman şu **16 dil** arasında geçiş yapabilirsiniz:

简体中文 · English · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português (Brasil) · Русский · العربية · हिन्दी · **Türkçe** · Nederlands · Polski

Arapça arayüz sağdan sola düzen kullanır. Görüntüler ve PDF içeriği değişmez; yer imlerinin TAB metin düzenleyicisi soldan sağa yapısını korur. Görünüm sistem, açık veya koyu olabilir. Dosya seçiciler gibi macOS bileşenleri sistem dilini kullanır. Arayüz dili ile OCR tanıma dili ayrı ayarlanır; OCR seçeneklerini yerel Vision desteği belirler.

## Uygulanan kapsam

| Özellik | Uygulama açıklaması |
|---|---|
| Görüntü girdisi | JPEG, PNG, TIFF, GIF, BMP, HEIC/HEIF, JPEG 2000 ve ImageIO’nun çözebildiği diğer biçimler; sistemin desteklediği diğer uzantılar dinamik olarak keşfedilir. RAW desteği yerel sistem çözücüsüne bağlıdır; tüm kamera modelleri garanti edilmez |
| Dosya düzeni | Yinelenenleri kaldırma, dosya adı/son sayı sıralaması, elle sıralama, yaygın e-kitap önekleriyle sıralama, alt klasörleri tarama ve üst klasörü dâhil etme seçimi |
| Toplu çıktı | Tek PDF’de birleştirme, kaynak dosya başına bir PDF veya doğrudan üst klasör başına bir PDF. Derin klasörler ayrı gruplanır; alt klasör görüntüleri üst klasöre tekrar sayılmaz |
| Sayfa | Özgün görüntü boyutu, sabit genişlik, A3/A4/A5/B5/Letter/Legal, milimetreyle özel boyut, yatay yön, dört kenar boşluğu, küçük görüntüleri büyütme ve DPI meta verisine öncelik |
| Sıkıştırma | Kayıpsız işleme ve JPEG kalite kontrolü. Özgün yönü normal olan JPEG’ler DCT veri akışını koruyabilir. Diğer biçim ve yönler ImageIO ile doğru çözülüp yerleştirilir; her kaynak biçimin veri akışının bayt bayt korunacağı taahhüt edilmez |
| Saydamlık | Saydamlığı koruma veya beyaz arka plan. JPEG alfa saklayamaz; saydamlık korunurken otomatik olarak kayıpsız kodlama kullanılır ve açıklama gösterilir |
| OCR | Apple Vision ile yerel ve doğru tanıma, yerel destekli dillerden otomatik veya elle seçim, aranabilir/kopyalanabilir gizli metin. GPU yolu başarısızsa CPU denenir. Tanıma başarısız olan sayfaların görüntüsü korunur ve durum açıkça bildirilir |
| Belge özellikleri | Başlık, yazar, konu, anahtar sözcükler; tek sayfa, sürekli veya çift sayfa okuma düzeni |
| PDF şifreleme | Yerel PDFKit AES-128; bağımsız açma parolası, düzenleme parolası veya iki parola desteği. Yalnızca açma parolası varsa rastgele owner parolası üretilir; düzenleme parolası varsa owner tam izinlerini bu parola verir. Seçili moda göre kilit durumu, parolalar, reader/owner izinleri ve sayfa sayısı doğrulandıktan sonra yayımlanır. Hata durumunda şifrelenmemiş alternatif üretilmez. Uygulama içi önizleme parola girişini destekler |
| Yer imleri | Otomatik kaynak dosya yer imleri, çok düzeyli içindekiler, sayfa numaraları, temel sayfa dönüşümü, düzenlenebilir metin ve JSON, yerel PDF hedef önizlemesi |
| Arayüz uyumluluğu | `FreePic2Pdf.itf` ve `FreePic2Pdf_bkmk.txt`, UTF-8/UTF-16LE ve ilgili eski kodlamalar; içindekiler/ana metin için bölümlü sayfa numaraları, meta veri, aranabilir metin sayfaları ekleme ve yer imi görünüm ayarları |
| Kararlılık | Arka plan görevleri, görüntüleri sayfa sayfa serbest bırakma, ilerleme, iptal, günlük, geçici dosyalar ve atomik yayımlama, ad çakışmalarında otomatik numaralandırma, toplu işlem yarıda başarısız olursa tamamlanan sonuçları koruma ve listeleme |

### Eski sürümden açık farklar

- OCR, MODI yerine Apple Vision kullanır; Office/Windows gerekmez. Eski grafik temizliği, CJK yazı tipi veya karakter/satır anahtarları devralınmamıştır.
- Mevcut sıkıştırma seçenekleri kayıpsız ve JPEG’dir. JBIG2, CCITT G4 veya JPEG 2000 kodlayıcıları yeniden uygulanmamıştır. Temel işlevler çalışır; ancak büyük siyah-beyaz kitaplar özel JBIG2 araçlarına göre daha büyük olabilir.
- Eski yazılımdaki OCR metnini gösterme/gizleme veya taranmış görüntüleri fiziksel olarak silme düzeltme araçları yoktur. Görüntü onarımı veya tam PDF içerik düzenleyicisi de sunulmaz.
- Uyumlu arayüzdeki `[Images]` çok katmanlı birleştirme ve `MinWidth` henüz uygulanmamıştır. Algılandığında açıklama gösterilir; uygulanmış gibi davranılmaz. Elle dosya sırası arayüzün mutlak sayfa numaralarıyla uyuşmuyorsa kullanıcı içindekiler hedeflerini kontrol etmelidir.
- Normal yerel sayfa numaraları, bazı standart adlandırılmış eylemler ve URL hedefleri kullanılabilir. PDFKit’in güvenilir biçimde kaydedemediği dış PDF hedefleri ile çözümlenemeyen adlandırılmış/özel hedefler açıkça işaretlenir ve sessizce kaydetme engellenir. Düzenleyicide geçerli yerel sayfa numarasına dönüştürülebilirler. JSON/TXT hedef verisini koruyabilir. Şifreli PDF’lerde yer imi düzenleme desteklenmez.
- Şifreleme yer imlerini, OCR metnini, meta veriyi, okuma düzenini ve normal bölümlü sayfa numaralarını korur. Yerel PDFKit sayfa etiketlerini korumaz; uygulama yalnızca metin öneki içermeyen etiketleri güvenli biçimde geri ekler. Özel metin önekli arayüz dosyaları şifreli dışa aktarmayı açıkça engeller; önekleri kaldırın veya şifrelemeyi kapatın.
- “E-kitap sırası” yaygın önek gruplarını uygular: cov, bok, leg, fow, !, toc, sayısal ana metin, att, ins, bac; diğerleri sona konur. Eski yazılımın yayımlanmamış kurallarıyla birebir aynı olduğu iddia edilmez.
- İptal veya hata durumunda toplu işlemde tamamlanmış PDF’ler korunur; tamamlanmamış geçici PDF silinir. Kesildiği yerden devam etme sunulmaz.

## Geliştirme ve derleme

Kaynak kod bir Swift Package’tır; `Package.swift` Xcode ile açılabilir. macOS SDK içeren Xcode ve Swift 5.9 veya üzeri gerekir. Doğrulama ortamı macOS 15.7.9 / Xcode Swift 6.2.4, çalışma uyumluluk hedefi macOS 14’tür.

```sh
# Hata ayıklama çalıştırması
swift run FolioPDF

# Testler ve 16 dilde arayüz metni kontrolü
bash scripts/test.sh

# Intel + Apple Silicon evrensel .app ve ZIP oluşturma
bash scripts/build-app.sh

# Yalnızca mevcut makinenin mimarisi için oluşturma
bash scripts/build-app.sh --host-only
```

`scripts/test.sh` içindeki gerçek OCR testleri, macOS Vision ve CoreVideo gibi sistem hizmetlerine normal erişim gerektirir. Donanım/sistem hizmetlerini sınırlayan bir yürütme sanal alanında CVPixelBuffer oluşturma hatası görülebilir. Normal sistem ortamında testler çalıştırılmalı ve geçmelidir; testleri atlamak doğrulamanın yerini tutmaz.

Paketleme yerel ad-hoc imzalama kullanır; Developer ID noter onayı içermez. Yerel makinede çalıştırılabilir. Diğer Mac’lere resmî dağıtım için geliştirici sertifikası ve noter onayı süreci gerekir.

### Kod düzeni

```text
Sources/FolioCore/       Görüntü, geometri, dönüştürme, OCR, yer imleri ve arayüz dosyaları
Sources/FolioPDF/        SwiftUI çalışma alanları, durum yönetimi, yerel önizleme ve çoklu dil
Tests/FolioCoreTests/    Gerçek görüntü/PDF/OCR/yer imi gidiş-dönüş ve sınır testleri
scripts/                Test, paketleme, simge ve örnek görüntü oluşturma
packaging/Info.plist     macOS uygulama bilgileri
docs/                   Doğrulama kayıtları ve gerçek pencere görüntüleri
dist/                   Çalıştırılabilir .app ve dağıtım ZIP’leri (derlemeyle üretilir)
```

## Belge dilleri

README ve doğrulama kaydı, arayüzle aynı 16 dilde sunulur; belgelerin üstündeki dil bağlantılarıyla geçiş yapılabilir. Özellik açıklamaları, parola sınırları, bilinen farklar ve derleme adımları tüm dillerde tutarlıdır. Test, derleme ve pencere görüntüsü günlükleri makine tarafından üretilen özgün kanıtlardır ve araç çıktısı değiştirilmez. İlgili açıklamalar doğrulama kaydında çok dilli olarak sunulur.

## Teknik dayanaklar

Apple’ın [Vision dil algılama arayüzü](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/automaticallydetectslanguage), [PDFKit belge özellikleri](https://developer.apple.com/documentation/pdfkit/pdfdocument/documentattributes) ve [ImageIO JPEG kalite parametresi](https://developer.apple.com/documentation/imageio/kcgimagedestinationlossycompressionquality) kullanılır. Uygulama ayrıca yerel SDK bildirimleri ve gerçek dosya testleriyle doğrulanmıştır. Özgün FreePic2Pdf programı, simgeleri veya eski arayüzü kopyalanmamıştır.
