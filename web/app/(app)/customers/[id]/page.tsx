"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { CustomerHistory } from "@/components/customer-history";
import { Card, PageHeader } from "@/components/ui";

export default function CustomerPage() {
  const { id } = useParams<{ id: string }>();
  return (
    <div className="mx-auto max-w-3xl">
      <Link href="/inbox" className="mb-3 inline-flex items-center gap-1 text-xs text-slate-500 hover:text-slate-900">
        <ArrowLeft className="size-3.5" aria-hidden /> Gelen kutusu
      </Link>
      <PageHeader title="Müşteri geçmişi" description="Müşterinin tüm kanallardaki talepleri (sentetik veri)" />
      <Card className="p-5">
        <CustomerHistory customerId={Number(id)} />
      </Card>
    </div>
  );
}
