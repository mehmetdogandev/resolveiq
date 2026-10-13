"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Sparkles } from "lucide-react";
import { useSession } from "@/components/session";
import { Button, Card, ErrorState, Field, Input, PageHeader, Select, Textarea } from "@/components/ui";
import { ApiError, api, errorMessage } from "@/lib/api";
import { CHANNEL_LABEL, PRIORITY_LABEL } from "@/lib/labels";
import type { Channel, Priority, TicketSummary } from "@/lib/types";

type Form = {
  customer_id: string;
  channel: Channel;
  subject: string;
  description: string;
  product: string;
  category: string;
  priority: Priority;
};

export default function NewTicketPage() {
  const { meta } = useSession();
  const router = useRouter();
  const [form, setForm] = useState<Form>({ customer_id: "", channel: "email", subject: "", description: "", product: "", category: "", priority: "normal" });
  const [errors, setErrors] = useState<Partial<Record<keyof Form, string>>>({});
  const [serverError, setServerError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [autoTriage, setAutoTriage] = useState(true);

  const set = <K extends keyof Form>(key: K, value: Form[K]) => setForm((f) => ({ ...f, [key]: value }));

  function validate() {
    const next: Partial<Record<keyof Form, string>> = {};
    if (!form.customer_id) next.customer_id = "Müşteri seçin";
    if (form.subject.trim().length < 5) next.subject = "Konu en az 5 karakter olmalı";
    if (form.description.trim().length < 10) next.description = "Açıklama en az 10 karakter olmalı";
    setErrors(next);
    return Object.keys(next).length === 0;
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    if (!validate()) return;
    setSaving(true);
    setServerError(null);
    try {
      const { ticket } = await api<{ ticket: TicketSummary }>("/tickets", {
        method: "POST",
        body: { ticket: { ...form, customer_id: Number(form.customer_id), product: form.product || null, category: form.category || null } },
      });
      router.push(`/tickets/${ticket.id}${autoTriage ? "?triage=auto" : ""}`);
    } catch (err) {
      if (err instanceof ApiError && err.details) {
        const mapped: Partial<Record<keyof Form, string>> = {};
        Object.entries(err.details).forEach(([k, v]) => {
          mapped[(k === "customer" ? "customer_id" : k) as keyof Form] = v[0];
        });
        setErrors(mapped);
      }
      setServerError(errorMessage(err));
      setSaving(false);
    }
  }

  return (
    <div className="mx-auto max-w-3xl">
      <PageHeader title="Yeni ticket" description="Gelen bir e-posta, web formu veya sohbet talebini kaydedin (sentetik kanal)." />
      <Card className="p-5">
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Müşteri *" htmlFor="customer" error={errors.customer_id}>
              <Select id="customer" value={form.customer_id} onChange={(e) => set("customer_id", e.target.value)} aria-invalid={!!errors.customer_id}>
                <option value="">Müşteri seçin</option>
                {meta.customers.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                    {c.company ? ` · ${c.company}` : ""}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="Kanal *" htmlFor="channel">
              <Select id="channel" value={form.channel} onChange={(e) => set("channel", e.target.value as Channel)}>
                {(Object.keys(CHANNEL_LABEL) as Channel[]).map((c) => (
                  <option key={c} value={c}>
                    {CHANNEL_LABEL[c]}
                  </option>
                ))}
              </Select>
            </Field>
          </div>
          <Field label="Konu *" htmlFor="subject" error={errors.subject}>
            <Input id="subject" value={form.subject} onChange={(e) => set("subject", e.target.value)} maxLength={200} aria-invalid={!!errors.subject} />
          </Field>
          <Field label="Açıklama (müşterinin mesajı) *" htmlFor="description" error={errors.description}>
            <Textarea id="description" rows={6} value={form.description} onChange={(e) => set("description", e.target.value)} aria-invalid={!!errors.description} />
          </Field>
          <div className="grid gap-4 sm:grid-cols-3">
            <Field label="Ürün" htmlFor="product">
              <Select id="product" value={form.product} onChange={(e) => set("product", e.target.value)}>
                <option value="">Belirtilmedi</option>
                {meta.products.map((p) => (
                  <option key={p.code} value={p.code}>
                    {p.name}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="Kategori" htmlFor="category" hint="Boş bırakabilirsiniz; AI triage önerir.">
              <Select id="category" value={form.category} onChange={(e) => set("category", e.target.value)}>
                <option value="">Belirtilmedi</option>
                {meta.categories.map((c) => (
                  <option key={c.code} value={c.code}>
                    {c.name}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="Öncelik" htmlFor="priority">
              <Select id="priority" value={form.priority} onChange={(e) => set("priority", e.target.value as Priority)}>
                {(Object.keys(PRIORITY_LABEL) as Priority[]).map((p) => (
                  <option key={p} value={p}>
                    {PRIORITY_LABEL[p]}
                  </option>
                ))}
              </Select>
            </Field>
          </div>
          <label className="flex items-start gap-2 rounded-lg border border-accent-100 bg-accent-50 p-3 text-sm text-slate-700">
            <input type="checkbox" className="mt-0.5 accent-accent-600" checked={autoTriage} onChange={(e) => setAutoTriage(e.target.checked)} />
            <span>
              <span className="flex items-center gap-1 font-medium text-slate-900">
                <Sparkles className="size-3.5 text-accent-600" aria-hidden /> Kaydettikten sonra AI triage çalıştır
              </span>
              <span className="text-xs text-slate-600">Kategori, öncelik, sorumlu, ilgili makaleler ve yanıt taslağı hazır gelir. Hiçbir şey onayınız olmadan uygulanmaz.</span>
            </span>
          </label>
          {serverError && <ErrorState message={serverError} />}
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => router.back()}>
              Vazgeç
            </Button>
            <Button type="submit" variant="accent" loading={saving}>
              Ticket oluştur
            </Button>
          </div>
        </form>
      </Card>
    </div>
  );
}
