const rawApiUrl = process.env.NEXT_PUBLIC_API_URL;

if (!rawApiUrl && process.env.NODE_ENV === "production") {
  console.warn("NEXT_PUBLIC_API_URL is not set; falling back to http://localhost:3001");
}

export const API_URL = (rawApiUrl ?? "http://localhost:3001").replace(/\/$/, "");

export type ApiErrorBody = {
  error?: string;
  code?: string;
  details?: Record<string, string[]>;
};

export class ApiError extends Error {
  status: number;
  code?: string;
  details?: Record<string, string[]>;

  constructor(status: number, message: string, body: ApiErrorBody | null) {
    super(message);
    this.status = status;
    this.code = body?.code;
    this.details = body?.details;
  }
}

type Options = Omit<RequestInit, "body"> & { body?: unknown };

export async function api<T>(path: string, options: Options = {}): Promise<T> {
  const { body, headers, ...rest } = options;
  let res: Response;
  try {
    res = await fetch(`${API_URL}/api/v1${path}`, {
      ...rest,
      credentials: "include",
      cache: "no-store",
      headers: {
        Accept: "application/json",
        ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
        ...headers,
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError(0, `API'ye ulaşılamadı (${API_URL}). Sunucu kapalı olabilir veya uykudan uyanıyor olabilir.`, null);
  }

  if (res.status === 204) return undefined as T;

  const data = (await res.json().catch(() => null)) as unknown;
  if (!res.ok) {
    const errorBody = data && typeof data === "object" ? (data as ApiErrorBody) : null;
    throw new ApiError(res.status, errorBody?.error ?? `İstek başarısız (${res.status})`, errorBody);
  }
  return data as T;
}

export function errorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    if (error.details) {
      const first = Object.values(error.details).flat()[0];
      if (first) return `${error.message}: ${first}`;
    }
    return error.message;
  }
  if (error instanceof Error) return error.message;
  return "Bilinmeyen hata";
}
