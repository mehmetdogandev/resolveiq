import { Suspense } from "react";
import { AppShell } from "@/components/app-shell";
import { SessionProvider } from "@/components/session";
import { LoadingBlock } from "@/components/ui";

export default function AppLayout({ children }: LayoutProps<"/">) {
  return (
    <Suspense fallback={<LoadingBlock label="Yükleniyor..." />}>
      <SessionProvider>
        <AppShell>{children}</AppShell>
      </SessionProvider>
    </Suspense>
  );
}
