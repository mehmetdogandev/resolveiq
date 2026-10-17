"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Bot, Layers, Workflow } from "lucide-react";
import { ApiStatus } from "@/components/api-status";
import { Logo } from "@/components/logo";
import { Button, ErrorState, Field, Input } from "@/components/ui";
import { api, errorMessage } from "@/lib/api";
import type { Me } from "@/lib/types";

const DEMO_PASSWORD = "resolveiq2026";
const demoUsers = [
  { email: "selin@resolveiq.demo", name: "Selin Aydın", role: "Destek Operasyon Müdürü (manager)" },
  { email: "burak@resolveiq.demo", name: "Burak Demir", role: "Batarya ve Şarj Uzmanı (agent)" },
  { email: "ayse@resolveiq.demo", name: "Ayşe Kara", role: "Garanti Uzmanı (agent)" },
];

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function login(loginEmail: string, loginPassword: string) {
    setLoading(true);
    setError(null);
    try {
      await api<{ user: Me }>("/auth/login", { method: "POST", body: { email: loginEmail, password: loginPassword } });
      router.replace("/dashboard");
    } catch (err) {
      setError(errorMessage(err));
      setLoading(false);
    }
  }

  function onSubmit(event: FormEvent) {
    event.preventDefault();
    if (!email || !password) {
      setError("E-posta ve parola zorunludur");
      return;
    }
    void login(email, password);
  }

  return (
    <div className="grid min-h-screen lg:grid-cols-[1.1fr_1fr]">
      <section className="relative hidden flex-col justify-between overflow-hidden bg-navy-950 p-10 text-white lg:flex">
        <div className="absolute -right-24 -top-24 size-96 rounded-full bg-accent-500/10 blur-3xl" aria-hidden />
        <Logo inverted />
        <div className="relative max-w-md">
          <h1 className="text-3xl font-semibold leading-tight tracking-tight">Destek ekibiniz yazmasın, karar versin.</h1>
          <p className="mt-3 text-sm leading-relaxed text-slate-300">
            ResolveIQ gelen talepleri sınıflandırır, benzer şikayetlerden olası ortak sorunu çıkarır ve ortak yanıtı hazırlar. Siz yalnızca
            inceleyip onaylarsınız.
          </p>
          <ul className="mt-8 space-y-4 text-sm">
            {[
              { icon: Layers, text: "E-posta, web ve sohbet tek gelen kutusunda" },
              { icon: Bot, text: "Akıllı triage: kategori, öncelik, sorumlu ve yanıt taslağı hazır gelir" },
              { icon: Workflow, text: "Örüntü tespiti ve çözüm paketi: tek onayla tüm etkilenen müşterilere" },
            ].map(({ icon: Icon, text }) => (
              <li key={text} className="flex items-start gap-3">
                <span className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-white/5 ring-1 ring-white/10">
                  <Icon className="size-4 text-accent-500" aria-hidden />
                </span>
                <span className="pt-1.5 text-slate-200">{text}</span>
              </li>
            ))}
          </ul>
        </div>
        <p className="relative text-xs text-slate-500">Tüm veriler sentetiktir. Northforge Tools hayali bir markadır.</p>
      </section>

      <section className="flex items-center justify-center p-6">
        <div className="w-full max-w-sm">
          <div className="lg:hidden">
            <Logo />
          </div>
          <h2 className="mt-6 text-xl font-semibold text-slate-900 lg:mt-0">Giriş yap</h2>
          <p className="mt-1 text-sm text-slate-500">Demo hesaplarından biriyle hızlıca girebilirsiniz.</p>

          <div className="mt-5 space-y-2">
            {demoUsers.map((user) => (
              <button
                key={user.email}
                type="button"
                disabled={loading}
                onClick={() => void login(user.email, DEMO_PASSWORD)}
                className="flex w-full items-center justify-between rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-left transition hover:border-accent-500 hover:bg-accent-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent-500 disabled:opacity-60"
              >
                <span>
                  <span className="block text-sm font-medium text-slate-900">{user.name}</span>
                  <span className="block text-xs text-slate-500">{user.role}</span>
                </span>
                <span className="text-xs font-medium text-accent-700">Giriş →</span>
              </button>
            ))}
          </div>

          <div className="my-5 flex items-center gap-3 text-xs text-slate-400">
            <span className="h-px flex-1 bg-slate-200" /> veya <span className="h-px flex-1 bg-slate-200" />
          </div>

          <form onSubmit={onSubmit} className="space-y-3" noValidate>
            <Field label="E-posta" htmlFor="email">
              <Input id="email" type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} />
            </Field>
            <Field label="Parola" htmlFor="password" hint={`Demo parolası: ${DEMO_PASSWORD}`}>
              <Input id="password" type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} />
            </Field>
            {error && <ErrorState message={error} />}
            <Button type="submit" className="w-full" loading={loading}>
              Giriş yap
            </Button>
          </form>

          <p className="mt-4 text-center text-xs text-slate-500">
            Müşteri misiniz?{" "}
            <Link href="/help" className="font-medium text-accent-700 hover:underline">
              Yardım merkezini açın
            </Link>
          </p>
          <div className="mt-6 border-t border-slate-100 pt-4">
            <ApiStatus />
          </div>
        </div>
      </section>
    </div>
  );
}
