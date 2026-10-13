"use client";

import { createContext, useContext, useEffect, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { ApiError } from "@/lib/api";
import { useApi } from "@/lib/hooks";
import type { Me, Meta } from "@/lib/types";
import { ErrorState, Spinner } from "./ui";

type SessionValue = { me: Me; meta: Meta; refreshMeta: () => void };

const SessionContext = createContext<SessionValue | null>(null);

export function useSession() {
  const value = useContext(SessionContext);
  if (!value) throw new Error("useSession must be used inside SessionProvider");
  return value;
}

export function SessionProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const me = useApi<{ user: Me }>("/me");
  const meta = useApi<Meta>(me.data ? "/meta" : null);
  const unauthorized = me.error instanceof ApiError && me.error.status === 401;

  useEffect(() => {
    if (unauthorized) router.replace("/login");
  }, [unauthorized, router]);

  if (!me.data || !meta.data) {
    const error = (!unauthorized && me.error) || meta.error;
    return (
      <div className="flex flex-1 items-center justify-center p-6">
        {error ? (
          <div className="w-full max-w-md">
            <ErrorState
              message={`${error.message}`}
              onRetry={() => {
                void me.mutate();
                void meta.mutate();
              }}
            />
          </div>
        ) : (
          <Spinner label={unauthorized ? "Giriş sayfasına yönlendiriliyor..." : "Oturum yükleniyor..."} />
        )}
      </div>
    );
  }

  return (
    <SessionContext.Provider value={{ me: me.data.user, meta: meta.data, refreshMeta: () => void meta.mutate() }}>
      {children}
    </SessionContext.Provider>
  );
}
