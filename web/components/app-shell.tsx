"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState, type FormEvent, type ReactNode } from "react";
import { BookOpen, Inbox, LayoutDashboard, LogOut, Menu, Search, Sparkles, Ticket, X } from "lucide-react";
import { api } from "@/lib/api";
import { useApi } from "@/lib/hooks";
import type { Dashboard } from "@/lib/types";
import { ApiStatus } from "./api-status";
import { Logo } from "./logo";
import { useSession } from "./session";
import { cn } from "./ui";

const NAV = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/tickets", label: "Ticket'lar", icon: Ticket },
  { href: "/inbox", label: "Gelen kutusu", icon: Inbox },
  { href: "/knowledge", label: "Bilgi bankası", icon: BookOpen },
  { href: "/ai-insights", label: "AI Insights", icon: Sparkles },
];

function NavLinks({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();
  return (
    <nav className="mt-6 space-y-0.5" aria-label="Ana menü">
      {NAV.map(({ href, label, icon: Icon }) => {
        const active = pathname === href || pathname.startsWith(`${href}/`);
        return (
          <Link
            key={href}
            href={href}
            onClick={onNavigate}
            aria-current={active ? "page" : undefined}
            className={cn(
              "flex items-center gap-2.5 rounded-md px-2.5 py-2 text-sm transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent-500",
              active ? "bg-white/10 font-medium text-white" : "text-slate-300 hover:bg-white/5 hover:text-white",
            )}
          >
            <Icon className={cn("size-4", active && "text-accent-500")} aria-hidden />
            {label}
          </Link>
        );
      })}
    </nav>
  );
}

export function AppShell({ children }: { children: ReactNode }) {
  const { me } = useSession();
  const router = useRouter();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [query, setQuery] = useState("");
  const { data: dashboard } = useApi<Dashboard>("/dashboard", { refreshInterval: 60000 });
  const pending = dashboard?.pending_actions.length ?? 0;

  function onSearch(event: FormEvent) {
    event.preventDefault();
    const q = query.trim();
    router.push(q ? `/tickets?q=${encodeURIComponent(q)}` : "/tickets");
  }

  async function logout() {
    await api("/auth/logout", { method: "DELETE" }).catch(() => undefined);
    router.replace("/login");
  }

  const sidebar = (
    <>
      <div className="flex items-center justify-between px-2">
        <Link href="/dashboard" aria-label="ResolveIQ ana sayfa">
          <Logo inverted />
        </Link>
      </div>
      <NavLinks onNavigate={() => setMobileOpen(false)} />
      <div className="mt-auto space-y-3 px-2">
        <p className="rounded-md bg-white/5 px-2.5 py-2 text-[11px] leading-snug text-slate-400">
          Tüm müşteri ve ürün verileri sentetiktir (hayali marka: Northforge Tools).
        </p>
        <ApiStatus compact />
      </div>
    </>
  );

  return (
    <div className="flex min-h-screen w-full">
      <aside className="sticky top-0 hidden h-screen w-60 shrink-0 flex-col bg-navy-900 px-3 py-4 lg:flex">{sidebar}</aside>

      {mobileOpen && (
        <div className="fixed inset-0 z-40 lg:hidden" role="dialog" aria-modal="true" aria-label="Menü">
          <button type="button" className="absolute inset-0 bg-navy-950/60" aria-label="Menüyü kapat" onClick={() => setMobileOpen(false)} />
          <aside className="relative flex h-full w-64 flex-col bg-navy-900 px-3 py-4">
            <button type="button" onClick={() => setMobileOpen(false)} className="absolute right-3 top-4 text-slate-300" aria-label="Menüyü kapat">
              <X className="size-5" />
            </button>
            {sidebar}
          </aside>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-14 items-center gap-3 border-b border-slate-200 bg-white/90 px-4 backdrop-blur">
          <button type="button" className="text-slate-600 lg:hidden" onClick={() => setMobileOpen(true)} aria-label="Menüyü aç">
            <Menu className="size-5" />
          </button>
          <form onSubmit={onSearch} className="relative max-w-md flex-1" role="search">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-slate-400" aria-hidden />
            <label htmlFor="global-search" className="sr-only">
              Ticket ara
            </label>
            <input
              id="global-search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Ticket no, konu, müşteri veya ürün ara..."
              className="h-9 w-full rounded-md border border-slate-200 bg-slate-50 pl-8 pr-3 text-sm placeholder:text-slate-400 focus:border-accent-500 focus:bg-white focus:outline-none focus:ring-2 focus:ring-accent-100"
            />
          </form>
          <div className="ml-auto flex items-center gap-3">
            <Link
              href="/dashboard#pending"
              className="relative flex items-center gap-1.5 rounded-md px-2 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-100"
              title="AI'ın hazırladığı ve onayınızı bekleyen işler"
            >
              <Sparkles className="size-4 text-accent-600" aria-hidden />
              <span className="hidden sm:inline">Onay bekleyen</span>
              <span
                className={cn(
                  "min-w-5 rounded-full px-1.5 py-0.5 text-center text-[11px]",
                  pending > 0 ? "bg-accent-600 text-white" : "bg-slate-100 text-slate-500",
                )}
              >
                {pending}
              </span>
            </Link>
            <div className="flex items-center gap-2 border-l border-slate-200 pl-3">
              <span className="flex size-8 items-center justify-center rounded-full bg-navy-800 text-xs font-semibold text-white" aria-hidden>
                {me.initials}
              </span>
              <div className="hidden leading-tight sm:block">
                <p className="text-sm font-medium text-slate-900">{me.name}</p>
                <p className="text-[11px] text-slate-500">{me.role === "manager" ? "Yönetici" : "Destek uzmanı"} · {me.team_name}</p>
              </div>
              <button type="button" onClick={() => void logout()} className="rounded-md p-1.5 text-slate-500 hover:bg-slate-100 hover:text-slate-900" aria-label="Çıkış yap" title="Çıkış yap">
                <LogOut className="size-4" />
              </button>
            </div>
          </div>
        </header>
        <main className="mx-auto w-full max-w-[1400px] flex-1 p-4 sm:p-6">{children}</main>
      </div>
    </div>
  );
}
