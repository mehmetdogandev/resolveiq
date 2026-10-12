"use client";

import { useState, type FormEvent } from "react";
import { api, errorMessage } from "@/lib/api";
import { Button, ErrorState, Field, Input, Select, Textarea } from "@/components/ui";
import { useApi } from "@/lib/hooks";
import type { CodeName } from "@/lib/types";

type HelpMeta = { products: CodeName[] };

export default function HelpRequestPage() {
  const meta = useApi<HelpMeta>("/help/articles");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [subject, setSubject] = useState("");
  const [description, setDescription] = useState("");
  const [product, setProduct] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [number, setNumber] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await api<{ ticket: { number: string } }>("/help/requests", {
        method: "POST",
        body: { request: { name, email, subject, description, product: product || undefined } },
      });
      setNumber(res.ticket.number);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }

  if (number) {
    return (
      <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-6">
        <h1 className="text-xl font-semibold text-emerald-950">Talebiniz alındı</h1>
        <p className="mt-2 text-sm text-emerald-900">
          Destek kaydınız oluşturuldu. Takip numaranız: <strong>{number}</strong>
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4 rounded-xl border border-slate-200 bg-white p-6">
      <div>
        <h1 className="text-xl font-semibold text-slate-900">Destek talebi</h1>
        <p className="mt-1 text-sm text-slate-600">Form, web kanalından bir ticket açar. Giriş gerekmez.</p>
      </div>
      <Field label="Ad soyad" htmlFor="name">
        <Input id="name" required value={name} onChange={(e) => setName(e.target.value)} />
      </Field>
      <Field label="E-posta" htmlFor="email">
        <Input id="email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
      </Field>
      <Field label="Ürün" htmlFor="product">
        <Select id="product" value={product} onChange={(e) => setProduct(e.target.value)}>
          <option value="">Belirtmek istemiyorum</option>
          {(meta.data?.products ?? []).map((p) => (
            <option key={p.code} value={p.code}>
              {p.name}
            </option>
          ))}
        </Select>
      </Field>
      <Field label="Konu" htmlFor="subject">
        <Input id="subject" required value={subject} onChange={(e) => setSubject(e.target.value)} />
      </Field>
      <Field label="Açıklama" htmlFor="description">
        <Textarea id="description" required rows={5} value={description} onChange={(e) => setDescription(e.target.value)} />
      </Field>
      {error && <ErrorState message={error} />}
      <Button type="submit" loading={loading}>
        Talebi gönder
      </Button>
    </form>
  );
}
