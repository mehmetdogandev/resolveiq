# ResolveIQ API (Rails 8.1)

ResolveIQ'nun JSON API'si. Proje açıklaması için kök [README.md](../README.md), mimari için [docs/architecture.md](../docs/architecture.md), canlı ortam için [docs/deployment.md](../docs/deployment.md).

```bash
docker compose up -d           # kök dizinde, PostgreSQL
bin/rails db:prepare           # şema + sentetik demo verisi
AI_DEMO_MODE=1 bin/rails server -p 3001
bin/rails test                 # Minitest
bin/rails demo:reset           # demo verisini sıfırla
```

`OPENAI_API_KEY` yalnızca sunucu ortam değişkeninde tutulur; anahtar yoksa ve `AI_DEMO_MODE` açık değilse AI uç noktaları 503 döner.
