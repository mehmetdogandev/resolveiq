"use client";

import { useState, type FormEvent } from "react";
import { ApiError, api, errorMessage } from "@/lib/api";
import type { ArticleDetail } from "@/lib/types";
import { useSession } from "../session";
import { Button, ErrorState, Field, Input, Select, Textarea } from "../ui";

type Values = { title: string; body: string; product: string; category: string; tags: string };

export function ArticleForm({
  article,
  onSaved,
  onCancel,
}: {
  article?: ArticleDetail;
  onSaved: (a: ArticleDetail) => void;
  onCancel: () => void;
}) {
  const { meta } = useSession();
  const [values, setValues] = useState<Values>({
    title: article?.title ?? "",
    body: article?.body ?? "",
    product: article?.product ?? "",
    category: article?.category ?? "",
    tags: article?.tags.join(", ") ?? "",
  });
  const [errors, setErrors] = useState<Partial<Record<keyof Values, string>>>({});
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const set = (key: keyof Values, value: string) => setValues((v) => ({ ...v, [key]: value }));

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const next: Partial<Record<keyof Values, string>> = {};
    if (values.title.trim().length < 5) next.title = "Başlık en az 5 karakter olmalı";
    if (values.body.trim().length < 20) next.body = "İçerik en az 20 karakter olmalı";
    setErrors(next);
    if (Object.keys(next).length) return;

    setSaving(true);
    setError(null);
    try {
      const body = { article: { ...values, product: values.product || null, category: values.category || null } };
      const res = article
        ? await api<{ article: ArticleDetail }>(`/articles/${article.id}`, { method: "PATCH", body })
        : await api<{ article: ArticleDetail }>("/articles", { method: "POST", body });
      onSaved(res.article);
    } catch (err) {
      if (err instanceof ApiError && err.details) {
        setErrors(Object.fromEntries(Object.entries(err.details).map(([k, v]) => [k, v[0]])));
      }
      setError(errorMessage(err));
      setSaving(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4" noValidate>
      <Field label="Başlık *" htmlFor="a-title" error={errors.title}>
        <Input id="a-title" value={values.title} onChange={(e) => set("title", e.target.value)} maxLength={200} />
      </Field>
      <div className="grid gap-4 sm:grid-cols-3">
        <Field label="Ürün" htmlFor="a-product">
          <Select id="a-product" value={values.product} onChange={(e) => set("product", e.target.value)}>
            <option value="">Genel</option>
            {meta.products.map((p) => (
              <option key={p.code} value={p.code}>
                {p.name}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Kategori" htmlFor="a-category">
          <Select id="a-category" value={values.category} onChange={(e) => set("category", e.target.value)}>
            <option value="">Belirtilmedi</option>
            {meta.categories.map((c) => (
              <option key={c.code} value={c.code}>
                {c.name}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Etiketler" htmlFor="a-tags" hint="Virgülle ayırın">
          <Input id="a-tags" value={values.tags} onChange={(e) => set("tags", e.target.value)} />
        </Field>
      </div>
      <Field label="İçerik *" htmlFor="a-body" error={errors.body} hint="Numaralı adımlar (1. 2. 3.) ticket yanıtına otomatik aktarılır.">
        <Textarea id="a-body" rows={14} value={values.body} onChange={(e) => set("body", e.target.value)} className="font-mono text-xs" />
      </Field>
      {error && <ErrorState message={error} />}
      <div className="flex justify-end gap-2">
        <Button type="button" variant="secondary" onClick={onCancel}>
          Vazgeç
        </Button>
        <Button type="submit" variant="accent" loading={saving}>
          {article ? "Kaydet" : "Taslak olarak kaydet"}
        </Button>
      </div>
    </form>
  );
}
