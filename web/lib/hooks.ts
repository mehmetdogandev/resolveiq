"use client";

import useSWR, { type SWRConfiguration } from "swr";
import { api } from "./api";

export function useApi<T>(path: string | null, config?: SWRConfiguration<T>) {
  return useSWR<T>(path, (p: string) => api<T>(p), { revalidateOnFocus: false, ...config });
}
