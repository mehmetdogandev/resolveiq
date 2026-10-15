# ResolveIQ: Pitch Deck (6 slayt)

PDF: [ResolveIQ-pitch-deck.pdf](ResolveIQ-pitch-deck.pdf) · Kaynak HTML: [pitch-deck.html](pitch-deck.html)

PDF'i yeniden üretmek için (Chrome veya Edge, headless):

```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-pdf-header-footer `
  --print-to-pdf="$PWD\docs\ResolveIQ-pitch-deck.pdf" "file:///$($PWD.Path.Replace('\','/'))/docs/pitch-deck.html"
```

Sunum akışı 5 dakikadır; canlı demo 2. ve 3. slayt arasında yapılır (ayrıntı: [demo-script.md](demo-script.md)).

---

## 1. Destek ekibiniz yazmasın, karar versin. (0:00-0:15)

- Stanley Black & Decker × Zendesk.
- ~10.000 ticket/ay; Türkiye, Peru, Arjantin, Brezilya çağrı merkezleri tek platformda; Zendesk Support, Guide, Chat, Talk.
- ResolveIQ: talepleri sınıflandırır, benzer şikayetlerden olası ortak sorunu çıkarır, etkilenen herkese ortak yanıtı hazırlar. İnsan yalnızca onaylar.

**Konuşma notu:** "SBD, Zendesk'i dört ülkedeki çağrı merkezlerini tek platformda toplamak için kullanıyor. Ayda yaklaşık on bin talep."

## 2. Firma bu SaaS'a ne ödüyor? (0:15-0:30)

| Zendesk planı | $/temsilci/ay (yıllık, liste) | 100 temsilci/yıl |
|---|---:|---:|
| Suite Team | 55 | 66.000 $ |
| Suite Growth | 89 | 106.800 $ |
| Suite Professional | 115 | 138.000 $ |
| Suite Enterprise | satış ekibiyle görüşme | |
| AI otomatik çözüm (ek) | 1,50-2,00 $ / çözüm | |

Varsayımlar (doğrulanmamış):

- Temsilci sayısı kamuya açık değil; 10.000 ticket/ay için 100 temsilci bir senaryodur.
- SBD'nin gerçek sözleşmesi ve kurumsal indirimi bilinmiyor; liste fiyatı üst sınır kabul edildi.
- Talk kullanım ücretleri, profesyonel hizmetler ve ek paketler dahil değil.

Gözlem: Zendesk AI'ı artık çözüm başına fiyatlıyor; değer koltuktan sonuca kayıyor.

**Konuşma notu:** "Bu bir tahmin, gerçek lisans bedelini bilmiyoruz. 100 temsilci senaryosunda liste fiyatıyla yılda 66 ile 138 bin dolar arası."

## 3. Üç temel iş akışı, uçtan uca (0:30-3:30, canlı demo)

- **A · Ticket yönetimi:** oluştur, filtrele, sırala; ata, durum ve öncelik; müşteriye yanıt ve iç not; çöz, yeniden aç, denetim kaydı.
- **B · Birleşik gelen kutusu:** e-posta, web formu, canlı sohbet tek listede; kanal sekmeleri ve sunucu taraflı filtreler; önizleme ve müşterinin tüm geçmişi; benzer talep uyarısı.
- **C · Bilgi bankası ve çözüm:** makale yaz, taslak, yayın (yönetici); ara, ticket'a bağla; adımları tek tıkla yanıta ekle; çöz ve kapat.

Teknoloji: Next.js 16 (Vercel), Rails 8.1 API (Render), PostgreSQL, HttpOnly cookie oturumu, rol bazlı yetki. Northforge Tools hayali bir markadır; tüm veri sentetiktir. Zendesk adı, logosu, renkleri, kodu veya verisi kullanılmadı.

## 4. AI-native fark: "kullanılabilir pas" (3:30-4:15)

Ajan sonraki adımı hazırlar, insan yalnızca karar verir:

1. **Akıllı triage:** kategori, öncelik, ekip ve iş yüküne göre uzman, ilgili makaleler, gerekçe, güven, yanıt taslağı. İnsan farkı görür, tek tıkla uygular.
2. **Örüntü tespiti:** TF-IDF ön filtresi + LLM; benzer şikayetler, ortak belirtiler, kanıt, olası kök neden, belirsizlik. İnsan hipotezi onaylar veya reddeder.
3. **Çözüm ve önleme:** sorun giderme adımları, kişiselleştirilen ortak yanıt, eskalasyon, ticket aksiyonları, KB taslağı. İnsan düzenler, seçili ticket'lara uygular.

| Klasik araçta insan yapar | ResolveIQ'da |
|---|---|
| Her ticket'ı okuyup sınıflandırmak, kime gideceğine karar vermek | Öneri hazır, tek tıkla uygulanır |
| Farklı kanallardaki aynı sorunu fark etmek | Tarama grubu, kanıtı ve etkilenen müşterileri çıkarır |
| Etkilenen müşterilere tek tek yanıt yazıp durum güncellemek | Tek ortak yanıt, tek onay, adla kişiselleştirilmiş |

Hiçbir ajan müşteriye kendiliğinden yazmaz; benzerlik nedensellik olarak sunulmaz; her çağrı `agent_runs` tablosuna kaydedilir.

## 5. Rakamlar (4:15-4:40)

| Metrik | Değer | Durum |
|---|---|---|
| Geliştirme süresi | 0,99 saat, 3 Cursor Agent oturumu | Git ve sohbet zaman damgalarından ölçüldü |
| Satır kod (boş olmayan) | 7.242 (API 2.770, test 493, web 3.911) | Ölçüldü |
| Testler | 39 Rails testi, 240 doğrulama, 0 hata; ESLint, tsc, build temiz | Yerelde çalıştırıldı |
| Geliştirme token kullanımı | ~44,1 M token (plan dahili) | Cursor Usage günlük toplamından türetildi (79,9 M − jokerai-jai 35.813.015) |
| Geliştirme maliyeti, API eşdeğeri | 12-39 $: Grok Build 12,5 $ · Claude Sonnet 5.5 19,5 $ · Grok 4.7 30,9 $ · Claude Opus 5.5 39 $ | **Tahmin**: liste fiyatları, %92 önbellek / %6 girdi / %2 çıktı varsayımı (METRICS.md) |
| Ürün içi AI maliyeti | Triage ~0,0003 $/ticket (1.246 girdi + 219 çıktı token), 10.000 ticket/ay ≈ 3 $/ay; 7 ticket'lık çözüm paketi 0,0008 $; canlı testlerin toplamı 8 çağrı, 0,0037 $ | Canlıda `agent_runs`'tan ölçüldü (fiyat tablosuyla tahmini maliyet) |

Ayrıntılar: [METRICS.md](../METRICS.md).

## 6. Cevap: almaya devam mı, kendisi mi üretmeli? (4:40-5:00)

- **Platformu almaya devam etsin:** telefon, SLA motoru, uyumluluk, 60+ web sitesi ve sosyal medya entegrasyonu bu MVP'de yok. Bunları kurup 7/24 işletmek ayrı bir mühendislik ve operasyon ekibi gerektirir (değerlendirme, ölçüm değil).
- **AI katmanını kendisi kursun:** değer triage, örüntü ve ortak çözümde. Bu MVP yaklaşık 1 saatlik agent çalışmasıyla çalışır hale geldi; üretim kalitesi daha fazla iş ister. Ürün bilgisi ve iş kuralları firmaya özel; veri firmada kalır.
- **Fiyatlama: hibrit, sonuç odaklı.** Düşük bir platform ücreti + çözülen olay veya doğru yönlendirilen ticket başına ücret. Koltuk başına fiyat AI'ın azalttığı işi cezalandırır; token başına fiyat riski müşteriye yükler. Müşteri sonucu satın alır.

---

## Kaynaklar

- [Zendesk müşteri hikayeleri, üretim sektörü: "Stanley Black & Decker and Zendesk"](https://www.zendesk.co.uk/customer/manufacturing/)
- [Zendesk Customer Story e-kitabı (PDF)](http://d26a57ydsghvgx.cloudfront.net/content/resources/Zendesk_CustomerStoryEbook.pdf)
- [Zendesk fiyatlandırma sayfası](https://www.zendesk.com/pricing/) (18.10.2026 erişim; Team, Professional ve AI çözüm fiyatları)
- Suite Growth fiyatı: getmacha.com plan karşılaştırması (Eylül 2026)
