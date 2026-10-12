import Link from "next/link";
import { Logo } from "@/components/logo";

export default function HelpLayout({ children }: LayoutProps<"/help">) {
  return (
    <div className="min-h-full bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-3xl items-center justify-between px-4 py-4">
          <Link href="/help" aria-label="Yardım merkezi">
            <Logo />
          </Link>
          <nav className="flex items-center gap-4 text-sm">
            <Link href="/help" className="text-slate-600 hover:text-slate-900">
              Makaleler
            </Link>
            <Link href="/help/request" className="font-medium text-accent-700 hover:underline">
              Destek talebi
            </Link>
            <Link href="/login" className="text-slate-500 hover:text-slate-900">
              Temsilci girişi
            </Link>
          </nav>
        </div>
      </header>
      <main className="mx-auto max-w-3xl px-4 py-8">{children}</main>
    </div>
  );
}
