# Deploy rehberi

| Parça | Platform | Adres |
|-------|----------|-------|
| Frontend (Next.js) | Vercel, kök dizin `web` | https://resolveiq.mehmetdogandev.com |
| API (Rails 8.1) | Render web servisi (free), kök dizin `api` | https://api-resolveiq.mehmetdogandev.com |
| Veritabanı | Render PostgreSQL (free) | Yalnızca Render içi bağlantı + harici URL |

> **Durum:** Yapılandırma hazır ve yerelde production modunda doğrulandı. Canlı deploy hesap erişimi gerektirdiği için aşağıdaki adımlar elle yapılacak. Canlı doğrulama sonuçları en alttaki tabloya yalnızca gerçekten çalıştırıldıktan sonra yazılır.

## 1. Render (API + PostgreSQL)

1. Render > **New > Blueprint** > GitHub `mehmetdogandev/resolveiq` reposunu seç. Kökteki [`render.yaml`](../render.yaml) okunur ve iki kaynak oluşur:
   - `resolveiq-api`: Ruby web servisi, `rootDir: api`, Frankfurt, free plan.
   - `resolveiq-db`: PostgreSQL, free plan.
2. İstendiğinde **`OPENAI_API_KEY`** değerini gir. Değer yalnızca Render'da durur, repoya veya tarayıcıya gitmez.
3. Blueprint'in ayarladığı değişkenler:

   | Değişken | Değer | Not |
   |----------|-------|-----|
   | `DATABASE_URL` | `resolveiq-db` bağlantı dizesi | Otomatik |
   | `RAILS_ENV` | `production` | |
   | `BUNDLE_WITHOUT` | `development:test` | |
   | `SECRET_KEY_BASE` | Render üretir | `RAILS_MASTER_KEY` gerekmez, credentials kullanılmıyor |
   | `ADMIN_TOKEN` | Render üretir | Demo reset ucu için |
   | `FRONTEND_ORIGIN` | `https://resolveiq.mehmetdogandev.com,http://localhost:3000` | CORS ve Origin kontrolü. Production'da yoksa uygulama açılmaz |
   | `ALLOWED_HOSTS` | `api-resolveiq.mehmetdogandev.com,.onrender.com` | Host header koruması |
   | `WEB_CONCURRENCY` / `RAILS_MAX_THREADS` | `0` / `3` | Free planın belleğine uygun tek süreç |
   | `OPENAI_MODEL` | `gpt-4o-mini` | |
   | `OPENAI_API_KEY` | elle girilir | Yoksa AI uçları 503 döner |

   İsteğe bağlı: `OPENAI_TIMEOUT_SECONDS` (varsayılan 30), `OPENAI_PRICE_INPUT_PER_1M` / `OPENAI_PRICE_OUTPUT_PER_1M` (varsayılan 0,15 / 0,60 USD, tahmini maliyet için). **`AI_DEMO_MODE` production'da ayarlanmamalıdır.**

4. Build komutu: `bundle install && bundle exec rails db:migrate && bundle exec rails db:seed`. Migration her deploy'da bir kez build adımında çalışır, uygulama açılışında çalışmaz. Seed idempotenttir: var olan kaydı değiştirmez, eksikleri ekler.
5. Başlatma: `bundle exec puma -C config/puma.rb` (Render'ın verdiği `PORT`). Health check yolu: `/api/v1/health`.
6. İlk deploy bitince `https://resolveiq-api.onrender.com/api/v1/health` adresi `"status":"ok"` ve `"checks":{"database":"ok"}` döndürmeli. (Servis adı alınmışsa Render farklı bir alt alan adı verir; DNS hedefini ona göre yaz.)
7. Servis > Settings > Custom Domains: `api-resolveiq.mehmetdogandev.com` (Blueprint ekler) doğrulanana kadar bekle.
8. Servis > Environment sekmesinden `ADMIN_TOKEN` değerini kopyala ve güvenli bir yerde tut.

## 2. Vercel (frontend)

1. Vercel > **Add New > Project** > aynı repo. **Root Directory: `web`**. Framework: Next.js (otomatik). Build: `next build`.
2. Environment Variables (Production): `NEXT_PUBLIC_API_URL = https://api-resolveiq.mehmetdogandev.com`
   - Bu değer build sırasında koda gömülür. Değiştirirsen **yeniden deploy** etmen gerekir (Deployments > ... > Redeploy).
3. Settings > Domains: `resolveiq.mehmetdogandev.com` ekle.

## 3. Cloudflare DNS

Her iki kayıt **DNS only (gri bulut)** olmalı. Proxy açıkken Vercel ve Render sertifika üretemez, 525 hatası görülür.

| Tip | Ad | Hedef | Proxy |
|-----|----|-------|-------|
| CNAME | `resolveiq` | `cname.vercel-dns.com` | DNS only |
| CNAME | `api-resolveiq` | `resolveiq-api.onrender.com` (Render'ın gösterdiği adres) | DNS only |

Oturum cookie'si API alan adına yazılır (`HttpOnly; Secure; SameSite=Lax`). İki alt alan adı aynı siteye (`mehmetdogandev.com`) ait olduğu için tarayıcı cookie'yi gönderir. Bu yüzden giriş yalnızca özel alan adlarıyla çalışır, `*.vercel.app` önizleme adreslerinde çalışmaz.

## 4. Canlı doğrulama

```powershell
$api = "https://api-resolveiq.mehmetdogandev.com"
$web = "https://resolveiq.mehmetdogandev.com"

# Health: status ok, database ok, ai.mode openai
Invoke-RestMethod "$api/api/v1/health" | ConvertTo-Json -Depth 5

# CORS: izin verilen origin geri yansıtılmalı
(Invoke-WebRequest "$api/api/v1/health" -Headers @{ Origin = $web }).Headers["Access-Control-Allow-Origin"]

# Giriş ve oturum
$s = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Invoke-RestMethod -Method Post "$api/api/v1/auth/login" -WebSession $s -ContentType "application/json" `
  -Headers @{ Origin = $web } -Body '{"email":"selin@resolveiq.demo","password":"resolveiq2026"}'
Invoke-RestMethod "$api/api/v1/dashboard" -WebSession $s | Select-Object -ExpandProperty totals

# Gerçek LLM ile örüntü taraması (agent_runs'a maliyet yazar)
Invoke-RestMethod -Method Post "$api/api/v1/ai/pattern_scan" -WebSession $s -Headers @{ Origin = $web } | ConvertTo-Json -Depth 4
Invoke-RestMethod "$api/api/v1/agent_runs" -WebSession $s | Select-Object -ExpandProperty totals
```

Ardından tarayıcıda [demo-script.md](demo-script.md) akışını baştan sona uygula ve sonunda demo verisini sıfırla.

## 5. Demo verisini sıfırlama

Render free planında Shell yoktur. İki yol:

```powershell
# a) Korumalı uç nokta (önerilen)
Invoke-RestMethod -Method Post "$api/api/v1/admin/demo_reset" -Headers @{ "X-Admin-Token" = "<ADMIN_TOKEN>" }

# b) Yerelden, Render > resolveiq-db > Connect > External Database URL ile
cd api
$env:DATABASE_URL = "<EXTERNAL_DATABASE_URL>"; $env:RAILS_ENV = "production"
$env:SECRET_KEY_BASE = "local-reset"; $env:FRONTEND_ORIGIN = "http://localhost:3000"
ruby bin/rails demo:reset
Remove-Item Env:DATABASE_URL, Env:RAILS_ENV, Env:SECRET_KEY_BASE, Env:FRONTEND_ORIGIN
```

Sıfırlama tüm ticket, olay, AI çalıştırması ve denetim kayıtlarını silip sentetik veriyi yeniden kurar. **Ürün içi AI maliyetini METRICS.md'ye yazmadan önce sıfırlama yapma.**

Yedek ve geri yükleme (repo dışına):

```powershell
docker run --rm -v "${HOME}\resolveiq-backups:/backup" postgres:17-alpine pg_dump "<EXTERNAL_DATABASE_URL>" -Fc -f /backup/resolveiq.dump
docker run --rm -v "${HOME}\resolveiq-backups:/backup" postgres:17-alpine pg_restore --no-owner --clean --if-exists -d "<HEDEF_DATABASE_URL>" /backup/resolveiq.dump
```

Render ücretsiz PostgreSQL oluşturulduktan 30 gün sonra silinir. Silinirse yeni bir DB oluştur, servisin `DATABASE_URL` değerini güncelle ve yeniden deploy et; build adımı şemayı ve seed'i kurar.

## 6. Uyku önleme

Free servis 15 dakika boşta kalınca uyur; ilk istek 30-60 saniye sürebilir. Sunumdan 10 dakika önce `$api/api/v1/health` adresini ve siteyi aç. İsteğe bağlı olarak cron-job.org üzerinden 10 dakikada bir health isteği atılabilir.

## 7. Yerelde production doğrulaması (yapıldı)

| Kontrol | Sonuç |
|---------|-------|
| `FRONTEND_ORIGIN` olmadan `RAILS_ENV=production` açılış | Açık bir hata ile durdu (beklenen) |
| `FRONTEND_ORIGIN` ile production açılış, eager load | Health `ok`, veritabanı `ok` |
| Seed iki kez | Sayılar değişmedi: 4 kullanıcı, 15 müşteri, 22 ticket, 11 makale |

## 8. Canlı doğrulama sonuçları

| Kontrol | Tarih | Sonuç |
|---------|-------|-------|
| Health (`status`, `database`, `ai.mode`) | 2026-10-18 18:41 | `ok`, veritabanı `ok`, `ai.mode: openai`, sürüm `d801276`, `environment: production` |
| CORS (`Access-Control-Allow-Origin`) | 2026-10-18 18:41 | `https://resolveiq.mehmetdogandev.com` |
| Demo girişi ve dashboard (API) | 2026-10-18 18:41 | Selin (manager) girişi; dashboard: 17 açık, 4 acil/yüksek, 10 atanmamış, 5 çözülmüş |
| Web girişi (tarayıcı, HttpOnly cookie) | 2026-10-18 18:44 | Tek tıkla Selin girişi → `/dashboard`, değerler canlı DB'den |
| Triage → uygula (gerçek LLM) | 2026-10-18 18:44 | `gpt-4o-mini-2024-07-18`: battery_charging / normal / Batarya ekibi, güven 0,8; uygulama sonrası sorumlu Burak Demir, 1 makale bağlandı |
| Ticket çözüm önerisi | 2026-10-18 18:44 | OpenAI, 5,7 sn |
| Örüntü taraması (demo sırası: reset → yeni ticket → triage → tarama) | 2026-10-18 18:45 | 23 aday tarandı, 1 grup: INC-001, **7 ticket / 7 müşteri**, yeni demo ticket'ı dahil, 8 kanıt satırı |
| Olay onayı → çözüm paketi → uygulama | 2026-10-18 18:44 | Olay `confirmed`; 7 ticket aksiyonu; ortak yanıt 7 ticket'a eklendi, adla kişiselleştirildi ("Merhaba Buse,"), durum `pending` |
| Demo reset (`POST /admin/demo_reset`) | 2026-10-18 18:46 | 4 kullanıcı, 15 müşteri, 22 ticket, 11 makale, 0 olay, 0 AI çalıştırması |

Not: PowerShell 5.1, BOM'suz UTF-8 `.ps1` dosyalarını Windows-1252 olarak okur. Türkçe metin gönderen betikleri UTF-8 **BOM'lu** kaydedin; aksi halde ticket metni bozulur ve benzerlik eşleşmesi kaçar. Tarayıcıdan yapılan girişlerde bu sorun yoktur.
