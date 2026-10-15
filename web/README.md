# ResolveIQ Web (Next.js)

ResolveIQ'nun Next.js 16 ön yüzü. Proje açıklaması, kurulum ve demo için kök [README.md](../README.md) dosyasına bakın.

```bash
cp .env.example .env.local   # NEXT_PUBLIC_API_URL=http://localhost:3001
npm install
npm run dev                  # http://localhost:3000
npm run lint && npx tsc --noEmit && npm run build
```

Tarayıcıya hiçbir sır gönderilmez; tüm AI çağrıları Rails API üzerinden yapılır. Yalnızca `NEXT_PUBLIC_API_URL` ortam değişkeni kullanılır.
