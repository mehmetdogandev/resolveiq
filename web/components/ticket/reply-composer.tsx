"use client";

import { useState } from "react";
import { Lock, Send, Sparkles } from "lucide-react";
import { api, errorMessage } from "@/lib/api";
import type { TicketDetail, TicketMessage, TicketStatus } from "@/lib/types";
import { Badge, Button, ErrorState, Textarea, cn } from "../ui";

export type Draft = { body: string; origin: TicketMessage["origin"] };

export function ReplyComposer({
  ticket,
  draft,
  setDraft,
  onSent,
}: {
  ticket: TicketDetail;
  draft: Draft;
  setDraft: (d: Draft) => void;
  onSent: (t: TicketDetail) => void;
}) {
  const [internal, setInternal] = useState(false);
  const [sending, setSending] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function send(status?: TicketStatus) {
    if (!draft.body.trim()) {
      setError("Mesaj boş olamaz");
      return;
    }
    setSending(status ?? "send");
    setError(null);
    try {
      const res = await api<{ ticket: TicketDetail }>(`/tickets/${ticket.id}/messages`, {
        method: "POST",
        body: { message: { body: draft.body, internal, origin: draft.origin, status } },
      });
      setDraft({ body: "", origin: "manual" });
      onSent(res.ticket);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSending(null);
    }
  }

  return (
    <div className={cn("rounded-xl border bg-white", internal ? "border-amber-300" : "border-slate-200")}>
      <div className="flex items-center gap-1 border-b border-slate-100 px-2 pt-2" role="tablist" aria-label="Mesaj türü">
        {[
          { key: false, label: "Müşteriye yanıt", icon: Send },
          { key: true, label: "İç not", icon: Lock },
        ].map(({ key, label, icon: Icon }) => (
          <button
            key={label}
            type="button"
            role="tab"
            aria-selected={internal === key}
            onClick={() => setInternal(key)}
            className={cn(
              "flex items-center gap-1.5 rounded-t-md px-3 py-1.5 text-xs font-medium",
              internal === key ? (key ? "bg-amber-50 text-amber-800" : "bg-accent-50 text-accent-700") : "text-slate-500 hover:text-slate-800",
            )}
          >
            <Icon className="size-3.5" aria-hidden /> {label}
          </button>
        ))}
        {draft.origin !== "manual" && (
          <Badge tone="teal" className="ml-auto font-normal">
            <Sparkles className="size-3" aria-hidden />
            {draft.origin === "ai_draft" ? "AI taslağı: göndermeden önce düzenleyin" : "Bilgi bankasından eklendi"}
          </Badge>
        )}
      </div>
      <label htmlFor="composer" className="sr-only">
        {internal ? "İç not" : "Yanıt"}
      </label>
      <Textarea
        id="composer"
        rows={6}
        value={draft.body}
        onChange={(e) => setDraft({ ...draft, body: e.target.value })}
        placeholder={internal ? "Ekip içi not (müşteriye gönderilmez)..." : `${ticket.customer.name} için yanıt yazın...`}
        className="rounded-none border-0 focus:ring-0"
      />
      {error && (
        <div className="px-3 pb-2">
          <ErrorState message={error} />
        </div>
      )}
      <div className="flex flex-wrap items-center justify-end gap-2 border-t border-slate-100 px-3 py-2">
        {internal ? (
          <Button variant="primary" size="sm" loading={sending === "send"} onClick={() => void send()}>
            <Lock className="size-3.5" aria-hidden /> Notu kaydet
          </Button>
        ) : (
          <>
            <Button variant="secondary" size="sm" loading={sending === "pending"} onClick={() => void send("pending")}>
              Gönder ve beklemeye al
            </Button>
            <Button variant="secondary" size="sm" loading={sending === "resolved"} onClick={() => void send("resolved")}>
              Gönder ve çöz
            </Button>
            <Button variant="accent" size="sm" loading={sending === "send"} onClick={() => void send()}>
              <Send className="size-3.5" aria-hidden /> Gönder
            </Button>
          </>
        )}
      </div>
    </div>
  );
}
