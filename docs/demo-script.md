# 5 dakikalık canlı demo akışı

Canlı adres: https://resolveiq.mehmetdogandev.com. Sunum 5. dakikada kesilir; her bölümün süresi sabittir.

## Sunumdan önce (10 dakika kala)

1. API'yi uyandır: `https://api-resolveiq.mehmetdogandev.com/api/v1/health` açılsın, `"status":"ok"` ve `"ai":{"configured":true,"mode":"openai"}` görünsün.
2. Demo verisini sıfırla (önce METRICS.md'deki ürün içi AI maliyetini kaydet):
   `Invoke-RestMethod -Method Post "https://api-resolveiq.mehmetdogandev.com/api/v1/admin/demo_reset" -Headers @{ "X-Admin-Token" = "<ADMIN_TOKEN>" }`
3. Tarayıcıda siteyi aç, çıkış yapılmış olsun. Yakınlaştırma %110, tek sekme.
4. Pitch deck PDF'i ayrı pencerede hazır olsun.

**Yedek plan:** OpenAI kesilirse AI uçları 502 döner ve ekranda hata görünür. Acil durumda Render'da `OPENAI_API_KEY` geçici olarak kaldırılıp `AI_DEMO_MODE=1` eklenebilir. Bu durumda tüm AI çıktıları "Fallback (LLM yok)" rozetiyle görünür ve sunumda bu açıkça söylenir.

## 0:00 – 0:30 · Firma, SaaS, maliyet (slayt 1-2)

- "Stanley Black & Decker, Zendesk ile Türkiye dahil dört ülkedeki çağrı merkezlerini tek platformda topladı ve ayda yaklaşık 10.000 ticket işliyor." (Kaynak: Zendesk müşteri hikayesi.)
- "Zendesk'in herkese açık liste fiyatı yıllık ödemede temsilci başına aylık 55-115 dolar. 100 temsilcilik bir senaryoda bu yılda 66-138 bin dolar ediyor. Gerçek sözleşme bilinmiyor; bu bir senaryo."

## 0:30 – 3:30 · Canlı ürün (3 iş akışı + 3 ajan)

| Süre | Ekran | Ne yapılır / söylenir |
|------|-------|----------------------|
| 0:30 | Giriş | **Selin Aydın (yönetici)** demo düğmesine bas. "Kendi markamız, kendi verimiz; tümü sentetik." |
| 0:40 | Dashboard | "Tüm sayılar veritabanından hesaplanıyor." Açık, acil ve atanmamış kartlarını göster. "Onay bekleyen AI işleri" şu an boş. |
| 0:55 | **B. Gelen kutusu** | Kanal sekmelerinde **Canlı sohbet**'e geç, sonra **E-posta**. Bir PC-5 talebi seç: sağda müşteri geçmişi ve **"benzer talep bulundu"** uyarısı. "Üç kanal tek listede, müşterinin tüm geçmişi yanında." |
| 1:20 | **A. Ticket + Ajan A** | Ticket'lar > **Yeni ticket**. Müşteri seç, ürün PC-5. Konu: "Soğuktan sonra batarya şarj olmuyor". Açıklama: "Gece arabada kalan PC-5 batarya sabah şarja takınca kırmızı LED yanıp sönüyor." **"Kaydettikten sonra AI triage çalıştır"** işaretli, oluştur. |
| 1:40 | Ticket çalışma alanı | Triage paneli: kategori, öncelik, sorumlu (mevcut → önerilen), gerekçe, kanıt, güven, makaleler. "AI hiçbir şeyi kendisi uygulamadı, müşteriye de yazmadı." **Önerileri uygula**, ardından **Yanıt taslağını kullan**. |
| 2:00 | **C. Bilgi bankası** | Bilgi bankası panelinde "LED" ara, *QC-2 şarj cihazı LED göstergeleri* makalesini bağla, **Yanıta ekle**: adımlar yanıt taslağına girer. Bir cümle düzenle, **Gönder ve beklemeye al**. Aktivite geçmişinde her adım görünür. |
| 2:25 | **AI Insights + Ajan B** | **Örüntü taraması çalıştır**. Sonuç: PC-5 grubu, 7 ticket, 7 müşteri. "Durum: **Önerildi (hipotez)**. Benzerlik nedensellik değildir." Ortak belirtiler, kanıt, olası kök neden (doğrulanmadı), belirsizlik. Kontrol ticket'ları (çatlak kasa, kısa çalışma süresi vb.) grupta yok. **Ortak sorun olarak onayla**. |
| 2:55 | **Ajan C** | **Çözüm paketi hazırla**: sorun giderme adımları, iç eskalasyon, bilgi bankası boşluğu. Ortak yanıtta bir cümleyi düzenle. Ticket listesinde birinin işaretini kaldır. **Uygula** > **Evet, uygula**. "Altı müşteriye tek onayla, adlarıyla kişiselleştirilmiş yanıt gitti." |
| 3:15 | Ticket | Yanıtın gittiği bir ticket'ı aç: "Merhaba Kerem," ve "Olay ortak yanıtı" etiketi. AI çalıştırma geçmişinde token ve tahmini maliyeti göster. |

## 3:30 – 4:15 · AI-native fark: "kullanılabilir pas" (slayt 4)

- "Klasik araçta uzman her ticket'ı okur, sınıflandırır, makale arar, yanıtı sıfırdan yazar. Aynı sorundan gelen şikayetleri fark etmek de bir insanın hafızasına kalır."
- "ResolveIQ'da sonraki adım hep önceden hazırlanmış olarak önünüzde duruyor: triage önerisi, makale adımları, olası ortak sorun, ortak yanıt ve bilgi bankası taslağı. İnsan yalnızca karar veriyor."
- "Hiçbir ajan müşteriye kendiliğinden yazmaz. Hipotez, yönetici onaylamadan doğrulanmış sayılmaz."

## 4:15 – 5:00 · Rakamlar ve cevap (slayt 5-6)

- "Benim maliyetim: METRICS.md'deki geliştirme süresi ve token maliyeti. Ürün içi AI çağrılarının gerçek maliyeti `agent_runs` tablosunda; triage çağrısı ticket başına bir sentin onda biri mertebesinde."
- "Firma Zendesk'i bırakmalı mı? Hayır: telefon, SLA, uyumluluk ve 60'tan fazla web sitesi entegrasyonu benim MVP'mde yok. Ama değerin taşındığı yer AI katmanı. Bu katmanı kendisi kurabilir ya da sonuç başına fiyatlanan bir eklenti olarak alabilir."
- "Fiyatlama: koltuk başına değil, **hibrit**: düşük bir platform ücreti + çözülen olay veya doğru yönlendirilen ticket başına ücret. Token maliyeti müşterinin sorunu değil; sonuç onun sorunu."
