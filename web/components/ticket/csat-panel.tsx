"use client";

import { useState } from "react";
import { api, errorMessage } from "@/lib/api";
import type { TicketDetail } from "@/lib/types";
import { Button, Card, CardHeader, ErrorState, Textarea } from "../ui";

export function CsatPanel({ ticket, onChange }: { ticket: TicketDetail; onChange: (t: TicketDetail) => void }) {
  const [score, setScore] = useState(5);
  const [comment, setComment] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (ticket.status !== "resolved") return null;

  async function submit() {
    setSaving(true);
    setError(null);
    try {
      const res = await api<{ ticket: TicketDetail }>(`/tickets/${ticket.id}/csat`, { method: "POST", body: { score, comment: comment || undefined } });
      onChange(res.ticket);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <CardHeader title="Müşteri memnuniyeti (CSAT)" description="Demo: temsilci, müşteri anketi sonucunu kaydeder" />
      <div className="space-y-3 p-4">
        {ticket.csat ? (
          <p className="text-sm text-slate-700">
            Kayıtlı puan: <strong>{ticket.csat.score}/5</strong>
            {ticket.csat.comment ? ` · ${ticket.csat.comment}` : ""}
          </p>
        ) : (
          <>
            <div className="flex gap-1" role="group" aria-label="CSAT puanı">
              {[1, 2, 3, 4, 5].map((n) => (
                <button
                  key={n}
                  type="button"
                  onClick={() => setScore(n)}
                  className={`size-8 rounded-md text-sm font-medium ${score === n ? "bg-navy-900 text-white" : "bg-slate-100 text-slate-700"}`}
                >
                  {n}
                </button>
              ))}
            </div>
            <Textarea rows={2} value={comment} onChange={(e) => setComment(e.target.value)} placeholder="İsteğe bağlı yorum" />
            {error && <ErrorState message={error} />}
            <Button size="sm" loading={saving} onClick={() => void submit()}>
              CSAT kaydet
            </Button>
          </>
        )}
      </div>
    </Card>
  );
}
