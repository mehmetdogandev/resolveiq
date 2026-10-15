"use client";

import Link from "next/link";
import { useState } from "react";
import { BookPlus } from "lucide-react";
import { api, errorMessage } from "@/lib/api";
import type { ArticleDetail } from "@/lib/types";
import { Button } from "../ui";

export function KbDraftButton({
  title,
  body,
  tags,
  product,
  category,
  runId,
}: {
  title: string;
  body: string;
  tags: string[];
  product: string | null;
  category?: string | null;
  runId?: number;
}) {
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState<ArticleDetail | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function save() {
    setSaving(true);
    setError(null);
    try {
      const res = await api<{ article: ArticleDetail }>("/articles", {
        method: "POST",
        body: { article: { title, body, tags, product, category: category ?? null, source: "ai_draft", agent_run_id: runId } },
      });
      setSaved(res.article);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(false);
    }
  }

  if (saved) {
    return (
      <p className="text-xs text-emerald-700">
        Taslak kaydedildi.{" "}
        <Link href={`/knowledge/${saved.slug}`} className="font-medium underline">
          Taslağı aç
        </Link>{" "}
        (yayın için yönetici onayı gerekir)
      </p>
    );
  }
  return (
    <div className="space-y-1">
      <Button size="sm" variant="secondary" loading={saving} disabled={!title || !body} onClick={() => void save()}>
        <BookPlus className="size-3.5" aria-hidden /> Bilgi bankası taslağı olarak kaydet
      </Button>
      {error && <p className="text-xs text-red-600">{error}</p>}
    </div>
  );
}
