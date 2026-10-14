"use client";

import { useRouter } from "next/navigation";
import { ArticleForm } from "@/components/knowledge/article-form";
import { Card, PageHeader } from "@/components/ui";

export default function NewArticlePage() {
  const router = useRouter();
  return (
    <div className="mx-auto max-w-3xl">
      <PageHeader title="Yeni makale" description="Makaleler taslak olarak kaydedilir; yayınlama yönetici onayı gerektirir." />
      <Card className="p-5">
        <ArticleForm onSaved={(a) => router.push(`/knowledge/${a.slug}`)} onCancel={() => router.back()} />
      </Card>
    </div>
  );
}
