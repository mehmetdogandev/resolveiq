import { AlertTriangle } from "lucide-react";
import { ApiError } from "@/lib/api";

export function AiErrorNotice({ error }: { error: unknown }) {
  const unavailable = error instanceof ApiError && error.code === "ai_unavailable";
  const message = error instanceof Error ? error.message : "AI isteği başarısız oldu";
  return (
    <div className="flex gap-2 rounded-lg border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900" role="alert">
      <AlertTriangle className="mt-0.5 size-4 shrink-0" aria-hidden />
      <div>
        <p className="font-medium">{unavailable ? "AI katmanı yapılandırılmamış" : "AI şu an yanıt veremedi"}</p>
        <p className="mt-0.5">{message}</p>
        <p className="mt-1 text-amber-800">Ticket işlemleri AI olmadan da normal çalışmaya devam eder.</p>
      </div>
    </div>
  );
}
