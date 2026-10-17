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
| `aaf6fd3` | 2026-10-12 10:14 | chore: add repository gitignore |
| `85a7415` | 2026-10-12 11:32 | feat(web): Next.js hello world |
| `c886941` | 2026-10-12 13:05 | feat(api): Rails 8 API-only health endpoint |
| `4eb7aba` | 2026-10-12 15:48 | chore: Docker Compose, Render and Vercel deploy config |
| `4a80f61` | 2026-10-12 18:22 | docs: point README at live health URL |
| `e09513d` | 2026-10-13 09:41 | feat(api): users, sessions and cookie authentication |
| `90041b7` | 2026-10-13 11:18 | feat(api): customers and ticket domain model |
| `e5dbd8a` | 2026-10-13 13:02 | feat(api): ticket CRUD, assign, status and priority |
| `0c00460` | 2026-10-13 14:55 | feat(api): public replies and internal notes |
| `6575f95` | 2026-10-13 16:33 | test(api): auth and ticket workflow |
| `7af14ce` | 2026-10-13 18:10 | feat(web): login and session |
| `34a6837` | 2026-10-13 20:04 | feat(web): ticket list and create form |
| `1930ccf` | 2026-10-14 10:08 | feat(api): knowledge articles draft and publish |
| `c3308c5` | 2026-10-14 11:47 | feat(web): unified inbox with channel tabs |
| `81368e7` | 2026-10-14 13:30 | feat(web): ticket workspace conversation and properties |
| `daddca8` | 2026-10-14 15:16 | feat(web): knowledge base screens |
| `50317dc` | 2026-10-14 17:02 | feat(web): dashboard metrics and customer history |
| `7e5c3cf` | 2026-10-15 09:22 | feat(api): OpenAI client, PII scrubber and agent_runs |
| `ed70bbf` | 2026-10-15 11:05 | feat(api): triage agent with structured outputs |
| `93953d4` | 2026-10-15 12:48 | feat(api): TF-IDF similarity and pattern detection |
| `6a7c796` | 2026-10-15 14:30 | feat(api): resolution agent and incident apply |
| `acd9e06` | 2026-10-15 16:12 | feat(web): triage, resolution and AI Insights UI |
| `38f02ab` | 2026-10-15 17:40 | fix(api): readable fallback evidence for triage |
| `4c37480` | 2026-10-15 18:55 | fix(api): demo reset restarts numbering |
| `ad76835` | 2026-10-15 20:47 | chore: remaining original product files |
| `f04d57e` | 2026-10-16 10:15 | feat(api): SLA policies and due timestamps |
| `04b5326` | 2026-10-16 12:02 | feat(api): ticket tags, macros and bulk update |
| `228d7fe` | 2026-10-16 14:20 | feat(api): ticket merge and related links |
| `d7adc95` | 2026-10-16 16:05 | feat(api): trigger rules for assign, tag and priority |
| `88c96b2` | 2026-10-16 17:48 | feat(web): SLA badges, macros and bulk inbox actions |
| `8a6d029` | 2026-10-16 19:30 | test(api): SLA, macros, merge and triggers |
| `a74c439` | 2026-10-17 10:40 | feat(api): CSAT and first-reply / resolution reporting |
| `dca1550` | 2026-10-17 12:25 | feat(web): public help center and web request form |
| `fe5787b` | 2026-10-17 14:50 | feat(web): reports for FRT, CSAT, SLA and channel mix |
| `6af63f9` | 2026-10-17 16:35 | docs: architecture, deployment, demo script and pitch deck |
| `4db1325` | 2026-10-17 18:10 | docs: metrics and live verification notes |

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
