export default async function Page() {
  const apiUrl = (process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001").replace(/\/$/, "");
  let body = "Rails API henüz yanıt vermedi.";
  try {
    const res = await fetch(`${apiUrl}/api/v1/health`, { cache: "no-store" });
    body = await res.text();
  } catch {
    body = "API'ye ulaşılamadı. Rails sunucusunu başlatın.";
  }
  return (
    <main style={{ fontFamily: "sans-serif", padding: 48 }}>
      <h1>ResolveIQ</h1>
      <p>Next.js + Rails API zinciri ayakta.</p>
      <pre>{body}</pre>
    </main>
  );
}
