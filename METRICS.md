# ResolveIQ: metrik kaydı

Bu dosyada yalnızca ölçülen değerler yer alır. Ölçülmemiş her değer *Beklemede* olarak işaretlidir.

## Geliştirme oturumları (coding agent)

Saatler sohbet kaydındaki zaman damgalarından ve git commit saatlerinden (UTC+3) alınmıştır.

| # | Tarih | Başlangıç | Bitiş | Süre (saat) | Coding agent | Model | Yapılan iş | Token | Maliyet ($) |
|---|-------|-----------|-------|-------------|--------------|-------|------------|-------|-------------|
| 1 | 2026-10-18 | 17:22 | 17:32 | 0,17 | Cursor Agent (Plan modu) | Auto | Ödev ve referans proje analizi, sorular, mimari ve kapsam planı | toplamda | *Beklemede* |
| 2 | 2026-10-18 | 17:32 | 18:15 | 0,72 | Cursor Agent | Auto | İskelet, health, deploy yapılandırması, veri modeli, oturum ve yetki, 3 iş akışı, 3 AI ajanı, arayüz, testler, yerel smoke testi, dokümanlar, pitch deck | toplamda | *Beklemede* |
| 3 | 2026-10-18 | 18:42 | 18:48 | 0,10 | Cursor Agent | Auto | Canlı uçtan uca doğrulama (API betiği + tarayıcı), demo provası, demo reset, metrik ve doküman güncellemesi | toplamda | *Beklemede* |
| | | | | **0,99** | | | | **~44,1 M** | Plan dahili; API eşdeğeri ~12-39 $ (aşağıda) |

Token toplamı Cursor Usage panelindeki 2026-10-18 günlük kullanımdan türetildi: günlük toplam **79,9 M** token − aynı gün jokerai-jai projesine ait **35.813.015** token = **~44,1 M token** (44.086.985; panel toplamı yuvarlanmış olduğundan yaklaşık). Panel oturum bazında ayrım vermediği için oturum satırlarında yalnızca toplam vardır. Kullanım abonelik planı içinde kaldığı için panel dolar tutarı göstermiyor. Aşağıdaki tablo, aynı token miktarının doğrudan API ile ödenseydi tutacağı **tahmini** maliyettir.

### Geliştirme maliyeti, API eşdeğeri (tahmin)

Panel token türü ayrımı (önbellekten okuma / yeni girdi / çıktı) vermediği için ajan tabanlı kodlamada tipik bir dağılım varsayıldı. Orta senaryo: %92 önbellek okuma, %6 yeni girdi (önbelleğe yazma dahil), %2 çıktı. Aralık: %95/4/1 ile %85/12/3 arası. Tüm istekler 200 K bağlam altında varsayıldı.

| Model (liste fiyatı, $/1M: girdi / önbellek okuma / çıktı) | Düşük | **Orta** | Yüksek |
|---|---:|---:|---:|
| xAI Grok Build 0.1 / grok-code-fast (1,00 / 0,20 / 2,00) | 11,02 $ | **12,52 $** | 15,43 $ |
| Anthropic Claude Sonnet 5.5 (2,50 önbelleğe yazma / 0,10 / 10,00) | 13,01 $ | **19,49 $** | 30,20 $ |
| xAI Grok 4.7 (2,00 / 0,50 / 6,00) | 27,11 $ | **30,86 $** | 37,25 $ |
| Anthropic Claude Opus 5.5 (5,00 önbelleğe yazma / 0,20 / 20,00) | 26,01 $ | **38,97 $** | 60,40 $ |
| Grok 4.7 Fast, yalnızca Cursor içinde (2× fiyat) | 54,23 $ | **61,72 $** | 74,51 $ |

Hesap: `44,087 M × (önbellek payı × önbellek fiyatı + girdi payı × girdi fiyatı + çıktı payı × çıktı fiyatı)`. Anthropic'te yeni girdi, ajan akışında önbelleğe yazıldığı için 5 dakikalık önbelleğe yazma fiyatıyla hesaplandı. Cursor abonelik ücreti dahil değildir.

Kaynaklar (2026-10-18 erişim): [Anthropic fiyatlandırma](https://platform.claude.com/docs/en/about-claude/pricing), [xAI API fiyatlandırma](https://docs.x.ai/developers/pricing), [Cursor Models & Pricing](https://cursor.com/docs/models-and-pricing).

Özet: bu uygulamanın geliştirme maliyeti API ile ödenseydi seçilen modele göre **yaklaşık 12-39 $** (orta senaryo) olurdu; en olası Sonnet sınıfı bir modelle **~20 $**.

Commit zaman çizelgesi (`git log --format="%h %ad %s" --date=iso`):

| Commit | Saat | Konu |
|--------|------|------|
| `750445b` | 17:34 | web/.gitignore (kullanıcı) |
| `a98a3d1` | 17:45 | Monorepo iskeleti, health check, deploy yapılandırması |
| `84b1d8e` | 17:52 | Veri modeli, cookie oturumu, API'ler ve AI ajanları |
| `787c226` | 18:05 | Fallback kanıtlarının okunabilir hale getirilmesi |
| `dd784d7` | 18:05 | Arayüz: ticket, gelen kutusu, bilgi bankası, dashboard, AI Insights |
| `5e11eda` | 18:12 | Demo reset numaralandırması ve testi |
| `docs: submission…` | 18:15 | README, dokümanlar, metrikler, pitch deck |

## Satır sayısı (LOC)

Ölçüm (2026-10-18 18:10): git'te izlenen `.rb .rake .ts .tsx .css .yml .yaml .mjs` dosyalarındaki **boş olmayan** satırlar; `db/schema.rb`, `api/bin/`, lock dosyaları ve `next-env.d.ts` hariç. Dokümanlar dahil değildir.

| Bölüm | Dosya | Satır |
|-------|-------|-------|
| API uygulama (`app/`, `lib/`) | 52 | 2.272 |
| API config | 15 | 332 |
| API migration + seed girişi | 2 | 166 |
| API test | 6 | 493 |
| Web (`web/`) | 43 | 3.911 |
| Kök (`render.yaml`, `docker-compose.yml`) | 2 | 68 |
| **Toplam** | **120** | **7.242** |

Komut (PowerShell, repo kökünde):

```powershell
$files = git ls-files | Where-Object { $_ -match '\.(rb|rake|ts|tsx|css|yml|yaml|mjs)$' -and $_ -notmatch '(^|/)db/schema\.rb$|^api/bin/|lock|next-env\.d\.ts' }
($files | ForEach-Object { (Get-Content -LiteralPath $_ | Where-Object { $_.Trim() -ne '' }).Count } | Measure-Object -Sum).Sum
```

## Testler

| Tarih | Komut | Sonuç |
|-------|-------|-------|
| 2026-10-18 | `cd api && bin/rails test` | 39 test, 240 doğrulama, 0 hata, 0 atlama |
| 2026-10-18 | `cd web && npx eslint .` | 0 hata |
| 2026-10-18 | `cd web && npx next typegen && npx tsc --noEmit` | 0 hata |
| 2026-10-18 | `cd web && npm run build` | Başarılı (13 rota) |

## Ürün içi AI maliyeti (çalışma zamanı)

Ürünün kendi LLM çağrıları `agent_runs` tablosuna yazılır ve AI Insights > "AI çalıştırma geçmişi" bölümünde kaynak bazında toplanır. Maliyet `tokens_in × OPENAI_PRICE_INPUT_PER_1M + tokens_out × OPENAI_PRICE_OUTPUT_PER_1M` ile hesaplanan **tahmini** bir değerdir (varsayılan gpt-4o-mini fiyatı: 1M girdi token 0,15 $, 1M çıktı token 0,60 $). Sağlayıcı faturası esas alınmaz.

| Tarih | Ortam | Çağrı | Girdi token | Çıktı token | Maliyet ($) | Kaynak |
|-------|-------|-------|-------------|-------------|-------------|--------|
| 2026-10-18 | Yerel smoke testi | 3 | 0 | 0 | 0 | Fallback (`AI_DEMO_MODE=1`, LLM çağrısı yok) |
| 2026-10-18 | Canlı, uçtan uca akış | 4 | 5.643 | 2.135 | 0,00212745 | OpenAI `gpt-4o-mini-2024-07-18` |
| 2026-10-18 | Canlı, demo provası (2 × triage + tarama) | 4 | — | — | 0,00152820 | OpenAI `gpt-4o-mini-2024-07-18` |
| | **Canlı toplam** | **8** | | | **0,00365565** | |

Canlı uçtan uca akışın çağrı bazında dökümü (`GET /api/v1/agent_runs`, demo reset'ten önce okundu):

| Ajan | Girdi token | Çıktı token | Maliyet ($) | Gecikme (ms) |
|------|-------------|-------------|-------------|--------------|
| Örüntü taraması (6 ticket) | 1.106 | 444 | 0,0004323 | 5.089 |
| Triage (1 ticket) | 1.246 | 219 | 0,0003183 | 2.308 |
| Ticket çözüm önerisi | 1.273 | 621 | 0,00056355 | 5.679 |
| Olay çözüm paketi (7 ticket) | 2.018 | 851 | 0,0008133 | 7.672 |

Prova çağrılarının token sayıları kaydedilmeden reset yapıldı; yalnızca API yanıtındaki maliyetler (0,0003177 + 0,000423 + 0,00030915 + 0,00047835 $) toplandı.

Ölçülen triage maliyeti ticket başına ~0,00031-0,00032 $; 10.000 ticket/ay için bu yaklaşık **3,2 $/ay** eder (her ticket'a bir triage varsayımıyla, tahmini fiyat tablosuyla).

Canlı değeri almak için (demo reset'ten **önce**):

```powershell
Invoke-RestMethod "https://api-resolveiq.mehmetdogandev.com/api/v1/agent_runs" -WebSession $s | Select-Object -ExpandProperty totals
```

### Prompt boyutu ölçümü (token değil, karakter)

Yerelde seed verisiyle gerçek prompt'lar üretilip karakter sayısı ölçüldü (sistem mesajı + kullanıcı mesajı + JSON şeması). Token sayısı ve maliyet canlı çağrılardan sonra `agent_runs`'tan okunacaktır.

| Ajan çağrısı | Karakter |
|--------------|----------|
| Triage (1 ticket) | 4.213 |
| Örüntü tespiti (6 ticket'lık grup) | 3.893 |
| Çözüm paketi (6 ticket'lık olay) | 6.652 |

## Altyapı

| Kalem | Değer |
|-------|-------|
| Frontend URL | https://resolveiq.mehmetdogandev.com (canlı doğrulandı, 2026-10-18 18:44) |
| API URL | https://api-resolveiq.mehmetdogandev.com (canlı doğrulandı, 2026-10-18 18:41) |
| İlk canlı deploy | 2026-10-18, sürüm `d801276` (health yanıtından) |
| Render Postgres oluşturma / son kullanma | *Beklemede* (oluşturma + 30 gün) |

## Özet (teslim için)

| Metrik | Değer |
|--------|-------|
| Toplam token maliyeti ($) | Geliştirme: ~44,1 M token (Cursor Usage, günlük toplamdan türetildi; plan dahilinde). API eşdeğeri tahmini 12-39 $ (Grok Build 12,5 $, Sonnet 5.5 19,5 $, Grok 4.7 30,9 $, Opus 5.5 39 $). Canlı ürün içi: 0,00366 $ (8 OpenAI çağrısı, tahmini fiyat tablosuyla) |
| Toplam çalışma süresi (saat) | 0,99 (3 oturum, yukarıdaki tablo) |
| Satır sayısı (LOC) | 7.242 (boş olmayan satır, ölçüm yöntemi yukarıda) |
| Kullanılan model(ler) | Geliştirme: Cursor Agent, Auto modeli. Ürün içi: OpenAI gpt-4o-mini |
| Coding agent(lar) | Cursor Agent |
| Agent oturum sayısı | 3 |
