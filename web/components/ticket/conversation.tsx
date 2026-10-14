import { BookOpen, Lock, Sparkles, Users } from "lucide-react";
import { formatDateTime } from "@/lib/format";
import type { TicketMessage } from "@/lib/types";
import { Badge, cn } from "../ui";

const originBadge: Record<TicketMessage["origin"], { label: string; icon: typeof Sparkles } | null> = {
  manual: null,
  ai_draft: { label: "AI taslağından", icon: Sparkles },
  knowledge: { label: "Bilgi bankasından", icon: BookOpen },
  incident: { label: "Olay ortak yanıtı", icon: Users },
};

export function Conversation({ messages }: { messages: TicketMessage[] }) {
  return (
    <ol className="space-y-4" aria-label="Konuşma geçmişi">
      {messages.map((m) => {
        const fromCustomer = m.author_type === "customer";
        const origin = originBadge[m.origin];
        return (
          <li key={m.id} className={cn("flex gap-3", !fromCustomer && "flex-row-reverse")}>
            <span
              className={cn(
                "flex size-8 shrink-0 items-center justify-center rounded-full text-[11px] font-semibold",
                fromCustomer ? "bg-slate-200 text-slate-700" : m.internal ? "bg-amber-100 text-amber-800" : "bg-navy-800 text-white",
              )}
              aria-hidden
            >
              {m.author_name
                .split(" ")
                .map((p) => p[0])
                .slice(0, 2)
                .join("")}
            </span>
            <div
              className={cn(
                "max-w-[85%] rounded-xl border px-4 py-3",
                fromCustomer && "border-slate-200 bg-white",
                !fromCustomer && !m.internal && "border-accent-100 bg-accent-50/60",
                m.internal && "border-amber-200 bg-amber-50",
              )}
            >
              <div className="mb-1 flex flex-wrap items-center gap-2 text-xs">
                <span className="font-medium text-slate-900">{m.author_name}</span>
                {m.internal && (
                  <Badge tone="amber">
                    <Lock className="size-3" aria-hidden /> İç not (müşteri görmez)
                  </Badge>
                )}
                {origin && (
                  <Badge tone="teal" className="font-normal">
                    <origin.icon className="size-3" aria-hidden /> {origin.label}
                  </Badge>
                )}
                <time className="text-slate-500" dateTime={m.created_at}>
                  {formatDateTime(m.created_at)}
                </time>
              </div>
              <p className="whitespace-pre-wrap text-sm leading-relaxed text-slate-800">{m.body}</p>
            </div>
          </li>
        );
      })}
    </ol>
  );
}
