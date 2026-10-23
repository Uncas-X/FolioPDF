# FolioPDF 1.3 Doğrulama Kaydı

<!-- languages:start -->
[简体中文](../VALIDATION.md) · [English](VALIDATION.en.md) · [繁體中文](VALIDATION.zh-Hant.md) · [日本語](VALIDATION.ja.md) · [한국어](VALIDATION.ko.md) · [Français](VALIDATION.fr.md) · [Deutsch](VALIDATION.de.md) · [Español](VALIDATION.es.md) · [Italiano](VALIDATION.it.md) · [Português (Brasil)](VALIDATION.pt-BR.md) · [Русский](VALIDATION.ru.md) · [العربية](VALIDATION.ar.md) · [हिन्दी](VALIDATION.hi.md) · **Türkçe** · [Nederlands](VALIDATION.nl.md) · [Polski](VALIDATION.pl.md)
<!-- languages:end -->

Durum: **testler ve derleme başarılı**. Kayıt tarihi: 2026-10-23. Doğrulama ortamı: Intel Mac, macOS 15.7.9, Swift 6.2.4 / Xcode. En düşük dağıtım sürümü macOS 14.

Bu sürümde bağımsız açma ve düzenleme parolaları eklendi; şifreleme ayarları sağ panelde varsayılan olarak daraltılmış, başlık satırının tamamı tıklanabilir bir bölüme taşındı. 50 XCTest’in tamamı çalıştırılıp geçti; 0 hata, 0 atlama. Yerel PDF yazma arayüzünün, 17–31 karakterlik açma parolalarında owner parolasını geçersiz kılabildiği doğrulandı. Uygulama, iki parolalı modda uzunluk ön kontrolüyle bu sorunu önler. Güvenlik sınırları aşağıdadır. Bu çalıştırmanın günlüğü `test-results.txt` dosyasındadır.

## Teslim edilenler

- `dist/FolioPDF.app`: yerel AppKit penceresi, SwiftUI arayüzü ve sistem PDFKit / Vision / ImageIO framework’leri. Uygulama dosya adında sürüm yoktur; sürüm uygulama meta verisindedir.
- `dist/FolioPDF-1.3-macOS.zip`: x86_64 ve arm64 içeren evrensel uygulama paketi; `lipo -archs` ile doğrulandı.
- `dist/FolioPDF-1.3-source.zip`: Xcode ile açılabilen Swift Package kaynak kodu; testler, betikler, kullanım belgeleri ve arayüz görüntüleri dâhil.
- Paketleme betiği yerel ad-hoc imzalama kullanır; `codesign --verify --deep --strict` başarılıdır. Developer ID noter onayı yoktur. İç sürüm 1.3 (build 4), uygulama dosya adı hâlâ `FolioPDF.app` olarak kalır.

## İşlev testleri

`bash scripts/test.sh` çalıştırıldı; 50 XCTest’in tamamı geçti. Ayrıntılı çıktı `test-results.txt` içindedir. Gerçek Vision OCR testleri de atlanmadan çalıştırıldı.

| Kapsam | Sayı | Doğrulananlar |
|---|---:|---|
| Kaynak keşfi ve sıralama | 3 | Sayısal sıralama, e-kitap önekleri, alt klasörler ve üst klasörü hariç tutma, yinelenen yollar |
| PDF dönüştürme | 10 | Sayfa geometrisi ve geçersiz parametreler, EXIF yönü, çok sayfalı TIFF/GIF, meta veri ve yer imleri, klasöre göre gruplama, üzerine yazmama, toplu işlemde kısmi hata, gerçek JPEG kodlama, özgün JPEG akışını koruma, Vision gizli metni ve aranabilirlik, iptal temizliği |
| Yer imleri ve arayüz dosyaları | 8 | Çok düzeyli yer imleri, BasePage dönüşümü, geçersiz hedefler, standart eylemler ve JSON, dış hedeflerin açıkça reddi, UTF-16 arayüzü ve bölümlü sayfa numaraları, kopya kaydetme, aranabilir metin sayfaları, mevcut sayfa etiketlerini koruma |
| Yerelleştirme | 3 | 16 dil ve sıraları, kaynakların eksiksiz yüklenmesi, 18 bölgesel dil eşlemesi, bilinmeyen dilde geri dönüş, elle seçimin önceliği, yalnızca Arapça için RTL |
| Yerel PDF şifreleme | 14 | Gerçek AESV2/128 bit sözlüğü, yalnızca açma/yalnızca düzenleme/iki parola, reader ve owner izin ayrımı, yanlış parolayla yetki yükseltmeme, farklı parola gereksinimi, rastgele owner, tek ve iki parola uzunluk sınırları, uzun açma parolasını yazmadan önce reddetme, baş/son boşlukları, Çince meta veri, yer imleri, gizli metin, normal bölümlü sayfa numaraları ve düzen, metin öneklerinin açıkça reddi, üzerine yazmama ve hata temizliği |
| Şifreli dönüştürme entegrasyonu | 7 | Birleştirilmiş, dosya başına ve klasör başına şifreleme, otomatik numaralandırma, kaynak dosyaların değişmemesi, geçersiz parolada çıktı olmaması, iki parola izinleri ve meta veriyi koruma, gerçek Vision OCR araması ve görsel koruma, dönüştürme sırasında belirlenimci iptal ve klasör temizliği |
| Şifreleme arayüz durumu | 5 | İki parola ve doğrulama kontrolü, anahtarların bağımsız temizliği, oturum yalıtımı ve sıfırlama, üç modda tam dışa aktarım ve geçmiş sayfa sayısı, parolaların ayarlara/geçmişe/günlüklere girmemesi |

OCR testleri gerçekten oluşturulmuş metin görüntüleri kullanır; çıktı PDF’sinin metninin çıkarılabildiğini ve gizli metnin sayfa görünümünü değiştirmediğini doğrular. Testler macOS sistem hizmetlerine erişebilen ortamda çalışmalıdır. Kısıtlı yürütme sanal alanındaki CoreVideo hataları başarı sayılmaz.

### İki parola kabul koşulları

| Mod | Normal okuyucu | Düzenleme parolası sahibi |
|---|---|---|
| Yalnızca açma parolası | Boş veya yanlış parola açamaz; doğru açma parolası tüm işlem izinlerini verir | Ayrı düzenleme parolası ayarlanmamıştır |
| Yalnızca düzenleme parolası | Parolasız okunur; içerik değiştirme, açıklama ekleme, form doldurma ve sayfa düzenleme yasaktır | Düzenleme parolası owner tam izinlerini verir |
| Her iki parola | Açma parolası user kısıtlı izinlerini verir | Düzenleme parolası dosyayı doğrudan açar ve owner tam izinlerini verir |

İki parola etkin olduğunda farklı olmalıdır. Üç modda da yazdırma, kopyalama ve erişilebilirlik serbesttir. Kısıtlı modlarda içerik değiştirme, açıklama, form doldurma ve sayfa ekleme/silme/döndürme kapalıdır. Okuyucunun izinlere uyması gerekir; bunlar “kesinlikle değiştirilemez” garantisi değildir.

Yalnızca yazdırılabilir ASCII karakterleri kabul edilir. Güvenli destek aralığı: yalnızca açma parolası 1–32 karakter; yalnızca düzenleme parolası 1–32 karakter; iki parolalı modda açma parolası 1–16, düzenleme parolası 1–32 karakter. İki parolalı modun koşullu sınırı arayüzde açıkça belirtilir ve dışa aktarma ön kontrolünde uygulanır. Sınır aşımı doğrudan hata verir; parola kesilmez, baş/son boşlukları değiştirilmez ve daha zayıf çıktıya geçilmez.

Açılmış bir PDF’de `unlock(withPassword:)`, owner parolası yanlış olsa bile `true` döndürebilir. Bu nedenle kabul kontrolü `permissionsStatus` ile tüm izin bitlerini denetler: kısıtlı reader user/51, owner owner/255; yalnızca açma parolasının reader’ı user/255 olmalıdır. Yalnızca düzenleme parolalı dosyalar otomatik açılır; geçmiş için sayfa sayısını okumak owner kilidini açmayı gerektirmez.

## Arayüz ve diller

- Mevcut kaynaklarda 292 metin × 16 dil vardır; gerçek arayüz metni sayısı 281’dir. `check-localization.py` başarılıdır; paket içindeki dil kaynakları kaynak dosyalarla bayt bayt aynıdır.
- Varsayılan dil sistemi izler. Sıra kullanıcının istediğiyle aynıdır: 简体中文, English, 繁體中文, 日本語, 한국어, Français, Deutsch, Español, Italiano, Português (Brasil), Русский, العربية, हिन्दी, Türkçe, Nederlands, Polski.
- Arapçada ana pencere ve ayar penceresi RTL düzenindedir. Dosya adları, görüntüler ve PDF içeriği değişmez. Yer imi TAB metin düzenleyicisi, arayüz dosyasını düzenlemenin anlamını değiştirmemek için LTR yapısını korur.
- Bu turda uygulama yeniden başlatıldı ve gerçek NSView çizdirildi. Çince açık görünümde varsayılan daraltılmış bölüm ve iki parola ayarlarının genişletilmiş durumları, Almanca koyu görünümde uzun metinler, Arapça RTL ve yalnızca düzenleme parolası incelendi. Alanlar ve açıklamalar normal satır kaydırdı; çakışma veya eksik karakter görülmedi. Görünür alanı aşan içerik sağ panelle kayar. Görüntüler aşağıdaki tablodadır.
- “Belge ayrıntıları”, “PDF şifreleme”, “Kenar boşlukları ve çözünürlük” gibi bölüm başlıkları satır boyunca Button kullanır; etiket genişliği doldurur ve dikdörtgen tıklama alanı tanımlar. Sol çalışma alanı gezintisi ve alttaki ayar girişi de genişletilmiş tıklama alanlarına sahiptir. Kaynak incelemesi boş alanları ve RTL anlamsal yönünü kapsadı; ayrı fare otomasyonu testi kullanılmadı. Son dağıtım uygulamasında başlatma ve ana pencereyi kapatıp yeniden açma doğrulandı; günlükte `reopen verified: true` bulunur.
- Dönüştürme sırasında pencereyi kapatma ve uygulamadan çıkma engellenir. Kaydedilmemiş yer imleri varsa kapatırken/çıkarken uyarı verilir. Kapatıp yeniden açmak mevcut oturum taslağını korur.
- Ayarlar düğmesi ve ⌘, aynı yerel ayar penceresini kullanır. ⌘N ana pencereyi gösterir, ⌘O görüntü, ⌘⇧O klasör ekler, ⌘E dışa aktarır.
- “PDF şifreleme”, sağ ayar panelinde “Belge ayrıntıları” sonrasında ayrı bir bölümdür; varsayılan olarak daraltılmıştır ve panelle kayar. Genişletildiğinde iki parola grubu doğrudan görünür; açılır panel kullanılmaz. Açma ve düzenleme parolalarının ayrı anahtarları, gizlenmiş giriş alanları ve doğrulama alanları vardır.
- Bir anahtarı kapatmak yalnızca o grubun parolasını ve doğrulamasını temizler; ayarları sıfırlamak ikisini de temizler. Geçersiz parola, doğrulama uyuşmazlığı veya iki parolanın aynı olması dışa aktarmayı engeller. İki grup da kapalıysa normal PDF dışa aktarılır. Bölümü genişletmek/daraltmak koruma ayarlarını değiştirmez.
- İki parola yalnızca mevcut süreçte tutulur; kalıcı ayarlara, geçmişe veya günlüklere yazılmaz. Şifreli dışa aktarmadaki düz metin geçici dosyalar 0700 izinli klasördedir; normal iptal ve hata yollarında temizlenir. Son olarak yalnızca seçili mod doğrulamasını geçen şifreli dosya yayımlanır; hata şifrelenmemiş çıktıya dönüşemez.
- OCR dillerini yine yerel Vision desteği belirler; arayüz dili sayısından OCR dili sayısı çıkarılamaz.

## Doğrulama sınırları

- Doğrulama makinesi Intel Mac’tir. 1.3 evrensel paketinin iki mimarisi de derlendi; henüz gerçek Apple Silicon makinede test edilmedi.
- En düşük dağıtım hedefi macOS 14; bu turdaki gerçek çalışma ortamı macOS 15.7.9’dur.
- Büyük ölçekli taranmış kitap performans ölçümü yapılmadı. Her kamera RAW biçimi veya her standart dışı PDF hedefiyle uyumluluk taahhüt edilmez.
- Şifreleme Apple PDFKit kullanır, AESV2/128 bit çıktı gerektirir ve seçili moda göre parolaları/izinleri doğrular. Yerel yazma arayüzünün 17–31 karakterlik açma parolası sorunu owner kimlik doğrulamasını etkilediği için iki parolalı modda açma parolası 1–16 karakterle sınırlanır. Düzenleme parolası ve iki tek-parola modu ayrı ayrı 1–32 karakter destekler. Uygulama kriptografik sonuçları kendisi yamamaz; Unicode, kontrol karakterleri ve seçili modun uzunluk sınırı dışındaki girdileri reddeder. Sınır ön kontrolü, owner izinleri ve baş/son boşluklarının korunması gerçek dosyalarla test edildi. İki parolalı modda 17, 31 ve 32 karakterlik açma parolaları yazmadan önce reddedilir.
- Özel metin önekli sayfa etiketleri mevcut yerel yolda güvenilir korunamaz; şifreleme açıkken açık hata verilir. Normal harf/Roma/rakam bölümlü sayfa numaraları, okuma düzeni ve meta veri için gidiş-dönüş testleri vardır. Açma parolası gereken dosyaların uygulama içi önizlemesinde parola girilebilir; yalnızca düzenleme parolalı dosyalar doğrudan önizlenir. Şifreli dosyalarda yer imi düzenleme hâlâ desteklenmez.
- JBIG2/G4 kodlama, eski OCR düzeltmesi, arayüz çok katmanları ve bazı özel yer imi hedefleri dâhil eski yazılımdan farklar, proje README’sindeki “Eski sürümden açık farklar” bölümündedir.

## Bu sürümün arayüz kayıtları

| Durum | Gerçek pencere görüntüsü |
|---|---|
| Çince, şifreleme bölümü varsayılan daraltılmış | [encryption-collapsed-zh.png](../screenshots/encryption-collapsed-zh.png) |
| Çince, iki parola ayarları genişletilmiş | [encryption-inline-zh.png](../screenshots/encryption-inline-zh.png) |
| Almanca, koyu, iki parola ayarları genişletilmiş | [encryption-inline-de-dark.png](../screenshots/encryption-inline-de-dark.png) |
| Arapça, RTL, iki parola ayarları genişletilmiş | [encryption-inline-ar.png](../screenshots/encryption-inline-ar.png) |
| Son evrensel uygulama, Çince, yalnızca düzenleme parolası ve kapatıp yeniden açma | [encryption-editing-only-zh.png](../screenshots/encryption-editing-only-zh.png) |

Görüntüler uygulamanın kendi `NSView` çiziminden alınmıştır; başka uygulama içeriği yoktur. `build-results.txt` iki mimarili üretim derlemesini kaydeder. [Releases](https://github.com/Uncas-X/FolioPDF/releases/tag/v1.3.0) içindeki `SHA256SUMS-1.3.txt`, dağıtım ZIP’lerinin sağlama değerlerini içerir. Eski düzen görüntüleri `screenshots/previous-layout/` konumuna taşındı; bu sürümün arayüz kabul kanıtı sayılmaz.

Özgün test, derleme ve görüntü günlükleri araçlarla üretilmiştir. Çıktılar korunmuş, yerel proje yolları `<project>` ile değiştirilmiştir. Günlükler çevrilip özgün kanıt gibi sunulmaz. Bu açıklamanın 16 dildeki sürümleri aynı test sonuçlarını, ortamı ve sınırları anlatır. Kaynak sürümde derleme önbelleği veya dağıtım ikili dosyaları yoktur; paketleri özel deponun Releases bölümünden indirin.
