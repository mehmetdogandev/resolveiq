export function LogoMark({ className = "size-8" }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className} aria-hidden>
      <rect width="32" height="32" rx="8" className="fill-accent-500" />
      <path d="M9 22V10h7.2a4.3 4.3 0 0 1 0 8.6H13" fill="none" stroke="#07111f" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" />
      <path d="m15.5 18.6 3.2 3.4 5-6" fill="none" stroke="#ffffff" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function Logo({ inverted = false }: { inverted?: boolean }) {
  return (
    <span className="flex items-center gap-2">
      <LogoMark />
      <span className={`text-[17px] font-semibold tracking-tight ${inverted ? "text-white" : "text-navy-900"}`}>
        Resolve<span className="text-accent-500">IQ</span>
      </span>
    </span>
  );
}
