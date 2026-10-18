# 5 dakikalık canlı demo akışı

Canlı adres: https://resolveiq.mehmetdogandev.com. Sunum 5. dakikada kesilir; her bölümün süresi sabittir.

## Sunumdan önce (10 dakika kala)

1. API'yi uyandır: `https://api-resolveiq.mehmetdogandev.com/api/v1/health` açılsın, `"status":"ok"` ve `"ai":{"configured":true,"mode":"openai"}` görünsün.
2. Demo verisini sıfırla (önce METRICS.md'deki ürün içi AI maliyetini kaydet):
   `Invoke-RestMethod -Method Post "https://api-resolveiq.mehmetdogandev.com/api/v1/admin/demo_reset" -Headers @{ "X-Admin-Token" = "<ADMIN_TOKEN>" }`
3. Tarayıcıda siteyi aç, çıkış yapılmış olsun. Yakınlaştırma %110, tek sekme.
4. Pitch deck: `sunum/index.html` (Ok / PageDown ile slayt) veya Classroom PDF (`sunum/ResolveIQ-strateji.pdf` — HTML değiştiyse PDF’i yeniden yazdır).

**Yedek plan:** OpenAI kesilirse AI uçları 502 döner ve ekranda hata görünür. Acil durumda Render'da `OPENAI_API_KEY` geçici olarak kaldırılıp `AI_DEMO_MODE=1` eklenebilir. Bu durumda tüm AI çıktıları "Fallback (LLM yok)" rozetiyle görünür ve sunumda bu açıkça söylenir.

## Slayt ↔ süre eşlemesi (`sunum/`)

| Süre | Slayt | Ne gösterilir |
|------|-------|----------------|
| 0:00–0:30 | 1 | SBD + Fortune kanıtı + Zendesk + **$1.014.000** ölçek |
| 0:30–3:30 | 2 (rehber) → **canlı site** | 3 iş akışı; slayt 3 yalnızca PDF yedeği |
| 3:30–4:15 | 4 | Kullanılabilir pas (triage / örüntü / toplu çözüm) |
| 4:15–5:00 | 5 → 6 | Metrik tablosu → make/buy + fiyatlama tezi |

## 0:00 – 0:30 · Firma, SaaS, maliyet (slayt 1)

- "Stanley Black & Decker, Zendesk ile Türkiye dahil dört ülkedeki çağrı merkezlerini tek platformda topladı ve ayda yaklaşık 10.000 ticket işliyor." (Kaynak: Zendesk müşteri hikayesi.)
- "Ölçek için: Suite Enterprise örnek satırında 500 ajan × $169 → yılda yaklaşık **1 milyon dolar**. Bu SBD'nin gerçek sözleşmesi değil; koltuk başına modelin ne kadar şişebileceğini göstermek için."

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

- "Kenara chatbot değil. Ajan bir sonraki adımı üretip önüme **uygulanabilir pas** koyuyor: triage'ta Önerileri uygula, olayda onayla, çözümde tek onayla altı müşteriye yaz."
- "Klasik araçta uzman her ticket'ı okur, sınıflandırır, makale arar, yanıtı sıfırdan yazar. Aynı sorundan gelen şikayetleri fark etmek de bir insanın hafızasına kalır."
- "Hiçbir ajan müşteriye kendiliğinden yazmaz. Hipotez, yönetici onaylamadan doğrulanmış sayılmaz."

## 4:15 – 5:00 · Rakamlar ve cevap (slayt 5 → 6)

- "Benim maliyetim: **0,99 saat**, ~44 M token (API eşdeğeri ~12–39 $), **7.242 LOC**. Canlı AI: **0,00366 $** / 8 çağrı; triage ~0,0003 $/ticket."
- "Firma Zendesk'i bırakmalı mı? **Hayır, hemen değil**: telefon, enterprise entegrasyon ve uyumluluk bu MVP'de yok. Ama değerin taşındığı yer AI katmanı — kendisi üretebilir veya eklenti alır."
- "Fiyatlama: **koltuk başına değil**, hibrit: düşük platform ücreti + sonuç başına (doğru triage / çözülen olay). Token müşterinin sorunu değil; sonuç onun sorunu."
