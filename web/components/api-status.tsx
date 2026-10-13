"use client";

import { useApi } from "@/lib/hooks";
import type { Health } from "@/lib/types";
import { cn } from "./ui";

export function useHealth() {
  return useApi<Health>("/health", { refreshInterval: 60000, shouldRetryOnError: true, errorRetryInterval: 8000 });
}

export function ApiStatus({ compact = false }: { compact?: boolean }) {
  const { data, error, isLoading } = useHealth();

  let tone = "bg-slate-400";
  let label = "API kontrol ediliyor...";
  let detail = "";

  if (data?.status === "ok") {
    tone = "bg-emerald-500";
    label = "API bağlı";
    detail = `Veritabanı: ${data.checks.database === "ok" ? "sağlıklı" : data.checks.database} · AI: ${aiLabel(data.ai.mode)}`;
  } else if (data) {
    tone = "bg-amber-500";
    label = "API kısmen çalışıyor";
    detail = "Veritabanına ulaşılamıyor";
  } else if (error && !isLoading) {
    tone = "bg-red-500";
    label = "API'ye ulaşılamıyor";
    detail = error.message;
  }

  return (
    <div className="flex items-center gap-2 text-xs" role="status" aria-live="polite" title={detail}>
      <span className={cn("size-2 rounded-full", tone, !data && !error && "animate-pulse")} />
      <span className={compact ? "text-slate-300" : "text-slate-700"}>{label}</span>
      {!compact && detail && <span className="text-slate-500">· {detail}</span>}
    </div>
  );
}

export function aiLabel(mode: Health["ai"]["mode"]) {
  switch (mode) {
    case "openai":
      return "OpenAI bağlı";
    case "fallback":
      return "Deterministik fallback (demo)";
    case "fake":
      return "Test";
    default:
      return "Yapılandırılmamış";
  }
}
